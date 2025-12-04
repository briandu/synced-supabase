process.env.NODE_TLS_REJECT_UNAUTHORIZED = '0';

/**
 * Execute a SQL file against a Postgres database using environment variables.
 *
 * Usage:
 *   node scripts/run-sql.js --file=scripts/migrations/add_stripe_customer_to_patient.sql --connection=postgresql://...
 */

const fs = require('fs');
const path = require('path');
const { Client } = require('pg');

function parseArgs() {
  const args = process.argv.slice(2);
  return args.reduce((acc, arg) => {
    if (arg.startsWith('--file=')) {
      acc.file = arg.slice('--file='.length);
    } else if (arg.startsWith('--connection=')) {
      acc.connectionString = arg.slice('--connection='.length);
    }
    return acc;
  }, {});
}

async function main() {
  const { file, connectionString } = parseArgs();

  if (!file) {
    console.error('Missing required parameter: --file=path/to/file.sql');
    process.exit(1);
  }
  if (!connectionString) {
    console.error('Missing required parameter: --connection=postgresql://user:pass@host:port/db');
    process.exit(1);
  }

  const absolutePath = path.resolve(process.cwd(), file);
  if (!fs.existsSync(absolutePath)) {
    console.error(`SQL file not found: ${absolutePath}`);
    process.exit(1);
  }
  const sql = fs.readFileSync(absolutePath, 'utf8');
  console.log(`Executing SQL from ${absolutePath}`);

  const client = new Client({
    connectionString,
    ssl: {
      rejectUnauthorized: false,
    },
  });

  try {
    await client.connect();
    console.log('Connected to database');
    await client.query(sql);
    console.log(`Successfully executed ${file}`);
  } catch (error) {
    console.error(`Failed to execute ${file}:`, error);
    process.exitCode = 1;
  } finally {
    await client.end();
  }
}

main();
