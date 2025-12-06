# Quick Migration Guide

**Created**: 2025-01-06  
**Last Updated**: 2025-01-06

## Step 1: Apply Migration 1 (Schema Columns)

1. Open: https://supabase.com/dashboard/project/tepdgpiyjluuddwgboyy
2. Click **SQL Editor** → **New query**
3. Copy ALL the contents from: `migrations/20251202160000_add_onboarding_columns.sql`
4. Paste into the SQL Editor
5. Click **RUN**
6. You should see: **"Success. No rows returned"**

## Step 2: Apply Migration 2 (Function)

1. In SQL Editor, click **New query** again
2. Copy ALL the contents from: `migrations/20251202170000_complete_onboarding_transaction.sql`
3. Paste into the SQL Editor
4. Click **RUN**
5. You should see: **"Success. No rows returned"**

## Step 3: Verify Function Exists

Run this query in SQL Editor:
```sql
SELECT routine_name 
FROM information_schema.routines 
WHERE routine_schema = 'public' 
  AND routine_name = 'complete_onboarding_transaction';
```

You should see one row returned with the function name.

## Step 4: Run Tests

```bash
cd tests
npm test
```

## ✅ Done!

If all tests pass, the function is ready to use in your frontend!

Check `NEXT_STEPS.md` for frontend integration instructions.
