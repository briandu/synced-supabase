# Database Scripts

This directory contains database scripts organized by purpose.

## Directory Structure

```
scripts/
├── migrations/    # Data migration scripts
├── seeding/       # Seed data scripts
├── fixes/         # Data fix scripts
└── utilities/     # Database utilities
```

## Migration Scripts (`migrations/`)

Scripts for migrating data between systems or syncing with external services.

### Available Scripts

- **`migrate-parse-files-to-supabase.js`**
  - Migrates files from Parse Server to Supabase Storage
  - Updates file references in database
  - Usage: `node scripts/migrations/migrate-parse-files-to-supabase.js`

- **`migrate-services-to-stripe.js`**
  - Syncs services to Stripe products/prices
  - Usage: `node scripts/migrations/migrate-services-to-stripe.js`

- **`sync-stripe-invoices.js`**
  - Syncs Stripe invoices to Supabase
  - Usage: `node scripts/migrations/sync-stripe-invoices.js`

## Seeding Scripts (`seeding/`)

Scripts for creating test/development data.

### Available Scripts

- **`seed-patients.js`**
  - Creates patient test data
  - Usage: `node scripts/seeding/seed-patients.js`

- **`seed-services-and-disciplines.js`**
  - Seeds services and disciplines
  - Usage: `node scripts/seeding/seed-services-and-disciplines.js`

- **`seed-default-fees.js`**
  - Seeds default fees
  - Usage: `node scripts/seeding/seed-default-fees.js`

## Fix Scripts (`fixes/`)

Scripts for fixing data issues or correcting errors.

### Available Scripts

- Various `fix-*.js` scripts for specific data corrections
- `cleanup-*.js` scripts for data cleanup

**Note:** Review each script before running to understand what it does.

## Utility Scripts (`utilities/`)

General-purpose database utilities.

### Available Scripts

- **`run-sql.js`**
  - Execute SQL files against the database
  - Usage: `node scripts/utilities/run-sql.js <sql-file>`

- **`verify-appointments.js`**
  - Validates appointment data
  - Usage: `node scripts/utilities/verify-appointments.js`

- **`check-appointment-structure.js`**
  - Validates appointment schema/structure
  - Usage: `node scripts/utilities/check-appointment-structure.js`

## Running Scripts

### Prerequisites

1. **Environment Variables**: Ensure `.env` file has:
   - `NEXT_PUBLIC_SUPABASE_URL`
   - `NEXT_PUBLIC_SUPABASE_ANON_KEY`
   - `SUPABASE_SERVICE_ROLE_KEY`
   - Database connection variables (if needed)

2. **Dependencies**: Install Node.js dependencies:
   ```bash
   npm install
   ```

### Running a Script

```bash
# From the repository root
node scripts/<category>/<script-name>.js
```

### Example

```bash
# Run a migration script
node scripts/migrations/migrate-parse-files-to-supabase.js

# Run a seeding script
node scripts/seeding/seed-patients.js

# Run a utility script
node scripts/utilities/verify-appointments.js
```

## Creating New Scripts

When creating new scripts:

1. **Choose the right directory** based on purpose
2. **Use environment variables** for configuration
3. **Add error handling** and logging
4. **Document usage** in script comments
5. **Test thoroughly** before committing

### Script Template

```javascript
require('dotenv').config();
const { createClient } = require('@supabase/supabase-js');

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL;
const supabaseKey = process.env.SUPABASE_SERVICE_ROLE_KEY;

if (!supabaseUrl || !supabaseKey) {
  console.error('Missing Supabase environment variables');
  process.exit(1);
}

const supabase = createClient(supabaseUrl, supabaseKey);

async function main() {
  try {
    // Your script logic here
    console.log('Script completed successfully');
  } catch (error) {
    console.error('Error:', error);
    process.exit(1);
  }
}

main();
```

## Best Practices

1. **Always use service role key** for scripts (not anon key)
2. **Add validation** before making changes
3. **Log operations** for debugging
4. **Handle errors gracefully**
5. **Test on staging** before production
6. **Document what the script does** in comments

## Related Documentation

- Migration guides: [`docs/migrations/`](../docs/migrations/)
- Architecture decisions: [`docs/architecture/`](../docs/architecture/)

