-- Phase 2: Forms & Charting tables
-- Creates tables needed for clinical charting and form management
-- Maps Parse classes: Chart, Form_Template, Form_Response, Form_Data, Form_Detail, Intake_Form

-- Charts - Clinical charts/notes
create table if not exists public.charts (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null references public.orgs(id) on delete cascade,
  patient_id uuid not null references public.patients(id) on delete cascade,
  status text not null default 'draft',
  appointment_id uuid references public.appointments(id) on delete set null,
  treatment_plan_id uuid references public.treatment_plans(id) on delete set null,
  is_starred boolean not null default false,
  is_black_boxed boolean not null default false,
  is_visible_to_patient boolean not null default false,
  signed_at timestamptz,
  signed_by_provider_id uuid references public.staff_members(id) on delete set null,
  parse_object_id text,
  created_by uuid references public.staff_members(id) on delete set null,
  updated_by uuid references public.staff_members(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Form Templates - Form template definitions
create table if not exists public.form_templates (
  id uuid primary key default gen_random_uuid(),
  org_id uuid references public.orgs(id) on delete cascade,
  location_id uuid references public.locations(id) on delete set null,
  ownership_group_id uuid references public.ownership_groups(id) on delete set null,
  user_id uuid references auth.users(id) on delete set null,
  type text not null,
  parse_object_id text,
  created_by uuid references public.staff_members(id) on delete set null,
  updated_by uuid references public.staff_members(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Intake Forms - Intake form submissions
create table if not exists public.intake_forms (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null references public.orgs(id) on delete cascade,
  patient_id uuid not null references public.patients(id) on delete cascade,
  type text not null,
  user_id uuid references auth.users(id) on delete set null,
  ownership_group_id uuid references public.ownership_groups(id) on delete set null,
  parse_object_id text,
  created_by uuid references public.staff_members(id) on delete set null,
  updated_by uuid references public.staff_members(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Form Data - Form data submissions (can be linked to templates, intake forms, or charts)
create table if not exists public.form_data (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null references public.orgs(id) on delete cascade,
  form_type text not null,
  form_template_id uuid references public.form_templates(id) on delete set null,
  intake_form_id uuid references public.intake_forms(id) on delete set null,
  chart_id uuid references public.charts(id) on delete set null,
  name text,
  type text,
  data text, -- JSON string or text data
  parse_object_id text,
  created_by uuid references public.staff_members(id) on delete set null,
  updated_by uuid references public.staff_members(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Form Details - Form detail entries (structure/definition for forms)
create table if not exists public.form_details (
  id uuid primary key default gen_random_uuid(),
  org_id uuid references public.orgs(id) on delete cascade,
  form_template_id uuid references public.form_templates(id) on delete set null,
  intake_form_id uuid references public.intake_forms(id) on delete set null,
  chart_id uuid references public.charts(id) on delete set null,
  name text,
  type text,
  data text, -- JSON string or text data
  order_index integer not null default 0,
  parse_object_id text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Form Responses - Form response submissions (alternative structure, may map to form_data)
-- Note: This table is created based on analysis doc, but may be consolidated with form_data
create table if not exists public.form_responses (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null references public.orgs(id) on delete cascade,
  form_template_id uuid references public.form_templates(id) on delete set null,
  patient_id uuid references public.patients(id) on delete set null,
  chart_id uuid references public.charts(id) on delete set null,
  data jsonb not null default '{}'::jsonb, -- JSONB for structured form response data
  parse_object_id text,
  created_by uuid references public.staff_members(id) on delete set null,
  updated_by uuid references public.staff_members(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Indexes for common queries
create index if not exists idx_charts_org on public.charts(org_id);
create index if not exists idx_charts_patient on public.charts(patient_id);
create index if not exists idx_charts_appointment on public.charts(appointment_id) where appointment_id is not null;
create index if not exists idx_charts_treatment_plan on public.charts(treatment_plan_id) where treatment_plan_id is not null;
create index if not exists idx_charts_status on public.charts(status);
create index if not exists idx_charts_starred on public.charts(is_starred) where is_starred = true;
create index if not exists idx_charts_black_boxed on public.charts(is_black_boxed) where is_black_boxed = true;
create index if not exists idx_charts_signed_by on public.charts(signed_by_provider_id) where signed_by_provider_id is not null;

-- Indexes for form_templates (conditional on columns existing)
do $$
begin
  if exists (
    select 1 from information_schema.columns
    where table_schema = 'public' and table_name = 'form_templates' and column_name = 'org_id'
  ) then
    create index if not exists idx_form_templates_org on public.form_templates(org_id) where org_id is not null;
  end if;
  if exists (
    select 1 from information_schema.columns
    where table_schema = 'public' and table_name = 'form_templates' and column_name = 'location_id'
  ) then
    create index if not exists idx_form_templates_location on public.form_templates(location_id) where location_id is not null;
  end if;
  if exists (
    select 1 from information_schema.columns
    where table_schema = 'public' and table_name = 'form_templates' and column_name = 'type'
  ) then
    create index if not exists idx_form_templates_type on public.form_templates(type);
  end if;
  if exists (
    select 1 from information_schema.columns
    where table_schema = 'public' and table_name = 'form_templates' and column_name = 'user_id'
  ) then
    create index if not exists idx_form_templates_user on public.form_templates(user_id) where user_id is not null;
  end if;
end;
$$;

create index if not exists idx_intake_forms_org on public.intake_forms(org_id);
create index if not exists idx_intake_forms_patient on public.intake_forms(patient_id);
create index if not exists idx_intake_forms_type on public.intake_forms(type);
create index if not exists idx_intake_forms_user on public.intake_forms(user_id) where user_id is not null;

create index if not exists idx_form_data_org on public.form_data(org_id);
create index if not exists idx_form_data_form_type on public.form_data(form_type);
create index if not exists idx_form_data_template on public.form_data(form_template_id) where form_template_id is not null;
create index if not exists idx_form_data_intake on public.form_data(intake_form_id) where intake_form_id is not null;
create index if not exists idx_form_data_chart on public.form_data(chart_id) where chart_id is not null;

create index if not exists idx_form_details_org on public.form_details(org_id) where org_id is not null;
create index if not exists idx_form_details_template on public.form_details(form_template_id) where form_template_id is not null;
create index if not exists idx_form_details_intake on public.form_details(intake_form_id) where intake_form_id is not null;
create index if not exists idx_form_details_chart on public.form_details(chart_id) where chart_id is not null;
create index if not exists idx_form_details_order on public.form_details(order_index);

-- Indexes for form_responses (conditional on columns existing)
do $$
begin
  if exists (
    select 1 from information_schema.columns
    where table_schema = 'public' and table_name = 'form_responses' and column_name = 'org_id'
  ) then
    create index if not exists idx_form_responses_org on public.form_responses(org_id);
  end if;
  if exists (
    select 1 from information_schema.columns
    where table_schema = 'public' and table_name = 'form_responses' and column_name = 'form_template_id'
  ) then
    create index if not exists idx_form_responses_template on public.form_responses(form_template_id) where form_template_id is not null;
  end if;
  if exists (
    select 1 from information_schema.columns
    where table_schema = 'public' and table_name = 'form_responses' and column_name = 'patient_id'
  ) then
    create index if not exists idx_form_responses_patient on public.form_responses(patient_id) where patient_id is not null;
  end if;
  if exists (
    select 1 from information_schema.columns
    where table_schema = 'public' and table_name = 'form_responses' and column_name = 'chart_id'
  ) then
    create index if not exists idx_form_responses_chart on public.form_responses(chart_id) where chart_id is not null;
  end if;
end;
$$;

-- Enable RLS on all tables
alter table public.charts enable row level security;
alter table public.form_templates enable row level security;
alter table public.intake_forms enable row level security;
alter table public.form_data enable row level security;
alter table public.form_details enable row level security;
alter table public.form_responses enable row level security;

-- RLS Policies: Charts
-- Org-scoped; org members can read; admins/staff can modify
drop policy if exists charts_select on public.charts;
drop policy if exists charts_modify on public.charts;
create policy charts_select on public.charts
  for select using (
    public.user_can_access_org(org_id)
    and exists (
      select 1 from public.org_memberships m
      where m.org_id = charts.org_id
        and m.user_id = auth.uid()
        and m.role in ('superadmin','org_admin','staff')
    )
  );
create policy charts_modify on public.charts
  for all using (
    public.user_can_access_org(org_id)
    and exists (
      select 1 from public.org_memberships m
      where m.org_id = charts.org_id
        and m.user_id = auth.uid()
        and m.role in ('superadmin','org_admin','staff')
    )
  )
  with check (
    public.user_can_access_org(org_id)
    and exists (
      select 1 from public.org_memberships m
      where m.org_id = charts.org_id
        and m.user_id = auth.uid()
        and m.role in ('superadmin','org_admin','staff')
    )
  );

-- RLS Policies: Form Templates
-- Org-scoped; org members can read; admins can modify
drop policy if exists form_templates_select on public.form_templates;
drop policy if exists form_templates_modify on public.form_templates;
create policy form_templates_select on public.form_templates
  for select using (
    org_id is null or public.user_can_access_org(org_id)
  );
create policy form_templates_modify on public.form_templates
  for all using (
    (org_id is null or public.user_can_access_org(org_id))
    and (
      org_id is null
      or exists (
        select 1 from public.org_memberships m
        where m.org_id = form_templates.org_id
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
        where m.org_id = form_templates.org_id
          and m.user_id = auth.uid()
          and m.role in ('superadmin','org_admin')
      )
    )
  );

-- RLS Policies: Intake Forms
-- Org-scoped; org members can read; admins/staff can modify
drop policy if exists intake_forms_select on public.intake_forms;
drop policy if exists intake_forms_modify on public.intake_forms;
create policy intake_forms_select on public.intake_forms
  for select using (public.user_can_access_org(org_id));
create policy intake_forms_modify on public.intake_forms
  for all using (
    public.user_can_access_org(org_id)
    and exists (
      select 1 from public.org_memberships m
      where m.org_id = intake_forms.org_id
        and m.user_id = auth.uid()
        and m.role in ('superadmin','org_admin','staff')
    )
  )
  with check (
    public.user_can_access_org(org_id)
    and exists (
      select 1 from public.org_memberships m
      where m.org_id = intake_forms.org_id
        and m.user_id = auth.uid()
        and m.role in ('superadmin','org_admin','staff')
    )
  );

-- RLS Policies: Form Data
-- Org-scoped; org members can read; admins/staff can modify
drop policy if exists form_data_select on public.form_data;
drop policy if exists form_data_modify on public.form_data;
create policy form_data_select on public.form_data
  for select using (public.user_can_access_org(org_id));
create policy form_data_modify on public.form_data
  for all using (
    public.user_can_access_org(org_id)
    and exists (
      select 1 from public.org_memberships m
      where m.org_id = form_data.org_id
        and m.user_id = auth.uid()
        and m.role in ('superadmin','org_admin','staff')
    )
  )
  with check (
    public.user_can_access_org(org_id)
    and exists (
      select 1 from public.org_memberships m
      where m.org_id = form_data.org_id
        and m.user_id = auth.uid()
        and m.role in ('superadmin','org_admin','staff')
    )
  );

-- RLS Policies: Form Details
-- Org-scoped; org members can read; admins can modify
drop policy if exists form_details_select on public.form_details;
drop policy if exists form_details_modify on public.form_details;
create policy form_details_select on public.form_details
  for select using (
    org_id is null or public.user_can_access_org(org_id)
  );
create policy form_details_modify on public.form_details
  for all using (
    (org_id is null or public.user_can_access_org(org_id))
    and (
      org_id is null
      or exists (
        select 1 from public.org_memberships m
        where m.org_id = form_details.org_id
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
        where m.org_id = form_details.org_id
          and m.user_id = auth.uid()
          and m.role in ('superadmin','org_admin')
      )
    )
  );

-- RLS Policies: Form Responses
-- Org-scoped; org members can read; admins/staff can modify
drop policy if exists form_responses_select on public.form_responses;
drop policy if exists form_responses_modify on public.form_responses;
create policy form_responses_select on public.form_responses
  for select using (public.user_can_access_org(org_id));
create policy form_responses_modify on public.form_responses
  for all using (
    public.user_can_access_org(org_id)
    and exists (
      select 1 from public.org_memberships m
      where m.org_id = form_responses.org_id
        and m.user_id = auth.uid()
        and m.role in ('superadmin','org_admin','staff')
    )
  )
  with check (
    public.user_can_access_org(org_id)
    and exists (
      select 1 from public.org_memberships m
      where m.org_id = form_responses.org_id
        and m.user_id = auth.uid()
        and m.role in ('superadmin','org_admin','staff')
    )
  );

-- Add to realtime publication for live updates (only if not already added)
do $$
begin
  if not exists (select 1 from pg_publication_tables where pubname = 'supabase_realtime' and tablename = 'charts' and schemaname = 'public') then
    alter publication supabase_realtime add table public.charts;
  end if;
  if not exists (select 1 from pg_publication_tables where pubname = 'supabase_realtime' and tablename = 'form_responses' and schemaname = 'public') then
    alter publication supabase_realtime add table public.form_responses;
  end if;
end;
$$;

