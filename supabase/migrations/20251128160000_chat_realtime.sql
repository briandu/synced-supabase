-- Supabase chat realtime scaffolding: threads, members, messages + RLS using org membership and thread membership

-- Threads (dm or channel)
create table if not exists public.chat_threads (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null references public.orgs(id) on delete cascade,
  ownership_group_id uuid references public.ownership_groups(id) on delete set null,
  location_id uuid references public.locations(id) on delete set null,
  type text not null check (type in ('dm','channel')),
  name text,
  is_private boolean not null default false,
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index if not exists chat_threads_org_idx on public.chat_threads(org_id);
create index if not exists chat_threads_og_idx on public.chat_threads(ownership_group_id);
create index if not exists chat_threads_loc_idx on public.chat_threads(location_id);

-- Thread members
create table if not exists public.chat_thread_members (
  id uuid primary key default gen_random_uuid(),
  thread_id uuid not null references public.chat_threads(id) on delete cascade,
  org_id uuid not null references public.orgs(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  staff_id uuid references public.staff_members(id) on delete set null,
  role text default 'member',
  inserted_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (thread_id, user_id)
);
create index if not exists chat_thread_members_thread_idx on public.chat_thread_members(thread_id);
create index if not exists chat_thread_members_org_idx on public.chat_thread_members(org_id);

-- Helper: check if current user is a member of a chat thread
create or replace function public.user_in_chat(target_thread uuid)
returns boolean
language sql
stable
as $$
  select exists (
    select 1
    from public.chat_thread_members m
    where m.thread_id = target_thread
      and m.user_id = auth.uid()
  );
$$;

-- Messages
create table if not exists public.chat_messages (
  id uuid primary key default gen_random_uuid(),
  thread_id uuid not null references public.chat_threads(id) on delete cascade,
  org_id uuid not null references public.orgs(id) on delete cascade,
  sender_id uuid references auth.users(id) on delete set null,
  sender_staff_id uuid references public.staff_members(id) on delete set null,
  message_type text not null default 'message', -- message | system
  body text,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);
create index if not exists chat_messages_thread_idx on public.chat_messages(thread_id, created_at desc);
create index if not exists chat_messages_org_idx on public.chat_messages(org_id);

-- Enable RLS
alter table public.chat_threads enable row level security;
alter table public.chat_thread_members enable row level security;
alter table public.chat_messages enable row level security;

-- Policies: require org access AND membership for threads/messages; allow org access for member list visibility
do $$
begin
  if not exists (select 1 from pg_policies where schemaname = 'public' and tablename = 'chat_threads' and policyname = 'chat_threads_all') then
    create policy chat_threads_all on public.chat_threads
      for all
      using (public.user_can_access_org(org_id) and public.user_in_chat(id))
      with check (public.user_can_access_org(org_id));
  end if;

  if not exists (select 1 from pg_policies where schemaname = 'public' and tablename = 'chat_thread_members' and policyname = 'chat_thread_members_select') then
    create policy chat_thread_members_select on public.chat_thread_members
      for select
      using (public.user_can_access_org(org_id));
  end if;

  if not exists (select 1 from pg_policies where schemaname = 'public' and tablename = 'chat_thread_members' and policyname = 'chat_thread_members_modify') then
    create policy chat_thread_members_modify on public.chat_thread_members
      for all
      using (public.user_can_access_org(org_id))
      with check (public.user_can_access_org(org_id));
  end if;

  if not exists (select 1 from pg_policies where schemaname = 'public' and tablename = 'chat_messages' and policyname = 'chat_messages_all') then
    create policy chat_messages_all on public.chat_messages
      for all
      using (
        public.user_can_access_org(org_id)
        and public.user_in_chat(thread_id)
      )
      with check (
        public.user_can_access_org(org_id)
        and public.user_in_chat(thread_id)
      );
  end if;
end;
$$;

-- Enable Realtime for chat tables
do $$
begin
  if not exists (select 1 from pg_publication_tables where pubname = 'supabase_realtime' and tablename = 'chat_threads' and schemaname = 'public') then
    alter publication supabase_realtime add table public.chat_threads;
  end if;
  if not exists (select 1 from pg_publication_tables where pubname = 'supabase_realtime' and tablename = 'chat_messages' and schemaname = 'public') then
    alter publication supabase_realtime add table public.chat_messages;
  end if;
  if not exists (select 1 from pg_publication_tables where pubname = 'supabase_realtime' and tablename = 'chat_thread_members' and schemaname = 'public') then
    alter publication supabase_realtime add table public.chat_thread_members;
  end if;
end;
$$;
