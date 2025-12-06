# Migration to Standard Supabase Structure

**Created**: 2024-12-05  
**Last Updated**: 2024-12-05

## What Changed (Dec 5, 2024)

We reorganized the project to follow the standard Supabase CLI structure for better scalability and team collaboration.

### Old Structure
```
├── migrations/           (29 migration files)
├── functions/            (database function examples)
├── scripts/              (utilities)
├── docs/                 (documentation)
├── seed.sql              (seed data)
└── supabase/
    ├── migrations/       (junction to ../migrations/)
    └── config.toml
```

### New Structure ✅
```
├── scripts/              (utilities - unchanged)
├── docs/                 (documentation - unchanged)
├── tests/                (tests - unchanged)
└── supabase/             (Standard Supabase directory)
    ├── migrations/       (29 migration files - MOVED HERE)
    ├── db-functions/     (database function examples - MOVED HERE)
    ├── seed.sql          (seed data - MOVED HERE)
    ├── config.toml       (Supabase config)
    └── .temp/            (CLI metadata - gitignored)
```

## Why This Is Better

1. **Future-proof**: When you add Edge Functions, they'll go in `supabase/functions/` (different from DB functions)
2. **Local Development**: Running `supabase start` expects this structure
3. **Team Onboarding**: Standard structure = developers know where everything is
4. **Documentation**: Official Supabase docs/examples work directly
5. **Scalability**: Adding seeds, functions, tests all follow conventions

## Updated CLI Commands

All commands work the same (no `--workdir` needed):

```bash
# Create new migration
npx supabase migration new my_new_migration

# Check migration status
npx supabase migration list

# Apply migrations to remote
npx supabase db push

# Pull remote schema
npx supabase db pull

# Start local development
npx supabase start
```

## What's Gitignored

In `supabase/.gitignore`:
- `.temp/` - CLI metadata and link info
- `.branches/` - Branch metadata
- `.env.local` - Local environment variables

## Database Functions vs Edge Functions

- **Database Functions** (`supabase/db-functions/`): PL/pgSQL stored procedures (like `create_organization_with_initial_data`)
- **Edge Functions** (`supabase/functions/`): Deno/TypeScript serverless functions (for future API endpoints)

These are different! DB functions run in Postgres, Edge Functions run on the edge.

## Migration History

All 29 migrations successfully migrated:
- ✅ Files physically moved to `supabase/migrations/`
- ✅ CLI recognizes all migrations
- ✅ Remote database sync verified
- ✅ Latest migration: `20251202180000_add_missing_parse_fields.sql`

## Next Steps

When you need to:
- **Add a migration**: `npx supabase migration new descriptive_name`
- **Add an Edge Function**: `npx supabase functions new my-function`
- **Run locally**: `npx supabase start` (requires Docker)
- **Deploy**: `npx supabase db push`
