-- Add audit_events table and status field to org_staff_invites

-- Add status field to org_staff_invites if it doesn't exist
do $$
begin
  -- Add status column if it doesn't exist
  if not exists (
    select 1 from information_schema.columns 
    where table_schema = 'public' 
    and table_name = 'org_staff_invites' 
    and column_name = 'status'
  ) then
    alter table public.org_staff_invites add column status text default 'pending';
  end if;

  -- Add staff_id column if it doesn't exist
  if not exists (
    select 1 from information_schema.columns 
    where table_schema = 'public' 
    and table_name = 'org_staff_invites' 
    and column_name = 'staff_id'
  ) then
    alter table public.org_staff_invites 
    add column staff_id uuid references public.staff_members(id) on delete set null;
  end if;

  -- Add accepted_at column if it doesn't exist
  if not exists (
    select 1 from information_schema.columns 
    where table_schema = 'public' 
    and table_name = 'org_staff_invites' 
    and column_name = 'accepted_at'
  ) then
    alter table public.org_staff_invites add column accepted_at timestamptz;
  end if;

  -- Add disconnected_at column if it doesn't exist
  if not exists (
    select 1 from information_schema.columns 
    where table_schema = 'public' 
    and table_name = 'org_staff_invites' 
    and column_name = 'disconnected_at'
  ) then
    alter table public.org_staff_invites add column disconnected_at timestamptz;
  end if;
end;
$$;

-- Create audit_events table if it doesn't exist
create table if not exists public.audit_events (
  id uuid primary key default gen_random_uuid(),
  org_id uuid references public.orgs(id) on delete set null,
  staff_id uuid references public.staff_members(id) on delete set null,
  type text not null,
  details jsonb,
  created_at timestamptz not null default now()
);

-- Add indexes
create index if not exists idx_audit_events_org on public.audit_events(org_id);
create index if not exists idx_audit_events_staff on public.audit_events(staff_id);
create index if not exists idx_audit_events_type on public.audit_events(type);
create index if not exists idx_audit_events_created on public.audit_events(created_at);

-- Enable RLS
alter table public.audit_events enable row level security;

-- RLS policies for audit_events
drop policy if exists audit_events_select on public.audit_events;
create policy audit_events_select on public.audit_events
  for select using (public.user_can_access_org(org_id));

drop policy if exists audit_events_insert on public.audit_events;
create policy audit_events_insert on public.audit_events
  for insert with check (public.user_can_access_org(org_id));

