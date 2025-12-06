-- Enable RLS for location_taxes table and add appropriate policies
-- This fixes the security advisor error: rls_disabled_in_public

-- Enable RLS
alter table public.location_taxes enable row level security;

-- Helper function to get org_id from location_id (for RLS policies)
-- We'll use a join in the policy instead, but this is for clarity

-- RLS policies for location_taxes
-- Select: Users can see location_taxes for locations in orgs they can access
drop policy if exists location_taxes_select on public.location_taxes;
create policy location_taxes_select on public.location_taxes
  for select
  using (
    exists (
      select 1
      from public.locations l
      where l.id = location_taxes.location_id
        and public.user_can_access_org(l.org_id)
    )
  );

-- Modify: Only superadmin and org_admin can modify location_taxes
drop policy if exists location_taxes_modify on public.location_taxes;
create policy location_taxes_modify on public.location_taxes
  for all
  using (
    exists (
      select 1
      from public.locations l
      join public.org_memberships m on m.org_id = l.org_id
      where l.id = location_taxes.location_id
        and m.user_id = auth.uid()
        and m.role in ('superadmin', 'org_admin')
    )
  )
  with check (
    exists (
      select 1
      from public.locations l
      join public.org_memberships m on m.org_id = l.org_id
      where l.id = location_taxes.location_id
        and m.user_id = auth.uid()
        and m.role in ('superadmin', 'org_admin')
    )
  );

