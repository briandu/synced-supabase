// ==============================================================
// Fix Service Disciplines Script
// ==============================================================
// This script fixes Service_Offering records that have null disciplineOfferingId
//
// Usage:
//   node scripts/fix-service-disciplines.js
// ==============================================================

require('dotenv').config();
const { Client } = require('pg');

const CONFIG = {
  ORG_ID: process.env.SEED_ORG_ID || '5xQsXXshnZ',
  DB_CONFIG: {
    host: process.env.DB_HOST,
    port: parseInt(process.env.DB_PORT || '5432', 10),
    database: process.env.DB_NAME,
    user: process.env.DB_USER,
    password: process.env.DB_PASSWORD,
    ssl:
      process.env.DB_SSL === 'true'
        ? {
          rejectUnauthorized: process.env.DB_SSL_REJECT_UNAUTHORIZED !== 'false',
        }
        : false,
  },
};

async function main() {
  console.log('\n🔧 Fixing Service Offerings with null disciplineOfferingId...\n');

  const client = new Client(CONFIG.DB_CONFIG);

  try {
    await client.connect();
    console.log('✓ Connected to database');

    await client.query('BEGIN');

    // Get a discipline to assign
    const disciplineResult = await client.query(
      `SELECT "objectId" FROM "Discipline_Offering"
       WHERE "orgId" = $1
       AND "customName" = 'Physical Therapy'
       LIMIT 1`,
      [CONFIG.ORG_ID]
    );

    if (disciplineResult.rows.length === 0) {
      throw new Error('No Physical Therapy discipline found');
    }

    const disciplineId = disciplineResult.rows[0].objectId;
    console.log(`Using discipline: ${disciplineId}`);

    // Update Service_Offering records
    const updateResult = await client.query(
      `UPDATE "Service_Offering"
       SET "disciplineOfferingId" = $1, "updatedAt" = NOW()
       WHERE "orgId" = $2
       AND "disciplineOfferingId" IS NULL
       AND "createdAt" > NOW() - INTERVAL '2 hours'`,
      [disciplineId, CONFIG.ORG_ID]
    );

    console.log(`✓ Updated ${updateResult.rowCount} Service_Offering records`);

    await client.query('COMMIT');
    console.log('✓ Transaction committed\n');
    console.log('✨ Fix completed successfully!\n');

  } catch (error) {
    await client.query('ROLLBACK');
    console.error('\n❌ Error:', error.message);
    process.exit(1);
  } finally {
    await client.end();
  }
}

main();

