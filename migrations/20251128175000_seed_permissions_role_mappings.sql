-- Seed permissions and role->permission mappings using existing permissions/role_permissions schema.

-- Insert permissions (name, description)
insert into public.permissions (name, description)
values
  ('manage_org', 'Manage organization settings'),
  ('manage_staff', 'Manage staff and invites'),
  ('manage_billing', 'Manage billing and Stripe'),
  ('manage_appointments', 'Manage appointments'),
  ('view_patients', 'View patients'),
  ('edit_patients', 'Edit patients')
on conflict (name) do nothing;

-- Map enum roles (user_role) to permissions (available enum values: superadmin, org_admin, staff, patient)
with perms as (select id, name from public.permissions)
insert into public.role_permissions (role, permission_id)
select 'superadmin'::public.user_role, p.id from perms p
on conflict (role, permission_id) do nothing;

-- org_admin permissions
with perms as (select id, name from public.permissions where name in ('manage_org','manage_staff','manage_appointments','view_patients','edit_patients','manage_billing'))
insert into public.role_permissions (role, permission_id)
select 'org_admin'::public.user_role, p.id from perms p
on conflict (role, permission_id) do nothing;

-- staff permissions
with perms as (select id, name from public.permissions where name in ('manage_appointments','view_patients'))
insert into public.role_permissions (role, permission_id)
select 'staff'::public.user_role, p.id from perms p
on conflict (role, permission_id) do nothing;
