-- Phase 2: Booking Policies tables
-- Creates tables needed for booking policy management and public booking portals
-- Maps Parse classes: Booking_Policy, Booking_Policy_Preset, Booking_Portal

-- Booking Policy Presets - Booking policy presets
create table if not exists public.booking_policy_presets (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  require_deposit boolean not null default false,
  require_credit_card boolean not null default false,
  deposit_type text,
  parse_object_id text,
  created_by uuid references public.staff_members(id) on delete set null,
  updated_by uuid references public.staff_members(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Booking Policies - Booking policies for locations/patients
create table if not exists public.booking_policies (
  id uuid primary key default gen_random_uuid(),
  org_id uuid references public.orgs(id) on delete cascade,
  location_id uuid references public.locations(id) on delete set null,
  ownership_group_id uuid references public.ownership_groups(id) on delete set null,
  booking_policy_preset_id uuid references public.booking_policy_presets(id) on delete set null,
  first_visit_policy_preset_id uuid references public.booking_policy_presets(id) on delete set null,
  allow_cancellations boolean not null default true,
  allow_same_day_booking boolean not null default false,
  deposit_amount numeric,
  deposit_percentage numeric,
  no_booking_within_id uuid references public.time_intervals(id) on delete set null,
  late_cancellation_period_id uuid references public.time_intervals(id) on delete set null,
  parse_object_id text,
  created_by uuid references public.staff_members(id) on delete set null,
  updated_by uuid references public.staff_members(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Booking Portals - Public booking portal configuration
create table if not exists public.booking_portals (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null references public.orgs(id) on delete cascade,
  slug text,
  title text,
  subtitle text,
  description text,
  is_active boolean not null default true,
  logo_storage_bucket text,
  logo_storage_path text,
  background_image_storage_bucket text,
  background_image_storage_path text,
  primary_color text not null default '#1976d2',
  secondary_color text not null default '#f5f5f5',
  accent_color text not null default '#ff4081',
  font_family text not null default 'Inter',
  theme_settings jsonb not null default '{}'::jsonb,
  ownership_group_id uuid references public.ownership_groups(id) on delete set null,
  contact_email text,
  contact_phone text,
  support_message text,
  show_pricing boolean not null default true,
  show_prices_including_tax boolean not null default true,
  require_payment boolean not null default false,
  require_account_creation boolean not null default false,
  require_phone_verification boolean not null default false,
  payment_provider text,
  deposit_percentage numeric not null default 0,
  cancellation_hours integer not null default 24,
  minimum_notice_hours integer not null default 24,
  advance_booking_days integer not null default 30,
  cancellation_policy text,
  enable_waitlist boolean not null default true,
  enable_group_booking boolean not null default false,
  enable_online_intake boolean not null default false,
  send_booking_notifications boolean not null default true,
  enable_tracking boolean not null default false,
  default_view_type text not null default 'location-first',
  blocked_dates jsonb not null default '[]'::jsonb, -- Array of dates
  custom_business_hours jsonb not null default '{}'::jsonb, -- Object with custom hours
  allowed_disciplines jsonb not null default '[]'::jsonb, -- Array of discipline IDs
  allowed_service_types jsonb not null default '[]'::jsonb, -- Array of service types
  excluded_staff_ids jsonb not null default '[]'::jsonb, -- Array of staff IDs
  featured_staff_ids jsonb not null default '[]'::jsonb, -- Array of staff IDs
  required_intake_forms jsonb not null default '[]'::jsonb, -- Array of intake form IDs
  meta_title text,
  meta_description text,
  meta_keywords jsonb not null default '[]'::jsonb, -- Array of keywords
  google_analytics_id text,
  facebook_pixel_id text,
  custom_css text,
  booking_confirmation_template text,
  booking_reminder_template text,
  parse_object_id text,
  created_by uuid references public.staff_members(id) on delete set null,
  updated_by uuid references public.staff_members(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Indexes for common queries
create index if not exists idx_booking_policy_presets_name on public.booking_policy_presets(name);

create index if not exists idx_booking_policies_org on public.booking_policies(org_id) where org_id is not null;
create index if not exists idx_booking_policies_location on public.booking_policies(location_id) where location_id is not null;
create index if not exists idx_booking_policies_ownership_group on public.booking_policies(ownership_group_id) where ownership_group_id is not null;
create index if not exists idx_booking_policies_preset on public.booking_policies(booking_policy_preset_id) where booking_policy_preset_id is not null;

create index if not exists idx_booking_portals_org on public.booking_portals(org_id);
create index if not exists idx_booking_portals_slug on public.booking_portals(slug) where slug is not null;
create index if not exists idx_booking_portals_active on public.booking_portals(is_active) where is_active = true;
create index if not exists idx_booking_portals_ownership_group on public.booking_portals(ownership_group_id) where ownership_group_id is not null;

-- Enable RLS on all tables
alter table public.booking_policy_presets enable row level security;
alter table public.booking_policies enable row level security;
alter table public.booking_portals enable row level security;

-- RLS Policies: Booking Policy Presets
-- Global/system-level; all authenticated users can read; admins can modify
drop policy if exists booking_policy_presets_select on public.booking_policy_presets;
drop policy if exists booking_policy_presets_modify on public.booking_policy_presets;
create policy booking_policy_presets_select on public.booking_policy_presets
  for select using (true);
create policy booking_policy_presets_modify on public.booking_policy_presets
  for all using (
    exists (
      select 1 from public.org_memberships m
      where m.user_id = auth.uid()
        and m.role in ('superadmin','org_admin')
    )
  )
  with check (
    exists (
      select 1 from public.org_memberships m
      where m.user_id = auth.uid()
        and m.role in ('superadmin','org_admin')
    )
  );

-- RLS Policies: Booking Policies
-- Org-scoped; org members can read; admins can modify
drop policy if exists booking_policies_select on public.booking_policies;
drop policy if exists booking_policies_modify on public.booking_policies;
create policy booking_policies_select on public.booking_policies
  for select using (
    org_id is null or public.user_can_access_org(org_id)
  );
create policy booking_policies_modify on public.booking_policies
  for all using (
    (org_id is null or public.user_can_access_org(org_id))
    and (
      org_id is null
      or exists (
        select 1 from public.org_memberships m
        where m.org_id = booking_policies.org_id
          and m.user_id = auth.uid()
          and m.role in ('superadmin','org_admin')
      )
    )
  )
  with check (
    (org_id is null or public.user_can_access_org(org_id))
    and (
      org_id is null
      or exists (
        select 1 from public.org_memberships m
        where m.org_id = booking_policies.org_id
          and m.user_id = auth.uid()
          and m.role in ('superadmin','org_admin')
      )
    )
  );

-- RLS Policies: Booking Portals
-- Org-scoped; org members can read; admins can modify; public can read active portals
drop policy if exists booking_portals_select on public.booking_portals;
drop policy if exists booking_portals_modify on public.booking_portals;
create policy booking_portals_select on public.booking_portals
  for select using (
    is_active = true -- Public can read active portals
    or public.user_can_access_org(org_id) -- Org members can read all
  );
create policy booking_portals_modify on public.booking_portals
  for all using (
    public.user_can_access_org(org_id)
    and exists (
      select 1 from public.org_memberships m
      where m.org_id = booking_portals.org_id
        and m.user_id = auth.uid()
        and m.role in ('superadmin','org_admin')
    )
  )
  with check (
    public.user_can_access_org(org_id)
    and exists (
      select 1 from public.org_memberships m
      where m.org_id = booking_portals.org_id
        and m.user_id = auth.uid()
        and m.role in ('superadmin','org_admin')
    )
  );

-- Add to realtime publication for live updates (only if not already added)
do $$
begin
  if not exists (select 1 from pg_publication_tables where pubname = 'supabase_realtime' and tablename = 'booking_portals' and schemaname = 'public') then
    alter publication supabase_realtime add table public.booking_portals;
  end if;
end;
$$;

