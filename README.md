# Synced Supabase Database

This repository contains all database migrations, schema definitions, functions, scripts, and documentation for the Synced Health platform's Supabase database.

## Overview

This is a dedicated repository for managing the Supabase database schema and migrations. It is shared across multiple services and applications that use the same Supabase database.

**Supabase Project:**
- Project URL: `https://tepdgpiyjluuddwgboyy.supabase.co`
- Project Reference: `tepdgpiyjluuddwgboyy`
- Dashboard: https://supabase.com/dashboard/project/tepdgpiyjluuddwgboyy

## Repository Structure

```
.
├── migrations/          # Database migration files (ordered by timestamp)
│   └── 26 migration files covering schema, RLS, and features
├── functions/           # PostgreSQL functions (transactional operations)
│   └── Example: create_organization_with_initial_data.sql
├── scripts/            # Database scripts organized by purpose
│   ├── migrations/     # Data migration scripts
│   ├── seeding/        # Seed data scripts
│   ├── fixes/          # Data fix scripts
│   └── utilities/      # Database utilities
├── docs/               # Comprehensive documentation
│   ├── migrations/     # Migration guides and status
│   ├── architecture/   # Database architecture decisions
│   ├── testing/        # Testing guides
│   └── scripts/        # Script documentation
├── seed.sql            # Seed data for development/testing
├── full.sql            # Complete schema dump (for reference)
├── pending.sql         # Pending changes (to be promoted to migrations)
└── README.md           # This file
```

## Quick Start

### 1. Clone This Repository

```bash
git clone <repository-url>
cd synced-supabase
```

### 2. Authenticate with Supabase

```bash
supabase login
```

This will open a browser window for authentication.

### 3. Link to Supabase Project

```bash
supabase link --project-ref tepdgpiyjluuddwgboyy
```

You'll be prompted for your database password. Find it in:
- Supabase Dashboard → Settings → Database → Database Password

### 4. Apply Migrations

```bash
supabase db push
```

This will:
- Check which migrations have already been applied
- Apply only new/pending migrations in chronological order
- Show you the status of each migration

### 5. Verify Migration Status

```bash
supabase migration list
```

## Key Components

### Migrations (`migrations/`)

26 migration files covering:
- **Core Schema**: Organizations, locations, users, profiles, roles
- **Scheduling**: Appointments, availability blocks, staff shifts, time off
- **Billing**: Invoices, payments, gift cards, transactions
- **Patient Management**: Patients, files, relationships, notes, consents
- **Staff Management**: Staff members, permissions, invites, join requests
- **Services & Products**: Catalog, offerings, pricing, inventory
- **Chat & Realtime**: Chat threads, messages, presence
- **Notifications**: Delivery tracking, preferences, triggers
- **RLS Policies**: Row-level security policies for all tables

See [`docs/migrations/MIGRATION_SCRIPT_SEQUENCE.md`](docs/migrations/MIGRATION_SCRIPT_SEQUENCE.md) for the complete list.

### Functions (`functions/`)

PostgreSQL functions for complex transactional operations:
- **Example**: `create_organization_with_initial_data()` - Example template for creating transactional operations
- **Onboarding**: `complete_onboarding_transaction()` - Handles complete onboarding process in a single atomic transaction

See [`docs/architecture/SUPABASE_TRANSACTIONAL_OPERATIONS.md`](docs/architecture/SUPABASE_TRANSACTIONAL_OPERATIONS.md) and [`docs/functions/complete_onboarding_transaction.md`](docs/functions/complete_onboarding_transaction.md) for details.

### Scripts (`scripts/`)

Database scripts organized by purpose:

- **`scripts/migrations/`**: Data migration scripts
  - `migrate-parse-files-to-supabase.js` - Migrate files from Parse to Supabase Storage
  - `migrate-services-to-stripe.js` - Sync services to Stripe
  - `sync-stripe-invoices.js` - Sync Stripe invoices

- **`scripts/seeding/`**: Seed data scripts
  - `seed-patients.js` - Create patient test data
  - `seed-services-and-disciplines.js` - Seed services and disciplines
  - `seed-default-fees.js` - Seed default fees

- **`scripts/fixes/`**: Data fix scripts
  - Various `fix-*.js` scripts for data corrections
  - `cleanup-*.js` scripts for data cleanup

- **`scripts/utilities/`**: Database utilities
  - `run-sql.js` - Execute SQL files
  - `verify-appointments.js` - Data validation
  - `check-appointment-structure.js` - Schema validation

### Documentation (`docs/`)

Comprehensive documentation organized by topic:

- **`docs/migrations/`**: Migration guides, status, and feature-specific docs
- **`docs/architecture/`**: Database architecture decisions and patterns
- **`docs/functions/`**: Database function documentation
- **`docs/integration/`**: Integration guides for frontend applications
- **`docs/testing/`**: Testing guides and plans
- **`docs/scripts/`**: Script documentation (to be added)

