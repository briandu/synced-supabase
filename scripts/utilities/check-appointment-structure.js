#!/usr/bin/env node

/**
 * Check the actual structure of the Appointment table
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

async function main() {
  console.log('\n🔍 Checking Appointment Table Structure\n');

  const dbConfig = loadDatabaseConfig();
  const client = new Client(dbConfig);

  try {
    await client.connect();
    console.log('✅ Connected\n');

    // Get first appointment
    const result = await client.query(`
      SELECT "objectId", "patientId", "startTime", "createdAt"
      FROM "Appointment"
      WHERE "objectId" = 'zGsh3LCzIZ'
      LIMIT 1
    `);

    console.log('Sample Appointment Record:');
    console.log(JSON.stringify(result.rows[0], null, 2));

    // Also check Chart table
    const chartResult = await client.query(`
      SELECT "objectId", "appointmentId", "createdAt"
      FROM "Chart"
      WHERE "objectId" = 'egpj9rd6Lh'
      LIMIT 1
    `);

    console.log('\nSample Chart Record:');
    console.log(JSON.stringify(chartResult.rows[0], null, 2));

  } catch (error) {
    console.error('\n❌ Error:', error.message);
    console.error(error);
    process.exit(1);
  } finally {
    await client.end();
  }
}

main();

