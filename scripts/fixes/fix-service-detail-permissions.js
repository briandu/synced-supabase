// ==============================================================
// Fix Service_Detail Permissions Script
// ==============================================================
// This script fixes Service_Detail records that have null _rperm
//
// Usage:
//   node scripts/fix-service-detail-permissions.js
// ==============================================================

require('dotenv').config();
const { Client } = require('pg');

const CONFIG = {
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
  console.log('\n🔧 Fixing Service_Detail permissions...\n');

  const client = new Client(CONFIG.DB_CONFIG);

  try {
    await client.connect();
    console.log('✓ Connected to database');

    await client.query('BEGIN');

    // Update Service_Detail records with null _rperm
    const updateResult = await client.query(
      `UPDATE "Service_Detail"
       SET "_rperm" = '{*}', "updatedAt" = NOW()
       WHERE "_rperm" IS NULL`
    );

    console.log(`✓ Updated ${updateResult.rowCount} Service_Detail records`);

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

