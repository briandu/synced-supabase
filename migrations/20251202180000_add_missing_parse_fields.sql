-- Add missing Parse fields to Supabase tables
-- This migration adds fields that were present in Parse but missing in Supabase
-- Safe to rerun: guards on every alter
-- 
-- Organized by:
-- 1. Audit fields (updated_by on all tables)
-- 2. Branding fields (currency, primary_color, secondary_color)
-- 3. Contact/address fields (billing addresses, phone, fax, email, website)
-- 4. Descriptive fields (bio, descriptions, operating hours)
-- 5. Staff location details (role, dates, employment type)
-- 6. Staff member additional fields

-- ============================================================================
-- 1. AUDIT FIELDS: Add updated_by to all tables
-- ============================================================================

-- orgs table
do $$
begin
  if not exists (select 1 from information_schema.columns where table_schema = 'public' and table_name = 'orgs' and column_name = 'updated_by') then
    alter table public.orgs add column updated_by uuid references auth.users(id) on delete set null;
  end if;
end;
$$;

-- ownership_groups table
do $$
begin
  if not exists (select 1 from information_schema.columns where table_schema = 'public' and table_name = 'ownership_groups' and column_name = 'updated_by') then
    alter table public.ownership_groups add column updated_by uuid references auth.users(id) on delete set null;
  end if;
end;
$$;

-- locations table
do $$
begin
  if not exists (select 1 from information_schema.columns where table_schema = 'public' and table_name = 'locations' and column_name = 'updated_by') then
    alter table public.locations add column updated_by uuid references auth.users(id) on delete set null;
  end if;
end;
$$;

-- staff_members table
do $$
begin
  if not exists (select 1 from information_schema.columns where table_schema = 'public' and table_name = 'staff_members' and column_name = 'updated_by') then
    alter table public.staff_members add column updated_by uuid references auth.users(id) on delete set null;
  end if;
end;
$$;

-- staff_locations table
do $$
begin
  if not exists (select 1 from information_schema.columns where table_schema = 'public' and table_name = 'staff_locations' and column_name = 'updated_by') then
    alter table public.staff_locations add column updated_by uuid references auth.users(id) on delete set null;
  end if;
end;
$$;

-- org_memberships table (add updated_at and updated_by)
do $$
begin
  if not exists (select 1 from information_schema.columns where table_schema = 'public' and table_name = 'org_memberships' and column_name = 'updated_at') then
    alter table public.org_memberships add column updated_at timestamptz not null default now();
  end if;
  
  if not exists (select 1 from information_schema.columns where table_schema = 'public' and table_name = 'org_memberships' and column_name = 'updated_by') then
    alter table public.org_memberships add column updated_by uuid references auth.users(id) on delete set null;
  end if;
end;
$$;

-- ============================================================================
-- 2. BRANDING FIELDS: Add currency and color fields
-- ============================================================================

-- orgs table: currency, primary_color, secondary_color
do $$
begin
  if not exists (select 1 from information_schema.columns where table_schema = 'public' and table_name = 'orgs' and column_name = 'currency') then
    alter table public.orgs add column currency text;
  end if;
  
  if not exists (select 1 from information_schema.columns where table_schema = 'public' and table_name = 'orgs' and column_name = 'primary_color') then
    alter table public.orgs add column primary_color text;
  end if;
  
  if not exists (select 1 from information_schema.columns where table_schema = 'public' and table_name = 'orgs' and column_name = 'secondary_color') then
    alter table public.orgs add column secondary_color text;
  end if;
end;
$$;

-- locations table: currency, primary_color, secondary_color
do $$
begin
  if not exists (select 1 from information_schema.columns where table_schema = 'public' and table_name = 'locations' and column_name = 'currency') then
    alter table public.locations add column currency text;
  end if;
  
  if not exists (select 1 from information_schema.columns where table_schema = 'public' and table_name = 'locations' and column_name = 'primary_color') then
    alter table public.locations add column primary_color text;
  end if;
  
  if not exists (select 1 from information_schema.columns where table_schema = 'public' and table_name = 'locations' and column_name = 'secondary_color') then
    alter table public.locations add column secondary_color text;
  end if;
end;
$$;

-- ============================================================================
-- 3. OWNERSHIP_GROUPS: Add missing fields
-- ============================================================================

