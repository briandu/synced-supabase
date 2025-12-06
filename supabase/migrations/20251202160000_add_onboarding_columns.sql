-- Add missing columns for onboarding functionality
-- Safe to rerun: guards on every alter

-- Add columns to orgs table
do $$
begin
  if not exists (select 1 from information_schema.columns where table_schema = 'public' and table_name = 'orgs' and column_name = 'subdomain') then
    alter table public.orgs add column subdomain text;
  end if;
  
  if not exists (select 1 from information_schema.columns where table_schema = 'public' and table_name = 'orgs' and column_name = 'website') then
    alter table public.orgs add column website text;
  end if;
  
  if not exists (select 1 from information_schema.columns where table_schema = 'public' and table_name = 'orgs' and column_name = 'logo_url') then
    alter table public.orgs add column logo_url text;
  end if;
  
  if not exists (select 1 from information_schema.columns where table_schema = 'public' and table_name = 'orgs' and column_name = 'previous_software') then
    alter table public.orgs add column previous_software text;
  end if;
  
  if not exists (select 1 from information_schema.columns where table_schema = 'public' and table_name = 'orgs' and column_name = 'recommendation_source') then
    alter table public.orgs add column recommendation_source text;
  end if;
  
  if not exists (select 1 from information_schema.columns where table_schema = 'public' and table_name = 'orgs' and column_name = 'account_type') then
    alter table public.orgs add column account_type text;
  end if;
  
  if not exists (select 1 from information_schema.columns where table_schema = 'public' and table_name = 'orgs' and column_name = 'company_size') then
    alter table public.orgs add column company_size text;
  end if;
  
  if not exists (select 1 from information_schema.columns where table_schema = 'public' and table_name = 'orgs' and column_name = 'created_by') then
    alter table public.orgs add column created_by uuid references auth.users(id) on delete set null;
  end if;
end;
$$;

-- Add columns to locations table
do $$
begin
  if not exists (select 1 from information_schema.columns where table_schema = 'public' and table_name = 'locations' and column_name = 'address_line1') then
    alter table public.locations add column address_line1 text;
  end if;
  
  if not exists (select 1 from information_schema.columns where table_schema = 'public' and table_name = 'locations' and column_name = 'address_line2') then
    alter table public.locations add column address_line2 text;
  end if;
  
  if not exists (select 1 from information_schema.columns where table_schema = 'public' and table_name = 'locations' and column_name = 'city') then
    alter table public.locations add column city text;
  end if;
  
  if not exists (select 1 from information_schema.columns where table_schema = 'public' and table_name = 'locations' and column_name = 'province_state') then
    alter table public.locations add column province_state text;
  end if;
  
  if not exists (select 1 from information_schema.columns where table_schema = 'public' and table_name = 'locations' and column_name = 'postal_zip_code') then
    alter table public.locations add column postal_zip_code text;
  end if;
  
  if not exists (select 1 from information_schema.columns where table_schema = 'public' and table_name = 'locations' and column_name = 'country') then
    alter table public.locations add column country text;
  end if;
  
  if not exists (select 1 from information_schema.columns where table_schema = 'public' and table_name = 'locations' and column_name = 'featured_image_url') then
    alter table public.locations add column featured_image_url text;
  end if;
  
  if not exists (select 1 from information_schema.columns where table_schema = 'public' and table_name = 'locations' and column_name = 'og_hq') then
    alter table public.locations add column og_hq boolean not null default false;
  end if;
  
  if not exists (select 1 from information_schema.columns where table_schema = 'public' and table_name = 'locations' and column_name = 'created_by') then
    alter table public.locations add column created_by uuid references auth.users(id) on delete set null;
  end if;
end;
$$;

-- Add columns to ownership_groups table
do $$
begin
  if not exists (select 1 from information_schema.columns where table_schema = 'public' and table_name = 'ownership_groups' and column_name = 'og_name') then
    alter table public.ownership_groups add column og_name text;
  end if;
  
  if not exists (select 1 from information_schema.columns where table_schema = 'public' and table_name = 'ownership_groups' and column_name = 'corporate_og') then
    alter table public.ownership_groups add column corporate_og boolean not null default false;
  end if;
  
  if not exists (select 1 from information_schema.columns where table_schema = 'public' and table_name = 'ownership_groups' and column_name = 'key_contact_id') then
    alter table public.ownership_groups add column key_contact_id uuid references auth.users(id) on delete set null;
  end if;
  
  if not exists (select 1 from information_schema.columns where table_schema = 'public' and table_name = 'ownership_groups' and column_name = 'created_by') then
    alter table public.ownership_groups add column created_by uuid references auth.users(id) on delete set null;
  end if;
end;
$$;

-- Add columns to profiles table
do $$
begin
  if not exists (select 1 from information_schema.columns where table_schema = 'public' and table_name = 'profiles' and column_name = 'is_onboarding_complete') then
    alter table public.profiles add column is_onboarding_complete boolean not null default false;
  end if;
end;
$$;

-- Add columns to staff_members table
do $$
begin
  if not exists (select 1 from information_schema.columns where table_schema = 'public' and table_name = 'staff_members' and column_name = 'is_active') then
    alter table public.staff_members add column is_active boolean not null default true;
  end if;
  
  if not exists (select 1 from information_schema.columns where table_schema = 'public' and table_name = 'staff_members' and column_name = 'created_by') then
    alter table public.staff_members add column created_by uuid references auth.users(id) on delete set null;
  end if;
end;
$$;

-- Add columns to staff_locations table
do $$
begin
  if not exists (select 1 from information_schema.columns where table_schema = 'public' and table_name = 'staff_locations' and column_name = 'is_active') then
    alter table public.staff_locations add column is_active boolean not null default true;
  end if;
  
  if not exists (select 1 from information_schema.columns where table_schema = 'public' and table_name = 'staff_locations' and column_name = 'created_by') then
    alter table public.staff_locations add column created_by uuid references auth.users(id) on delete set null;
  end if;
end;
$$;

-- Create unique index on orgs subdomain if it doesn't exist
create unique index if not exists uidx_orgs_subdomain on public.orgs(subdomain) where subdomain is not null;
