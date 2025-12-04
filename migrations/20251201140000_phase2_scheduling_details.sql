-- Phase 2: Scheduling Details tables
-- Creates tables needed for full scheduling functionality: rooms, resources, treatment plans, waitlists, operating hours, time intervals
-- Maps Parse classes: Room, Resource, Treatment_Plan, Waitlist, Operating_Hour, Time_Interval

-- Rooms - Physical rooms for appointments
create table if not exists public.rooms (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null references public.orgs(id) on delete cascade,
  location_id uuid references public.locations(id) on delete set null,
  name text not null,
  parse_object_id text,
  created_by uuid references public.staff_members(id) on delete set null,
  updated_by uuid references public.staff_members(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Resources - Resources for appointments (equipment, etc.)
create table if not exists public.resources (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null references public.orgs(id) on delete cascade,
  location_id uuid not null references public.locations(id) on delete cascade,
  name text not null,
  parse_object_id text,
  created_by uuid references public.staff_members(id) on delete set null,
  updated_by uuid references public.staff_members(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Treatment Plans - Treatment plans for patients
create table if not exists public.treatment_plans (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null references public.orgs(id) on delete cascade,
  patient_id uuid not null references public.patients(id) on delete cascade,
  name text not null,
  start_date date not null,
  end_date date,
  primary_staff_id uuid references public.staff_members(id) on delete set null,
  parse_object_id text,
  created_by uuid references public.staff_members(id) on delete set null,
  updated_by uuid references public.staff_members(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Waitlists - Waitlist entries for appointments
create table if not exists public.waitlists (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null references public.orgs(id) on delete cascade,
  patient_id uuid not null references public.patients(id) on delete cascade,
  location_id uuid references public.locations(id) on delete set null,
  service_offering_id uuid references public.service_offerings(id) on delete set null,
  staff_id uuid references public.staff_members(id) on delete set null,
  discipline_id uuid references public.disciplines(id) on delete set null,
  availability_status text not null default 'waiting',
  first_available_date date,
  preferred_start_time text,
  preferred_end_time text,
  days_available text,
  availability_range text,
  waitlist_expiry_date date,
  notes text,
  parse_object_id text,
  created_by uuid references public.staff_members(id) on delete set null,
  updated_by uuid references public.staff_members(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Operating Hours - Operating hours for locations
create table if not exists public.operating_hours (
  id uuid primary key default gen_random_uuid(),
  location_id uuid not null references public.locations(id) on delete cascade,
  day integer not null check (day >= 0 and day <= 6), -- 0 = Sunday, 6 = Saturday
  start_time time not null,
  end_time time not null,
  is_open boolean not null default true,
  parse_object_id text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (location_id, day)
);

-- Time Intervals - Time interval definitions for scheduling
create table if not exists public.time_intervals (
  id uuid primary key default gen_random_uuid(),
  duration_minutes integer not null default 0,
  parse_object_id text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Add foreign key columns to appointments table if they don't exist
do $$
begin
  if not exists (
    select 1 from information_schema.columns
    where table_schema = 'public' and table_name = 'appointments' and column_name = 'room_id'
  ) then
    alter table public.appointments
      add column room_id uuid references public.rooms(id) on delete set null;
    create index if not exists idx_appointments_room on public.appointments(room_id) where room_id is not null;
  end if;

  if not exists (
    select 1 from information_schema.columns
    where table_schema = 'public' and table_name = 'appointments' and column_name = 'resource_id'
  ) then
    alter table public.appointments
      add column resource_id uuid references public.resources(id) on delete set null;
    create index if not exists idx_appointments_resource on public.appointments(resource_id) where resource_id is not null;
  end if;

  if not exists (
    select 1 from information_schema.columns
    where table_schema = 'public' and table_name = 'appointments' and column_name = 'treatment_plan_id'
  ) then
    alter table public.appointments
      add column treatment_plan_id uuid references public.treatment_plans(id) on delete set null;
    create index if not exists idx_appointments_treatment_plan on public.appointments(treatment_plan_id) where treatment_plan_id is not null;
  end if;
end;
$$;

-- Indexes for common queries
create index if not exists idx_rooms_org on public.rooms(org_id);
create index if not exists idx_rooms_location on public.rooms(location_id) where location_id is not null;

create index if not exists idx_resources_org on public.resources(org_id);
create index if not exists idx_resources_location on public.resources(location_id);

create index if not exists idx_treatment_plans_org on public.treatment_plans(org_id);
create index if not exists idx_treatment_plans_patient on public.treatment_plans(patient_id);
create index if not exists idx_treatment_plans_staff on public.treatment_plans(primary_staff_id) where primary_staff_id is not null;
create index if not exists idx_treatment_plans_dates on public.treatment_plans(start_date, end_date);

create index if not exists idx_waitlists_org on public.waitlists(org_id);
create index if not exists idx_waitlists_patient on public.waitlists(patient_id);
create index if not exists idx_waitlists_location on public.waitlists(location_id) where location_id is not null;
create index if not exists idx_waitlists_service_offering on public.waitlists(service_offering_id) where service_offering_id is not null;
create index if not exists idx_waitlists_staff on public.waitlists(staff_id) where staff_id is not null;
create index if not exists idx_waitlists_status on public.waitlists(availability_status);
create index if not exists idx_waitlists_first_available on public.waitlists(first_available_date) where first_available_date is not null;

create index if not exists idx_operating_hours_location on public.operating_hours(location_id);
create index if not exists idx_operating_hours_day on public.operating_hours(day);
create index if not exists idx_operating_hours_location_day on public.operating_hours(location_id, day);

-- Enable RLS on all tables
alter table public.rooms enable row level security;
alter table public.resources enable row level security;
alter table public.treatment_plans enable row level security;
alter table public.waitlists enable row level security;
alter table public.operating_hours enable row level security;
alter table public.time_intervals enable row level security;

-- RLS Policies: Rooms
-- Org-scoped; org members can read; admins can modify
drop policy if exists rooms_select on public.rooms;
drop policy if exists rooms_modify on public.rooms;
create policy rooms_select on public.rooms
  for select using (public.user_can_access_org(org_id));
create policy rooms_modify on public.rooms
  for all using (
    public.user_can_access_org(org_id)
    and exists (
      select 1 from public.org_memberships m
      where m.org_id = rooms.org_id
        and m.user_id = auth.uid()
        and m.role in ('superadmin','org_admin')
    )
  )
  with check (
    public.user_can_access_org(org_id)
    and exists (
      select 1 from public.org_memberships m
      where m.org_id = rooms.org_id
        and m.user_id = auth.uid()
        and m.role in ('superadmin','org_admin')
    )
  );

-- RLS Policies: Resources
-- Org-scoped; org members can read; admins can modify
drop policy if exists resources_select on public.resources;
drop policy if exists resources_modify on public.resources;
create policy resources_select on public.resources
  for select using (public.user_can_access_org(org_id));
create policy resources_modify on public.resources
  for all using (
    public.user_can_access_org(org_id)
    and exists (
      select 1 from public.org_memberships m
      where m.org_id = resources.org_id
        and m.user_id = auth.uid()
        and m.role in ('superadmin','org_admin')
    )
  )
  with check (
    public.user_can_access_org(org_id)
    and exists (
      select 1 from public.org_memberships m
      where m.org_id = resources.org_id
        and m.user_id = auth.uid()
        and m.role in ('superadmin','org_admin')
    )
  );

-- RLS Policies: Treatment Plans
-- Org-scoped; org members can read; admins/staff can modify
drop policy if exists treatment_plans_select on public.treatment_plans;
drop policy if exists treatment_plans_modify on public.treatment_plans;
create policy treatment_plans_select on public.treatment_plans
  for select using (public.user_can_access_org(org_id));
create policy treatment_plans_modify on public.treatment_plans
  for all using (
    public.user_can_access_org(org_id)
    and exists (
      select 1 from public.org_memberships m
      where m.org_id = treatment_plans.org_id
        and m.user_id = auth.uid()
        and m.role in ('superadmin','org_admin','staff')
    )
  )
  with check (
    public.user_can_access_org(org_id)
    and exists (
      select 1 from public.org_memberships m
      where m.org_id = treatment_plans.org_id
        and m.user_id = auth.uid()
        and m.role in ('superadmin','org_admin','staff')
    )
  );

-- RLS Policies: Waitlists
-- Org-scoped; org members can read; admins/staff can modify
drop policy if exists waitlists_select on public.waitlists;
drop policy if exists waitlists_modify on public.waitlists;
create policy waitlists_select on public.waitlists
  for select using (public.user_can_access_org(org_id));
create policy waitlists_modify on public.waitlists
  for all using (
    public.user_can_access_org(org_id)
    and exists (
      select 1 from public.org_memberships m
      where m.org_id = waitlists.org_id
        and m.user_id = auth.uid()
        and m.role in ('superadmin','org_admin','staff')
    )
  )
  with check (
    public.user_can_access_org(org_id)
    and exists (
      select 1 from public.org_memberships m
      where m.org_id = waitlists.org_id
        and m.user_id = auth.uid()
        and m.role in ('superadmin','org_admin','staff')
    )
  );

-- RLS Policies: Operating Hours
-- Access via location_id -> locations.org_id
drop policy if exists operating_hours_select on public.operating_hours;
drop policy if exists operating_hours_modify on public.operating_hours;
create policy operating_hours_select on public.operating_hours
  for select using (
    exists (
      select 1 from public.locations l
      where l.id = operating_hours.location_id
        and public.user_can_access_org(l.org_id)
    )
  );
create policy operating_hours_modify on public.operating_hours
  for all using (
    exists (
      select 1 from public.locations l
      where l.id = operating_hours.location_id
        and public.user_can_access_org(l.org_id)
        and exists (
          select 1 from public.org_memberships m
          where m.org_id = l.org_id
            and m.user_id = auth.uid()
            and m.role in ('superadmin','org_admin')
        )
    )
  )
  with check (
    exists (
      select 1 from public.locations l
      where l.id = operating_hours.location_id
        and public.user_can_access_org(l.org_id)
        and exists (
          select 1 from public.org_memberships m
          where m.org_id = l.org_id
            and m.user_id = auth.uid()
            and m.role in ('superadmin','org_admin')
        )
    )
  );

-- RLS Policies: Time Intervals
-- Global/system-level; all authenticated users can read; admins can modify
drop policy if exists time_intervals_select on public.time_intervals;
drop policy if exists time_intervals_modify on public.time_intervals;
create policy time_intervals_select on public.time_intervals
  for select using (true);
create policy time_intervals_modify on public.time_intervals
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

-- Add to realtime publication for live updates (only if not already added)
do $$
begin
  if not exists (select 1 from pg_publication_tables where pubname = 'supabase_realtime' and tablename = 'waitlists' and schemaname = 'public') then
    alter publication supabase_realtime add table public.waitlists;
  end if;
  if not exists (select 1 from pg_publication_tables where pubname = 'supabase_realtime' and tablename = 'treatment_plans' and schemaname = 'public') then
    alter publication supabase_realtime add table public.treatment_plans;
  end if;
end;
$$;