do $$
begin
  if not exists (select 1 from information_schema.columns where table_schema = 'public' and table_name = 'ownership_groups' and column_name = 'legal_name') then
    alter table public.ownership_groups add column legal_name text;
  end if;
  
  if not exists (select 1 from information_schema.columns where table_schema = 'public' and table_name = 'ownership_groups' and column_name = 'tax_number') then
    alter table public.ownership_groups add column tax_number text;
  end if;
end;
$$;

-- ============================================================================
-- 4. LOCATIONS: Add missing contact, address, and descriptive fields
-- ============================================================================

do $$
begin
  -- Operating and legal names
  if not exists (select 1 from information_schema.columns where table_schema = 'public' and table_name = 'locations' and column_name = 'operating_name') then
    alter table public.locations add column operating_name text;
  end if;
  
  if not exists (select 1 from information_schema.columns where table_schema = 'public' and table_name = 'locations' and column_name = 'legal_name') then
    alter table public.locations add column legal_name text;
  end if;
  
  -- Billing address fields
  if not exists (select 1 from information_schema.columns where table_schema = 'public' and table_name = 'locations' and column_name = 'billing_address_line1') then
    alter table public.locations add column billing_address_line1 text;
  end if;
  
  if not exists (select 1 from information_schema.columns where table_schema = 'public' and table_name = 'locations' and column_name = 'billing_address_line2') then
    alter table public.locations add column billing_address_line2 text;
  end if;
  
  if not exists (select 1 from information_schema.columns where table_schema = 'public' and table_name = 'locations' and column_name = 'billing_city') then
    alter table public.locations add column billing_city text;
  end if;
  
  if not exists (select 1 from information_schema.columns where table_schema = 'public' and table_name = 'locations' and column_name = 'billing_province_state') then
    alter table public.locations add column billing_province_state text;
  end if;
  
  if not exists (select 1 from information_schema.columns where table_schema = 'public' and table_name = 'locations' and column_name = 'billing_country') then
    alter table public.locations add column billing_country text;
  end if;
  
  if not exists (select 1 from information_schema.columns where table_schema = 'public' and table_name = 'locations' and column_name = 'billing_postal_zip_code') then
    alter table public.locations add column billing_postal_zip_code text;
  end if;
  
  if not exists (select 1 from information_schema.columns where table_schema = 'public' and table_name = 'locations' and column_name = 'use_location_for_billing') then
    alter table public.locations add column use_location_for_billing boolean not null default true;
  end if;
  
  -- Contact fields
  if not exists (select 1 from information_schema.columns where table_schema = 'public' and table_name = 'locations' and column_name = 'phone_number') then
    alter table public.locations add column phone_number text;
  end if;
  
  if not exists (select 1 from information_schema.columns where table_schema = 'public' and table_name = 'locations' and column_name = 'fax_number') then
    alter table public.locations add column fax_number text;
  end if;
  
  if not exists (select 1 from information_schema.columns where table_schema = 'public' and table_name = 'locations' and column_name = 'email') then
    alter table public.locations add column email text;
  end if;
  
  if not exists (select 1 from information_schema.columns where table_schema = 'public' and table_name = 'locations' and column_name = 'website') then
    alter table public.locations add column website text;
  end if;
  
  -- Tax and key contact
  if not exists (select 1 from information_schema.columns where table_schema = 'public' and table_name = 'locations' and column_name = 'tax_number') then
    alter table public.locations add column tax_number text;
  end if;
  
  if not exists (select 1 from information_schema.columns where table_schema = 'public' and table_name = 'locations' and column_name = 'key_contact_id') then
    alter table public.locations add column key_contact_id uuid references auth.users(id) on delete set null;
  end if;
  
  -- Logo (separate from featured_image_url)
  if not exists (select 1 from information_schema.columns where table_schema = 'public' and table_name = 'locations' and column_name = 'logo_url') then
    alter table public.locations add column logo_url text;
  end if;
  
  -- Descriptive fields
  if not exists (select 1 from information_schema.columns where table_schema = 'public' and table_name = 'locations' and column_name = 'short_description') then
    alter table public.locations add column short_description text;
  end if;
  
  if not exists (select 1 from information_schema.columns where table_schema = 'public' and table_name = 'locations' and column_name = 'long_description') then
    alter table public.locations add column long_description text;
  end if;
  
  -- Operating hours (stored as JSONB array)
  if not exists (select 1 from information_schema.columns where table_schema = 'public' and table_name = 'locations' and column_name = 'operating_hours') then
    alter table public.locations add column operating_hours jsonb;
  end if;
