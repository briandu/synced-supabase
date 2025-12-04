// ==============================================================
// Fix Old Discipline Permissions
// ==============================================================
// This script fixes old Discipline_Offering records that have null _rperm
// by setting them to have proper read permissions
//
// Usage:
//   node scripts/fix-old-discipline-permissions.js
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
  console.log('\n🔧 Fixing Old Discipline Offering Permissions\n');

  const client = new Client(CONFIG.DB_CONFIG);

  try {
    await client.connect();
    console.log('✓ Connected to database\n');

    await client.query('BEGIN');

    // Update Discipline_Offering records with null _rperm
    const updateResult = await client.query(
      `UPDATE "Discipline_Offering"
       SET "_rperm" = '{*}', "updatedAt" = NOW()
       WHERE "_rperm" IS NULL`
    );

    await client.query('COMMIT');

    console.log(`\n✅ Updated ${updateResult.rowCount} Discipline_Offering records with proper permissions\n`);

  } catch (error) {
    await client.query('ROLLBACK');
    console.error('\n❌ Error:', error.message);
    process.exit(1);
  } finally {
    await client.end();
  }
}

main();

