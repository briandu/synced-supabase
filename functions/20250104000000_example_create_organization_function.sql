-- Example: Create Organization with Initial Data
-- This is a template/example function showing how to create transactional operations
-- 
-- To use this pattern:
-- 1. Copy this file and modify for your specific use case
-- 2. Update the function name and parameters
-- 3. Add your specific INSERT/UPDATE/DELETE operations
-- 4. Test thoroughly before applying to production
--
-- This example creates an organization with:
-- - Ownership group
-- - Organization record
-- - Default location
-- - Org membership for owner
-- - Staff member record
-- - Staff-location link
--
-- All in a single transaction that rolls back on any error

create or replace function public.create_organization_with_initial_data(
  p_org_name text,
  p_org_owner_user_id uuid,
  p_location_name text,
  p_location_timezone text default 'America/Toronto',
  p_location_address jsonb default null
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_org_id uuid;
  v_location_id uuid;
  v_ownership_group_id uuid;
  v_staff_member_id uuid;
  v_result jsonb;
begin
  -- Validate inputs
  if p_org_name is null or length(trim(p_org_name)) = 0 then
    raise exception 'Organization name cannot be empty';
  end if;
  
  if p_org_owner_user_id is null then
    raise exception 'Organization owner user ID is required';
  end if;
  
  if p_location_name is null or length(trim(p_location_name)) = 0 then
    raise exception 'Location name cannot be empty';
  end if;
  
  -- All operations below run in a single transaction
  -- If any operation fails, the entire transaction is rolled back
  
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
    -- Return error details
    raise exception 'Error creating organization: %', sqlerrm;
end;
$$;

-- Grant execute permission to authenticated users
grant execute on function public.create_organization_with_initial_data(text, uuid, text, text, jsonb) to authenticated;

-- Grant execute permission to service role (for API routes)
grant execute on function public.create_organization_with_initial_data(text, uuid, text, text, jsonb) to service_role;

-- Add comment for documentation
comment on function public.create_organization_with_initial_data is 
  'Creates an organization with ownership group, default location, staff member, and memberships in a single transaction. Returns JSON with created IDs or raises exception on failure. All operations are atomic - if any step fails, the entire transaction is rolled back.';

