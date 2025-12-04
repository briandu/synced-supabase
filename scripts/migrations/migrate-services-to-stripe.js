#!/usr/bin/env node

/**
 * Migration Script: Sync Existing Services to Stripe
 * 
 * This script syncs all existing services (Items_Catalog) and prices (Item_Price)
 * to Stripe Products and Prices, then updates the Parse Server records with Stripe IDs.
 * 
 * Usage:
 *   node scripts/migrate-services-to-stripe.js --org <orgId> [--dry-run]
 * 
 * Options:
 *   --org <orgId>    Organization ID to sync services for (required)
 *   --dry-run        Preview changes without making them
 *   --limit <n>      Limit number of services to process (for testing)
 */

require('dotenv').config({ path: '.env.local' });
const { Client } = require('pg');
const Stripe = require('stripe');

// Configuration
const CONFIG = {
  ORG_ID: null,
  DRY_RUN: false,
  LIMIT: null,
  DB_CONFIG: {
    connectionString: process.env.DATABASE_URL,
    ssl: process.env.DATABASE_URL?.includes('localhost') ? false : { rejectUnauthorized: false },
  },
};

// Parse command line arguments
process.argv.slice(2).forEach((arg, index, args) => {
  if (arg === '--org' && args[index + 1]) {
    CONFIG.ORG_ID = args[index + 1];
  } else if (arg === '--dry-run') {
    CONFIG.DRY_RUN = true;
  } else if (arg === '--limit' && args[index + 1]) {
    CONFIG.LIMIT = parseInt(args[index + 1], 10);
  }
});

if (!CONFIG.ORG_ID) {
  console.error('❌ Error: --org parameter is required');
  console.log('\nUsage: node scripts/migrate-services-to-stripe.js --org <orgId> [--dry-run] [--limit <n>]');
  process.exit(1);
}

// Initialize Stripe
function getStripe() {
  const apiKey = process.env.STRIPE_SECRET_KEY;
  if (!apiKey) {
    throw new Error('STRIPE_SECRET_KEY is not configured');
  }
  return new Stripe(apiKey, { apiVersion: '2024-06-20' });
}

// Utility functions
function log(message) {
  const prefix = CONFIG.DRY_RUN ? '[DRY RUN]' : '';
  console.log(`${prefix} ${message}`);
}

function generateObjectId() {
  const timestamp = Math.floor(new Date().getTime() / 1000).toString(16);
  const randomBytes = 'xxxxxxxxxxxx'.replace(/x/g, () => ((Math.random() * 16) | 0).toString(16));
  return timestamp + randomBytes;
}

// Build Stripe metadata
function buildProductMetadata(serviceOffering) {
  const metadata = {
    itemId: serviceOffering.itemId,
    serviceOfferingId: serviceOffering.serviceOfferingId,
    orgId: serviceOffering.orgId,
    source: 'synced-admin-portal-migration',
  };

  if (serviceOffering.disciplineOfferingId) {
    metadata.disciplineOfferingId = serviceOffering.disciplineOfferingId;
  }

  if (serviceOffering.locationId) {
    metadata.locationId = serviceOffering.locationId;
    metadata.hierarchy = 'location';
  } else if (serviceOffering.ownershipGroupId) {
    metadata.ownershipGroupId = serviceOffering.ownershipGroupId;
    metadata.hierarchy = 'ownershipGroup';
  } else {
    metadata.hierarchy = 'org';
  }

  return metadata;
}

function buildPriceMetadata(itemPrice, serviceOffering) {
  const metadata = {
    itemPriceId: itemPrice.itemPriceId,
    itemId: itemPrice.itemId,
    durationMinutes: String(itemPrice.durationMinutes),
    orgId: itemPrice.orgId || serviceOffering.orgId,
    source: 'synced-admin-portal-migration',
  };

  if (itemPrice.staffId) {
    metadata.staffId = itemPrice.staffId;
    metadata.priceType = 'staff';
  } else if (itemPrice.locationId) {
    metadata.locationId = itemPrice.locationId;
    metadata.priceType = 'location';
  } else if (itemPrice.ownershipGroupId) {
    metadata.ownershipGroupId = itemPrice.ownershipGroupId;
    metadata.priceType = 'ownershipGroup';
  } else {
    metadata.priceType = 'org';
  }

  return metadata;
}

