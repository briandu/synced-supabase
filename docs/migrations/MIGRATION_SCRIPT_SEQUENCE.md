# Migration Script Application Sequence

**Date:** 2025-01-XX  
**Purpose:** Complete ordered list of migration scripts to apply to Supabase database

---

## ⚠️ Important Notes

1. **Apply scripts in chronological order** (by timestamp in filename)
2. **Supabase automatically runs migrations in order** if you use `supabase migration up`
3. **All scripts are now idempotent** - safe to run multiple times
4. **GraphQL inflection is included** in the initial schema

---

## Complete Migration Sequence

### 1. **Initial Schema** (Foundation)
**File:** `migrations/2025-01-01T00-00-00_initial_schema.sql` (in Supabase repository)

**What it does:**
- ✅ Creates extensions (`pgcrypto`, `uuid-ossp`, `pg_graphql`)
- ✅ **Enables GraphQL name inflection** (camelCase support)
- ✅ Creates enums (`user_role`, `appointment_status`, `invoice_status`)
- ✅ Creates helper functions (`user_can_access_org`, `user_can_access_location`)
- ✅ Creates core tables:
  - `orgs`, `ownership_groups`, `locations`
  - `profiles`, `org_memberships`, `roles`
  - `staff_members`, `staff_locations`
  - `patients`, `appointments`, `patient_files`
  - `invoices`, `invoice_items`
  - `payment_methods`, `payments`, `gift_cards`
  - `permissions`, `role_permissions`
- ✅ Creates indexes
- ✅ Enables RLS and creates policies (idempotent)

**Dependencies:** None (foundation script)

---

### 2. **Taxes Table**
**File:** `migrations/2025-11-28T12-00-00_next_batch.sql` (in Supabase repository)

**What it does:**
- ✅ Creates `taxes` table
- ✅ Creates `location_taxes` junction table
- ✅ Creates indexes

