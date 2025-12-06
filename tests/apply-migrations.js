require('dotenv').config();
const { createClient } = require('@supabase/supabase-js');
const fs = require('fs');
const path = require('path');

const supabaseUrl = process.env.SUPABASE_URL;
const supabaseKey = process.env.SUPABASE_SERVICE_ROLE_KEY;

if (!supabaseKey) {
  console.error('ERROR: SUPABASE_SERVICE_ROLE_KEY not found in .env file');
  process.exit(1);
}

const supabase = createClient(supabaseUrl, supabaseKey);

async function applyMigration(migrationFile) {
  console.log(`\nApplying migration: ${migrationFile}`);
  
  const sql = fs.readFileSync(
    path.join(__dirname, '..', 'migrations', migrationFile),
    'utf-8'
  );

  const { data, error } = await supabase.rpc('exec_sql', { sql_query: sql });

  if (error) {
    console.error(`❌ Error applying ${migrationFile}:`, error.message);
    return false;
  }

  console.log(`✅ Successfully applied ${migrationFile}`);
  return true;
}

async function main() {
  console.log('🚀 Applying onboarding migrations...\n');
  console.log('Connected to:', supabaseUrl);

  const migrations = [
    '20251202160000_add_onboarding_columns.sql',
    '20251202170000_complete_onboarding_transaction.sql',
  ];

  for (const migration of migrations) {
    const success = await applyMigration(migration);
    if (!success) {
      console.error('\n❌ Migration failed. Stopping.');
      process.exit(1);
    }
  }

  console.log('\n✅ All migrations applied successfully!');
}

main().catch(console.error);
