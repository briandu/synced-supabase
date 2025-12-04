-- Supabase full schema + RLS for Synced Admin Portal (Parse/Firebase -> Supabase)
-- Safe to run in Supabase SQL Editor (idempotent creates where possible).

-- Extensions
create extension if not exists "pgcrypto";
create extension if not exists "uuid-ossp";
create extension if not exists "pg_graphql";

-- Enums
do $$ begin
  if not exists (select 1 from pg_type where typname = 'user_role') then
    create type public.user_role as enum ('superadmin', 'org_admin', 'staff', 'patient');
  end if;
end $$;

do $$ begin
  if not exists (select 1 from pg_type where typname = 'appointment_status') then
    create type public.appointment_status as enum ('scheduled', 'completed', 'cancelled', 'no_show', 'draft');
  end if;
end $$;

do $$ begin
  if not exists (select 1 from pg_type where typname = 'invoice_status') then
    create type public.invoice_status as enum ('draft', 'open', 'paid', 'void', 'uncollectible');
  end if;
end $$;

do $$ begin
  if not exists (select 1 from pg_type where typname = 'payment_status') then
    create type public.payment_status as enum ('succeeded', 'pending', 'failed', 'requires_action', 'refunded', 'void');
  end if;
end $$;

do $$ begin
  if not exists (select 1 from pg_type where typname = 'task_status') then
    create type public.task_status as enum ('open', 'in_progress', 'done', 'cancelled');
  end if;
end $$;

-- Helper functions
create or replace function public.user_can_access_org(target_org uuid)
returns boolean
language plpgsql
stable
as $$
begin
  return exists (
    select 1 from public.org_memberships m
    where m.org_id = target_org and m.user_id = auth.uid()
  )
  or exists (
    select 1 from public.org_memberships m
    where m.user_id = auth.uid() and m.role = 'superadmin'
  );
end;
$$;

-- Core / Org
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
  stripe_account_status text,
  stripe_onboarding_completed boolean not null default false,
  stripe_account_type text,
  stripe_account_country text,
  stripe_account_email text,
  stripe_onboarding_started_at timestamptz,
  stripe_onboarding_completed_at timestamptz,
  stripe_account_created_at timestamptz,
  stripe_charges_enabled boolean,
  stripe_payouts_enabled boolean,
  stripe_account_metadata jsonb,
  is_active boolean not null default true,
  parse_object_id text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Users / Roles / Permissions
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

-- Staff (moved early to satisfy FKs)
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
  discipline_ids uuid[] default '{}',
  is_active boolean not null default true,
  preferred_name text,
  work_email text,
  title text,
  parse_object_id text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.org_staff_invites (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null references public.orgs(id) on delete cascade,
  email text not null,
  role public.user_role not null default 'staff',
  invited_by_staff_id uuid references public.staff_members(id),
  token text not null,
  expires_at timestamptz,
  accepted_at timestamptz,
  parse_object_id text,
  created_at timestamptz not null default now()
);

