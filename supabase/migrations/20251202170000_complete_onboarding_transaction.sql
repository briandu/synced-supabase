-- Complete Onboarding Transaction Function
-- This function handles all onboarding database operations in a single atomic transaction

create or replace function public.complete_onboarding_transaction(
  -- Required parameters (no defaults) - MUST come first
  p_user_id uuid,
  p_org_name text,
  p_location_name text,
  p_staff_first_name text,
  p_staff_last_name text,
  p_staff_email text,
  -- Optional parameters (with defaults) - MUST come after required ones
  p_org_subdomain text default null,
  p_org_website text default null,
  p_org_previous_software text default null,
  p_org_recommendation_source text default null,
  p_org_account_type text default null,
  p_org_company_size text default null,
  p_org_logo_url text default null,
  p_location_address_line1 text default null,
  p_location_address_line2 text default null,
  p_location_city text default null,
  p_location_province_state text default null,
  p_location_postal_zip_code text default null,
  p_location_country text default null,
  p_location_timezone text default 'America/Toronto',
  p_location_image_url text default null,
  p_operating_hours jsonb default null
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_org_id uuid;
  v_ownership_group_id uuid;
  v_location_id uuid;
  v_staff_member_id uuid;
  v_staff_location_id uuid;
  v_owner_role_id uuid;
  v_operating_hour record;
  v_result jsonb;
begin
  -- Validate required inputs
  if p_user_id is null then
    raise exception 'User ID is required';
  end if;
  
  if p_org_name is null or length(trim(p_org_name)) = 0 then
    raise exception 'Organization name is required';
  end if;
  
  if p_location_name is null or length(trim(p_location_name)) = 0 then
    raise exception 'Location name is required';
  end if;
  
  if p_staff_first_name is null or length(trim(p_staff_first_name)) = 0 then
    raise exception 'Staff first name is required';
  end if;
  
  if p_staff_email is null or length(trim(p_staff_email)) = 0 then
    raise exception 'Staff email is required';
  end if;
  
  -- Check if org with same subdomain already exists (if subdomain provided)
  if p_org_subdomain is not null then
    if exists (select 1 from public.orgs where subdomain = p_org_subdomain) then
      raise exception 'An organization with subdomain "%" already exists', p_org_subdomain;
    end if;
  end if;
  
  -- All operations below run in a single transaction
  -- If any operation fails, the entire transaction is rolled back
  
  -- 1. Create organization first (without ownership_group_id)
  insert into public.orgs (
    name,
    subdomain,
    website,
    logo_url,
    previous_software,
    recommendation_source,
    account_type,
    company_size,
    created_by
  )
  values (
    p_org_name,
    p_org_subdomain,
    p_org_website,
    p_org_logo_url,
    p_org_previous_software,
    p_org_recommendation_source,
    p_org_account_type,
    p_org_company_size,
    p_user_id
  )
  returning id into v_org_id;
  
  if v_org_id is null then
    raise exception 'Failed to create organization';
  end if;
  
  -- 2. Create ownership group (now we have org_id)
  insert into public.ownership_groups (
    name,
    og_name,
    org_id,
    key_contact_id,
    corporate_og,
    created_by
  )
  values (
    p_org_name || ' Ownership Group',
    p_org_name,
    v_org_id,
    p_user_id,
    true,
    p_user_id
  )
  returning id into v_ownership_group_id;
  
  if v_ownership_group_id is null then
    raise exception 'Failed to create ownership group';
  end if;
  
  -- 3. Create organization membership for owner
  insert into public.org_memberships (
    user_id,
    org_id,
    role
  )
  values (
    p_user_id,
    v_org_id,
    'org_admin'
  );
  
  -- 4. Create location
  insert into public.locations (
    org_id,
    ownership_group_id,
    name,
    timezone,
    address_line1,
    address_line2,
    city,
    province_state,
    postal_zip_code,
    country,
    featured_image_url,
    og_hq,
    is_active,
    created_by
  )
  values (
    v_org_id,
    v_ownership_group_id,
    p_location_name,
    p_location_timezone,
    p_location_address_line1,
    p_location_address_line2,
    p_location_city,
    p_location_province_state,
    p_location_postal_zip_code,
    p_location_country,
    p_location_image_url,
    true,  -- This is the HQ location
    true,
    p_user_id
  )
  returning id into v_location_id;
  
  if v_location_id is null then
    raise exception 'Failed to create location';
  end if;
  
  -- 5. Create staff member
  insert into public.staff_members (
    user_id,
    org_id,
    location_id,
    first_name,
    last_name,
    email,
    role,
    is_active,
    created_by
  )
  values (
    p_user_id,
    v_org_id,
    v_location_id,
    p_staff_first_name,
    p_staff_last_name,
    p_staff_email,
    'org_admin',
    true,
    p_user_id
  )
  returning id into v_staff_member_id;
  
  if v_staff_member_id is null then
    raise exception 'Failed to create staff member';
  end if;
  
  -- 6. Create staff-location link
  insert into public.staff_locations (
    staff_id,
    location_id,
    org_id,
    is_active,
    created_by
  )
  values (
    v_staff_member_id,
    v_location_id,
    v_org_id,
    true,
    p_user_id
  )
  returning id into v_staff_location_id;
  
  if v_staff_location_id is null then
    raise exception 'Failed to create staff-location link';
  end if;
  
  -- 7. Create operating hours (if provided)
  if p_operating_hours is not null and jsonb_array_length(p_operating_hours) > 0 then
    for v_operating_hour in
      select * from jsonb_to_recordset(p_operating_hours) as x(
        day integer,
        is_open boolean,
        start_time text,
        end_time text
      )
    loop
      -- Only create if we have valid data
      if v_operating_hour.day is not null then
        insert into public.operating_hours (
          location_id,
          day,
          is_open,
          start_time,
          end_time
        )
        values (
          v_location_id,
          v_operating_hour.day,
          coalesce(v_operating_hour.is_open, false),
          coalesce(v_operating_hour.start_time::time, '09:00'::time),
          coalesce(v_operating_hour.end_time::time, '17:00'::time)
        );
      end if;
    end loop;
  end if;
  
  -- 8. Get Owner role for the organization (if exists)
  select id into v_owner_role_id
  from public.roles
  where org_id = v_org_id
    and lower(key) = 'owner'
  limit 1;
  
  -- 9. Create staff permission with Owner role (if role exists)
  if v_owner_role_id is not null then
    insert into public.staff_permissions (
      staff_id,
      org_id,
      role_id
    )
    values (
      v_staff_member_id,
      v_org_id,
      v_owner_role_id
    );
  end if;
  
  -- 10. Update user profile onboarding status
  update public.profiles
  set is_onboarding_complete = true
  where id = p_user_id;
  
  -- If we get here, all operations succeeded
  -- Return the created IDs
  v_result := jsonb_build_object(
    'success', true,
    'org_id', v_org_id,
    'ownership_group_id', v_ownership_group_id,
    'location_id', v_location_id,
    'staff_member_id', v_staff_member_id,
    'staff_location_id', v_staff_location_id
  );
  
  return v_result;
  
exception
  when others then
    -- Any error will automatically rollback the transaction
    -- Re-raise the exception with context
    raise exception 'Error completing onboarding: %', sqlerrm;
end;
$$;

-- Grant execute permission to authenticated users
grant execute on function public.complete_onboarding_transaction(
  uuid, text, text, text, text, text,
  text, text, text, text, text, text, text, 
  text, text, text, text, text, text, text, text, jsonb
) to authenticated;

-- Grant execute permission to service role (for API routes)
grant execute on function public.complete_onboarding_transaction(
  uuid, text, text, text, text, text,
  text, text, text, text, text, text, text,
  text, text, text, text, text, text, text, text, jsonb
) to service_role;

-- Add comment for
