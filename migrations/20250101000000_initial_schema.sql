-- Base Supabase schema for Synced Admin Portal migration from Parse/Firebase to Supabase
-- This DDL covers core domains (auth, org/location, staff, patients, scheduling, billing/Stripe, files) and RLS scaffolding.

-- Extensions
create extension if not exists "pgcrypto";
create extension if not exists "uuid-ossp";
create extension if not exists "pg_graphql";

-- Enable GraphQL name inflection for camelCase field names
-- This allows frontend code to use camelCase (firstName, orgId) instead of snake_case (first_name, org_id)
-- See: docs/migrations/GRAPHQL_CAMELCASE_MIGRATION.md
-- Note: Setting this multiple times is safe (idempotent)
comment on schema public is e'@graphql({"inflect_names": true})';

-- Enums
do $$
begin
  if not exists (select 1 from pg_type where typname = 'user_role') then
    create type public.user_role as enum ('superadmin', 'org_admin', 'staff', 'patient');
  end if;
end$$;

do $$
begin
  if not exists (select 1 from pg_type where typname = 'appointment_status') then
    create type public.appointment_status as enum ('scheduled', 'completed', 'cancelled', 'no_show', 'draft');
  end if;
end$$;

do $$
begin
  if not exists (select 1 from pg_type where typname = 'invoice_status') then
    create type public.invoice_status as enum ('draft', 'open', 'paid', 'void', 'uncollectible');
  end if;
end$$;

-- Helper functions
create or replace function public.user_can_access_org(target_org uuid)
returns boolean
language plpgsql
stable
as $$
begin
  return exists (
    select 1
    from public.org_memberships m
    where m.org_id = target_org
      and m.user_id = auth.uid()
  )
  or exists (
    select 1
    from public.org_memberships m
    where m.user_id = auth.uid()
      and m.role = 'superadmin'
  );
end;
$$;

-- Check location access by org membership (superadmin/org_admin/staff tied to org that owns the location)
create or replace function public.user_can_access_location(target_location uuid)
returns boolean
language sql
stable
as $$
  select exists (
    select 1
    from public.locations l
    join public.org_memberships m on m.org_id = l.org_id
    where l.id = target_location
      and m.user_id = auth.uid()
      and m.role in ('superadmin','org_admin','staff')
  );
$$;

