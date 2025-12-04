# GraphQL Name Inflection Setup - Summary

**Date:** 2025-01-XX  
**Status:** ✅ Inflection Enabled

## What Was Done

### 1. ✅ Enabled Name Inflection

Executed in Supabase SQL Editor:
```sql
COMMENT ON SCHEMA public IS e'@graphql({"inflect_names": true})';
```

**Result:** All GraphQL field names are now automatically converted from snake_case (database columns) to camelCase (GraphQL fields).

### 2. ✅ Created Documentation

Created comprehensive documentation:

- **`GRAPHQL_CAMELCASE_MIGRATION.md`** - Complete guide on:
  - The snake_case vs camelCase problem
  - Name inflection solution
  - Migration examples
  - Troubleshooting
  - Field naming conventions

- **Updated `GRAPHQL_FIELD_NAMING_MIGRATION.md`** to:
  - Reference inflection as enabled
  - Update examples to show camelCase field names
  - Include notes about inflection throughout

- **Updated `SUPABASE_MIGRATION_CHECKLIST.md`** to:
  - Mark inflection as enabled in Phase 1 (Database & Extensions)
  - Add inflection to Phase 4 (GraphQL migration) checklist

## Impact

### Before (snake_case)
```graphql
query {
  patients {
    first_name    # ❌ Frontend code breaks
    last_name     # ❌ Frontend code breaks
    org_id        # ❌ Frontend code breaks
  }
}
```

### After (camelCase with inflection)
```graphql
query {
  patients {
    firstName     # ✅ Works with frontend code
    lastName      # ✅ Works with frontend code
    orgId         # ✅ Works with frontend code
  }
}
```

## Next Steps

### Immediate Actions Required

1. **Verify Inflection is Working**
   - Test in GraphQL playground: `https://tepdgpiyjluuddwgboyy.supabase.co/graphql/v1`
   - Try query with camelCase fields
   - See verification query in `GRAPHQL_CAMELCASE_MIGRATION.md`

2. **Update Existing Supabase Queries**
   - Update `GET_PATIENTS_SUPA` and other `_SUPA` queries
   - Change `first_name` → `firstName`
   - Change `org_id` → `orgId`
   - Change `created_at` → `createdAt`
   - Keep `where` and `order_by` using snake_case

3. **Migrate All GraphQL Queries**
   - Follow priority order in `GRAPHQL_MIGRATION_QUICK_REFERENCE.md`
   - Use camelCase field names in selections
   - Use snake_case in filters/ordering

### Files That Need Updates

All queries in `src/app/graphql/**` that currently use snake_case need to be updated to camelCase:

- `src/app/graphql/patients.graphql.js` - `GET_PATIENTS_SUPA` uses `first_name`, `last_name`, etc.
- `src/app/graphql/staff.graphql.js` - `GET_STAFF_SUPA` uses snake_case
- `src/app/graphql/users.graphql.js` - Supabase queries use snake_case
- And 33+ more files

## Example Migration

### Current Query (snake_case)
```graphql
export const GET_PATIENTS_SUPA = gql`
  query GetPatientsSupa($orgId: uuid!) {
    patients(where: { org_id: { _eq: $orgId } }, order_by: { last_name: asc, first_name: asc }) {
      id
      org_id
      first_name
      last_name
      email
      created_at
    }
  }
`;
```

### Should Become (camelCase)
```graphql
export const GET_PATIENTS_SUPA = gql`
  query GetPatientsSupa($orgId: uuid!) {
    patients(where: { org_id: { _eq: $orgId } }, order_by: { last_name: asc, first_name: asc }) {
      id
      orgId          # camelCase
      firstName      # camelCase
      lastName       # camelCase
      email
      createdAt      # camelCase
    }
  }
`;
```

**Note:** `where` and `order_by` still use snake_case column names (`org_id`, `last_name`, `first_name`), but field selections use camelCase.

## Documentation References

- **Primary Guide:** `docs/migrations/GRAPHQL_CAMELCASE_MIGRATION.md`
- **Field Naming Patterns:** `docs/migrations/GRAPHQL_FIELD_NAMING_MIGRATION.md`
- **Quick Reference:** `docs/migrations/GRAPHQL_MIGRATION_QUICK_REFERENCE.md`
- **Migration Checklist:** `docs/migrations/SUPABASE_MIGRATION_CHECKLIST.md`

---

**Last Updated:** 2025-01-XX  
**Action Required:** Update all GraphQL queries to use camelCase field names

