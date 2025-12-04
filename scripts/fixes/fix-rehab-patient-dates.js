#!/usr/bin/env node

/**
 * Fix: Update createdAt dates for appointments and charts to match appointment dates
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
  console.log('\n🔧 Fixing CreatedAt Dates for Rehab Patients\n');
  console.log('='.repeat(80));

  const { PARSE_SERVER_URL, PARSE_APP_ID, PARSE_MASTER_KEY } = loadParseEnv();
  Parse.initialize(PARSE_APP_ID);
  Parse.serverURL = PARSE_SERVER_URL;
  Parse.masterKey = PARSE_MASTER_KEY;

  try {
    const Patient = Parse.Object.extend('Patient');
    const Appointment = Parse.Object.extend('Appointment');
    const Chart = Parse.Object.extend('Chart');
    const FormDetail = Parse.Object.extend('Form_Detail');

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

      console.log(`   ✅ Found patient (${patient.id})\n`);

      // Find all appointments for this patient
      const apptQuery = new Parse.Query(Appointment);
      apptQuery.equalTo('patientId', patient);
      apptQuery.ascending('startTime');
      const appointments = await apptQuery.find({ useMasterKey: true });

      console.log(`   📅 Found ${appointments.length} appointments\n`);

      let updatedAppts = 0;
      let updatedCharts = 0;
      let updatedFormDetails = 0;

      for (const appt of appointments) {
        const startTime = appt.get('startTime');
        const currentCreatedAt = appt.createdAt;

        // Calculate creation time (assume chart was created 1 hour after appointment started)
        const creationTime = new Date(startTime.getTime() + 60 * 60 * 1000);

        console.log(`   📝 Appointment ${appt.id}:`);
        console.log(`      Start: ${startTime.toISOString()}`);
        console.log(`      CreatedAt: ${currentCreatedAt.toISOString()} → ${creationTime.toISOString()}`);

        // Update appointment createdAt using raw query
        // (Parse doesn't allow direct modification of createdAt via SDK)
        const apptUpdateQuery = `
          UPDATE "Appointment" 
          SET "createdAt" = $1, "updatedAt" = $2
          WHERE "objectId" = $3
        `;
        
        try {
          // We'll use Parse.Cloud.httpRequest to execute raw SQL via Parse Server
          // But since we can't do raw SQL easily, we'll note this in the output
          console.log(`      ⚠️  Note: Appointment createdAt needs database-level update`);
        } catch (e) {
          console.log(`      ⚠️  Could not update appointment createdAt: ${e.message}`);
        }

        // Find associated chart
        const chartQuery = new Parse.Query(Chart);
        chartQuery.equalTo('appointmentId', appt);
        const chart = await chartQuery.first({ useMasterKey: true });

        if (chart) {
          console.log(`      📋 Chart ${chart.id}:`);
          console.log(`         CreatedAt: ${chart.createdAt.toISOString()} → ${creationTime.toISOString()}`);

          // Find all form details for this chart
          const formDetailQuery = new Parse.Query(FormDetail);
          formDetailQuery.equalTo('chartId', chart);
          const formDetails = await formDetailQuery.find({ useMasterKey: true });

          console.log(`         📄 ${formDetails.length} Form_Detail items`);

          updatedCharts++;
          updatedFormDetails += formDetails.length;
        }

        updatedAppts++;
      }

      console.log(`\n   ✅ Summary: ${updatedAppts} appointments, ${updatedCharts} charts, ${updatedFormDetails} form details`);
    }

    console.log('\n' + '='.repeat(80));
    console.log('⚠️  IMPORTANT: Parse SDK does not allow updating createdAt directly.');
    console.log('   We need to run a direct PostgreSQL query to update these dates.');
    console.log('='.repeat(80) + '\n');

  } catch (error) {
    console.error('\n❌ Error:', error.message);
    console.error(error);
    process.exit(1);
  }
}

main();



