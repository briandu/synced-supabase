-- Phase 2: Insurance tables
-- Creates tables needed for insurance management, claims, and billing
-- Maps Parse classes: Insurers, Insurance_Plan, User_Insurance, Patient_Insurance, Provider_Insurance,
-- Claim, Claim_Item, Claim_Payment, Eligibility_Check, Pre_Authorization, Insurance_Document
-- Note: insurance_claims table already exists but may need refinement; creating new claims table per Parse schema

-- Insurers - Insurance company master list
create table if not exists public.insurers (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  description text,
  address text,
  contact_email text,
  contact_phone text,
  api_endpoint text,
  api_credentials text,
  direct_billing_enabled boolean not null default false,
  parse_object_id text,
  created_by uuid references public.staff_members(id) on delete set null,
  updated_by uuid references public.staff_members(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Insurance Plans - Insurance plan definitions
create table if not exists public.insurance_plans (
  id uuid primary key default gen_random_uuid(),
  insurer_id uuid not null references public.insurers(id) on delete cascade,
  name text not null,
  plan_type text,
  max_treatments integer not null default 0,
  policy_end_date date,
  coverage_details text,
  eligibility_criteria text,
  direct_billing_config text,
  parse_object_id text,
  created_by uuid references public.staff_members(id) on delete set null,
  updated_by uuid references public.staff_members(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- User Insurance - User insurance policies
create table if not exists public.user_insurance (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  insurance_plan_id uuid not null references public.insurance_plans(id) on delete cascade,
  policy_number text not null,
  subscriber_name text not null,
  effective_date date not null,
  expiration_date date,
  member_id text,
  group_number text,
  relationship_type text not null,
  is_primary_holder boolean not null default false,
  primary_member_dob date,
  primary_card_holder_first_name text,
  primary_card_holder_last_name text,
  insurance_company_name text,
  is_extended_coverage boolean not null default false,
  accident_type text,
  injury_date date,
  referral_date date,
  referral_physician_name text,
  prior_authorization_number text,
  current_number_of_treatments integer not null default 0,
  other_practitioners_seen text,
  adjuster_name text,
  adjuster_email text,
  adjuster_phone text,
  parse_object_id text,
  created_by uuid references public.staff_members(id) on delete set null,
  updated_by uuid references public.staff_members(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Patient Insurance - Patient-insurance associations
create table if not exists public.patient_insurance (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null references public.orgs(id) on delete cascade,
  patient_id uuid not null references public.patients(id) on delete cascade,
  user_insurance_id uuid not null references public.user_insurance(id) on delete cascade,
  parse_object_id text,
  created_by uuid references public.staff_members(id) on delete set null,
  updated_by uuid references public.staff_members(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Provider Insurance - Provider insurance credentials
-- Note: provider_credential_id references Provider_Credential which may not exist yet
create table if not exists public.provider_insurance (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null references public.orgs(id) on delete cascade,
  provider_credential_id uuid, -- Will reference provider_credentials(id) when that table is created
  insurer_id uuid not null references public.insurers(id) on delete cascade,
  location_id uuid not null references public.locations(id) on delete cascade,
  provider_type text not null,
  country text not null,
  jurisdiction text,
  npi text,
  provincial_billing_number text,
  other_identifier text,
  parse_object_id text,
  created_by uuid references public.staff_members(id) on delete set null,
  updated_by uuid references public.staff_members(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Claims - Insurance claims (new table per Parse schema; insurance_claims exists but may be legacy)
create table if not exists public.claims (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null references public.orgs(id) on delete cascade,
  appointment_id uuid not null references public.appointments(id) on delete cascade,
  patient_insurance_id uuid not null references public.patient_insurance(id) on delete cascade,
  total_billed numeric not null,
  submission_date date not null,
  claim_status text not null default 'submitted',
  total_allowed numeric,
  total_paid numeric,
  billing_provider_insurance_id uuid references public.provider_insurance(id) on delete set null,
  rendering_provider_insurance_id uuid references public.provider_insurance(id) on delete set null,
  parse_object_id text,
  created_by uuid references public.staff_members(id) on delete set null,
  updated_by uuid references public.staff_members(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Claim Items - Line items on claims
create table if not exists public.claim_items (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null references public.orgs(id) on delete cascade,
  claim_id uuid not null references public.claims(id) on delete cascade,
  service_code text not null,
  quantity numeric not null,
  unit_price numeric not null,
  total numeric not null,
  procedure_code text,
  diagnosis_code text,
  description text,
  parse_object_id text,
  created_by uuid references public.staff_members(id) on delete set null,
  updated_by uuid references public.staff_members(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Claim Payments - Payments received for claims
create table if not exists public.claim_payments (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null references public.orgs(id) on delete cascade,
  claim_id uuid not null references public.claims(id) on delete cascade,
  payment_amount numeric not null,
  payment_date date not null,
  payment_status text not null default 'pending',
  eob_details text,
  parse_object_id text,
  created_by uuid references public.staff_members(id) on delete set null,
  updated_by uuid references public.staff_members(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Eligibility Checks - Insurance eligibility check records
create table if not exists public.eligibility_checks (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null references public.orgs(id) on delete cascade,
  patient_insurance_id uuid not null references public.patient_insurance(id) on delete cascade,
  check_date date not null,
  response_date date,
  valid_until date,
  result text,
  parse_object_id text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Pre Authorizations - Pre-authorization requests
create table if not exists public.pre_authorizations (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null references public.orgs(id) on delete cascade,
  patient_insurance_id uuid not null references public.patient_insurance(id) on delete cascade,
  service_code text not null,
  request_date date not null,
  response_date date,
  pre_auth_number text,
  status text not null default 'pending',
  response text,
  appointment_id uuid references public.appointments(id) on delete set null,
  parse_object_id text,
  created_by uuid references public.staff_members(id) on delete set null,
  updated_by uuid references public.staff_members(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Insurance Documents - Insurance-related documents
create table if not exists public.insurance_documents (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null references public.orgs(id) on delete cascade,
  user_insurance_id uuid not null references public.user_insurance(id) on delete cascade,
  document_url text not null,
  document_type text not null,
  storage_bucket text,
  storage_path text,
  metadata text,
  parse_object_id text,
  created_by uuid references public.staff_members(id) on delete set null,
  created_at timestamptz not null default now()
);

-- Indexes for common queries
create index if not exists idx_insurers_name on public.insurers(name);
create index if not exists idx_insurers_direct_billing on public.insurers(direct_billing_enabled) where direct_billing_enabled = true;

create index if not exists idx_insurance_plans_insurer on public.insurance_plans(insurer_id);
create index if not exists idx_insurance_plans_name on public.insurance_plans(name);

create index if not exists idx_user_insurance_user on public.user_insurance(user_id);
create index if not exists idx_user_insurance_plan on public.user_insurance(insurance_plan_id);
create index if not exists idx_user_insurance_policy_number on public.user_insurance(policy_number);
create index if not exists idx_user_insurance_effective_date on public.user_insurance(effective_date, expiration_date);

create index if not exists idx_patient_insurance_org on public.patient_insurance(org_id);
create index if not exists idx_patient_insurance_patient on public.patient_insurance(patient_id);
create index if not exists idx_patient_insurance_user_insurance on public.patient_insurance(user_insurance_id);

create index if not exists idx_provider_insurance_org on public.provider_insurance(org_id);
create index if not exists idx_provider_insurance_insurer on public.provider_insurance(insurer_id);
create index if not exists idx_provider_insurance_location on public.provider_insurance(location_id);
create index if not exists idx_provider_insurance_npi on public.provider_insurance(npi) where npi is not null;

create index if not exists idx_claims_org on public.claims(org_id);
create index if not exists idx_claims_appointment on public.claims(appointment_id);
create index if not exists idx_claims_patient_insurance on public.claims(patient_insurance_id);
create index if not exists idx_claims_status on public.claims(claim_status);
create index if not exists idx_claims_submission_date on public.claims(submission_date);

create index if not exists idx_claim_items_org on public.claim_items(org_id);
create index if not exists idx_claim_items_claim on public.claim_items(claim_id);
create index if not exists idx_claim_items_service_code on public.claim_items(service_code);

create index if not exists idx_claim_payments_org on public.claim_payments(org_id);
create index if not exists idx_claim_payments_claim on public.claim_payments(claim_id);
create index if not exists idx_claim_payments_status on public.claim_payments(payment_status);
create index if not exists idx_claim_payments_date on public.claim_payments(payment_date);

create index if not exists idx_eligibility_checks_org on public.eligibility_checks(org_id);
create index if not exists idx_eligibility_checks_patient_insurance on public.eligibility_checks(patient_insurance_id);
create index if not exists idx_eligibility_checks_date on public.eligibility_checks(check_date);
create index if not exists idx_eligibility_checks_valid_until on public.eligibility_checks(valid_until) where valid_until is not null;

create index if not exists idx_pre_authorizations_org on public.pre_authorizations(org_id);
create index if not exists idx_pre_authorizations_patient_insurance on public.pre_authorizations(patient_insurance_id);
create index if not exists idx_pre_authorizations_status on public.pre_authorizations(status);
create index if not exists idx_pre_authorizations_appointment on public.pre_authorizations(appointment_id) where appointment_id is not null;
create index if not exists idx_pre_authorizations_request_date on public.pre_authorizations(request_date);

create index if not exists idx_insurance_documents_org on public.insurance_documents(org_id);
create index if not exists idx_insurance_documents_user_insurance on public.insurance_documents(user_insurance_id);
create index if not exists idx_insurance_documents_type on public.insurance_documents(document_type);

-- Enable RLS on all tables
alter table public.insurers enable row level security;
alter table public.insurance_plans enable row level security;
alter table public.user_insurance enable row level security;
alter table public.patient_insurance enable row level security;
alter table public.provider_insurance enable row level security;
alter table public.claims enable row level security;
alter table public.claim_items enable row level security;
alter table public.claim_payments enable row level security;
alter table public.eligibility_checks enable row level security;
alter table public.pre_authorizations enable row level security;
alter table public.insurance_documents enable row level security;

-- RLS Policies: Insurers
-- Global/system-level; all authenticated users can read; admins can modify
drop policy if exists insurers_select on public.insurers;
drop policy if exists insurers_modify on public.insurers;
create policy insurers_select on public.insurers
  for select using (true);
create policy insurers_modify on public.insurers
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

-- RLS Policies: Insurance Plans
-- Global/system-level; all authenticated users can read; admins can modify
drop policy if exists insurance_plans_select on public.insurance_plans;
drop policy if exists insurance_plans_modify on public.insurance_plans;
create policy insurance_plans_select on public.insurance_plans
  for select using (true);
create policy insurance_plans_modify on public.insurance_plans
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

-- RLS Policies: User Insurance
-- Users can read their own; admins can read all; users can modify their own; admins can modify all
drop policy if exists user_insurance_select on public.user_insurance;
drop policy if exists user_insurance_modify on public.user_insurance;
create policy user_insurance_select on public.user_insurance
  for select using (
    auth.uid() = user_id
    or exists (
      select 1 from public.org_memberships m
      where m.user_id = auth.uid()
        and m.role in ('superadmin','org_admin','staff')
    )
  );
create policy user_insurance_modify on public.user_insurance
  for all using (
    auth.uid() = user_id
    or exists (
      select 1 from public.org_memberships m
      where m.user_id = auth.uid()
        and m.role in ('superadmin','org_admin')
    )
  )
  with check (
    auth.uid() = user_id
    or exists (
      select 1 from public.org_memberships m
      where m.user_id = auth.uid()
        and m.role in ('superadmin','org_admin')
    )
  );

-- RLS Policies: Patient Insurance
-- Org-scoped; org members can read; admins/staff can modify
drop policy if exists patient_insurance_select on public.patient_insurance;
drop policy if exists patient_insurance_modify on public.patient_insurance;
create policy patient_insurance_select on public.patient_insurance
  for select using (public.user_can_access_org(org_id));
create policy patient_insurance_modify on public.patient_insurance
  for all using (
    public.user_can_access_org(org_id)
    and exists (
      select 1 from public.org_memberships m
      where m.org_id = patient_insurance.org_id
        and m.user_id = auth.uid()
        and m.role in ('superadmin','org_admin','staff')
    )
  )
  with check (
    public.user_can_access_org(org_id)
    and exists (
      select 1 from public.org_memberships m
      where m.org_id = patient_insurance.org_id
        and m.user_id = auth.uid()
        and m.role in ('superadmin','org_admin','staff')
    )
  );

-- RLS Policies: Provider Insurance
-- Org-scoped; org members can read; admins can modify
drop policy if exists provider_insurance_select on public.provider_insurance;
drop policy if exists provider_insurance_modify on public.provider_insurance;
create policy provider_insurance_select on public.provider_insurance
  for select using (public.user_can_access_org(org_id));
create policy provider_insurance_modify on public.provider_insurance
  for all using (
    public.user_can_access_org(org_id)
    and exists (
      select 1 from public.org_memberships m
      where m.org_id = provider_insurance.org_id
        and m.user_id = auth.uid()
        and m.role in ('superadmin','org_admin')
    )
  )
  with check (
    public.user_can_access_org(org_id)
    and exists (
      select 1 from public.org_memberships m
      where m.org_id = provider_insurance.org_id
        and m.user_id = auth.uid()
        and m.role in ('superadmin','org_admin')
    )
  );

-- RLS Policies: Claims
-- Org-scoped; org members can read; admins/staff can modify
drop policy if exists claims_select on public.claims;
drop policy if exists claims_modify on public.claims;
create policy claims_select on public.claims
  for select using (public.user_can_access_org(org_id));
create policy claims_modify on public.claims
  for all using (
    public.user_can_access_org(org_id)
    and exists (
      select 1 from public.org_memberships m
      where m.org_id = claims.org_id
        and m.user_id = auth.uid()
        and m.role in ('superadmin','org_admin','staff')
    )
  )
  with check (
    public.user_can_access_org(org_id)
    and exists (
      select 1 from public.org_memberships m
      where m.org_id = claims.org_id
        and m.user_id = auth.uid()
        and m.role in ('superadmin','org_admin','staff')
    )
  );

-- RLS Policies: Claim Items
-- Org-scoped; org members can read; admins/staff can modify
drop policy if exists claim_items_select on public.claim_items;
drop policy if exists claim_items_modify on public.claim_items;
create policy claim_items_select on public.claim_items
  for select using (public.user_can_access_org(org_id));
create policy claim_items_modify on public.claim_items
  for all using (
    public.user_can_access_org(org_id)
    and exists (
      select 1 from public.org_memberships m
      where m.org_id = claim_items.org_id
        and m.user_id = auth.uid()
        and m.role in ('superadmin','org_admin','staff')
    )
  )
  with check (
    public.user_can_access_org(org_id)
    and exists (
      select 1 from public.org_memberships m
      where m.org_id = claim_items.org_id
        and m.user_id = auth.uid()
        and m.role in ('superadmin','org_admin','staff')
    )
  );

-- RLS Policies: Claim Payments
-- Org-scoped; org members can read; admins/staff can modify
drop policy if exists claim_payments_select on public.claim_payments;
drop policy if exists claim_payments_modify on public.claim_payments;
create policy claim_payments_select on public.claim_payments
  for select using (public.user_can_access_org(org_id));
create policy claim_payments_modify on public.claim_payments
  for all using (
    public.user_can_access_org(org_id)
    and exists (
      select 1 from public.org_memberships m
      where m.org_id = claim_payments.org_id
        and m.user_id = auth.uid()
        and m.role in ('superadmin','org_admin','staff')
    )
  )
  with check (
    public.user_can_access_org(org_id)
    and exists (
      select 1 from public.org_memberships m
      where m.org_id = claim_payments.org_id
        and m.user_id = auth.uid()
        and m.role in ('superadmin','org_admin','staff')
    )
  );

-- RLS Policies: Eligibility Checks
-- Org-scoped; org members can read; admins/staff can modify
drop policy if exists eligibility_checks_select on public.eligibility_checks;
drop policy if exists eligibility_checks_modify on public.eligibility_checks;
create policy eligibility_checks_select on public.eligibility_checks
  for select using (public.user_can_access_org(org_id));
create policy eligibility_checks_modify on public.eligibility_checks
  for all using (
    public.user_can_access_org(org_id)
    and exists (
      select 1 from public.org_memberships m
      where m.org_id = eligibility_checks.org_id
        and m.user_id = auth.uid()
        and m.role in ('superadmin','org_admin','staff')
    )
  )
  with check (
    public.user_can_access_org(org_id)
    and exists (
      select 1 from public.org_memberships m
      where m.org_id = eligibility_checks.org_id
        and m.user_id = auth.uid()
        and m.role in ('superadmin','org_admin','staff')
    )
  );

-- RLS Policies: Pre Authorizations
-- Org-scoped; org members can read; admins/staff can modify
drop policy if exists pre_authorizations_select on public.pre_authorizations;
drop policy if exists pre_authorizations_modify on public.pre_authorizations;
create policy pre_authorizations_select on public.pre_authorizations
  for select using (public.user_can_access_org(org_id));
create policy pre_authorizations_modify on public.pre_authorizations
  for all using (
    public.user_can_access_org(org_id)
    and exists (
      select 1 from public.org_memberships m
      where m.org_id = pre_authorizations.org_id
        and m.user_id = auth.uid()
        and m.role in ('superadmin','org_admin','staff')
    )
  )
  with check (
    public.user_can_access_org(org_id)
    and exists (
      select 1 from public.org_memberships m
      where m.org_id = pre_authorizations.org_id
        and m.user_id = auth.uid()
        and m.role in ('superadmin','org_admin','staff')
    )
  );

-- RLS Policies: Insurance Documents
-- Org-scoped; org members can read; admins/staff can modify
drop policy if exists insurance_documents_select on public.insurance_documents;
drop policy if exists insurance_documents_modify on public.insurance_documents;
create policy insurance_documents_select on public.insurance_documents
  for select using (public.user_can_access_org(org_id));
create policy insurance_documents_modify on public.insurance_documents
  for all using (
    public.user_can_access_org(org_id)
    and exists (
      select 1 from public.org_memberships m
      where m.org_id = insurance_documents.org_id
        and m.user_id = auth.uid()
        and m.role in ('superadmin','org_admin','staff')
    )
  )
  with check (
    public.user_can_access_org(org_id)
    and exists (
      select 1 from public.org_memberships m
      where m.org_id = insurance_documents.org_id
        and m.user_id = auth.uid()
        and m.role in ('superadmin','org_admin','staff')
    )
  );

-- Add to realtime publication for live updates (only if not already added)
do $$
begin
  if not exists (select 1 from pg_publication_tables where pubname = 'supabase_realtime' and tablename = 'claims' and schemaname = 'public') then
    alter publication supabase_realtime add table public.claims;
  end if;
  if not exists (select 1 from pg_publication_tables where pubname = 'supabase_realtime' and tablename = 'pre_authorizations' and schemaname = 'public') then
    alter publication supabase_realtime add table public.pre_authorizations;
  end if;
end;
$$;