async function main() {
  console.log('\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  console.log('🔄 Stripe Service Migration');
  console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');

  log(`Organization ID: ${CONFIG.ORG_ID}`);
  if (CONFIG.DRY_RUN) {
    log('🔍 DRY RUN MODE - No changes will be made');
  }
  if (CONFIG.LIMIT) {
    log(`📊 Limiting to ${CONFIG.LIMIT} services`);
  }

  const client = new Client(CONFIG.DB_CONFIG);
  const stripe = getStripe();

  try {
    await client.connect();
    log('✅ Connected to database');

    if (!CONFIG.DRY_RUN) {
      await client.query('BEGIN');
      log('✅ Transaction started');
    }

    // Step 1: Get all Service_Offerings for the org (with hierarchy)
    console.log('\n━━━ Step 1: Fetching Service Offerings ━━━\n');
    const serviceOfferingsQuery = `
      SELECT 
        so."objectId" as "serviceOfferingId",
        so."orgId",
        so."ownershipGroupId",
        so."locationId",
        so."disciplineOfferingId",
        so."itemId",
        ic."objectId" as "itemCatalogId",
        ic."itemName",
        ic."description",
        ic."stripeProductId"
      FROM "Service_Offering" so
      INNER JOIN "Items_Catalog" ic ON so."itemId" = ic."objectId"
      WHERE so."orgId" = $1
        AND ic."type" = 'service'
        AND ic."itemName" NOT LIKE '%Staff Placeholder%'
      ${CONFIG.LIMIT ? `LIMIT ${CONFIG.LIMIT}` : ''}
    `;

    const serviceOfferings = await client.query(serviceOfferingsQuery, [CONFIG.ORG_ID]);
    log(`Found ${serviceOfferings.rows.length} service offerings`);

    let productsCreated = 0;
    let productsUpdated = 0;
    let productsSkipped = 0;
    let pricesCreated = 0;
    let pricesSkipped = 0;

    // Step 2: Process each service offering
    for (const offering of serviceOfferings.rows) {
      console.log(`\n📦 Processing: ${offering.itemName} (${offering.serviceOfferingId})`);

      const productMetadata = buildProductMetadata(offering);

      try {
        let stripeProductId = offering.stripeProductId;
        let productAction = 'skipped';

        if (!stripeProductId) {
          // Create new Stripe Product
          if (!CONFIG.DRY_RUN) {
            const product = await stripe.products.create({
              name: offering.itemName,
              description: offering.description || offering.itemName,
              metadata: productMetadata,
              active: true,
            });
            stripeProductId = product.id;
          } else {
            stripeProductId = 'prod_DRY_RUN_' + generateObjectId();
          }
          productAction = 'created';
          productsCreated++;
        } else {
          // Update existing Stripe Product metadata
          if (!CONFIG.DRY_RUN) {
            await stripe.products.update(stripeProductId, {
              metadata: productMetadata,
            });
          }
          productAction = 'updated';
          productsUpdated++;
        }

        log(`  ✓ Product ${productAction}: ${stripeProductId}`);

        // Update Items_Catalog with Stripe Product ID
        if (!CONFIG.DRY_RUN && productAction === 'created') {
          await client.query(
            `UPDATE "Items_Catalog" SET "stripeProductId" = $1, "updatedAt" = NOW() WHERE "objectId" = $2`,
            [stripeProductId, offering.itemCatalogId]
          );
        }

        // Step 3: Get all Item_Prices for this service
        const itemPricesQuery = `
          SELECT 
            "objectId" as "itemPriceId",
            "price",
            "currency",
            "durationMinutes",
            "itemId",
            "orgId",
            "ownershipGroupId",
            "locationId",
            "staffId",
            "stripePriceId"
          FROM "Item_Price"
          WHERE "itemId" = $1
        `;

        const itemPrices = await client.query(itemPricesQuery, [offering.itemId]);
        log(`  Found ${itemPrices.rows.length} price variant(s)`);

        // Step 4: Create Stripe Prices for each Item_Price
        for (const itemPrice of itemPrices.rows) {
          const priceMetadata = buildPriceMetadata(itemPrice, offering);

          try {
            if (!itemPrice.stripePriceId) {
              let stripePriceId;

              if (!CONFIG.DRY_RUN) {
                const price = await stripe.prices.create({
                  product: stripeProductId,
                  unit_amount: itemPrice.price,
                  currency: itemPrice.currency?.toLowerCase() || 'usd',
                  metadata: priceMetadata,
                  active: true,
                });
                stripePriceId = price.id;
              } else {
                stripePriceId = 'price_DRY_RUN_' + generateObjectId();
              }

              log(`    ✓ Price created: ${stripePriceId} (${itemPrice.durationMinutes} mins, $${itemPrice.price / 100})`);
              pricesCreated++;

              // Update Item_Price with Stripe Price ID
              if (!CONFIG.DRY_RUN) {
                await client.query(
                  `UPDATE "Item_Price" SET "stripePriceId" = $1, "updatedAt" = NOW() WHERE "objectId" = $2`,
                  [stripePriceId, itemPrice.itemPriceId]
                );
              }
            } else {
              log(`    → Price already synced: ${itemPrice.stripePriceId}`);
              pricesSkipped++;
            }
          } catch (priceError) {
            console.error(`    ❌ Error creating price: ${priceError.message}`);
          }
        }
      } catch (productError) {
        console.error(`  ❌ Error processing product: ${productError.message}`);
        productsSkipped++;
      }
    }

    // Commit transaction
    if (!CONFIG.DRY_RUN) {
      await client.query('COMMIT');
      log('\n✅ Transaction committed');
    }

    // Summary
    console.log('\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    console.log('📊 Migration Summary');
    console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
    console.log(`Products Created:  ${productsCreated}`);
    console.log(`Products Updated:  ${productsUpdated}`);
    console.log(`Products Skipped:  ${productsSkipped}`);
    console.log(`Prices Created:    ${pricesCreated}`);
    console.log(`Prices Skipped:    ${pricesSkipped}`);
    console.log('\n✨ Migration completed successfully!\n');
  } catch (error) {
    console.error('\n❌ Migration failed:', error);
    if (!CONFIG.DRY_RUN) {
      await client.query('ROLLBACK');
      log('↩️  Transaction rolled back');
    }
    process.exit(1);
  } finally {
    await client.end();
  }
}

// Run the migration
main();

