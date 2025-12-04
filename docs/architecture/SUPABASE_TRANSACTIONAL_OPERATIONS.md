# Supabase Transactional Operations Guide

## Overview

For complex operations that require multiple database operations in a single transaction (like creating an organization with all its initial data), we use **PostgreSQL Functions** (stored procedures) that run in the database with native transaction support.

## Architecture

```
Frontend/API Route
    ↓
Supabase RPC Call (via .rpc())
    ↓
PostgreSQL Function (in database)
    ↓
BEGIN TRANSACTION
    ↓
Multiple INSERT/UPDATE/DELETE operations
    ↓
COMMIT (or ROLLBACK on error)
```

## Where to House These Functions

### 1. **Database Functions** → In Supabase Repository

**Location:** `synced-supabase/migrations/YYYYMMDDHHMMSS_function_name.sql`

Database functions are version-controlled in migration files, just like tables and RLS policies.

### 2. **API Routes** (Optional) → In Frontend Repository

**Location:** `src/pages/api/organizations/create.js` or `src/app/api/organizations/create/route.js`

API routes can call the RPC function and add additional logic (validation, logging, etc.).

### 3. **GraphQL Mutations** (If Simple) → In Frontend Repository

**Location:** `src/app/graphql/organization.graphql.js`

For simple operations, GraphQL mutations can call RPC functions directly.

## Example: Creating an Organization with Initial Data

### Step 1: Create PostgreSQL Function (Migration)

**File:** `synced-supabase/migrations/20250104000000_create_organization_function.sql`

```sql
-- Function to create an organization with all initial data in a single transaction
create or replace function public.create_organization_with_initial_data(
  p_org_name text,
  p_org_owner_user_id uuid,
  p_location_name text,
  p_location_timezone text default 'America/Toronto',
  p_location_address jsonb default null
)
returns jsonb
language plpgsql
security definer -- Runs with function creator's privileges (needed for service role)
as $$
declare
  v_org_id uuid;
  v_location_id uuid;
  v_ownership_group_id uuid;
  v_staff_member_id uuid;
  v_result jsonb;
begin
  -- Start transaction (implicit in function, but explicit for clarity)
  -- All operations below will be rolled back if any fail
  
  -- 1. Create ownership group
  insert into public.ownership_groups (name, created_by)
  values (p_org_name || ' Ownership Group', p_org_owner_user_id)
  returning id into v_ownership_group_id;
  
  if v_ownership_group_id is null then
    raise exception 'Failed to create ownership group';
  end if;
  
  -- 2. Create organization
  insert into public.orgs (name, ownership_group_id, created_by)
  values (p_org_name, v_ownership_group_id, p_org_owner_user_id)
  returning id into v_org_id;
  
  if v_org_id is null then
    raise exception 'Failed to create organization';
  end if;
  
  -- 3. Create default location
  insert into public.locations (
    org_id,
    name,
    timezone,
    address,
    created_by
  )
  values (
    v_org_id,
    p_location_name,
    p_location_timezone,
    p_location_address,
    p_org_owner_user_id
  )
  returning id into v_location_id;
  
  if v_location_id is null then
    raise exception 'Failed to create location';
  end if;
  
  -- 4. Create org membership for owner
  insert into public.org_memberships (org_id, user_id, role, created_by)
  values (v_org_id, p_org_owner_user_id, 'org_admin', p_org_owner_user_id);
  
  -- 5. Create staff member record for owner
  insert into public.staff_members (
    org_id,
    user_id,
    first_name,
    last_name,
    email,
    role,
    is_active,
    created_by
  )
  select
    v_org_id,
    p_org_owner_user_id,
    p.first_name,
    p.last_name,
    p.email,
    'org_admin',
    true,
    p_org_owner_user_id
  from public.profiles p
  where p.id = p_org_owner_user_id
  returning id into v_staff_member_id;
  
  if v_staff_member_id is null then
    raise exception 'Failed to create staff member';
  end if;
  
  -- 6. Link staff to location
  insert into public.staff_locations (staff_id, location_id, created_by)
  values (v_staff_member_id, v_location_id, p_org_owner_user_id);
  
  -- 7. Create default permissions (if needed)
  -- This could be done via seed data, but including here for completeness
  -- insert into public.staff_permissions (staff_id, permission_id, created_by)
  -- select v_staff_member_id, id, p_org_owner_user_id
  -- from public.permissions
  -- where name in ('manage_org', 'manage_staff', 'manage_patients', 'manage_schedule', 'manage_billing');
  
  -- If we get here, all operations succeeded
  -- Return the created IDs
  v_result := jsonb_build_object(
    'success', true,
    'org_id', v_org_id,
    'location_id', v_location_id,
    'ownership_group_id', v_ownership_group_id,
    'staff_member_id', v_staff_member_id
  );
  
  return v_result;
  
exception
  when others then
    -- Any error will automatically rollback the transaction
    -- Log the error (optional)
    raise exception 'Error creating organization: %', sqlerrm;
end;
$$;

-- Grant execute permission to authenticated users
grant execute on function public.create_organization_with_initial_data(text, uuid, text, text, jsonb) to authenticated;

-- Grant execute permission to service role (for API routes)
grant execute on function public.create_organization_with_initial_data(text, uuid, text, text, jsonb) to service_role;

-- Add comment for documentation
comment on function public.create_organization_with_initial_data is 
  'Creates an organization with ownership group, default location, staff member, and memberships in a single transaction. Returns JSON with created IDs or raises exception on failure.';
```

### Step 2: Call from API Route (Recommended)

**File:** `src/pages/api/organizations/create.js`