end;
$$;

-- ============================================================================
-- 5. STAFF_MEMBERS: Add missing fields
-- ============================================================================

do $$
begin
  -- Name fields
  if not exists (select 1 from information_schema.columns where table_schema = 'public' and table_name = 'staff_members' and column_name = 'middle_name') then
    alter table public.staff_members add column middle_name text;
  end if;
  
  if not exists (select 1 from information_schema.columns where table_schema = 'public' and table_name = 'staff_members' and column_name = 'prefix') then
    alter table public.staff_members add column prefix text;
  end if;
  
  -- Personal information
  if not exists (select 1 from information_schema.columns where table_schema = 'public' and table_name = 'staff_members' and column_name = 'bio') then
    alter table public.staff_members add column bio text;
  end if;
  
  if not exists (select 1 from information_schema.columns where table_schema = 'public' and table_name = 'staff_members' and column_name = 'date_of_birth') then
    alter table public.staff_members add column date_of_birth date;
  end if;
  
  if not exists (select 1 from information_schema.columns where table_schema = 'public' and table_name = 'staff_members' and column_name = 'gender') then
    alter table public.staff_members add column gender text;
  end if;
  
  if not exists (select 1 from information_schema.columns where table_schema = 'public' and table_name = 'staff_members' and column_name = 'is_provider') then
    alter table public.staff_members add column is_provider boolean not null default false;
  end if;
  
  if not exists (select 1 from information_schema.columns where table_schema = 'public' and table_name = 'staff_members' and column_name = 'firebase_uid') then
    alter table public.staff_members add column firebase_uid text;
  end if;
  
  -- Address fields
  if not exists (select 1 from information_schema.columns where table_schema = 'public' and table_name = 'staff_members' and column_name = 'address_line1') then
    alter table public.staff_members add column address_line1 text;
  end if;
  
  if not exists (select 1 from information_schema.columns where table_schema = 'public' and table_name = 'staff_members' and column_name = 'address_line2') then
    alter table public.staff_members add column address_line2 text;
  end if;
  
  if not exists (select 1 from information_schema.columns where table_schema = 'public' and table_name = 'staff_members' and column_name = 'city') then
    alter table public.staff_members add column city text;
  end if;
  
  if not exists (select 1 from information_schema.columns where table_schema = 'public' and table_name = 'staff_members' and column_name = 'province_state') then
    alter table public.staff_members add column province_state text;
  end if;
  
  if not exists (select 1 from information_schema.columns where table_schema = 'public' and table_name = 'staff_members' and column_name = 'country') then
    alter table public.staff_members add column country text;
  end if;
  
  if not exists (select 1 from information_schema.columns where table_schema = 'public' and table_name = 'staff_members' and column_name = 'postal_zip_code') then
    alter table public.staff_members add column postal_zip_code text;
  end if;
  
  -- Contact fields
  if not exists (select 1 from information_schema.columns where table_schema = 'public' and table_name = 'staff_members' and column_name = 'mobile') then
    alter table public.staff_members add column mobile text;
  end if;
  
  if not exists (select 1 from information_schema.columns where table_schema = 'public' and table_name = 'staff_members' and column_name = 'work_phone') then
    alter table public.staff_members add column work_phone text;
  end if;
  
  -- Profile picture and signature
  if not exists (select 1 from information_schema.columns where table_schema = 'public' and table_name = 'staff_members' and column_name = 'profile_picture_url') then
    alter table public.staff_members add column profile_picture_url text;
  end if;
  
  if not exists (select 1 from information_schema.columns where table_schema = 'public' and table_name = 'staff_members' and column_name = 'signature') then
    alter table public.staff_members add column signature text;
  end if;
end;
$$;

-- ============================================================================
-- 6. STAFF_LOCATIONS: Add missing location-specific staff fields
-- ============================================================================