-- Tables
create table if not exists public.orgs (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  stripe_connected_account_id text,
  parse_object_id text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.ownership_groups (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null references public.orgs(id) on delete cascade,
  name text not null,
  parse_object_id text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.locations (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null references public.orgs(id) on delete cascade,
  ownership_group_id uuid references public.ownership_groups(id) on delete set null,
  name text not null,
  timezone text,
  stripe_connected_account_id text,
  parse_object_id text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text,
  email text,
  phone text,
  role public.user_role not null default 'staff',
  default_org_id uuid references public.orgs(id) on delete set null,
  parse_object_id text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.org_memberships (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  org_id uuid not null references public.orgs(id) on delete cascade,
  role public.user_role not null default 'staff',
  created_at timestamptz not null default now(),
  unique (user_id, org_id)
);

-- Roles catalog (org-scoped)
create table if not exists public.roles (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null references public.orgs(id) on delete cascade,
  name text not null,
  description text,
  parse_object_id text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (org_id, name)
);

-- Staff <-> Location mapping
create table if not exists public.staff_members (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id) on delete set null,
  org_id uuid not null references public.orgs(id) on delete cascade,
  location_id uuid references public.locations(id) on delete set null,
  first_name text,
  last_name text,
  email text,
  phone text,
  role public.user_role not null default 'staff',
  parse_object_id text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Staff <-> Location mapping
create table if not exists public.staff_locations (
  id uuid primary key default gen_random_uuid(),
  staff_id uuid not null references public.staff_members(id) on delete cascade,
  location_id uuid not null references public.locations(id) on delete cascade,
  org_id uuid not null references public.orgs(id) on delete cascade,
  parse_object_id text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (staff_id, location_id)
);

create table if not exists public.patients (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null references public.orgs(id) on delete cascade,
  patient_user_id uuid references auth.users(id) on delete set null,
  first_name text not null,
  last_name text not null,
  email text,
  phone text,
  date_of_birth date,
  parse_object_id text,
  created_by uuid references public.staff_members(id),
  updated_by uuid references public.staff_members(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.appointments (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null references public.orgs(id) on delete cascade,
  location_id uuid references public.locations(id) on delete set null,
  patient_id uuid references public.patients(id) on delete set null,
  staff_id uuid references public.staff_members(id) on delete set null,
  starts_at timestamptz not null,
  ends_at timestamptz not null,
  status public.appointment_status not null default 'scheduled',
  parse_object_id text,
  created_by uuid references public.staff_members(id),
  updated_by uuid references public.staff_members(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.patient_files (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null references public.orgs(id) on delete cascade,
  patient_id uuid references public.patients(id) on delete cascade,
  storage_bucket text not null,
  storage_path text not null,
  mime_type text,
  size_bytes bigint,
  parse_object_id text,
  created_by uuid references public.staff_members(id),
  updated_by uuid references public.staff_members(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.invoices (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null references public.orgs(id) on delete cascade,
  patient_id uuid references public.patients(id) on delete set null,
  location_id uuid references public.locations(id) on delete set null,
  appointment_id uuid references public.appointments(id) on delete set null,
  status public.invoice_status not null default 'draft',
  total_amount_cents integer not null default 0,
  balance_cents integer not null default 0,
  currency text not null default 'usd',
  stripe_invoice_id text,
  parse_object_id text,
  created_by uuid references public.staff_members(id),
  updated_by uuid references public.staff_members(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.invoice_items (
  id uuid primary key default gen_random_uuid(),
  invoice_id uuid not null references public.invoices(id) on delete cascade,
  org_id uuid not null references public.orgs(id) on delete cascade,
  description text not null,
  quantity numeric not null default 1,
  unit_amount_cents integer not null default 0,
  total_amount_cents integer not null default 0,
  stripe_price_id text,
  parse_object_id text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.payment_methods (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null references public.orgs(id) on delete cascade,
  patient_id uuid references public.patients(id) on delete cascade,
  stripe_payment_method_id text not null,
  brand text,
  last4 text,
  exp_month int,
  exp_year int,
  is_default boolean not null default false,
  parse_object_id text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.payments (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null references public.orgs(id) on delete cascade,
  invoice_id uuid references public.invoices(id) on delete set null,
  patient_id uuid references public.patients(id) on delete set null,
  amount_cents integer not null,
  currency text not null default 'usd',
  stripe_payment_intent_id text,
  stripe_charge_id text,
  method_id uuid references public.payment_methods(id) on delete set null,
  status text default 'succeeded',
  parse_object_id text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.gift_cards (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null references public.orgs(id) on delete cascade,
  code text not null,
  balance_cents integer not null default 0,
  currency text not null default 'usd',
  parse_object_id text,
  created_by uuid references public.staff_members(id),
  updated_by uuid references public.staff_members(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (org_id, code)
);

-- Backfill columns for existing tables if migration re-applied (run before indexes/policies)
-- These handle cases where tables were created in earlier versions without these columns
alter table public.patients add column if not exists patient_user_id uuid references auth.users(id) on delete set null;
alter table public.staff_locations add column if not exists org_id uuid references public.orgs(id) on delete cascade;
alter table public.roles add column if not exists org_id uuid references public.orgs(id) on delete cascade;

-- Permissions
create table if not exists public.permissions (
  id uuid primary key default gen_random_uuid(),
  name text not null unique,
  description text,
  created_at timestamptz not null default now()
);

create table if not exists public.role_permissions (
  id uuid primary key default gen_random_uuid(),
  role public.user_role not null,
  permission_id uuid not null references public.permissions(id) on delete cascade,
  created_at timestamptz not null default now(),
  unique (role, permission_id)
);

-- Indexes for common queries (after backfill to ensure columns exist)
create index if not exists idx_locations_org on public.locations(org_id);
create index if not exists idx_staff_org on public.staff_members(org_id);
create index if not exists idx_patients_org on public.patients(org_id);
create index if not exists idx_appointments_org on public.appointments(org_id, starts_at);
create index if not exists idx_invoices_org on public.invoices(org_id, status);
create index if not exists idx_payments_org on public.payments(org_id, created_at);
create index if not exists idx_roles_org on public.roles(org_id);
create index if not exists idx_staff_locations_org on public.staff_locations(org_id);
create index if not exists idx_staff_locations_staff on public.staff_locations(staff_id);
create index if not exists idx_staff_locations_location on public.staff_locations(location_id);

-- Add indexes for backfilled columns
create index if not exists idx_patients_user on public.patients(patient_user_id);

-- RLS policies
alter table public.orgs enable row level security;
alter table public.ownership_groups enable row level security;
alter table public.locations enable row level security;
alter table public.profiles enable row level security;
alter table public.org_memberships enable row level security;
alter table public.staff_members enable row level security;
alter table public.staff_locations enable row level security;
alter table public.patients enable row level security;
alter table public.appointments enable row level security;
alter table public.patient_files enable row level security;
alter table public.invoices enable row level security;
alter table public.invoice_items enable row level security;
alter table public.payment_methods enable row level security;
alter table public.payments enable row level security;
alter table public.gift_cards enable row level security;
alter table public.roles enable row level security;
alter table public.permissions enable row level security;
alter table public.role_permissions enable row level security;

-- Org-level access
-- Use drop policy if exists to make idempotent (PostgreSQL doesn't support create policy if not exists)
drop policy if exists orgs_select on public.orgs;
drop policy if exists orgs_insert on public.orgs;
drop policy if exists orgs_update on public.orgs;
create policy orgs_select on public.orgs for select using (public.user_can_access_org(id));
create policy orgs_insert on public.orgs for insert with check (auth.role() = 'service_role');
create policy orgs_update on public.orgs for update using (public.user_can_access_org(id));

drop policy if exists ownership_groups_select on public.ownership_groups;
drop policy if exists ownership_groups_modify on public.ownership_groups;
create policy ownership_groups_select on public.ownership_groups for select using (public.user_can_access_org(org_id));
create policy ownership_groups_modify on public.ownership_groups for all using (public.user_can_access_org(org_id)) with check (public.user_can_access_org(org_id));

drop policy if exists locations_select on public.locations;
drop policy if exists locations_modify on public.locations;
create policy locations_select on public.locations for select using (public.user_can_access_org(org_id));
create policy locations_modify on public.locations for all using (public.user_can_access_org(org_id)) with check (public.user_can_access_org(org_id));

-- Profile access (self or same org)
drop policy if exists profiles_self_select on public.profiles;
drop policy if exists profiles_self_update on public.profiles;
create policy profiles_self_select on public.profiles for select using (auth.uid() = id or exists (select 1 from public.org_memberships m where m.user_id = auth.uid() and m.org_id = profiles.default_org_id));
create policy profiles_self_update on public.profiles for update using (auth.uid() = id);

drop policy if exists org_memberships_select on public.org_memberships;
drop policy if exists org_memberships_modify on public.org_memberships;
create policy org_memberships_select on public.org_memberships for select using (auth.uid() = user_id or exists (select 1 from public.org_memberships m where m.user_id = auth.uid() and m.role = 'superadmin'));
create policy org_memberships_modify on public.org_memberships for all using (exists (select 1 from public.org_memberships m where m.user_id = auth.uid() and m.role in ('superadmin','org_admin'))) with check (exists (select 1 from public.org_memberships m where m.user_id = auth.uid() and m.role in ('superadmin','org_admin')));

drop policy if exists staff_select on public.staff_members;
drop policy if exists staff_modify on public.staff_members;
create policy staff_select on public.staff_members for select using (public.user_can_access_org(org_id));
create policy staff_modify on public.staff_members for all using (public.user_can_access_org(org_id)) with check (public.user_can_access_org(org_id));

drop policy if exists patients_select on public.patients;
drop policy if exists patients_modify on public.patients;
create policy patients_select on public.patients for select using (public.user_can_access_org(org_id));
create policy patients_modify on public.patients for all using (public.user_can_access_org(org_id)) with check (public.user_can_access_org(org_id));

drop policy if exists appointments_select on public.appointments;
drop policy if exists appointments_modify on public.appointments;
create policy appointments_select on public.appointments for select using (public.user_can_access_org(org_id));
create policy appointments_modify on public.appointments for all using (public.user_can_access_org(org_id)) with check (public.user_can_access_org(org_id));

drop policy if exists patient_files_select on public.patient_files;
drop policy if exists patient_files_modify on public.patient_files;
create policy patient_files_select on public.patient_files for select using (public.user_can_access_org(org_id));
create policy patient_files_modify on public.patient_files for all using (public.user_can_access_org(org_id)) with check (public.user_can_access_org(org_id));

drop policy if exists invoices_select on public.invoices;
drop policy if exists invoices_modify on public.invoices;
create policy invoices_select on public.invoices for select using (public.user_can_access_org(org_id));
create policy invoices_modify on public.invoices for all using (public.user_can_access_org(org_id)) with check (public.user_can_access_org(org_id));

drop policy if exists invoice_items_select on public.invoice_items;
drop policy if exists invoice_items_modify on public.invoice_items;
create policy invoice_items_select on public.invoice_items for select using (public.user_can_access_org(org_id));
create policy invoice_items_modify on public.invoice_items for all using (public.user_can_access_org(org_id)) with check (public.user_can_access_org(org_id));

drop policy if exists payment_methods_select on public.payment_methods;
drop policy if exists payment_methods_modify on public.payment_methods;
create policy payment_methods_select on public.payment_methods for select using (public.user_can_access_org(org_id));
create policy payment_methods_modify on public.payment_methods for all using (public.user_can_access_org(org_id)) with check (public.user_can_access_org(org_id));

drop policy if exists payments_select on public.payments;
drop policy if exists payments_modify on public.payments;
create policy payments_select on public.payments for select using (public.user_can_access_org(org_id));
create policy payments_modify on public.payments for all using (public.user_can_access_org(org_id)) with check (public.user_can_access_org(org_id));

drop policy if exists gift_cards_select on public.gift_cards;
drop policy if exists gift_cards_modify on public.gift_cards;
create policy gift_cards_select on public.gift_cards for select using (public.user_can_access_org(org_id));
create policy gift_cards_modify on public.gift_cards for all using (public.user_can_access_org(org_id)) with check (public.user_can_access_org(org_id));

drop policy if exists staff_locations_all on public.staff_locations;
create policy staff_locations_all on public.staff_locations for all using (public.user_can_access_org(org_id)) with check (public.user_can_access_org(org_id));

drop policy if exists roles_all on public.roles;
create policy roles_all on public.roles for all using (public.user_can_access_org(org_id)) with check (public.user_can_access_org(org_id));

drop policy if exists permissions_select on public.permissions;
drop policy if exists permissions_modify on public.permissions;
create policy permissions_select on public.permissions for select using (true);
create policy permissions_modify on public.permissions for all using (auth.role() = 'service_role') with check (auth.role() = 'service_role');

drop policy if exists role_permissions_select on public.role_permissions;
drop policy if exists role_permissions_modify on public.role_permissions;
create policy role_permissions_select on public.role_permissions for select using (true);
create policy role_permissions_modify on public.role_permissions for all using (auth.role() = 'service_role') with check (auth.role() = 'service_role');

-- Realtime (only add if not already in publication)
do $$
begin
  if not exists (select 1 from pg_publication_tables where pubname = 'supabase_realtime' and tablename = 'appointments' and schemaname = 'public') then
    alter publication supabase_realtime add table public.appointments;
  end if;
  if not exists (select 1 from pg_publication_tables where pubname = 'supabase_realtime' and tablename = 'patient_files' and schemaname = 'public') then
    alter publication supabase_realtime add table public.patient_files;
  end if;
  if not exists (select 1 from pg_publication_tables where pubname = 'supabase_realtime' and tablename = 'invoices' and schemaname = 'public') then
    alter publication supabase_realtime add table public.invoices;
  end if;
  if not exists (select 1 from pg_publication_tables where pubname = 'supabase_realtime' and tablename = 'payments' and schemaname = 'public') then
    alter publication supabase_realtime add table public.payments;
  end if;
end;
$$;
