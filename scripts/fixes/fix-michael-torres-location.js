#!/usr/bin/env node

/**
 * Fix: Move Michael Torres to Myo Richmond Hill
 * - Update all appointments to use Myo Richmond Hill location
 * - Update to use Jenna Ortega as provider (if Tom Holland isn't at Richmond Hill)
 * - Verify ownership group is correct
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
  console.log('\n🔧 Moving Michael Torres to Myo Richmond Hill\n');
  console.log('='.repeat(80));

  const { PARSE_SERVER_URL, PARSE_APP_ID, PARSE_MASTER_KEY } = loadParseEnv();
  Parse.initialize(PARSE_APP_ID);
  Parse.serverURL = PARSE_SERVER_URL;
  Parse.masterKey = PARSE_MASTER_KEY;

  try {
    // ============================================================
    // STEP 1: Find Michael Torres
    // ============================================================
    console.log('\n📍 STEP 1: Finding Michael Torres');
    console.log('-'.repeat(80));

    const Patient = Parse.Object.extend('Patient');
    const michaelQuery = new Parse.Query(Patient);
    michaelQuery.equalTo('firstName', 'Michael');
    michaelQuery.equalTo('lastName', 'Torres');
    michaelQuery.descending('createdAt');
    const michael = await michaelQuery.first({ useMasterKey: true });

    if (!michael) {
      throw new Error('Michael Torres not found');
    }
    console.log(`✅ Found Michael Torres (${michael.id})`);

    // ============================================================
    // STEP 2: Find Staff and Their Locations
    // ============================================================
    console.log('\n📍 STEP 2: Finding Staff and Their Locations');
    console.log('-'.repeat(80));

    const StaffMember = Parse.Object.extend('Staff_Member');
    const StaffLocation = Parse.Object.extend('Staff_Location');
    
    // Get Tom Holland
    const tomQuery = new Parse.Query(StaffMember);
    tomQuery.equalTo('firstName', 'Tom');
    tomQuery.equalTo('lastName', 'Holland');
    const tom = await tomQuery.first({ useMasterKey: true });

    // Get Jenna Ortega
    const jennaQuery = new Parse.Query(StaffMember);
    jennaQuery.equalTo('firstName', 'Jenna');
    jennaQuery.equalTo('lastName', 'Ortega');
    const jenna = await jennaQuery.first({ useMasterKey: true });

    if (!tom || !jenna) {
      throw new Error('Staff members not found');
    }

    // Get Tom's locations
    const tomLocQuery = new Parse.Query(StaffLocation);
    tomLocQuery.equalTo('staffId', tom);
    tomLocQuery.include('locationId');
    const tomLocations = await tomLocQuery.find({ useMasterKey: true });

    console.log(`\n👤 Tom Holland (${tom.id}) locations:`);
    tomLocations.forEach(sl => {
      const loc = sl.get('locationId');
      console.log(`   - ${loc.get('locationName')} (${loc.id})`);
    });

    // Get Jenna's locations
    const jennaLocQuery = new Parse.Query(StaffLocation);
    jennaLocQuery.equalTo('staffId', jenna);
    jennaLocQuery.include('locationId');
    const jennaLocations = await jennaLocQuery.find({ useMasterKey: true });

    console.log(`\n👤 Jenna Ortega (${jenna.id}) locations:`);
    jennaLocations.forEach(sl => {
      const loc = sl.get('locationId');
      console.log(`   - ${loc.get('locationName')} (${loc.id})`);
    });

    // ============================================================
    // STEP 3: Find Myo Richmond Hill Location
    // ============================================================
    console.log('\n📍 STEP 3: Finding Myo Richmond Hill Location');
    console.log('-'.repeat(80));

    // Use the exact location ID from Jenna's staff location (cyu4AXl7Z5)
    const Location = Parse.Object.extend('Location');
    const richmondHillQuery = new Parse.Query(Location);
    richmondHillQuery.equalTo('objectId', 'cyu4AXl7Z5'); // Exact Myo Richmond Hill location
    const richmondHill = await richmondHillQuery.first({ useMasterKey: true });

    if (!richmondHill) {
      throw new Error('Myo Richmond Hill location (cyu4AXl7Z5) not found');
    }

    console.log(`✅ Found: ${richmondHill.get('locationName')} (${richmondHill.id})`);

    // Check ownership group
    const OwnershipGroup = Parse.Object.extend('Ownership_Group');
    const ownershipGroupPointer = richmondHill.get('ownershipGroupId');
    
    if (ownershipGroupPointer) {
      await ownershipGroupPointer.fetch({ useMasterKey: true });
      console.log(`   Ownership Group: ${ownershipGroupPointer.get('ogName')} (${ownershipGroupPointer.id})`);
      
      const orgPointer = ownershipGroupPointer.get('orgId');
      if (orgPointer) {
        await orgPointer.fetch({ useMasterKey: true });
        console.log(`   Organization: ${orgPointer.get('orgName')} (${orgPointer.id})`);
      }
    }

    // Check if Tom or Jenna work at Richmond Hill
    const tomAtRichmondHill = tomLocations.some(sl => sl.get('locationId').id === richmondHill.id);
    const jennaAtRichmondHill = jennaLocations.some(sl => sl.get('locationId').id === richmondHill.id);

    console.log(`\n🔍 Staff availability at Myo Richmond Hill:`);
    console.log(`   Tom Holland: ${tomAtRichmondHill ? '✅ Yes' : '❌ No'}`);
    console.log(`   Jenna Ortega: ${jennaAtRichmondHill ? '✅ Yes' : '❌ No'}`);

    // Decide which provider to use
    let newProvider;
    if (tomAtRichmondHill) {
      newProvider = tom;
      console.log(`\n✅ Will keep Tom Holland as provider`);
    } else if (jennaAtRichmondHill) {
      newProvider = jenna;
      console.log(`\n✅ Will switch to Jenna Ortega as provider`);
    } else {
      throw new Error('Neither Tom nor Jenna work at Myo Richmond Hill');
    }

    // ============================================================
    // STEP 4: Update Michael's Appointments
    // ============================================================
    console.log('\n📍 STEP 4: Updating Michael Torres Appointments');
    console.log('-'.repeat(80));

    const Appointment = Parse.Object.extend('Appointment');
    const apptQuery = new Parse.Query(Appointment);
    apptQuery.equalTo('patientId', michael);
    apptQuery.include('locationId');
    apptQuery.include('providerId');
    const appointments = await apptQuery.find({ useMasterKey: true });

    console.log(`\nFound ${appointments.length} appointments for Michael Torres`);

    let updatedCount = 0;
    for (const appt of appointments) {
      const currentLocation = appt.get('locationId');
      const currentProvider = appt.get('providerId');
      
      let needsUpdate = false;
      let updates = [];

      if (currentLocation?.id !== richmondHill.id) {
        appt.set('locationId', richmondHill);
        needsUpdate = true;
        updates.push(`location: ${currentLocation?.get('locationName')} → ${richmondHill.get('locationName')}`);
      }

      if (currentProvider?.id !== newProvider.id) {
        appt.set('providerId', newProvider);
        needsUpdate = true;
        const currentName = `${currentProvider?.get('firstName')} ${currentProvider?.get('lastName')}`;
        const newName = `${newProvider.get('firstName')} ${newProvider.get('lastName')}`;
        updates.push(`provider: ${currentName} → ${newName}`);
      }

      if (needsUpdate) {
        await appt.save(null, { useMasterKey: true });
        console.log(`   ✅ Updated appointment ${appt.id}: ${updates.join(', ')}`);
        updatedCount++;
      } else {
        console.log(`   ℹ️  Appointment ${appt.id}: Already correct`);
      }
    }

    // ============================================================
    // SUMMARY
    // ============================================================
    console.log('\n' + '='.repeat(80));
    console.log('✨ SUMMARY');
    console.log('='.repeat(80));
    console.log(`\n📊 Updated ${updatedCount} out of ${appointments.length} appointments`);
    console.log(`\n👤 Patient: Michael Torres`);
    console.log(`🏥 Location: ${richmondHill.get('locationName')}`);
    console.log(`👨‍⚕️ Provider: ${newProvider.get('firstName')} ${newProvider.get('lastName')}`);
    console.log(`🏢 Organization: ${ownershipGroupPointer ? (await ownershipGroupPointer.get('orgId').fetch({ useMasterKey: true })).get('orgName') : 'Unknown'}`);
    console.log('');

  } catch (error) {
    console.error('\n❌ Error:', error.message);
    console.error(error);
    process.exit(1);
  }
}

main();

