// ==============================================================
// Service & Discipline Seeding Script
// ==============================================================
// This script creates diverse services, disciplines, and pricing
// at different levels (org/ownership group/location)
//
// Usage:
//   node scripts/seed-services-and-disciplines.js
//
// Options:
//   DRY_RUN=true node scripts/seed-services-and-disciplines.js (preview only)
// ==============================================================

require('dotenv').config();
const { Client } = require('pg');

// ==============================================================
// Configuration
// ==============================================================

const CONFIG = {
  DRY_RUN: process.env.DRY_RUN === 'true' || false,
  ORG_ID: process.env.SEED_ORG_ID,
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
  const required = ['SEED_ORG_ID', 'DB_HOST', 'DB_NAME', 'DB_USER', 'DB_PASSWORD'];

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
// Discipline Templates
// ==============================================================

const DISCIPLINES = [
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
];

// ==============================================================
// Service Templates by Type
// ==============================================================

const SERVICE_TEMPLATES = {
  // Initial Assessments
  initial_assessment: [
    { name: 'Initial Assessment - General', duration: 60, basePrice: 150 },
    { name: 'Initial Assessment - Complex Case', duration: 90, basePrice: 225 },
    { name: 'Initial Assessment - Pediatric', duration: 75, basePrice: 180 },
    { name: 'Initial Assessment - Geriatric', duration: 75, basePrice: 180 },
    { name: 'Initial Assessment - Sports Injury', duration: 60, basePrice: 165 },
  ],

  // Follow-up Treatments
  follow_up: [
    { name: 'Follow-up Treatment - Standard', duration: 45, basePrice: 110 },
    { name: 'Follow-up Treatment - Extended', duration: 60, basePrice: 140 },
    { name: 'Follow-up Treatment - Short', duration: 30, basePrice: 85 },
    { name: 'Progress Re-assessment', duration: 45, basePrice: 120 },
  ],

  // Specialized Treatments
  specialized: [
    { name: 'Manual Therapy Session', duration: 60, basePrice: 140 },
    { name: 'Dry Needling', duration: 30, basePrice: 95 },
    { name: 'Cupping Therapy', duration: 30, basePrice: 90 },
    { name: 'Instrument Assisted Soft Tissue Mobilization', duration: 45, basePrice: 120 },
    { name: 'Therapeutic Taping', duration: 30, basePrice: 75 },
    { name: 'Joint Mobilization', duration: 45, basePrice: 125 },
    { name: 'Myofascial Release', duration: 60, basePrice: 135 },
    { name: 'Trigger Point Therapy', duration: 45, basePrice: 115 },
  ],

  // Exercise-based
  exercise: [
    { name: 'Therapeutic Exercise Session', duration: 45, basePrice: 100 },
    { name: 'Strength & Conditioning Program', duration: 60, basePrice: 130 },
    { name: 'Balance & Coordination Training', duration: 45, basePrice: 105 },
    { name: 'Gait Training', duration: 45, basePrice: 110 },
    { name: 'Functional Movement Assessment', duration: 60, basePrice: 145 },
  ],

  // Aquatic Therapy
  aquatic: [
    { name: 'Aquatic Therapy Session', duration: 45, basePrice: 125 },
    { name: 'Pool-based Exercise Class', duration: 60, basePrice: 95 },
    { name: 'Aquatic Rehabilitation', duration: 60, basePrice: 140 },
  ],

  // Group Services
  group: [
    { name: 'Group Exercise Class', duration: 60, basePrice: 45 },
    { name: 'Group Education Session', duration: 90, basePrice: 55 },
    { name: 'Wellness Workshop', duration: 120, basePrice: 65 },
    { name: 'Injury Prevention Seminar', duration: 90, basePrice: 60 },
  ],

  // Consultations
  consultation: [
    { name: 'Telehealth Consultation', duration: 30, basePrice: 80 },
    { name: 'Home Assessment Visit', duration: 90, basePrice: 195 },
    { name: 'Workplace Ergonomic Assessment', duration: 120, basePrice: 250 },
    { name: 'Pre-surgical Consultation', duration: 45, basePrice: 135 },
    { name: 'Post-surgical Follow-up', duration: 45, basePrice: 125 },
  ],

  // WCB Services
  wcb: [
    { name: 'WCB Initial Assessment', duration: 60, basePrice: 155 },
    { name: 'WCB Follow-up Treatment', duration: 45, basePrice: 115 },
    { name: 'WCB Functional Capacity Evaluation', duration: 180, basePrice: 450 },
    { name: 'WCB Work Conditioning Program', duration: 120, basePrice: 280 },
  ],

  // MVA Services
  mva: [
    { name: 'MVA Initial Assessment', duration: 60, basePrice: 155 },
    { name: 'MVA Follow-up Treatment', duration: 45, basePrice: 115 },
    { name: 'MVA Documentation & Reporting', duration: 30, basePrice: 95 },
  ],
};

// ==============================================================
// Price & Duration Variation Strategies
// ==============================================================

function calculateVariedPrice(basePrice, level, locationMultiplier = 1) {
  // level can be 'org', 'ownershipGroup', or 'location'
  let price = basePrice;

  // Apply location-based multiplier (for urban vs suburban pricing)
  price *= locationMultiplier;

  // Add small random variation (-5% to +10%)
  const variation = 1 + (Math.random() * 0.15 - 0.05);
  price *= variation;

  // Round to nearest $5
  price = Math.round(price / 5) * 5;
  
  // Convert to cents for storage (prices are stored as cents in the database)
  return Math.round(price * 100);
}

// Get varied duration options for a service (e.g., 30, 45, 60 min versions)
function getVariedDurations(baseDuration) {
  const durations = [baseDuration];
  
  // Add shorter option for longer services
  if (baseDuration >= 60) {
    durations.push(baseDuration - 15);
  }
  
  // Add longer option for shorter services
  if (baseDuration <= 45) {
    durations.push(baseDuration + 15);
  }
  
  // For 45min services, add both 30min and 60min options
  if (baseDuration === 45) {
    durations.unshift(30); // Add 30min at start
  }
  
  return durations;
}

// ==============================================================
// Main Script
// ==============================================================

async function main() {
  console.log('\n╔═══════════════════════════════════════════════════════════╗');
  console.log('║     Service & Discipline Seeding Script                 ║');
  console.log('╚═══════════════════════════════════════════════════════════╝\n');

  validateConfig();

  console.log(`Mode: ${CONFIG.DRY_RUN ? '🔍 DRY RUN (no data will be created)' : '💾 LIVE (data will be created)'}\n`);

  const client = new Client(CONFIG.DB_CONFIG);

  try {
    await client.connect();
    log('Connected to database');

    if (!CONFIG.DRY_RUN) {
      await client.query('BEGIN');
      log('Transaction started');
    }

    // ==============================================================
    // STEP 1: Get Org Structure
    // ==============================================================
    console.log('\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    console.log('STEP 1: Analyzing Organization Structure');
    console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');

    const orgResult = await client.query(
      'SELECT "objectId", "orgName" FROM "Org" WHERE "objectId" = $1',
      [CONFIG.ORG_ID]
    );

    if (orgResult.rows.length === 0) {
      throw new Error(`Organization not found with ID: ${CONFIG.ORG_ID}`);
    }

    const org = orgResult.rows[0];
    log(`Found organization: ${org.orgName} (${org.objectId})`);

    // Get ownership groups
    const ownershipGroupsResult = await client.query(
      'SELECT "objectId", "ogName" FROM "Ownership_Group" WHERE "orgId" = $1',
      [CONFIG.ORG_ID]
    );
    const ownershipGroups = ownershipGroupsResult.rows;
    log(`Found ${ownershipGroups.length} ownership groups`);

    // Get locations
    const locationsResult = await client.query(
      `SELECT l."objectId", l."locationName", l."ownershipGroupId"
       FROM "Location" l
       INNER JOIN "Ownership_Group" og ON l."ownershipGroupId" = og."objectId"
       WHERE og."orgId" = $1`,
      [CONFIG.ORG_ID]
    );
    const locations = locationsResult.rows;
    log(`Found ${locations.length} locations`);

    // ==============================================================
    // STEP 2: Create or Get Discipline Presets
    // ==============================================================
    console.log('\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    console.log('STEP 2: Ensuring Discipline Presets Exist');
    console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');

    const presetMap = {};
    let presetsCreated = 0;

    // First, get existing presets
    const existingPresetsResult = await client.query(
      'SELECT "objectId", "name" FROM "Discipline_Preset"'
    );
    
    existingPresetsResult.rows.forEach(preset => {
      presetMap[preset.name] = preset.objectId;
    });
    
    log(`Found ${existingPresetsResult.rows.length} existing Discipline_Preset records`);

    // Create missing presets
    for (const discipline of DISCIPLINES) {
      if (!presetMap[discipline.name]) {
        const presetId = generateObjectId();
        presetMap[discipline.name] = presetId;

        console.log(`Creating Discipline_Preset: ${discipline.name}`);

        if (!CONFIG.DRY_RUN) {
          await client.query(
            `INSERT INTO "Discipline_Preset" 
             ("objectId", "createdAt", "updatedAt", "_rperm", "_wperm", "name", "icon", "isPreset", "disciplineName")
             VALUES ($1, NOW(), NOW(), ARRAY['*'], ARRAY[]::text[], $2, $3, true, $4)`,
            [presetId, discipline.name, discipline.icon, discipline.name]
          );
        }
        presetsCreated++;
      } else {
        console.log(`Using existing Discipline_Preset: ${discipline.name}`);
      }
    }

    log(`✓ Created ${presetsCreated} new Discipline_Preset records`);

    // ==============================================================
    // STEP 3: Create Discipline Offerings
    // ==============================================================
    console.log('\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    console.log('STEP 3: Creating Discipline Offerings');
    console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');

    const disciplineIds = {};
    let disciplinesCreated = 0;

    for (const discipline of DISCIPLINES) {
      const disciplineId = generateObjectId();
      disciplineIds[discipline.name] = disciplineId;
      const presetId = presetMap[discipline.name];

      console.log(`Creating discipline offering: ${discipline.name} (linked to preset ${presetId})`);

      if (!CONFIG.DRY_RUN) {
        await client.query(
          `INSERT INTO "Discipline_Offering" 
           ("objectId", "createdAt", "updatedAt", "_rperm", "_wperm", "presetId", "customName", "orgId")
           VALUES ($1, NOW(), NOW(), ARRAY['*'], ARRAY[]::text[], $2, $3, $4)`,
          [disciplineId, presetId, discipline.name, CONFIG.ORG_ID]
        );
      }

      disciplinesCreated++;
    }

    log(`✓ Created ${disciplinesCreated} discipline offerings`);

    // ==============================================================
    // STEP 4: Create Services & Pricing
    // ==============================================================
    console.log('\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    console.log('STEP 4: Creating Services & Pricing');
    console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');

    let servicesCreated = 0;
    let pricesCreated = 0;

    for (const [serviceType, services] of Object.entries(SERVICE_TEMPLATES)) {
      console.log(`\n--- ${serviceType.toUpperCase()} Services ---`);

      for (const service of services) {
        // Create Service_Detail
        const serviceDetailId = generateObjectId();
        const itemId = generateObjectId();

        // Map service type to standardized types
        const mappedServiceType = (() => {
          if (serviceType === 'specialized' || serviceType === 'exercise' || serviceType === 'aquatic') {
            return 'follow_up';
          }
          if (serviceType === 'consultation') {
            return 'initial_consultation';
          }
          if (serviceType === 'group') {
            return 'group_session';
          }
          if (serviceType === 'wcb') {
            return serviceType.includes('initial') ? 'wcb_initial' : 'wcb_follow_up';
          }
          if (serviceType === 'mva') {
            return serviceType.includes('initial') ? 'mva_initial' : 'mva_follow_up';
          }
          return serviceType;
        })();

        console.log(`  • ${service.name} (${service.duration}min, $${service.basePrice})`);

        if (!CONFIG.DRY_RUN) {
          // Create Service_Detail
          await client.query(
            `INSERT INTO "Service_Detail"
             ("objectId", "createdAt", "updatedAt", "serviceType", "schedulingDurationMinutes", "itemId")
             VALUES ($1, NOW(), NOW(), $2, $3, $4)`,
            [serviceDetailId, mappedServiceType, service.duration, itemId]
          );

          // Create Items_Catalog entry
          await client.query(
            `INSERT INTO "Items_Catalog"
             ("objectId", "createdAt", "updatedAt", "type", "itemName", "serviceDetailId")
             VALUES ($1, NOW(), NOW(), 'service', $2, $3)`,
            [itemId, service.name, serviceDetailId]
          );

          // ==============================================================
          // Create Service_Offering at Org Level
          // ==============================================================
          const orgOfferingId = generateObjectId();
          await client.query(
            `INSERT INTO "Service_Offering"
             ("objectId", "createdAt", "updatedAt", "itemId", "orgId")
             VALUES ($1, NOW(), NOW(), $2, $3)`,
            [orgOfferingId, itemId, CONFIG.ORG_ID]
          );

          // Create Org-level pricing with varied durations
          const variedDurations = getVariedDurations(service.duration);
          for (const duration of variedDurations) {
            // Adjust price based on duration
            const durationMultiplier = duration / service.duration;
            const adjustedBasePrice = service.basePrice * durationMultiplier;
            const orgPrice = calculateVariedPrice(adjustedBasePrice, 'org');
            const orgPriceId = generateObjectId();
            await client.query(
              `INSERT INTO "Item_Price"
               ("objectId", "createdAt", "updatedAt", "itemId", "price", "durationMinutes", "orgId")
               VALUES ($1, NOW(), NOW(), $2, $3, $4, $5)`,
              [orgPriceId, itemId, orgPrice, duration, CONFIG.ORG_ID]
            );
            pricesCreated++;
          }

          // ==============================================================
          // Create Service_Offering at Ownership Group Level (50% of groups)
          // ==============================================================
          const selectedGroups = ownershipGroups.slice(0, Math.ceil(ownershipGroups.length * 0.5));
          for (const og of selectedGroups) {
            const ogOfferingId = generateObjectId();
            await client.query(
              `INSERT INTO "Service_Offering"
               ("objectId", "createdAt", "updatedAt", "itemId", "orgId", "ownershipGroupId")
               VALUES ($1, NOW(), NOW(), $2, $3, $4)`,
              [ogOfferingId, itemId, CONFIG.ORG_ID, og.objectId]
            );

            // Create OG-level pricing with varied durations (slight variation from org price)
            for (const duration of variedDurations) {
              const durationMultiplier = duration / service.duration;
              const adjustedBasePrice = service.basePrice * durationMultiplier;
              const ogPrice = calculateVariedPrice(adjustedBasePrice, 'ownershipGroup', 1.05);
              const ogPriceId = generateObjectId();
              await client.query(
                `INSERT INTO "Item_Price"
                 ("objectId", "createdAt", "updatedAt", "itemId", "price", "durationMinutes", "orgId", "ownershipGroupId")
                 VALUES ($1, NOW(), NOW(), $2, $3, $4, $5, $6)`,
                [ogPriceId, itemId, ogPrice, duration, CONFIG.ORG_ID, og.objectId]
              );
              pricesCreated++;
            }
          }

          // ==============================================================
          // Create Service_Offering at Location Level (30% of locations)
          // ==============================================================
          const selectedLocations = locations.slice(0, Math.ceil(locations.length * 0.3));
          for (const location of selectedLocations) {
            const locOfferingId = generateObjectId();
            await client.query(
              `INSERT INTO "Service_Offering"
               ("objectId", "createdAt", "updatedAt", "itemId", "orgId", "ownershipGroupId", "locationId")
               VALUES ($1, NOW(), NOW(), $2, $3, $4, $5)`,
              [locOfferingId, itemId, CONFIG.ORG_ID, location.ownershipGroupId, location.objectId]
            );

            // Create location-level pricing with varied durations (higher variation for downtown vs suburban)
            const locationMultiplier = Math.random() > 0.5 ? 1.15 : 0.95; // Urban vs suburban
            for (const duration of variedDurations) {
              const durationMultiplier = duration / service.duration;
              const adjustedBasePrice = service.basePrice * durationMultiplier;
              const locPrice = calculateVariedPrice(adjustedBasePrice, 'location', locationMultiplier);
              const locPriceId = generateObjectId();
              await client.query(
                `INSERT INTO "Item_Price"
                 ("objectId", "createdAt", "updatedAt", "itemId", "price", "durationMinutes", "orgId", "ownershipGroupId", "locationId")
                 VALUES ($1, NOW(), NOW(), $2, $3, $4, $5, $6, $7)`,
                [locPriceId, itemId, locPrice, duration, CONFIG.ORG_ID, location.ownershipGroupId, location.objectId]
              );
              pricesCreated++;
            }
          }
        }

        servicesCreated++;
      }
    }

    log(`\n✓ Created ${servicesCreated} services`);
    log(`✓ Created ${pricesCreated} price points across different levels`);

    // ==============================================================
    // Summary
    // ==============================================================
    console.log('\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    console.log('SUMMARY');
    console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
    console.log(`Organization: ${org.orgName}`);
    console.log(`Ownership Groups: ${ownershipGroups.length}`);
    console.log(`Locations: ${locations.length}`);
    console.log(`\n✓ Disciplines Created: ${disciplinesCreated}`);
    console.log(`✓ Services Created: ${servicesCreated}`);
    console.log(`✓ Price Points Created: ${pricesCreated}`);
    console.log(`\nPrice Distribution:`);
    console.log(`  • Org-level: ${servicesCreated} prices`);
    console.log(`  • Ownership Group-level: ~${Math.ceil(ownershipGroups.length * 0.5) * servicesCreated} prices`);
    console.log(`  • Location-level: ~${Math.ceil(locations.length * 0.3) * servicesCreated} prices`);

    if (!CONFIG.DRY_RUN) {
      await client.query('COMMIT');
      log('\n✓ Transaction committed successfully');
    } else {
      console.log('\n🔍 DRY RUN - No changes were made to the database');
    }

  } catch (error) {
    if (!CONFIG.DRY_RUN) {
      await client.query('ROLLBACK');
      log('Transaction rolled back due to error');
    }
    console.error('\n❌ Error:', error.message);
    console.error(error.stack);
    process.exit(1);
  } finally {
    await client.end();
    log('Database connection closed');
  }

  console.log('\n✨ Script completed successfully!\n');
}

// ==============================================================
// Run the script
// ==============================================================

main();

