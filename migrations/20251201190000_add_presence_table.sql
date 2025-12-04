-- Add presence table for tracking user online/offline status

create table if not exists public.presence (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null references public.orgs(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  status text not null default 'online', -- online | offline | away
  last_seen timestamptz not null default now(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (org_id, user_id)
);

-- Add indexes
create index if not exists idx_presence_org on public.presence(org_id);
create index if not exists idx_presence_user on public.presence(user_id);
create index if not exists idx_presence_status on public.presence(status);

-- Enable RLS
alter table public.presence enable row level security;

-- RLS policies for presence
drop policy if exists presence_select on public.presence;
create policy presence_select on public.presence
  for select using (public.user_can_access_org(org_id));

drop policy if exists presence_modify on public.presence;
create policy presence_modify on public.presence
  for all
  using (public.user_can_access_org(org_id))
  with check (public.user_can_access_org(org_id) and user_id = auth.uid());

-- Enable Realtime for presence
do $$
begin
  if not exists (select 1 from pg_publication_tables where pubname = 'supabase_realtime' and tablename = 'presence' and schemaname = 'public') then
    alter publication supabase_realtime add table public.presence;
  end if;
end;
$$;

