#!/usr/bin/env node

/**
 * Seed default no-show and late cancellation fees
 * This creates default fees matching the hardcoded options that were previously used
 */

import fs from 'fs';
import pg from 'pg';
import path from 'path';

const { Client } = pg;

function loadDatabaseConfig() {
  try {
    const homeDir = process.env.HOME || process.env.USERPROFILE || '';
    const cfgPath = path.join(homeDir, '.cursor', 'mcp.json');
    const txt = fs.readFileSync(cfgPath, 'utf-8');
    const cfg = JSON.parse(txt);

    let dbUrl = cfg?.mcpServers?.['postgres-dev-write']?.env?.DATABASE_URL;
    if (!dbUrl && cfg?.mcpServers?.['postgres-dev']?.args) {
      const { args } = cfg.mcpServers['postgres-dev'];
      dbUrl = args.find((arg) => arg.startsWith('postgresql://'));
    }

    if (dbUrl) {
      // Modify connection string to allow insecure SSL
      if (dbUrl.includes('?sslmode=require')) {
        dbUrl = dbUrl.replace('?sslmode=require', '?sslmode=no-verify');
      } else if (dbUrl.includes('sslmode=require')) {
        dbUrl = dbUrl.replace('sslmode=require', 'sslmode=no-verify');
      } else if (!dbUrl.includes('sslmode')) {
        dbUrl += (dbUrl.includes('?') ? '&' : '?') + 'sslmode=no-verify';
      }

      return {
        connectionString: dbUrl,
        ssl: { rejectUnauthorized: false },
      };
    }
  } catch (err) {
    console.log('⚠️  Could not read mcp.json:', err.message);
  }

  throw new Error('Missing database configuration');
}

async function seedDefaultFees(orgId) {
  console.log(`\n💰 Seeding default fees for org: ${orgId}\n`);

  const client = new Client(loadDatabaseConfig());

  try {
    await client.connect();
    console.log('✅ Connected to database\n');

    // Default no-show fees (matching previously hardcoded options)
    const defaultNoShowFees = [
      {
        name: 'No Show - Full Price',
        feeCalculationType: 'override',
        sortOrder: 1,
      },
      {
        name: 'No Show - 50%',
        feeCalculationType: 'percent_discount',
        sortOrder: 2,
      },
      {
        name: 'No Show - $20.00',
        feeCalculationType: 'dollar_discount',
        sortOrder: 3,
      },
      {
        name: 'No Show - $0.00',
        feeCalculationType: 'no_charge',
        sortOrder: 4,
      },
    ];

    // Default late cancellation fees
    const defaultLateCancellationFees = [
      {
        name: 'Late Cancellation - 50%',
        feeCalculationType: 'percent_discount',
        sortOrder: 1,
      },
      {
        name: 'Late Cancellation - $20.00',
        feeCalculationType: 'dollar_discount',
        sortOrder: 2,
      },
    ];

    // Check if fees already exist for this org
    const checkQuery = `
      SELECT COUNT(*) as count
      FROM "Fee"
      WHERE "orgId" = $1
    `;
    const checkResult = await client.query(checkQuery, [orgId]);
    const existingCount = parseInt(checkResult.rows[0].count, 10);

    if (existingCount > 0) {
      console.log(`⚠️  Found ${existingCount} existing fees for this org. Skipping seed.`);
      console.log('   To re-seed, delete existing fees first.\n');
      return;
    }

    console.log('📝 Creating default fees...\n');

    // Insert no-show fees
    for (const fee of defaultNoShowFees) {
      const insertQuery = `
        INSERT INTO "Fee" ("objectId", "feeType", "name", "feeCalculationType", "orgId", "sortOrder", "isActive", "createdAt", "updatedAt", "_rperm", "_wperm")
        VALUES (
          gen_random_uuid()::text,
          $1,
          $2,
          $3,
          $4,
          $5,
          true,
          NOW(),
          NOW(),
          ARRAY[]::text[],
          ARRAY[]::text[]
        )
        RETURNING "objectId", "name"
      `;

      const result = await client.query(insertQuery, [
        'no_show',
        fee.name,
        fee.feeCalculationType,
        orgId,
        fee.sortOrder,
      ]);

      console.log(`  ✅ Created: ${result.rows[0].name} (${result.rows[0].objectId})`);
    }

    // Insert late cancellation fees
    for (const fee of defaultLateCancellationFees) {
      const insertQuery = `
        INSERT INTO "Fee" ("objectId", "feeType", "name", "feeCalculationType", "orgId", "sortOrder", "isActive", "createdAt", "updatedAt", "_rperm", "_wperm")
        VALUES (
          gen_random_uuid()::text,
          $1,
          $2,
          $3,
          $4,
          $5,
          true,
          NOW(),
          NOW(),
          ARRAY[]::text[],
          ARRAY[]::text[]
        )
        RETURNING "objectId", "name"
      `;

      const result = await client.query(insertQuery, [
        'late_cancellation',
        fee.name,
        fee.feeCalculationType,
        orgId,
        fee.sortOrder,
      ]);

      console.log(`  ✅ Created: ${result.rows[0].name} (${result.rows[0].objectId})`);
    }

    console.log(`\n✅ Successfully seeded ${defaultNoShowFees.length + defaultLateCancellationFees.length} default fees\n`);
  } catch (error) {
    console.error('❌ Error seeding fees:', error.message);
    process.exit(1);
  } finally {
    await client.end();
  }
}

// Get orgId from command line argument
const orgId = process.argv[2];

if (!orgId) {
  console.error('❌ Usage: node scripts/seed-default-fees.js <orgId>');
  console.error('   Example: node scripts/seed-default-fees.js abc123xyz');
  process.exit(1);
}

seedDefaultFees(orgId)
  .then(() => {
    console.log('✅ Done!');
    process.exit(0);
  })
  .catch((error) => {
    console.error('\n❌ Error:', error);
    process.exit(1);
  });