Key documents:
- [`SUPABASE_MIGRATION_CHECKLIST.md`](docs/migrations/SUPABASE_MIGRATION_CHECKLIST.md) - Complete migration checklist
- [`SUPABASE_RUNNING_GUIDE.md`](docs/migrations/SUPABASE_RUNNING_GUIDE.md) - Setup and running guide
- [`APPLY_MIGRATIONS_GUIDE.md`](docs/migrations/APPLY_MIGRATIONS_GUIDE.md) - How to apply migrations
- [`SUPABASE_TRANSACTIONAL_OPERATIONS.md`](docs/architecture/SUPABASE_TRANSACTIONAL_OPERATIONS.md) - Transactional operations guide
- [`complete_onboarding_transaction.md`](docs/functions/complete_onboarding_transaction.md) - Onboarding function documentation
- [`onboarding-backend-integration.md`](docs/integration/onboarding-backend-integration.md) - Frontend integration guide
- [`function-testing-guide.md`](docs/testing/function-testing-guide.md) - How to test database functions

## Migration Workflow

### Creating a New Migration

1. **Make changes to `pending.sql`** (for testing/development)
2. **Create a new migration file**:
   ```bash
   supabase migration new <descriptive_name>
   ```
   This creates a timestamped file in `migrations/` directory.

3. **Write your migration SQL** in the new file
4. **Test locally** (if using Supabase local development):
   ```bash
   supabase db reset  # Resets and applies all migrations
   ```

5. **Apply to remote**:
   ```bash
   supabase db push
   ```

### Creating a Database Function

1. **Create function file** in `functions/` directory:
   ```sql
   -- functions/YYYYMMDDHHMMSS_function_name.sql
   create or replace function public.my_function(...)
   returns jsonb
   language plpgsql
   security definer
   as $$ ... $$;
   ```

2. **Apply via migration** or directly via SQL Editor
3. **Document** in `docs/architecture/`

See [`docs/architecture/SUPABASE_TRANSACTIONAL_OPERATIONS.md`](docs/architecture/SUPABASE_TRANSACTIONAL_OPERATIONS.md) for examples.

## Seed Data

The `seed.sql` file contains sample data for development and testing:

- Demo organization and location
- Default permissions and role mappings
- Sample disciplines and services

**To apply seed data:**

```bash
# Via Supabase Dashboard SQL Editor
# Copy and paste contents of seed.sql
```

Or if using Supabase local development:

```bash
supabase db reset  # Applies migrations and seed data
```

## Full Schema Reference

The `full.sql` file contains the complete schema dump. This is useful for:
- Reference when understanding the full database structure
- Quick setup in a new environment (though migrations are preferred)
- Documentation purposes

**Note:** Always prefer using migrations over applying `full.sql` directly.

## Multi-Service Usage

This repository is designed to be shared across multiple services:

### For Frontend Applications

```bash
# Clone the repository
git clone <supabase-repo-url>
cd synced-supabase

# Link and apply migrations
supabase link --project-ref tepdgpiyjluuddwgboyy
supabase db push
```

### For Backend Services

Same process - clone, link, and apply migrations as needed.

### For CI/CD Pipelines

```bash
# In your CI/CD script
supabase link --project-ref tepdgpiyjluuddwgboyy --password ${{ secrets.SUPABASE_DB_PASSWORD }}
supabase db push
```

## Troubleshooting

### Migration Errors

**"policy already exists"**
- Migrations should be idempotent with `DROP POLICY IF EXISTS`
- If errors persist, check migration order

**"column does not exist"**
- Ensure migrations are applied in chronological order
- Check that dependent migrations ran successfully

**"relation does not exist"**
- Verify all prerequisite migrations have been applied
- Check migration dependencies

### Reset Database (⚠️ WARNING: Deletes All Data!)

```bash
supabase db reset
```

This will:
- Drop all tables
- Re-apply all migrations from scratch
- Re-seed any seed data

### Manual Migration Application

If CLI doesn't work, apply migrations via Supabase Dashboard:

1. Go to: https://supabase.com/dashboard/project/tepdgpiyjluuddwgboyy
2. Navigate to: **SQL Editor**
3. Copy and paste each migration file (in chronological order)
4. Run each SQL script

**⚠️ Warning:** Manual application doesn't track migration state. Use CLI if possible.

## Best Practices

1. **Always use migrations** - Never modify the database directly
2. **Test migrations locally** - Use Supabase local development when possible
3. **Keep migrations idempotent** - Use `IF EXISTS` and `IF NOT EXISTS` clauses
4. **One logical change per migration** - Keep migrations focused and atomic
5. **Document breaking changes** - Update this README for significant schema changes
6. **Review before merging** - Have migrations reviewed before applying to production
7. **Use functions for transactions** - Complex multi-table operations should use PostgreSQL functions
8. **Version control scripts** - All database scripts should be in this repository

## Related Repositories

- **Frontend Admin Portal**: [synced-admin-portal](https://github.com/your-org/synced-admin-portal)
- (Add other services that use this database)

## Support

For issues or questions:
1. Check existing migrations for similar patterns
2. Review Supabase documentation: https://supabase.com/docs
3. Check documentation in `docs/` directory
4. Contact the database team

## License

[Your License Here]

---

**Last Updated:** 2025-01-XX  
**Maintained by:** Synced Health Team
