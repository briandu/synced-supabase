#!/usr/bin/env node

/**
 * Fix: Add Ownership_Group_Patient records for Michael Torres and Rachel Kim
 */

import fs from 'fs';
import Parse from 'parse/node.js';
import path from 'path';
import { config } from 'dotenv';

config({ path: '.env.local' });

function loadParseEnv() {
  const env = {
    PARSE_SERVER_URL: process.env.PARSE_SERVER_URL || process.env.NEXT_PUBLIC_PARSE_SERVER_URL,
    PARSE_APP_ID: process.env.PARSE_APP_ID || process.env.NEXT_PUBLIC_PARSE_APP_ID,
    PARSE_MASTER_KEY: process.env.PARSE_MASTER_KEY || process.env.NEXT_PUBLIC_PARSE_MASTER_KEY,
  };
  if (env.PARSE_SERVER_URL && env.PARSE_APP_ID && env.PARSE_MASTER_KEY) {
    return env;
  }
  try {
    const homeDir = process.env.HOME || process.env.USERPROFILE || '';
    const cfgPath = path.join(homeDir, '.cursor', 'mcp.json');
    const txt = fs.readFileSync(cfgPath, 'utf-8');
    const cfg = JSON.parse(txt);
    const parseCfg = cfg?.mcpServers?.parse?.env;
    if (parseCfg?.PARSE_SERVER_URL && parseCfg?.PARSE_APP_ID && parseCfg?.PARSE_MASTER_KEY) {
      return {
        PARSE_SERVER_URL: parseCfg.PARSE_SERVER_URL,
        PARSE_APP_ID: parseCfg.PARSE_APP_ID,
        PARSE_MASTER_KEY: parseCfg.PARSE_MASTER_KEY,
      };
    }
  } catch (_) {}
  throw new Error('Missing Parse env');
}

async function main() {
  console.log('\n🔧 Fixing Ownership Group Assignment for Rehab Patients\n');

  const { PARSE_SERVER_URL, PARSE_APP_ID, PARSE_MASTER_KEY } = loadParseEnv();
  Parse.initialize(PARSE_APP_ID);
  Parse.serverURL = PARSE_SERVER_URL;
  Parse.masterKey = PARSE_MASTER_KEY;

  try {
    // Find Michael Torres and Rachel Kim (most recent)
    const Patient = Parse.Object.extend('Patient');
    
    const michaelQuery = new Parse.Query(Patient);
    michaelQuery.equalTo('firstName', 'Michael');
    michaelQuery.equalTo('lastName', 'Torres');
    michaelQuery.descending('createdAt');
    const michael = await michaelQuery.first({ useMasterKey: true });

    const rachelQuery = new Parse.Query(Patient);
    rachelQuery.equalTo('firstName', 'Rachel');
    rachelQuery.equalTo('lastName', 'Kim');
    rachelQuery.descending('createdAt');
    const rachel = await rachelQuery.first({ useMasterKey: true });

    if (!michael || !rachel) {
      throw new Error('Patients not found. Run create-rehab-patient-data.js first.');
    }

    console.log(`✅ Found Michael Torres (${michael.id})`);
    console.log(`✅ Found Rachel Kim (${rachel.id})\n`);

    // Find ownership groups
    const OwnershipGroup = Parse.Object.extend('Ownership_Group');
    const ogQuery = new Parse.Query(OwnershipGroup);
    const ownershipGroups = await ogQuery.find({ useMasterKey: true });

    console.log(`📊 Found ${ownershipGroups.length} ownership groups:`);
    ownershipGroups.forEach(og => {
      console.log(`   - ${og.get('name')} (${og.id})`);
    });
    console.log('');

    // Use first ownership group (typically Myodetox)
    if (ownershipGroups.length === 0) {
      throw new Error('No ownership groups found');
    }

    const myodetox = ownershipGroups[0];
    console.log(`✅ Using ownership group: ${myodetox.get('name')} (${myodetox.id})\n`);

    // Check if already assigned
    const OwnershipGroupPatient = Parse.Object.extend('Ownership_Group_Patient');
    
    const michaelCheckQuery = new Parse.Query(OwnershipGroupPatient);
    michaelCheckQuery.equalTo('patientId', michael);
    const michaelExisting = await michaelCheckQuery.first({ useMasterKey: true });

    const rachelCheckQuery = new Parse.Query(OwnershipGroupPatient);
    rachelCheckQuery.equalTo('patientId', rachel);
    const rachelExisting = await rachelCheckQuery.first({ useMasterKey: true });

    // Create Michael's assignment if needed
    if (michaelExisting) {
      console.log(`ℹ️  Michael Torres already assigned to ownership group`);
    } else {
      const michaelOGP = new OwnershipGroupPatient();
      michaelOGP.set('patientId', michael);
      michaelOGP.set('ownershipGroupId', myodetox);
      michaelOGP.set('isActive', true);
      await michaelOGP.save(null, { useMasterKey: true });
      console.log(`✅ Created Ownership_Group_Patient for Michael Torres (${michaelOGP.id})`);
    }

    // Create Rachel's assignment if needed
    if (rachelExisting) {
      console.log(`ℹ️  Rachel Kim already assigned to ownership group`);
    } else {
      const rachelOGP = new OwnershipGroupPatient();
      rachelOGP.set('patientId', rachel);
      rachelOGP.set('ownershipGroupId', myodetox);
      rachelOGP.set('isActive', true);
      await rachelOGP.save(null, { useMasterKey: true });
      console.log(`✅ Created Ownership_Group_Patient for Rachel Kim (${rachelOGP.id})`);
    }

    console.log('\n✨ Patients should now be visible in the patients page!');
    console.log(`\n📍 Both patients assigned to: ${myodetox.get('name')}`);
    console.log(`\n🏥 Locations:`);
    console.log(`   - Michael Torres: Appointments at Yonge & Bloor (Tom Holland's location)`);
    console.log(`   - Rachel Kim: Appointments at Myo Richmond Hill (Jenna Ortega's location)\n`);

  } catch (error) {
    console.error('\n❌ Error:', error.message);
    console.error(error);
    process.exit(1);
  }
}

main();



