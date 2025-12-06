# Supabase Directory

This directory contains all Supabase-specific configuration and database files following the standard Supabase CLI structure.

## Directory Structure

```
supabase/
├── .gitignore              # Ignore .temp/, .branches/, etc.
├── config.toml             # Supabase local dev configuration
├── migrations/             # Database migration scripts (29 files)
├── db-functions/           # Example database functions (PL/pgSQL)
└── seed.sql                # Seed data for local development
```

## Key Files

### `config.toml`
Configuration for local Supabase development:
- API ports and settings
- Database configuration
- Auth settings
- Storage limits
- Realtime configuration

**Note**: This is for LOCAL development only. Production config is on Supabase dashboard.

### `migrations/`
All database schema migrations in chronological order. Each file is timestamped (`YYYYMMDDHHMMSS_description.sql`).

**Latest migration**: `20251202180000_add_missing_parse_fields.sql`

### `db-functions/`
Example database functions (PL/pgSQL stored procedures):
- `create_organization_with_initial_data()` - Transactional org creation

**Note**: These are DATABASE functions (run in Postgres), not Edge Functions (Deno/TS).

### `seed.sql`
Optional seed data for local development. Run with:
```bash
npx supabase db reset  # Resets and reseeds local database
```

## Common Commands

### Migrations
```bash
# Create new migration
npx supabase migration new my_migration_name

# List all migrations
npx supabase migration list

# Apply to remote database
npx supabase db push

# Pull from remote
npx supabase db pull
```

### Local Development
```bash
# Start local Supabase (requires Docker)
npx supabase start

# Stop local Supabase
npx supabase stop

# Reset local database
npx supabase db reset
```

### Functions (Future)
When you add Edge Functions (serverless API endpoints):
```bash
# Create new Edge Function
npx supabase functions new my-function

# Serve locally
npx supabase functions serve

# Deploy
npx supabase functions deploy my-function
```

Edge Functions will go in `supabase/functions/` (separate from `db-functions/`).

## What's Tracked in Git

✅ **Tracked** (committed to repo):
- `config.toml` - Local dev config
- `migrations/` - All migration files
- `db-functions/` - Database function examples
- `seed.sql` - Seed data
- `.gitignore` - Git ignore rules

❌ **Not Tracked** (in .gitignore):
- `.temp/` - CLI metadata and link info
- `.branches/` - Branch metadata
- `.env.local` - Local environment variables

## Database Functions vs Edge Functions

| Feature | Database Functions | Edge Functions |
|---------|-------------------|----------------|
| **Location** | `supabase/db-functions/` | `supabase/functions/` |
| **Language** | PL/pgSQL, SQL | Deno, TypeScript |
| **Runs In** | PostgreSQL | Edge Runtime (Deno) |
| **Use Case** | Complex queries, transactions | API endpoints, webhooks |
| **Example** | `create_organization_with_initial_data` | REST API handler |

## Project Context

This project migrated from Parse to Supabase. The migrations in this directory represent the complete schema transformation, including:
- Initial schema (tables, indexes, RLS)
- Parse field compatibility
- Advanced features (realtime, notifications, stripe integration)

See `/docs/migrations/` for detailed migration documentation.

## Remote Database

**Project**: `tepdgpiyjluuddwgboyy`  
**Linked**: Yes (via `npx supabase link`)

All migrations are synchronized with the remote database. Use `npx supabase migration list` to verify sync status.