**Dependencies:** Requires `orgs`, `locations` (from #1)

---

### 3. **Stripe Metadata & Gift Card Fields**
**File:** `migrations/2025-11-28T12-45-00_apply_pending.sql` (in Supabase repository)

**What it does:**
- ✅ Adds Stripe Connect metadata columns to `locations` table
- ✅ Extends `gift_cards` table with operational fields
- ✅ Adds staff/location active flags and metadata

**Dependencies:** Requires `locations`, `gift_cards`, `staff_members` (from #1)

---

### 4. **Chat & Realtime**
**File:** `migrations/2025-11-28T16-00-00_chat_realtime.sql` (in Supabase repository)

**What it does:**
- ✅ Creates `chat_threads` table
- ✅ Creates `chat_thread_members` table
- ✅ Creates `chat_messages` table
- ✅ Sets up realtime publication

**Dependencies:** Requires `orgs`, `staff_members`, `patients` (from #1)

---

### 5. **Phase 2: Missing Domain Tables**
**File:** `migrations/2025-11-28T17-00-00_phase2_fill_missing_domains.sql` (in Supabase repository)

**What it does:**
- ✅ Creates `staff_permissions` table
- ✅ Creates `org_staff_invites`, `org_join_requests` tables
- ✅ Creates `patient_relationships`, `patient_notes`, `patient_consents` tables
- ✅ Creates scheduling tables: `availability_blocks`, `staff_shifts`, `staff_breaks`, `staff_time_off`, `staff_tasks`
- ✅ Creates `disciplines`, `services` tables
- ✅ Creates billing tables: `credit_memos`, `discounts`, `fees`, `transactions`
- ✅ Creates `insurance_claims` table
- ✅ Creates `staff_notifications`, `patient_notifications` tables
- ✅ Enables RLS and creates basic policies

**Dependencies:** Requires core tables from #1

---

### 6. **Seed Permissions & Role Mappings**
**File:** `migrations/2025-11-28T17-50-00_seed_permissions_role_mappings.sql` (in Supabase repository)

**What it does:**
- ✅ Seeds default permissions
- ✅ Seeds role-permission mappings

**Dependencies:** Requires `permissions`, `role_permissions` (from #1)

---

### 7. **RLS Policy Tightening**
**File:** `migrations/2025-11-28T18-00-00_rls_tighten_core.sql` (in Supabase repository)

**What it does:**
- ✅ Tightens RLS policies for invites/join-requests
- ✅ Tightens RLS policies for patients, appointments, scheduling
- ✅ Tightens RLS policies for notifications, staff permissions
- ✅ Tightens RLS policies for disciplines, services, billing

**Dependencies:** Requires all tables from previous migrations

---

### 8. **Phase 2: Services & Products** ⭐ NEW
**File:** `migrations/2025-11-28T19-00-00_phase2_services_products.sql` (in Supabase repository)

**What it does:**
- ✅ Creates `items_catalog` table (master catalog)
- ✅ Creates `service_details`, `product_details` tables
- ✅ Creates `income_categories`, `suppliers` tables
- ✅ Creates `discipline_presets`, `discipline_offerings` tables
- ✅ Creates `service_offerings` table
- ✅ Creates `item_prices` table (pricing)
- ✅ Creates `product_inventory` table
- ✅ Adds `service_offering_id`, `item_price_id` to `appointments` table
- ✅ Adds `item_id`, `custom_tax_id` to `invoice_items` table
- ✅ Creates indexes
- ✅ Enables RLS and creates policies (idempotent)
- ✅ Adds to realtime publication

**Dependencies:** Requires `orgs`, `locations`, `staff_members`, `taxes`, `ownership_groups`, `appointments`, `invoice_items` (from #1, #2)

---

## ⚠️ Duplicate File Warning

**File to IGNORE:** `migrations/2025-01-XX_phase2_services_products.sql` (if it exists)

This is an old version with a placeholder date. **DO NOT RUN THIS FILE.** Use `2025-11-28T19-00-00_phase2_services_products.sql` instead.

---

## Quick Reference: Execution Order

```
1. 2025-01-01T00-00-00_initial_schema.sql                    ← Foundation
2. 2025-11-28T12-00-00_next_batch.sql                        ← Taxes
3. 2025-11-28T12-45-00_apply_pending.sql                     ← Stripe metadata
4. 2025-11-28T16-00-00_chat_realtime.sql                     ← Chat tables
5. 2025-11-28T17-00-00_phase2_fill_missing_domains.sql       ← Phase 2 additions
6. 2025-11-28T17-50-00_seed_permissions_role_mappings.sql    ← Seed data
7. 2025-11-28T18-00-00_rls_tighten_core.sql                  ← RLS tightening
8. 2025-11-28T19-00-00_phase2_services_products.sql          ← Services & Products ⭐
```

**Total: 8 migration scripts**

---

## How to Apply

### Option 1: Using Supabase CLI (Recommended)

```bash
# Navigate to Supabase migrations repository
cd synced-supabase

# Apply all migrations in order
supabase db push

# Or link first if not already linked
supabase link --project-ref tepdgpiyjluuddwgboyy
supabase db push
```

Supabase CLI will automatically:
- ✅ Run migrations in chronological order
- ✅ Track which migrations have been applied
- ✅ Skip already-applied migrations
- ✅ Show progress and errors

### Option 2: Manual Application (SQL Editor)

If you need to apply manually via Supabase SQL Editor:

1. Go to: https://supabase.com/dashboard/project/tepdgpiyjluuddwgboyy/sql
2. Apply each script **in order** (1-8 above)
3. Copy and paste each file's contents
4. Run each script

**⚠️ Warning:** Manual application doesn't track migration state. Use CLI if possible.

---

## Verification Steps

After applying all migrations, verify:

### 1. Check Tables Exist

```sql
-- Should return 50+ tables
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
ORDER BY table_name;
```

### 2. Check GraphQL Inflection

```sql
-- Should return: @graphql({"inflect_names": true})
SELECT obj_description('public'::regnamespace, 'pg_namespace');
```

### 3. Check RLS is Enabled

```sql
-- Should show RLS enabled for all tables
SELECT tablename, rowsecurity 
FROM pg_tables 
WHERE schemaname = 'public' 
AND rowsecurity = true;
```

### 4. Test GraphQL Query

In GraphQL playground (`https://tepdgpiyjluuddwgboyy.supabase.co/graphql/v1`):

```graphql
query TestSetup {
  patients(limit: 1) {
    id
    firstName  # Should work (camelCase with inflection)
    lastName
    orgId
  }
  items_catalog(limit: 1) {
    id
    itemName
    type
  }
}
```

---

## Troubleshooting

### Error: "policy already exists"
**Status:** ✅ **FIXED** - All policies now use `drop policy if exists` pattern

### Error: "column does not exist"
**Status:** ✅ **FIXED** - Backfill columns now run before indexes

### Error: "relation does not exist"
**Cause:** Missing dependency - ensure you're running scripts in order

### GraphQL fields still snake_case?
**Check:** Verify inflection is enabled (see verification step #2 above)

---

## Migration Status Summary

| Script | Status | Tables Created | Notes |
|--------|--------|----------------|-------|
| 1. Initial Schema | ✅ Ready | 18 core tables | Includes GraphQL inflection |
| 2. Taxes | ✅ Ready | 2 tables | |
| 3. Stripe Metadata | ✅ Ready | 0 (alters existing) | |
| 4. Chat Realtime | ✅ Ready | 3 tables | |
| 5. Phase 2 Domains | ✅ Ready | 20+ tables | |
| 6. Seed Data | ✅ Ready | 0 (inserts data) | |
| 7. RLS Tighten | ✅ Ready | 0 (updates policies) | |
| 8. Services & Products | ✅ Ready | 10 tables | ⭐ NEW |

**Total Tables:** ~53 tables after all migrations

---

## Next Steps After Applying

1. ✅ Verify all migrations applied successfully
2. ✅ Test GraphQL queries with camelCase field names
3. ✅ Continue with remaining Phase 2 tables (scheduling details, forms, insurance)
4. ✅ Update frontend GraphQL queries to use camelCase

---

**Last Updated:** 2025-01-XX  
**Status:** ✅ All scripts ready to apply in sequence

