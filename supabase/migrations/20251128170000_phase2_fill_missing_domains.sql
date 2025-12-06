-- Phase 2: Add missing domain tables and baseline RLS (org-scoped) per migration checklist.

-- Role/permission tables
-- permissions/roles already exist in base schema; ensure org_scoped roles and staff_permissions table

do $$
begin
  if not exists (select 1 from information_schema.tables where table_schema='public' and table_name='staff_permissions') then
    create table public.staff_permissions (
      id uuid primary key default gen_random_uuid(),
      staff_id uuid not null references public.staff_members(id) on delete cascade,
      org_id uuid not null references public.orgs(id) on delete cascade,
      role_id uuid references public.roles(id) on delete set null,
      location_id uuid references public.locations(id) on delete set null,
      ownership_group_id uuid references public.ownership_groups(id) on delete set null,
      created_at timestamptz not null default now(),
      updated_at timestamptz not null default now(),
      unique (staff_id, org_id, location_id, ownership_group_id, role_id)
    );
  end if;
end;
$$;

-- Org join/invite tables
create table if not exists public.org_staff_invites (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null references public.orgs(id) on delete cascade,
  email text not null,
  role text default 'staff',
  token text not null,
  expires_at timestamptz,
  created_at timestamptz not null default now(),
  created_by uuid references auth.users(id) on delete set null
);

create table if not exists public.org_join_requests (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null references public.orgs(id) on delete cascade,
  location_id uuid references public.locations(id) on delete set null,
  user_id uuid not null references auth.users(id) on delete cascade,
  status text not null default 'pending',
  message text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Patient relationships/notes/consents
create table if not exists public.patient_relationships (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null references public.orgs(id) on delete cascade,
  patient_id uuid not null references public.patients(id) on delete cascade,
  related_patient_id uuid references public.patients(id) on delete cascade,
  relationship_type text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.patient_notes (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null references public.orgs(id) on delete cascade,
  patient_id uuid not null references public.patients(id) on delete cascade,
  staff_id uuid references public.staff_members(id) on delete set null,
  note text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.patient_consents (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null references public.orgs(id) on delete cascade,
  patient_id uuid not null references public.patients(id) on delete cascade,
  consent_type text not null,
  consent_text text,
  signed_at timestamptz,
  signed_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now()
);

-- Scheduling: availability blocks, shifts, breaks, time off, tasks
create table if not exists public.availability_blocks (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null references public.orgs(id) on delete cascade,
  staff_id uuid not null references public.staff_members(id) on delete cascade,
  location_id uuid references public.locations(id) on delete set null,
  start_time timestamptz not null,
  end_time timestamptz not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.staff_shifts (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null references public.orgs(id) on delete cascade,
  staff_id uuid not null references public.staff_members(id) on delete cascade,
  location_id uuid references public.locations(id) on delete set null,
  start_time timestamptz not null,
  end_time timestamptz not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.staff_breaks (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null references public.orgs(id) on delete cascade,
  staff_id uuid not null references public.staff_members(id) on delete cascade,
  location_id uuid references public.locations(id) on delete set null,
  start_time timestamptz not null,
  end_time timestamptz not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.staff_time_off (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null references public.orgs(id) on delete cascade,
  staff_id uuid not null references public.staff_members(id) on delete cascade,
  start_time timestamptz not null,
  end_time timestamptz not null,
  reason text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.staff_tasks (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null references public.orgs(id) on delete cascade,
  staff_id uuid references public.staff_members(id) on delete set null,
  assigned_to_staff_id uuid references public.staff_members(id) on delete set null,
  title text not null,
  description text,
  status text default 'open',
  due_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Services/products refinements
create table if not exists public.disciplines (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null references public.orgs(id) on delete cascade,
  name text not null,
  description text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.services (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null references public.orgs(id) on delete cascade,
  discipline_id uuid references public.disciplines(id) on delete set null,
  name text not null,
  description text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Billing: credit memos, discounts, taxes, fees, transactions
create table if not exists public.credit_memos (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null references public.orgs(id) on delete cascade,
  patient_id uuid references public.patients(id) on delete set null,
  amount_cents integer not null default 0,
  reason text,
  created_at timestamptz not null default now()
);

create table if not exists public.discounts (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null references public.orgs(id) on delete cascade,
  code text,
  description text,
  percent_off numeric,
  amount_off_cents integer,
  created_at timestamptz not null default now()
);

create table if not exists public.fees (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null references public.orgs(id) on delete cascade,
  name text not null,
  amount_cents integer default 0,
  fee_type text,
  created_at timestamptz not null default now()
);

create table if not exists public.transactions (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null references public.orgs(id) on delete cascade,
  invoice_id uuid references public.invoices(id) on delete set null,
  payment_id uuid references public.payments(id) on delete set null,
  amount_cents integer not null default 0,
  type text,
  created_at timestamptz not null default now()
);

-- Insurance claims scaffolding
create table if not exists public.insurance_claims (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null references public.orgs(id) on delete cascade,
  appointment_id uuid references public.appointments(id) on delete set null,
  patient_insurance_id uuid,
  total_billed_cents integer,
  status text default 'submitted',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Notifications scaffolding
create table if not exists public.staff_notifications (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null references public.orgs(id) on delete cascade,
  staff_id uuid references public.staff_members(id) on delete set null,
  type text,
  payload jsonb not null default '{}'::jsonb,
  is_read boolean default false,
  created_at timestamptz not null default now()
);

create table if not exists public.patient_notifications (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null references public.orgs(id) on delete cascade,
  patient_id uuid references public.patients(id) on delete set null,
  type text,
  payload jsonb not null default '{}'::jsonb,
  is_read boolean default false,
  created_at timestamptz not null default now()
);

-- RLS: enable on new tables (org-scoped)
do $$
declare
  tbl text;
  has_org boolean;
begin
  for tbl in
    select unnest(ARRAY[
      'staff_permissions',
      'org_staff_invites','org_join_requests',
      'patient_relationships','patient_notes','patient_consents',
      'availability_blocks','staff_shifts','staff_breaks','staff_time_off','staff_tasks',
      'disciplines','services',
      'credit_memos','discounts','taxes','fees','transactions',
      'insurance_claims',
      'staff_notifications','patient_notifications'
    ])
  loop
    execute format('alter table public.%I enable row level security', tbl);
    select exists (
      select 1
      from information_schema.columns
      where table_schema = 'public' and table_name = tbl and column_name = 'org_id'
    ) into has_org;

    if not exists (select 1 from pg_policies where schemaname='public' and tablename=tbl and policyname=tbl||'_all') then
      if has_org then
        execute format('create policy %I on public.%I for all using (public.user_can_access_org(org_id)) with check (public.user_can_access_org(org_id))', tbl||'_all', tbl);
      else
        execute format('create policy %I on public.%I for all using (true) with check (true)', tbl||'_all', tbl);
      end if;
    end if;
  end loop;
end;
$$;