create table if not exists public.org_join_requests (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null references public.orgs(id) on delete cascade,
  email text not null,
  message text,
  status text not null default 'pending',
  reviewed_by_staff_id uuid references public.staff_members(id),
  parse_object_id text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.permissions (
  id uuid primary key default gen_random_uuid(),
  name text not null unique,
  description text
);

create table if not exists public.role_permissions (
  id uuid primary key default gen_random_uuid(),
  role public.user_role not null,
  permission_id uuid not null references public.permissions(id) on delete cascade,
  unique (role, permission_id)
);

create table if not exists public.disciplines (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null references public.orgs(id) on delete cascade,
  name text not null,
  parse_object_id text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (org_id, name)
);

-- Location access helper (defined after org_memberships exists)
create or replace function public.user_can_access_location(target_location uuid)
returns boolean
language sql
stable
as $$
  select exists (
    select 1
    from public.locations l
    join public.org_memberships m on m.org_id = l.org_id
    where l.id = target_location and m.user_id = auth.uid()
  ) or exists (
    select 1 from public.org_memberships m where m.user_id = auth.uid() and m.role = 'superadmin'
  );
$$;

-- Staff permissions (depends on staff_members and permissions)
create table if not exists public.staff_permissions (
  id uuid primary key default gen_random_uuid(),
  staff_id uuid not null references public.staff_members(id) on delete cascade,
  permission_id uuid not null references public.permissions(id) on delete cascade,
  unique (staff_id, permission_id)
);

create table if not exists public.staff_locations (
  id uuid primary key default gen_random_uuid(),
  staff_id uuid not null references public.staff_members(id) on delete cascade,
  location_id uuid not null references public.locations(id) on delete cascade,
  is_active boolean not null default true,
  unique (staff_id, location_id)
);

create table if not exists public.staff_availability (
  id uuid primary key default gen_random_uuid(),
  staff_id uuid not null references public.staff_members(id) on delete cascade,
  location_id uuid references public.locations(id) on delete cascade,
  weekday int not null check (weekday between 0 and 6),
  starts_at time not null,
  ends_at time not null,
  parse_object_id text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.staff_shifts (
  id uuid primary key default gen_random_uuid(),
  staff_id uuid not null references public.staff_members(id) on delete cascade,
  location_id uuid references public.locations(id) on delete set null,
  starts_at timestamptz not null,
  ends_at timestamptz not null,
  parse_object_id text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.staff_breaks (
  id uuid primary key default gen_random_uuid(),
  staff_id uuid not null references public.staff_members(id) on delete cascade,
  shift_id uuid references public.staff_shifts(id) on delete cascade,
  starts_at timestamptz not null,
  ends_at timestamptz not null,
  parse_object_id text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.staff_time_off (
  id uuid primary key default gen_random_uuid(),
  staff_id uuid not null references public.staff_members(id) on delete cascade,
  starts_at timestamptz not null,
  ends_at timestamptz not null,
  reason text,
  parse_object_id text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Patients
create table if not exists public.patients (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null references public.orgs(id) on delete cascade,
  patient_user_id uuid references auth.users(id) on delete set null,
  first_name text not null,
  last_name text not null,
  email text,
  phone text,
  date_of_birth date,
  stripe_customer_id text,
  parse_object_id text,
  created_by uuid references public.staff_members(id),
  updated_by uuid references public.staff_members(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.patient_relationships (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null references public.orgs(id) on delete cascade,
  patient_id uuid not null references public.patients(id) on delete cascade,
  related_patient_id uuid references public.patients(id) on delete cascade,
  relationship text,
  parse_object_id text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.patient_notes (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null references public.orgs(id) on delete cascade,
  patient_id uuid not null references public.patients(id) on delete cascade,
  author_staff_id uuid references public.staff_members(id),
  content text not null,
  parse_object_id text,
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

-- Scheduling
create table if not exists public.appointments (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null references public.orgs(id) on delete cascade,
  location_id uuid references public.locations(id) on delete set null,
  patient_id uuid references public.patients(id) on delete set null,
  staff_id uuid references public.staff_members(id) on delete set null,
  starts_at timestamptz not null,
  ends_at timestamptz not null,
  status public.appointment_status not null default 'scheduled',
  notes text,
  parse_object_id text,
  created_by uuid references public.staff_members(id),
  updated_by uuid references public.staff_members(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.availability_blocks (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null references public.orgs(id) on delete cascade,
  location_id uuid references public.locations(id) on delete cascade,
  staff_id uuid references public.staff_members(id) on delete cascade,
  starts_at timestamptz not null,
  ends_at timestamptz not null,
  status text not null default 'active',
  outcome text,
  cancel_reason text,
  outcome_at timestamptz,
  outcome_by uuid references public.staff_members(id) on delete set null,
  notes text,
  created_by uuid references public.staff_members(id),
  updated_by uuid references public.staff_members(id),
  reason text,
  parse_object_id text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.waitlist (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null references public.orgs(id) on delete cascade,
  patient_id uuid references public.patients(id) on delete set null,
  location_id uuid references public.locations(id) on delete set null,
  requested_date date,
  status text default 'open',
  parse_object_id text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.rooms (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null references public.orgs(id) on delete cascade,
  location_id uuid references public.locations(id) on delete cascade,
  name text not null,
  parse_object_id text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.resources (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null references public.orgs(id) on delete cascade,
  location_id uuid references public.locations(id) on delete cascade,
  name text not null,
  parse_object_id text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.staff_tasks (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null references public.orgs(id) on delete cascade,
  title text not null,
  description text,
  status public.task_status not null default 'open',
  assignee_staff_id uuid references public.staff_members(id),
  location_id uuid references public.locations(id) on delete set null,
  due_at timestamptz,
  parse_object_id text,
  created_by uuid references public.staff_members(id),
  updated_by uuid references public.staff_members(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Services / Products / Pricing (services first for downstream FKs)
create table if not exists public.services (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null references public.orgs(id) on delete cascade,
  discipline_id uuid references public.disciplines(id) on delete set null,
  name text not null,
  description text,
  duration_minutes int,
  parse_object_id text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.appointment_services (
  id uuid primary key default gen_random_uuid(),
  appointment_id uuid not null references public.appointments(id) on delete cascade,
  service_id uuid references public.services(id) on delete set null,
  quantity numeric not null default 1,
  notes text
);

create table if not exists public.service_prices (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null references public.orgs(id) on delete cascade,
  service_id uuid not null references public.services(id) on delete cascade,
  location_id uuid references public.locations(id) on delete set null,
  price_cents int not null,
  currency text not null default 'usd',
  stripe_price_id text,
  stripe_product_id text,
  parse_object_id text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Income categories before products/services pricing relations
create table if not exists public.income_categories (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null references public.orgs(id) on delete cascade,
  name text not null,
  parse_object_id text,
  created_by uuid references public.staff_members(id),
  updated_by uuid references public.staff_members(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (org_id, name)
);

create table if not exists public.products (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null references public.orgs(id) on delete cascade,
  name text not null,
  description text,
  income_category_id uuid references public.income_categories(id) on delete set null,
  stripe_product_id text,
  parse_object_id text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Suppliers before inventory
create table if not exists public.suppliers (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null references public.orgs(id) on delete cascade,
  name text not null,
  contact_email text,
  contact_phone text,
  parse_object_id text,
  created_by uuid references public.staff_members(id),
  updated_by uuid references public.staff_members(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.product_inventory (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null references public.orgs(id) on delete cascade,
  product_id uuid not null references public.products(id) on delete cascade,
  supplier_id uuid references public.suppliers(id) on delete set null,
  quantity int not null default 0,
  reorder_level int default 0,
  parse_object_id text,
  created_by uuid references public.staff_members(id),
  updated_by uuid references public.staff_members(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Billing / Payments / Stripe
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
  stripe_customer_id text,
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
  stripe_customer_id text,
  brand text,
  last4 text,
  exp_month int,
  exp_year int,
  is_default boolean not null default false,
  is_active boolean not null default true,
  card_funding text,
  card_fingerprint text,
  card_country text,
  billing_postal_code text,
  billing_country text,
  billing_name text,
  billing_email text,
  billing_phone text,
  nickname text,
  color text,
  color_name text,
  metadata jsonb,
  usage_count int not null default 0,
  integration_provider text,
  deactivated_at timestamptz,
  deactivated_reason text,
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
  status public.payment_status default 'succeeded',
  parse_object_id text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.credit_memos (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null references public.orgs(id) on delete cascade,
  invoice_id uuid references public.invoices(id) on delete set null,
  amount_cents integer not null,
  reason text,
  parse_object_id text,
  created_by uuid references public.staff_members(id),
  created_at timestamptz not null default now()
);

create table if not exists public.discounts (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null references public.orgs(id) on delete cascade,
  name text not null,
  amount_cents integer,
  percent numeric,
  parse_object_id text,
  created_by uuid references public.staff_members(id),
  created_at timestamptz not null default now()
);

create table if not exists public.taxes (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null references public.orgs(id) on delete cascade,
  name text not null,
  rate numeric not null,
  parse_object_id text,
  created_by uuid references public.staff_members(id),
  created_at timestamptz not null default now()
);

create table if not exists public.fees (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null references public.orgs(id) on delete cascade,
  name text not null,
  amount_cents integer not null,
  parse_object_id text,
  created_by uuid references public.staff_members(id),
  updated_by uuid references public.staff_members(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.transactions (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null references public.orgs(id) on delete cascade,
  invoice_id uuid references public.invoices(id) on delete set null,
  payment_id uuid references public.payments(id) on delete set null,
  amount_cents integer not null,
  type text not null,
  parse_object_id text,
  created_at timestamptz not null default now()
);

create table if not exists public.gift_cards (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null references public.orgs(id) on delete cascade,
  patient_id uuid references public.patients(id) on delete set null,
  location_id uuid references public.locations(id) on delete set null,
  code text not null,
  balance_cents integer not null default 0,
  currency text not null default 'usd',
  status text not null default 'active',
  initial_amount_cents integer not null default 0,
  loaded_by uuid references public.staff_members(id) on delete set null,
  loaded_by_name text,
  notes text,
  transactions jsonb not null default '[]'::jsonb,
  last_used_at timestamptz,
  issued_at timestamptz,
  deactivated_at timestamptz,
  deactivation_reason text,
  parse_object_id text,
  created_by uuid references public.staff_members(id),
  updated_by uuid references public.staff_members(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (org_id, code)
);

-- Insurance
create table if not exists public.insurance_policies (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null references public.orgs(id) on delete cascade,
  patient_id uuid not null references public.patients(id) on delete cascade,
  provider_name text not null,
  policy_number text not null,
  group_number text,
  parse_object_id text,
  created_by uuid references public.staff_members(id),
  updated_by uuid references public.staff_members(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.insurance_claims (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null references public.orgs(id) on delete cascade,
  patient_id uuid references public.patients(id) on delete set null,
  policy_id uuid references public.insurance_policies(id) on delete set null,
  invoice_id uuid references public.invoices(id) on delete set null,
  status text default 'open',
  amount_cents integer,
  parse_object_id text,
  created_by uuid references public.staff_members(id),
  updated_by uuid references public.staff_members(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Forms / Charting
create table if not exists public.form_templates (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null references public.orgs(id) on delete cascade,
  name text not null,
  schema jsonb not null,
  parse_object_id text,
  created_by uuid references public.staff_members(id),
  updated_by uuid references public.staff_members(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.form_responses (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null references public.orgs(id) on delete cascade,
  form_template_id uuid references public.form_templates(id) on delete cascade,
  patient_id uuid references public.patients(id) on delete set null,
  staff_id uuid references public.staff_members(id) on delete set null,
  responses jsonb not null,
  parse_object_id text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.charting_assets (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null references public.orgs(id) on delete cascade,
  patient_id uuid references public.patients(id) on delete set null,
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

-- Notifications / Presence
create table if not exists public.staff_notifications (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null references public.orgs(id) on delete cascade,
  staff_id uuid references public.staff_members(id) on delete set null,
  type text not null,
  payload jsonb,
  read_at timestamptz,
  parse_object_id text,
  created_at timestamptz not null default now()
);

create table if not exists public.patient_notifications (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null references public.orgs(id) on delete cascade,
  patient_id uuid references public.patients(id) on delete set null,
  type text not null,
  payload jsonb,
  read_at timestamptz,
  parse_object_id text,
  created_at timestamptz not null default now()
);

create table if not exists public.onesignal_devices (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id) on delete cascade,
  player_id text not null,
  platform text,
  created_at timestamptz not null default now(),
  unique (user_id, player_id)
);

create table if not exists public.presence (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id) on delete cascade,
  org_id uuid references public.orgs(id) on delete cascade,
  status text not null default 'online',
  last_seen timestamptz not null default now()
);

-- Audit
create table if not exists public.audit_logs (
  id uuid primary key default gen_random_uuid(),
  org_id uuid references public.orgs(id) on delete cascade,
  actor_user_id uuid references auth.users(id),
  action text not null,
  entity text,
  entity_id uuid,
  meta jsonb,
  created_at timestamptz not null default now()
);

-- Indexes
create index if not exists idx_locations_org on public.locations(org_id);
create index if not exists idx_staff_org on public.staff_members(org_id);
create index if not exists idx_patients_org on public.patients(org_id);
create index if not exists idx_appointments_org on public.appointments(org_id, starts_at);
create index if not exists idx_invoices_org on public.invoices(org_id, status);
create index if not exists idx_payments_org on public.payments(org_id, created_at);
create index if not exists idx_tasks_org on public.staff_tasks(org_id, status);
create index if not exists idx_notifications_staff on public.staff_notifications(staff_id, created_at);
create index if not exists idx_notifications_patient on public.patient_notifications(patient_id, created_at);
create unique index if not exists uidx_service_prices_service_location
  on public.service_prices (service_id, coalesce(location_id, '00000000-0000-0000-0000-000000000000'::uuid));
create unique index if not exists uidx_payment_methods_stripe_id on public.payment_methods(stripe_payment_method_id);

-- RLS enable
alter table public.orgs enable row level security;
alter table public.ownership_groups enable row level security;
alter table public.locations enable row level security;
alter table public.org_staff_invites enable row level security;
alter table public.org_join_requests enable row level security;
alter table public.profiles enable row level security;
alter table public.org_memberships enable row level security;
alter table public.permissions enable row level security;
alter table public.role_permissions enable row level security;
alter table public.staff_permissions enable row level security;
alter table public.disciplines enable row level security;
alter table public.staff_members enable row level security;
alter table public.staff_locations enable row level security;
alter table public.staff_availability enable row level security;
alter table public.staff_shifts enable row level security;
alter table public.staff_breaks enable row level security;
alter table public.staff_time_off enable row level security;
alter table public.patients enable row level security;
alter table public.patient_relationships enable row level security;
alter table public.patient_notes enable row level security;
alter table public.patient_files enable row level security;
alter table public.appointments enable row level security;
alter table public.availability_blocks enable row level security;
alter table public.waitlist enable row level security;
alter table public.rooms enable row level security;
alter table public.resources enable row level security;
alter table public.staff_tasks enable row level security;
alter table public.appointment_services enable row level security;
alter table public.services enable row level security;
alter table public.service_prices enable row level security;
alter table public.products enable row level security;
alter table public.product_inventory enable row level security;
alter table public.suppliers enable row level security;
alter table public.income_categories enable row level security;
alter table public.invoices enable row level security;
alter table public.invoice_items enable row level security;
alter table public.payment_methods enable row level security;
alter table public.payments enable row level security;
alter table public.credit_memos enable row level security;
alter table public.discounts enable row level security;
alter table public.taxes enable row level security;
alter table public.fees enable row level security;
alter table public.transactions enable row level security;
alter table public.gift_cards enable row level security;
alter table public.insurance_policies enable row level security;
alter table public.insurance_claims enable row level security;
alter table public.form_templates enable row level security;
alter table public.form_responses enable row level security;
alter table public.charting_assets enable row level security;
alter table public.staff_notifications enable row level security;
alter table public.patient_notifications enable row level security;
alter table public.onesignal_devices enable row level security;
alter table public.presence enable row level security;
alter table public.audit_logs enable row level security;

-- Policies (org-scoped; service_role bypass via supabase default)
-- Drop existing policies to keep this script idempotent on reruns
drop policy if exists orgs_select on public.orgs;
drop policy if exists orgs_modify on public.orgs;
drop policy if exists ownership_groups_select on public.ownership_groups;
drop policy if exists ownership_groups_modify on public.ownership_groups;
drop policy if exists locations_select on public.locations;
drop policy if exists locations_modify on public.locations;
drop policy if exists org_staff_invites_all on public.org_staff_invites;
drop policy if exists org_join_requests_all on public.org_join_requests;
drop policy if exists profiles_select on public.profiles;
drop policy if exists profiles_update on public.profiles;
drop policy if exists org_memberships_select on public.org_memberships;
drop policy if exists org_memberships_modify on public.org_memberships;
drop policy if exists permissions_select on public.permissions;
drop policy if exists role_permissions_select on public.role_permissions;
drop policy if exists staff_permissions_all on public.staff_permissions;
drop policy if exists disciplines_all on public.disciplines;
drop policy if exists staff_all on public.staff_members;
drop policy if exists staff_locations_all on public.staff_locations;
drop policy if exists staff_availability_all on public.staff_availability;
drop policy if exists staff_shifts_all on public.staff_shifts;
drop policy if exists staff_breaks_all on public.staff_breaks;
drop policy if exists staff_time_off_all on public.staff_time_off;
drop policy if exists patients_all on public.patients;
drop policy if exists patient_relationships_all on public.patient_relationships;
drop policy if exists patient_notes_all on public.patient_notes;
drop policy if exists patient_files_all on public.patient_files;
drop policy if exists appointments_all on public.appointments;
drop policy if exists availability_blocks_all on public.availability_blocks;
drop policy if exists waitlist_all on public.waitlist;
drop policy if exists rooms_all on public.rooms;
drop policy if exists resources_all on public.resources;
drop policy if exists staff_tasks_all on public.staff_tasks;
drop policy if exists appointment_services_all on public.appointment_services;
drop policy if exists services_all on public.services;
drop policy if exists service_prices_all on public.service_prices;
drop policy if exists products_all on public.products;
drop policy if exists product_inventory_all on public.product_inventory;
drop policy if exists suppliers_all on public.suppliers;
drop policy if exists income_categories_all on public.income_categories;
drop policy if exists invoices_all on public.invoices;
drop policy if exists invoice_items_all on public.invoice_items;
drop policy if exists payment_methods_all on public.payment_methods;
drop policy if exists payments_all on public.payments;
drop policy if exists credit_memos_all on public.credit_memos;
drop policy if exists discounts_all on public.discounts;
drop policy if exists taxes_all on public.taxes;
drop policy if exists fees_all on public.fees;
drop policy if exists transactions_all on public.transactions;
drop policy if exists gift_cards_all on public.gift_cards;
drop policy if exists insurance_policies_all on public.insurance_policies;
drop policy if exists insurance_claims_all on public.insurance_claims;
drop policy if exists form_templates_all on public.form_templates;
drop policy if exists form_responses_all on public.form_responses;
drop policy if exists charting_assets_all on public.charting_assets;
drop policy if exists staff_notifications_all on public.staff_notifications;
drop policy if exists patient_notifications_all on public.patient_notifications;
drop policy if exists onesignal_devices_all on public.onesignal_devices;
drop policy if exists presence_all on public.presence;
drop policy if exists audit_logs_select on public.audit_logs;

create policy orgs_select on public.orgs for select using (public.user_can_access_org(id));
create policy orgs_modify on public.orgs for all using (public.user_can_access_org(id)) with check (public.user_can_access_org(id));

create policy ownership_groups_select on public.ownership_groups for select using (public.user_can_access_org(org_id));
create policy ownership_groups_modify on public.ownership_groups for all using (public.user_can_access_org(org_id)) with check (public.user_can_access_org(org_id));

create policy locations_select on public.locations for select using (public.user_can_access_org(org_id));
create policy locations_modify on public.locations for all using (public.user_can_access_org(org_id)) with check (public.user_can_access_org(org_id));

create policy org_staff_invites_all on public.org_staff_invites for all using (public.user_can_access_org(org_id)) with check (public.user_can_access_org(org_id));
create policy org_join_requests_all on public.org_join_requests for all using (public.user_can_access_org(org_id)) with check (public.user_can_access_org(org_id));

create policy profiles_select on public.profiles for select using (auth.uid() = id or exists (select 1 from public.org_memberships m where m.user_id = auth.uid() and m.org_id = profiles.default_org_id));
create policy profiles_update on public.profiles for update using (auth.uid() = id);

create policy org_memberships_select on public.org_memberships for select using (auth.uid() = user_id or exists (select 1 from public.org_memberships m where m.user_id = auth.uid() and m.role = 'superadmin'));
create policy org_memberships_modify on public.org_memberships for all using (exists (select 1 from public.org_memberships m where m.user_id = auth.uid() and m.role in ('superadmin','org_admin'))) with check (exists (select 1 from public.org_memberships m where m.user_id = auth.uid() and m.role in ('superadmin','org_admin')));

create policy permissions_select on public.permissions for select using (true);
create policy role_permissions_select on public.role_permissions for select using (true);
create policy staff_permissions_all on public.staff_permissions for all using (public.user_can_access_org((select org_id from public.staff_members sm where sm.id = staff_permissions.staff_id))) with check (public.user_can_access_org((select org_id from public.staff_members sm where sm.id = staff_permissions.staff_id)));

create policy disciplines_all on public.disciplines for all using (public.user_can_access_org(org_id)) with check (public.user_can_access_org(org_id));
create policy staff_all on public.staff_members for all using (public.user_can_access_org(org_id)) with check (public.user_can_access_org(org_id));
create policy staff_locations_all on public.staff_locations for all using (public.user_can_access_org((select org_id from public.staff_members sm where sm.id = staff_locations.staff_id))) with check (public.user_can_access_org((select org_id from public.staff_members sm where sm.id = staff_locations.staff_id)));
create policy staff_availability_all on public.staff_availability for all using (public.user_can_access_org((select org_id from public.staff_members sm where sm.id = staff_availability.staff_id))) with check (public.user_can_access_org((select org_id from public.staff_members sm where sm.id = staff_availability.staff_id)));
create policy staff_shifts_all on public.staff_shifts for all using (public.user_can_access_org((select org_id from public.staff_members sm where sm.id = staff_shifts.staff_id))) with check (public.user_can_access_org((select org_id from public.staff_members sm where sm.id = staff_shifts.staff_id)));
create policy staff_breaks_all on public.staff_breaks for all using (public.user_can_access_org((select org_id from public.staff_members sm where sm.id = staff_breaks.staff_id))) with check (public.user_can_access_org((select org_id from public.staff_members sm where sm.id = staff_breaks.staff_id)));
create policy staff_time_off_all on public.staff_time_off for all using (public.user_can_access_org((select org_id from public.staff_members sm where sm.id = staff_time_off.staff_id))) with check (public.user_can_access_org((select org_id from public.staff_members sm where sm.id = staff_time_off.staff_id)));

create policy patients_all on public.patients for all using (public.user_can_access_org(org_id)) with check (public.user_can_access_org(org_id));
create policy patient_relationships_all on public.patient_relationships for all using (public.user_can_access_org(org_id)) with check (public.user_can_access_org(org_id));
create policy patient_notes_all on public.patient_notes for all using (public.user_can_access_org(org_id)) with check (public.user_can_access_org(org_id));
create policy patient_files_all on public.patient_files for all using (public.user_can_access_org(org_id)) with check (public.user_can_access_org(org_id));

create policy appointments_all on public.appointments for all using (public.user_can_access_org(org_id)) with check (public.user_can_access_org(org_id));
create policy availability_blocks_all on public.availability_blocks for all using (public.user_can_access_org(org_id)) with check (public.user_can_access_org(org_id));
create policy waitlist_all on public.waitlist for all using (public.user_can_access_org(org_id)) with check (public.user_can_access_org(org_id));
create policy rooms_all on public.rooms for all using (public.user_can_access_org(org_id)) with check (public.user_can_access_org(org_id));
create policy resources_all on public.resources for all using (public.user_can_access_org(org_id)) with check (public.user_can_access_org(org_id));
create policy staff_tasks_all on public.staff_tasks for all using (public.user_can_access_org(org_id)) with check (public.user_can_access_org(org_id));
create policy appointment_services_all on public.appointment_services for all using (exists (select 1 from public.appointments a where a.id = appointment_services.appointment_id and public.user_can_access_org(a.org_id))) with check (exists (select 1 from public.appointments a where a.id = appointment_services.appointment_id and public.user_can_access_org(a.org_id)));

create policy services_all on public.services for all using (public.user_can_access_org(org_id)) with check (public.user_can_access_org(org_id));
create policy service_prices_all on public.service_prices for all using (public.user_can_access_org(org_id)) with check (public.user_can_access_org(org_id));
create policy products_all on public.products for all using (public.user_can_access_org(org_id)) with check (public.user_can_access_org(org_id));
create policy product_inventory_all on public.product_inventory for all using (public.user_can_access_org(org_id)) with check (public.user_can_access_org(org_id));
create policy suppliers_all on public.suppliers for all using (public.user_can_access_org(org_id)) with check (public.user_can_access_org(org_id));
create policy income_categories_all on public.income_categories for all using (public.user_can_access_org(org_id)) with check (public.user_can_access_org(org_id));

create policy invoices_all on public.invoices for all using (public.user_can_access_org(org_id)) with check (public.user_can_access_org(org_id));
create policy invoice_items_all on public.invoice_items for all using (public.user_can_access_org(org_id)) with check (public.user_can_access_org(org_id));
create policy payment_methods_all on public.payment_methods for all using (public.user_can_access_org(org_id)) with check (public.user_can_access_org(org_id));
create policy payments_all on public.payments for all using (public.user_can_access_org(org_id)) with check (public.user_can_access_org(org_id));
create policy credit_memos_all on public.credit_memos for all using (public.user_can_access_org(org_id)) with check (public.user_can_access_org(org_id));
create policy discounts_all on public.discounts for all using (public.user_can_access_org(org_id)) with check (public.user_can_access_org(org_id));
create policy taxes_all on public.taxes for all using (public.user_can_access_org(org_id)) with check (public.user_can_access_org(org_id));
create policy fees_all on public.fees for all using (public.user_can_access_org(org_id)) with check (public.user_can_access_org(org_id));
create policy transactions_all on public.transactions for all using (public.user_can_access_org(org_id)) with check (public.user_can_access_org(org_id));
create policy gift_cards_all on public.gift_cards for all using (public.user_can_access_org(org_id)) with check (public.user_can_access_org(org_id));

create policy insurance_policies_all on public.insurance_policies for all using (public.user_can_access_org(org_id)) with check (public.user_can_access_org(org_id));
create policy insurance_claims_all on public.insurance_claims for all using (public.user_can_access_org(org_id)) with check (public.user_can_access_org(org_id));

create policy form_templates_all on public.form_templates for all using (public.user_can_access_org(org_id)) with check (public.user_can_access_org(org_id));
create policy form_responses_all on public.form_responses for all using (public.user_can_access_org(org_id)) with check (public.user_can_access_org(org_id));
create policy charting_assets_all on public.charting_assets for all using (public.user_can_access_org(org_id)) with check (public.user_can_access_org(org_id));

create policy staff_notifications_all on public.staff_notifications for all using (public.user_can_access_org(org_id)) with check (public.user_can_access_org(org_id));
create policy patient_notifications_all on public.patient_notifications for all using (public.user_can_access_org(org_id)) with check (public.user_can_access_org(org_id));
create policy onesignal_devices_all on public.onesignal_devices for all using (auth.uid() = user_id);
create policy presence_all on public.presence for all using (auth.uid() = user_id or public.user_can_access_org(org_id)) with check (auth.uid() = user_id or public.user_can_access_org(org_id));

create policy audit_logs_select on public.audit_logs for select using (public.user_can_access_org(org_id));

-- Realtime publications
do $$
begin
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = 'appointments'
  ) then
    alter publication supabase_realtime add table public.appointments;
  end if;
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = 'staff_tasks'
  ) then
    alter publication supabase_realtime add table public.staff_tasks;
  end if;
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = 'patient_files'
  ) then
    alter publication supabase_realtime add table public.patient_files;
  end if;
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = 'charting_assets'
  ) then
    alter publication supabase_realtime add table public.charting_assets;
  end if;
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = 'invoices'
  ) then
    alter publication supabase_realtime add table public.invoices;
  end if;
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = 'payments'
  ) then
    alter publication supabase_realtime add table public.payments;
  end if;
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = 'presence'
  ) then
    alter publication supabase_realtime add table public.presence;
  end if;
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = 'staff_notifications'
  ) then
    alter publication supabase_realtime add table public.staff_notifications;
  end if;
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = 'patient_notifications'
  ) then
    alter publication supabase_realtime add table public.patient_notifications;
  end if;
end;
$$;
