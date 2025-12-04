-- Fix function search_path security warnings
-- Functions without a fixed search_path are vulnerable to search_path manipulation attacks
-- Setting search_path = '' forces fully qualified schema names (which we already use)

-- Fix user_can_access_org function
create or replace function public.user_can_access_org(target_org uuid)
returns boolean
language plpgsql
stable
security definer
set search_path = ''
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

-- Fix user_can_access_location function
create or replace function public.user_can_access_location(target_location uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
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

-- Fix user_in_chat function
create or replace function public.user_in_chat(target_thread uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.chat_thread_members m
    where m.thread_id = target_thread
      and m.user_id = auth.uid()
  );
$$;

