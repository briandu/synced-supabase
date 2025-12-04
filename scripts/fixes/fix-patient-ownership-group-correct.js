#!/usr/bin/env node

/**
 * Fix: Reassign Michael Torres and Rachel Kim to the correct Myodetox ownership group
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
  console.log('\n🔧 Fixing Ownership Group Assignment\n');
  console.log('='.repeat(80));

  const { PARSE_SERVER_URL, PARSE_APP_ID, PARSE_MASTER_KEY } = loadParseEnv();
  Parse.initialize(PARSE_APP_ID);
  Parse.serverURL = PARSE_SERVER_URL;
  Parse.masterKey = PARSE_MASTER_KEY;

  try {
    // Get the correct Myodetox ownership group (FGogOzxNJA)
    const OwnershipGroup = Parse.Object.extend('Ownership_Group');
    const correctOGQuery = new Parse.Query(OwnershipGroup);
    correctOGQuery.equalTo('objectId', 'FGogOzxNJA');
    const correctOG = await correctOGQuery.first({ useMasterKey: true });

    if (!correctOG) {
      throw new Error('Myodetox ownership group (FGogOzxNJA) not found');
    }

    await correctOG.fetch({ useMasterKey: true });
    console.log(`✅ Found correct ownership group: ${correctOG.get('ogName')} (${correctOG.id})\n`);

    // Find Michael Torres and Rachel Kim
    const Patient = Parse.Object.extend('Patient');
    const OwnershipGroupPatient = Parse.Object.extend('Ownership_Group_Patient');

    const patients = [
      { first: 'Michael', last: 'Torres' },
      { first: 'Rachel', last: 'Kim' }
    ];

    for (const { first, last } of patients) {
      console.log(`\n👤 Processing ${first} ${last}:`);
      console.log('-'.repeat(80));

      // Find patient
      const patientQuery = new Parse.Query(Patient);
      patientQuery.equalTo('firstName', first);
      patientQuery.equalTo('lastName', last);
      patientQuery.descending('createdAt');
      const patient = await patientQuery.first({ useMasterKey: true });

      if (!patient) {
        console.log(`   ❌ Patient not found`);
        continue;
      }

      console.log(`   ✅ Found patient (${patient.id})`);

      // Find their existing OGP record
      const ogpQuery = new Parse.Query(OwnershipGroupPatient);
      ogpQuery.equalTo('patientId', patient);
      const ogp = await ogpQuery.first({ useMasterKey: true });

      if (ogp) {
        // Update existing record
        const oldOG = ogp.get('ownershipGroupId');
        await oldOG.fetch({ useMasterKey: true });
        
        console.log(`   📝 Updating existing Ownership_Group_Patient record (${ogp.id})`);
        console.log(`      Old: ${oldOG.get('ogName')} (${oldOG.id})`);
        console.log(`      New: ${correctOG.get('ogName')} (${correctOG.id})`);
        
        ogp.set('ownershipGroupId', correctOG);
        ogp.set('isActive', true);
        await ogp.save(null, { useMasterKey: true });
        
        console.log(`   ✅ Successfully updated!`);
      } else {
        // Create new record (shouldn't happen, but just in case)
        console.log(`   📝 Creating new Ownership_Group_Patient record`);
        
        const newOGP = new OwnershipGroupPatient();
        newOGP.set('patientId', patient);
        newOGP.set('ownershipGroupId', correctOG);
        newOGP.set('isActive', true);
        await newOGP.save(null, { useMasterKey: true });
        
        console.log(`   ✅ Successfully created (${newOGP.id})`);
      }
    }

    console.log('\n' + '='.repeat(80));
    console.log('✨ SUCCESS! Both patients are now assigned to the correct ownership group.');
    console.log('   They should now be visible in the Myodetox patients list.');
    console.log('='.repeat(80) + '\n');

  } catch (error) {
    console.error('\n❌ Error:', error.message);
    console.error(error);
    process.exit(1);
  }
}

main();



