// ==============================================================
// Fix Service Prices Script
// ==============================================================
// This script fixes existing Item_Price records by converting
// dollar amounts to cents (multiplying by 100)
//
// Usage:
//   node scripts/fix-service-prices.js
//
// Options:
//   DRY_RUN=true node scripts/fix-service-prices.js (preview only)
// ==============================================================

require('dotenv').config();
const { Client } = require('pg');

// ==============================================================
// Configuration
// ==============================================================

const CONFIG = {
  DRY_RUN: process.env.DRY_RUN === 'true' || false,
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

// ==============================================================
// Validation
// ==============================================================

function validateConfig() {
  const required = ['DB_HOST', 'DB_NAME', 'DB_USER', 'DB_PASSWORD'];

  const missing = required.filter((key) => !process.env[key]);

  if (missing.length > 0) {
    console.error('\n❌ Missing required environment variables:');
    missing.forEach((key) => console.error(`   - ${key}`));
    console.error('\nPlease check your .env file. See .env.example for reference.\n');
    process.exit(1);
  }
}

// ==============================================================
// Utility Functions
// ==============================================================

function log(message) {
  console.log(`[${new Date().toISOString()}] ${message}`);
}

// ==============================================================
// Main Script
// ==============================================================

async function main() {
  console.log('\n╔═══════════════════════════════════════════════════════════╗');
  console.log('║           Fix Service Prices Script                    ║');
  console.log('╚═══════════════════════════════════════════════════════════╝\n');

  validateConfig();

  console.log(`Mode: ${CONFIG.DRY_RUN ? '🔍 DRY RUN (no data will be modified)' : '💾 LIVE (data will be modified)'}\n`);

  const client = new Client(CONFIG.DB_CONFIG);

  try {
    await client.connect();
    log('Connected to database');

    if (!CONFIG.DRY_RUN) {
      await client.query('BEGIN');
      log('Transaction started');
    }

    // ==============================================================
    // STEP 1: Find Prices That Need Fixing
    // ==============================================================
    console.log('\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    console.log('STEP 1: Analyzing Item_Price Records');
    console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');

    // Get all prices that look like they're in dollars instead of cents
    // (i.e., prices less than 10 which would be less than $0.10)
    const pricesResult = await client.query(
      `SELECT "objectId", "price", "durationMinutes"
       FROM "Item_Price"
       WHERE "price" < 1000
       ORDER BY "price" ASC`
    );

    const pricesToFix = pricesResult.rows;
    log(`Found ${pricesToFix.length} Item_Price records that need fixing`);

    if (pricesToFix.length === 0) {
      console.log('\n✅ All Item_Price records appear to be in correct format (cents)!');
      
      if (!CONFIG.DRY_RUN) {
        await client.query('COMMIT');
        log('Transaction committed');
      }
      
      await client.end();
      log('Database connection closed');
      console.log('\n✅ Script completed successfully!\n');
      return;
    }

    // Show sample of prices to fix
    console.log('\nSample of prices to fix:');
    pricesToFix.slice(0, 10).forEach(record => {
      const currentPrice = parseFloat(record.price);
      const newPrice = Math.round(currentPrice * 100);
      console.log(`  - Price: $${currentPrice.toFixed(2)} → $${(newPrice / 100).toFixed(2)} (${record.durationMinutes}min)`);
    });

    if (pricesToFix.length > 10) {
      console.log(`  ... and ${pricesToFix.length - 10} more`);
    }

    // ==============================================================
    // STEP 2: Fix Prices
    // ==============================================================
    console.log('\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    console.log('STEP 2: Fixing Prices');
    console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');

    let pricesFixed = 0;

    for (const record of pricesToFix) {
      const currentPrice = parseFloat(record.price);
      const newPrice = Math.round(currentPrice * 100);

      if (!CONFIG.DRY_RUN) {
        await client.query(
          `UPDATE "Item_Price"
           SET "price" = $1, "updatedAt" = NOW()
           WHERE "objectId" = $2`,
          [newPrice, record.objectId]
        );
      }

      pricesFixed++;

      if (pricesFixed % 50 === 0) {
        console.log(`  Processed ${pricesFixed}/${pricesToFix.length} prices...`);
      }
    }

    log(`✓ Fixed ${pricesFixed} Item_Price records`);

    // ==============================================================
    // STEP 3: Verify Results
    // ==============================================================
    console.log('\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    console.log('STEP 3: Verifying Results');
    console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');

    const remainingLowPricesResult = await client.query(
      `SELECT COUNT(*) as count
       FROM "Item_Price"
       WHERE "price" < 1000`
    );

    const remainingLowPrices = parseInt(remainingLowPricesResult.rows[0].count);

    if (remainingLowPrices > 0) {
      console.log(`⚠️  Still ${remainingLowPrices} Item_Price records with prices under $10.00`);
    } else {
      console.log('✅ All Item_Price records now have realistic prices!');
    }

    // Show sample of fixed prices
    const sampleFixedResult = await client.query(
      `SELECT "price", "durationMinutes"
       FROM "Item_Price"
       ORDER BY "price" ASC
       LIMIT 10`
    );

    console.log('\nSample of current prices (lowest):');
    sampleFixedResult.rows.forEach(record => {
      const priceInDollars = parseFloat(record.price) / 100;
      console.log(`  - $${priceInDollars.toFixed(2)} (${record.durationMinutes}min)`);
    });

    // ==============================================================
    // Commit Transaction
    // ==============================================================

    if (!CONFIG.DRY_RUN) {
      await client.query('COMMIT');
      log('Transaction committed');
    } else {
      console.log('\n🔍 DRY RUN - No changes were made to the database');
    }

    await client.end();
    log('Database connection closed');

    console.log('\n╔═══════════════════════════════════════════════════════════╗');
    console.log('║             Script Completed Successfully!              ║');
    console.log('╚═══════════════════════════════════════════════════════════╝');
    console.log('\nSummary:');
    console.log(`  - Item_Price records fixed: ${pricesFixed}\n`);

  } catch (error) {
    console.error('\n❌ Error:', error.message);
    console.error(error.stack);

    if (!CONFIG.DRY_RUN) {
      try {
        await client.query('ROLLBACK');
        log('Transaction rolled back');
      } catch (rollbackError) {
        console.error('Failed to rollback transaction:', rollbackError.message);
      }
    }

    await client.end();
    process.exit(1);
  }
}

// ==============================================================
// Run Script
// ==============================================================

main();

