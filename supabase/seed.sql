-- Seed data for Supabase schema
-- Run in Supabase SQL editor after schema is applied

-- Org and location
insert into public.orgs (id, name) values
  ('11111111-1111-1111-1111-111111111111', 'Synced Health Demo')
on conflict (id) do nothing;

insert into public.locations (id, org_id, name, timezone)
values
  ('22222222-2222-2222-2222-222222222222', '11111111-1111-1111-1111-111111111111', 'Main Clinic', 'America/Toronto')
on conflict (id) do nothing;

-- Disciplines
insert into public.disciplines (id, org_id, name)
values
  ('33333333-3333-3333-3333-333333333333', '11111111-1111-1111-1111-111111111111', 'Physiotherapy'),
  ('33333333-3333-3333-3333-333333333334', '11111111-1111-1111-1111-111111111111', 'Chiropractic')
on conflict (id) do nothing;

-- Permissions baseline
insert into public.permissions (id, name, description)
values
  ('44444444-4444-4444-4444-444444444441', 'manage_org', 'Manage organization settings'),
  ('44444444-4444-4444-4444-444444444442', 'manage_staff', 'Manage staff and invites'),
  ('44444444-4444-4444-4444-444444444443', 'manage_patients', 'Manage patients and files'),
  ('44444444-4444-4444-4444-444444444444', 'manage_schedule', 'Manage appointments and availability'),
  ('44444444-4444-4444-4444-444444444445', 'manage_billing', 'Manage invoices and payments')
on conflict (id) do nothing;

-- Role permissions
insert into public.role_permissions (id, role, permission_id) values
  ('55555555-5555-5555-5555-555555555551', 'superadmin', '44444444-4444-4444-4444-444444444441'),
  ('55555555-5555-5555-5555-555555555552', 'superadmin', '44444444-4444-4444-4444-444444444442'),
  ('55555555-5555-5555-5555-555555555553', 'superadmin', '44444444-4444-4444-4444-444444444443'),
  ('55555555-5555-5555-5555-555555555554', 'superadmin', '44444444-4444-4444-4444-444444444444'),
  ('55555555-5555-5555-5555-555555555555', 'superadmin', '44444444-4444-4444-4444-444444444445'),
  ('55555555-5555-5555-5555-555555555561', 'org_admin', '44444444-4444-4444-4444-444444444441'),
  ('55555555-5555-5555-5555-555555555562', 'org_admin', '44444444-4444-4444-4444-444444444442'),
  ('55555555-5555-5555-5555-555555555563', 'org_admin', '44444444-4444-4444-4444-444444444443'),
  ('55555555-5555-5555-5555-555555555564', 'org_admin', '44444444-4444-4444-4444-444444444444'),
  ('55555555-5555-5555-5555-555555555565', 'org_admin', '44444444-4444-4444-4444-444444444445'),
  ('55555555-5555-5555-5555-555555555571', 'staff', '44444444-4444-4444-4444-444444444443'),
  ('55555555-5555-5555-5555-555555555572', 'staff', '44444444-4444-4444-4444-444444444444')
on conflict (id) do nothing;

-- Income category sample
insert into public.income_categories (id, org_id, name, created_by)
values ('66666666-6666-6666-6666-666666666666', '11111111-1111-1111-1111-111111111111', 'Consultation', null)
on conflict (id) do nothing;

-- Services and prices
insert into public.services (id, org_id, discipline_id, name, description, duration_minutes)
values ('77777777-7777-7777-7777-777777777777', '11111111-1111-1111-1111-111111111111', '33333333-3333-3333-3333-333333333333', 'Initial Assessment', 'Initial intake assessment', 60)
on conflict (id) do nothing;

insert into public.service_prices (id, org_id, service_id, location_id, price_cents, currency)
values ('88888888-8888-8888-8888-888888888888', '11111111-1111-1111-1111-111111111111', '77777777-7777-7777-7777-777777777777', '22222222-2222-2222-2222-222222222222', 15000, 'usd')
on conflict (id) do nothing;

-- Products and inventory
insert into public.products (id, org_id, name, description, income_category_id)
values ('99999999-9999-9999-9999-999999999999', '11111111-1111-1111-1111-111111111111', 'Massage Oil', 'Retail item', '66666666-6666-6666-6666-666666666666')
on conflict (id) do nothing;

insert into public.suppliers (id, org_id, name)
values ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', '11111111-1111-1111-1111-111111111111', 'Default Supplier')
on conflict (id) do nothing;

insert into public.product_inventory (id, org_id, product_id, supplier_id, quantity)
values ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', '11111111-1111-1111-1111-111111111111', '99999999-9999-9999-9999-999999999999', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 10)
on conflict (id) do nothing;

-- Example patient and appointment (requires manual auth.users link for staff/patient if desired)
insert into public.patients (id, org_id, first_name, last_name, email, phone)
values ('cccccccc-cccc-cccc-cccc-cccccccccccc', '11111111-1111-1111-1111-111111111111', 'Test', 'Patient', 'patient@example.com', '+10000000000')
on conflict (id) do nothing;

insert into public.appointments (id, org_id, location_id, patient_id, starts_at, ends_at, status)
values (
  'dddddddd-dddd-dddd-dddd-dddddddddddd',
  '11111111-1111-1111-1111-111111111111',
  '22222222-2222-2222-2222-222222222222',
  'cccccccc-cccc-cccc-cccc-cccccccccccc',
  now() + interval '1 day',
  now() + interval '1 day' + interval '1 hour',
  'scheduled'
) on conflict (id) do nothing;