do $$
begin
  -- Role and provider status
  if not exists (select 1 from information_schema.columns where table_schema = 'public' and table_name = 'staff_locations' and column_name = 'role_id') then
    alter table public.staff_locations add column role_id uuid references public.roles(id) on delete set null;
  end if;
  
  if not exists (select 1 from information_schema.columns where table_schema = 'public' and table_name = 'staff_locations' and column_name = 'is_provider') then
    alter table public.staff_locations add column is_provider boolean not null default false;
  end if;
  
  -- Location-specific staff details
  if not exists (select 1 from information_schema.columns where table_schema = 'public' and table_name = 'staff_locations' and column_name = 'title') then
    alter table public.staff_locations add column title text;
  end if;
  
  if not exists (select 1 from information_schema.columns where table_schema = 'public' and table_name = 'staff_locations' and column_name = 'bio') then
    alter table public.staff_locations add column bio text;
  end if;
  
  if not exists (select 1 from information_schema.columns where table_schema = 'public' and table_name = 'staff_locations' and column_name = 'work_email') then
    alter table public.staff_locations add column work_email text;
  end if;
  
  if not exists (select 1 from information_schema.columns where table_schema = 'public' and table_name = 'staff_locations' and column_name = 'work_phone') then
    alter table public.staff_locations add column work_phone text;
  end if;
  
  -- Employment dates and type
  if not exists (select 1 from information_schema.columns where table_schema = 'public' and table_name = 'staff_locations' and column_name = 'start_date') then
    alter table public.staff_locations add column start_date date;
  end if;
  
  if not exists (select 1 from information_schema.columns where table_schema = 'public' and table_name = 'staff_locations' and column_name = 'end_date') then
    alter table public.staff_locations add column end_date date;
  end if;
  
  if not exists (select 1 from information_schema.columns where table_schema = 'public' and table_name = 'staff_locations' and column_name = 'employment_type') then
    alter table public.staff_locations add column employment_type text;
  end if;
  
  -- Provider credential (if provider_credentials table exists, otherwise can be added later)
  -- Note: This assumes a provider_credentials table exists. If not, this will need to be added separately.
  -- if not exists (select 1 from information_schema.columns where table_schema = 'public' and table_name = 'staff_locations' and column_name = 'provider_credential_id') then
  --   alter table public.staff_locations add column provider_credential_id uuid references public.provider_credentials(id) on delete set null;
  -- end if;
end;
$$;

-- ============================================================================
-- COMMENTS: Add documentation for new fields
-- ============================================================================

comment on column public.orgs.currency is 'Organization currency code (e.g., USD, CAD)';
comment on column public.orgs.primary_color is 'Primary brand color (hex code)';
comment on column public.orgs.secondary_color is 'Secondary brand color (hex code)';
comment on column public.orgs.updated_by is 'User who last updated this organization';

comment on column public.ownership_groups.legal_name is 'Legal name of the ownership group';
comment on column public.ownership_groups.tax_number is 'Tax identification number';
comment on column public.ownership_groups.updated_by is 'User who last updated this ownership group';

comment on column public.locations.operating_name is 'Operating/trading name (may differ from legal name)';
comment on column public.locations.legal_name is 'Legal name of the location';
comment on column public.locations.currency is 'Location currency code (e.g., USD, CAD)';
comment on column public.locations.primary_color is 'Primary brand color for this location (hex code)';
comment on column public.locations.secondary_color is 'Secondary brand color for this location (hex code)';
comment on column public.locations.use_location_for_billing is 'Whether to use location address for billing (default: true)';
comment on column public.locations.operating_hours is 'Operating hours stored as JSONB array';
comment on column public.locations.updated_by is 'User who last updated this location';

comment on column public.staff_members.middle_name is 'Middle name';
comment on column public.staff_members.prefix is 'Name prefix (e.g., Dr., Mr., Ms.)';
comment on column public.staff_members.bio is 'Biography or professional summary';
comment on column public.staff_members.is_provider is 'Whether this staff member is a healthcare provider';
comment on column public.staff_members.profile_picture_url is 'URL to profile picture (stored in Supabase Storage)';
comment on column public.staff_members.updated_by is 'User who last updated this staff member';

comment on column public.staff_locations.role_id is 'Role assigned at this specific location';
comment on column public.staff_locations.is_provider is 'Whether staff member is a provider at this location';
comment on column public.staff_locations.title is 'Job title at this location';
comment on column public.staff_locations.bio is 'Biography specific to this location';
comment on column public.staff_locations.work_email is 'Work email at this location';
comment on column public.staff_locations.work_phone is 'Work phone at this location';
comment on column public.staff_locations.start_date is 'Employment start date at this location';
comment on column public.staff_locations.end_date is 'Employment end date at this location (null if current)';
comment on column public.staff_locations.employment_type is 'Type of employment (e.g., full-time, part-time, contractor)';
comment on column public.staff_locations.updated_by is 'User who last updated this staff-location assignment';
