-- Fix final orgs policy conflicts
-- Drop orgs_modify (for all) which conflicts with orgs_select, orgs_update, and orgs_insert
-- Keep only orgs_select, orgs_update, and orgs_insert (for service_role)

-- Drop conflicting policies
drop policy if exists orgs_modify on public.orgs;
drop policy if exists orgs_all on public.orgs;

-- Drop and recreate orgs_select and orgs_update to ensure they're correct
drop policy if exists orgs_select on public.orgs;
drop policy if exists orgs_update on public.orgs;

-- Create orgs_select policy
create policy orgs_select on public.orgs
  for select
  using (
    public.user_can_access_org(id)
    and exists (
      select 1
      from public.org_memberships m
      where m.org_id = orgs.id
        and m.user_id = (select auth.uid())
        and m.role in ('superadmin','org_admin')
    )
  );

-- Create orgs_update policy
create policy orgs_update on public.orgs
  for update
  using (
    public.user_can_access_org(id)
    and exists (
      select 1
      from public.org_memberships m
      where m.org_id = orgs.id
        and m.user_id = (select auth.uid())
        and m.role in ('superadmin','org_admin')
    )
  )
  with check (
    public.user_can_access_org(id)
    and exists (
      select 1
      from public.org_memberships m
      where m.org_id = orgs.id
        and m.user_id = (select auth.uid())
        and m.role in ('superadmin','org_admin')
    )
  );

-- Note: orgs_insert should remain for service_role only (from initial schema)
-- We don't drop it here

