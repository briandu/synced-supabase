# How to Apply Supabase Migrations

## Prerequisites

1. **Supabase CLI installed** (you have version 2.54.11 ✅)
2. **Authenticated with Supabase** (run `supabase login`)
3. **Project linked** (run `supabase link --project-ref tepdgpiyjluuddwgboyy`)

## Step-by-Step Instructions

### 1. Authenticate with Supabase

```bash
supabase login
```

This will open a browser window for you to authenticate.

### 2. Clone the Supabase Migrations Repository

```bash
# Clone the dedicated Supabase repository
git clone <supabase-repo-url>
cd synced-supabase
```

### 3. Link Your Project

```bash
supabase link --project-ref tepdgpiyjluuddwgboyy
```

You'll be prompted for your database password. You can find this in:
- Supabase Dashboard → Settings → Database → Database Password

### 4. Apply All Migrations

Once linked, apply all pending migrations:

```bash
supabase db push
```

This will:
- Check which migrations have already been applied
- Apply only the new/pending migrations in chronological order
- Show you the status of each migration

### 5. Verify Migration Status

Check which migrations have been applied:

```bash
supabase migration list
```

## Migration Files (in order)

The migrations will be applied in this order:

1. `2025-01-01T00-00-00_initial_schema.sql` - Base schema with core tables
2. `2025-11-28T12-00-00_next_batch.sql` - Additional tables
3. `2025-11-28T12-45-00_apply_pending.sql` - Pending changes
4. `2025-11-28T16-00-00_chat_realtime.sql` - Chat and realtime setup
5. `2025-11-28T17-00-00_phase2_fill_missing_domains.sql` - Missing domain tables
6. `2025-11-28T17-50-00_seed_permissions_role_mappings.sql` - Permissions seeding
7. `2025-11-28T18-00-00_rls_tighten_core.sql` - RLS policy tightening
8. `2025-11-28T19-00-00_phase2_services_products.sql` - Services & Products tables

## Troubleshooting

### If you get "policy already exists" errors:
The migrations now include `DROP POLICY IF EXISTS` statements, so this should be resolved. If you still see errors, you may need to manually drop the conflicting policies first.

### If you get "column does not exist" errors:
Make sure migrations are applied in order. The `supabase db push` command handles this automatically.

### If you need to reset and start fresh:
⚠️ **WARNING: This will delete all data!**

```bash
supabase db reset
```

This will:
- Drop all tables
- Re-apply all migrations from scratch
- Re-seed any seed data

## Alternative: Apply via Supabase Dashboard

If CLI doesn't work, you can also apply migrations via the Supabase Dashboard:

1. Go to: https://supabase.com/dashboard/project/tepdgpiyjluuddwgboyy
2. Navigate to: **SQL Editor**
3. Copy and paste the contents of each migration file (in order)
4. Run each SQL script

## What's Fixed in the Latest Migrations

- ✅ Policy idempotency: All `CREATE POLICY` statements now have `DROP POLICY IF EXISTS` before them
- ✅ GraphQL inflection: Enabled in initial schema for camelCase field names
- ✅ Column ordering: Backfill columns are added before indexes that reference them
- ✅ Services & Products: Complete domain with 10 new tables and foreign keys

