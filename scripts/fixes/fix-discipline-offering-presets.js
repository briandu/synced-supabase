// ==============================================================
// Fix Discipline_Offering Preset Links Script
// ==============================================================
// This script ensures all Discipline_Offering records are properly
// linked to Discipline_Preset records via presetId
//
// Usage:
//   node scripts/fix-discipline-offering-presets.js
//
// Options:
//   DRY_RUN=true node scripts/fix-discipline-offering-presets.js (preview only)
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

function generateObjectId() {
  const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
  let result = '';
  for (let i = 0; i < 10; i++) {
    result += chars.charAt(Math.floor(Math.random() * chars.length));
  }
  return result;
}

function log(message) {
  console.log(`[${new Date().toISOString()}] ${message}`);
}

// ==============================================================
// Discipline Preset Templates
// ==============================================================

const DISCIPLINE_PRESETS = [
  { name: 'Physical Therapy', icon: 'AccessibilityNew' },
  { name: 'Occupational Therapy', icon: 'Work' },
  { name: 'Sports Medicine', icon: 'FitnessCenter' },
  { name: 'Orthopedics', icon: 'Healing' },
  { name: 'Neurology', icon: 'Psychology' },
  { name: 'Pediatric Therapy', icon: 'ChildCare' },
  { name: 'Geriatric Care', icon: 'Elderly' },
  { name: 'Aquatic Therapy', icon: 'Pool' },
  { name: 'Manual Therapy', icon: 'PanTool' },
  { name: 'Wellness & Prevention', icon: 'Favorite' },
  { name: 'Other', icon: 'MoreHoriz' }, // For custom disciplines
];

// ==============================================================
// Main Script
// ==============================================================

async function main() {
  console.log('\n╔═══════════════════════════════════════════════════════════╗');
  console.log('║   Fix Discipline_Offering Preset Links Script          ║');
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
    // STEP 1: Check and Create Discipline_Preset Records
    // ==============================================================
    console.log('\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    console.log('STEP 1: Checking Discipline_Preset Records');
    console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');

    const existingPresetsResult = await client.query(
      'SELECT "objectId", "name", "icon" FROM "Discipline_Preset"'
    );
    
    const existingPresets = existingPresetsResult.rows;
    log(`Found ${existingPresets.length} existing Discipline_Preset records`);

    const presetMap = new Map();
    existingPresets.forEach(preset => {
      presetMap.set(preset.name.toLowerCase().trim(), preset.objectId);
      console.log(`  - ${preset.name} (${preset.objectId})`);
    });

    let presetsCreated = 0;

    // Create missing presets
    for (const preset of DISCIPLINE_PRESETS) {
      const normalizedName = preset.name.toLowerCase().trim();
      
      if (!presetMap.has(normalizedName)) {
        const presetId = generateObjectId();
        console.log(`Creating Discipline_Preset: ${preset.name}`);

        if (!CONFIG.DRY_RUN) {
          await client.query(
            `INSERT INTO "Discipline_Preset" 
             ("objectId", "createdAt", "updatedAt", "_rperm", "_wperm", "name", "icon", "isPreset", "disciplineName")
             VALUES ($1, NOW(), NOW(), ARRAY['*'], ARRAY[]::text[], $2, $3, true, $4)`,
            [presetId, preset.name, preset.icon, preset.name]
          );
        }

        presetMap.set(normalizedName, presetId);
        presetsCreated++;
      }
    }

    log(`✓ Created ${presetsCreated} new Discipline_Preset records`);

    // ==============================================================
    // STEP 2: Find Discipline_Offerings Without presetId
    // ==============================================================
    console.log('\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    console.log('STEP 2: Finding Discipline_Offering Records Without presetId');
    console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');

    const offeringsWithoutPresetResult = await client.query(
      `SELECT "objectId", "customName", "orgId", "ownershipGroupId", "locationId"
       FROM "Discipline_Offering"
       WHERE "presetId" IS NULL`
    );

    const offeringsWithoutPreset = offeringsWithoutPresetResult.rows;
    log(`Found ${offeringsWithoutPreset.length} Discipline_Offering records without presetId`);

    if (offeringsWithoutPreset.length === 0) {
      console.log('\n✅ All Discipline_Offering records already have presetId set!');
      
      if (!CONFIG.DRY_RUN) {
        await client.query('COMMIT');
        log('Transaction committed');
      }
      
      await client.end();
      log('Database connection closed');
      console.log('\n✅ Script completed successfully!\n');
      return;
    }

    // ==============================================================
    // STEP 3: Link Discipline_Offerings to Presets
    // ==============================================================
    console.log('\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    console.log('STEP 3: Linking Discipline_Offerings to Presets');
    console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');

    let offeringsUpdated = 0;
    let offeringsWithoutMatch = [];

    for (const offering of offeringsWithoutPreset) {
      const customName = offering.customName || '';
      const normalizedName = customName.toLowerCase().trim();
      
      // Try to find a matching preset
      let presetId = presetMap.get(normalizedName);

      // If no exact match, use "Other" preset
      if (!presetId) {
        presetId = presetMap.get('other');
        console.log(`  ⚠ No exact match for "${customName}" - using "Other" preset`);
        offeringsWithoutMatch.push({ 
          objectId: offering.objectId, 
          customName: customName,
          presetUsed: 'Other'
        });
      } else {
        console.log(`  ✓ Linking "${customName}" to preset ${presetId}`);
      }

      if (presetId && !CONFIG.DRY_RUN) {
        await client.query(
          `UPDATE "Discipline_Offering"
           SET "presetId" = $1, "updatedAt" = NOW()
           WHERE "objectId" = $2`,
          [presetId, offering.objectId]
        );
        offeringsUpdated++;
      } else if (presetId) {
        offeringsUpdated++;
      }
    }

    log(`✓ Updated ${offeringsUpdated} Discipline_Offering records`);

    if (offeringsWithoutMatch.length > 0) {
      console.log(`\n⚠️  ${offeringsWithoutMatch.length} offerings were linked to "Other" preset:`);
      offeringsWithoutMatch.forEach(item => {
        console.log(`   - ${item.customName} (${item.objectId})`);
      });
      console.log('\n   These can be manually updated if needed.');
    }

    // ==============================================================
    // STEP 4: Verify Results
    // ==============================================================
    console.log('\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    console.log('STEP 4: Verifying Results');
    console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');

    const remainingNullResult = await client.query(
      `SELECT COUNT(*) as count
       FROM "Discipline_Offering"
       WHERE "presetId" IS NULL`
    );

    const remainingNull = parseInt(remainingNullResult.rows[0].count);

    if (remainingNull > 0) {
      console.log(`⚠️  Still ${remainingNull} Discipline_Offering records without presetId`);
    } else {
      console.log('✅ All Discipline_Offering records now have presetId set!');
    }

    const linkedResult = await client.query(
      `SELECT COUNT(*) as count
       FROM "Discipline_Offering"
       WHERE "presetId" IS NOT NULL`
    );

    const linkedCount = parseInt(linkedResult.rows[0].count);
    console.log(`✅ Total Discipline_Offering records with presetId: ${linkedCount}`);

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
    console.log(`  - Discipline_Preset records created: ${presetsCreated}`);
    console.log(`  - Discipline_Offering records updated: ${offeringsUpdated}`);
    console.log(`  - Records linked to "Other": ${offeringsWithoutMatch.length}\n`);

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