```javascript
import { createSupabaseServiceClient } from '@/lib/supabaseClient';

export default async function handler(req, res) {
  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method not allowed' });
  }

  try {
    const { orgName, locationName, locationTimezone, locationAddress } = req.body;
    
    // Validate input
    if (!orgName || !locationName) {
      return res.status(400).json({ error: 'Organization name and location name are required' });
    }

    // Get authenticated user
    const supabase = createSupabaseServiceClient();
    const { data: { user }, error: authError } = await supabase.auth.getUser(
      req.headers.authorization?.replace('Bearer ', '')
    );

    if (authError || !user) {
      return res.status(401).json({ error: 'Unauthorized' });
    }

    // Call the RPC function
    const { data, error } = await supabase.rpc('create_organization_with_initial_data', {
      p_org_name: orgName,
      p_org_owner_user_id: user.id,
      p_location_name: locationName,
      p_location_timezone: locationTimezone || 'America/Toronto',
      p_location_address: locationAddress || null,
    });

    if (error) {
      console.error('Error creating organization:', error);
      return res.status(500).json({ 
        error: 'Failed to create organization',
        details: error.message 
      });
    }

    return res.status(201).json({
      success: true,
      organization: {
        id: data.org_id,
        name: orgName,
        locationId: data.location_id,
        ownershipGroupId: data.ownership_group_id,
        staffMemberId: data.staff_member_id,
      },
    });
  } catch (error) {
    console.error('Unexpected error:', error);
    return res.status(500).json({ error: 'Internal server error' });
  }
}
```

### Step 3: Call from Frontend (Alternative)

**File:** `src/app/graphql/organization.graphql.js`

```javascript
import { gql } from '@apollo/client';

// GraphQL mutation that calls the RPC function
export const CREATE_ORGANIZATION_WITH_INITIAL_DATA = gql`
  mutation CreateOrganizationWithInitialData(
    $orgName: String!
    $locationName: String!
    $locationTimezone: String
    $locationAddress: JSON
  ) {
    createOrganizationWithInitialData(
      pOrgName: $orgName
      pOrgOwnerUserId: $userId  # Get from auth context
      pLocationName: $locationName
      pLocationTimezone: $locationTimezone
      pLocationAddress: $locationAddress
    )
  }
`;
```

**Note:** Supabase GraphQL doesn't directly support RPC calls. You'll need to use the Supabase JS client:

```javascript
import { supabaseClient } from '@/lib/supabaseClient';

async function createOrganization(orgName, locationName) {
  const { data: { user } } = await supabaseClient.auth.getUser();
  
  const { data, error } = await supabaseClient.rpc('create_organization_with_initial_data', {
    p_org_name: orgName,
    p_org_owner_user_id: user.id,
    p_location_name: locationName,
    p_location_timezone: 'America/Toronto',
    p_location_address: null,
  });

  if (error) throw error;
  return data;
}
```

## Key Benefits

1. **Atomic Transactions**: All operations succeed or fail together
2. **Automatic Rollback**: PostgreSQL automatically rolls back on any error
3. **Performance**: Single database round-trip instead of multiple
4. **Data Integrity**: No partial states or orphaned records
5. **Version Controlled**: Functions are in migration files
6. **Reusable**: Can be called from API routes, frontend, or other functions

## Best Practices

### 1. Use `SECURITY DEFINER` for Service Role Operations

```sql
create or replace function public.create_organization_with_initial_data(...)
language plpgsql
security definer  -- Runs with function creator's privileges
set search_path = public  -- Prevent search_path attacks
as $$ ... $$;
```

### 2. Validate Input Parameters

```sql
if p_org_name is null or length(trim(p_org_name)) = 0 then
  raise exception 'Organization name cannot be empty';
end if;
```

### 3. Return Meaningful Results

```sql
-- Return JSON with created IDs
return jsonb_build_object(
  'success', true,
  'org_id', v_org_id,
  'location_id', v_location_id
);
```

### 4. Handle Errors Gracefully

```sql
exception
  when others then
    -- Log error details
    raise exception 'Error creating organization: %', sqlerrm;
    -- Transaction automatically rolls back
end;
```

### 5. Grant Appropriate Permissions

```sql
-- Allow authenticated users to call
grant execute on function public.create_organization_with_initial_data(...) to authenticated;

-- Allow service role (for API routes)
grant execute on function public.create_organization_with_initial_data(...) to service_role;
```

## Testing

### Test the Function Directly

```sql
-- In Supabase SQL Editor
select public.create_organization_with_initial_data(
  'Test Org',
  '00000000-0000-0000-0000-000000000000'::uuid,  -- Test user ID
  'Test Location',
  'America/Toronto',
  '{"street": "123 Main St"}'::jsonb
);
```

### Test via API Route

```bash
curl -X POST http://localhost:3000/api/organizations/create \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -d '{
    "orgName": "Test Org",
    "locationName": "Test Location",
    "locationTimezone": "America/Toronto"
  }'
```

## Migration Workflow

1. **Create migration file** in `synced-supabase/migrations/`
2. **Write function SQL** with transaction logic
3. **Test locally** (if using Supabase local development)
4. **Apply migration**: `supabase db push`
5. **Create API route** (optional) in frontend repository
6. **Update frontend** to call API route or RPC directly

## Related Files

- **Migration files**: `synced-supabase/migrations/`
- **API routes**: `src/pages/api/` or `src/app/api/`
- **GraphQL queries**: `src/app/graphql/`
- **Supabase client**: `src/lib/supabaseClient.js`

## Summary

For complex transactional operations:
1. ✅ **Create PostgreSQL functions** in migration files (Supabase repository)
2. ✅ **Use transactions** (automatic in functions)
3. ✅ **Call via RPC** from API routes or frontend
4. ✅ **Version control** functions in migrations
5. ✅ **Test thoroughly** before deploying

This approach ensures data integrity, performance, and maintainability.

