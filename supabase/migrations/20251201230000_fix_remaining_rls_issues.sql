-- Fix remaining RLS performance issues
-- 1. Fix remaining auth_rls_initplan warnings in initial schema policies
-- 2. Fix multiple_permissive_policies warnings by consolidating duplicate policies

-- ============================================================================
-- Fix remaining auth_rls_initplan warnings in initial schema
-- ============================================================================

-- profiles: Fix profiles_self_select and profiles_self_update (from initial schema)
drop policy if exists profiles_self_select on public.profiles;
drop policy if exists profiles_self_update on public.profiles;
create policy profiles_self_select on public.profiles
  for select
  using (
    (select auth.uid()) = id
    or exists (
      select 1
      from public.org_memberships m
      where m.user_id = (select auth.uid())
        and m.org_id = profiles.default_org_id
    )
  );
create policy profiles_self_update on public.profiles
  for update
  using ((select auth.uid()) = id);

-- org_memberships: Fix org_memberships_select and org_memberships_modify (from initial schema)
-- Note: org_memberships_modify was already fixed in 20251201220000, but org_memberships_select wasn't
drop policy if exists org_memberships_select on public.org_memberships;
create policy org_memberships_select on public.org_memberships
  for select
  using (
    (select auth.uid()) = user_id
    or exists (
      select 1
      from public.org_memberships m
      where m.user_id = (select auth.uid())
        and m.role = 'superadmin'
    )
  );

-- orgs: Fix orgs_insert (from initial schema)
-- Note: orgs_insert uses auth.role() which doesn't need the (select ...) wrapper, but we should check if it's causing issues
-- Actually, auth.role() is fine as-is, but let's check the orgs_select and orgs_update policies
-- They use public.user_can_access_org which internally uses auth.uid(), so those should be fine

-- ============================================================================
-- Fix multiple_permissive_policies warnings
-- ============================================================================

-- appointments: Drop old separate policies since appointments_all already covers all operations
-- The appointments_all policy from 20251128180000_rls_tighten_core.sql (and updated in 20251201220000)
-- already covers SELECT, INSERT, UPDATE, DELETE, so we should drop the old separate policies
drop policy if exists appointments_select on public.appointments;
drop policy if exists appointments_modify on public.appointments;
-- Note: appointments_all is already created in 20251201220000_fix_auth_rls_initplan.sql

-- ============================================================================
-- Fix user_insurance_select policy (from 20251201160000_phase2_insurance.sql)
-- ============================================================================

-- The migration 20251201220000 only fixed user_insurance_modify, but user_insurance_select also needs fixing
-- It uses auth.uid() directly which causes auth_rls_initplan warnings
drop policy if exists user_insurance_select on public.user_insurance;
create policy user_insurance_select on public.user_insurance
  for select
  using (
    (select auth.uid()) = user_id
    or exists (
      select 1
      from public.org_memberships m
      where m.user_id = (select auth.uid())
        and m.role in ('superadmin','org_admin','staff')
    )
  );

-- ============================================================================
-- Additional fixes for any remaining policies that might have auth.uid() directly
-- ============================================================================

-- Check and fix any policies in the initial schema that use auth.uid() directly
-- These should already be covered, but let's be thorough

-- The initial schema policies that use auth.uid() directly:
-- 1. profiles_self_select - FIXED above
-- 2. profiles_self_update - FIXED above
-- 3. org_memberships_select - FIXED above
-- 4. org_memberships_modify - Already fixed in 20251201220000
-- 5. orgs_insert - Uses auth.role(), not auth.uid(), so it's fine

-- All other policies in the initial schema use public.user_can_access_org() which internally uses auth.uid()
-- The user_can_access_org function itself should be fine since it's a function call, not a direct policy expression

-- ============================================================================
-- Comprehensive consolidation of multiple_permissive_policies warnings
-- Drop redundant _select, _modify, _insert, _update, _delete policies
-- for tables that have _all policies (which cover all operations)
-- ============================================================================

-- Core tables
drop policy if exists ownership_groups_select on public.ownership_groups;
drop policy if exists ownership_groups_modify on public.ownership_groups;
drop policy if exists locations_select on public.locations;
drop policy if exists locations_modify on public.locations;
drop policy if exists staff_select on public.staff_members;
drop policy if exists staff_modify on public.staff_members;
drop policy if exists patients_select on public.patients;
drop policy if exists patients_modify on public.patients;
drop policy if exists patient_files_select on public.patient_files;
drop policy if exists patient_files_modify on public.patient_files;
drop policy if exists invoices_select on public.invoices;
drop policy if exists invoices_modify on public.invoices;
drop policy if exists invoice_items_select on public.invoice_items;
drop policy if exists invoice_items_modify on public.invoice_items;
drop policy if exists payment_methods_select on public.payment_methods;
drop policy if exists payment_methods_modify on public.payment_methods;
drop policy if exists payments_select on public.payments;
drop policy if exists payments_modify on public.payments;
drop policy if exists gift_cards_select on public.gift_cards;
drop policy if exists gift_cards_modify on public.gift_cards;
drop policy if exists roles_select on public.roles;
drop policy if exists roles_modify on public.roles;
drop policy if exists permissions_select on public.permissions;
drop policy if exists permissions_modify on public.permissions;
drop policy if exists role_permissions_select on public.role_permissions;
drop policy if exists role_permissions_modify on public.role_permissions;

-- Chat tables
drop policy if exists chat_threads_select on public.chat_threads;
drop policy if exists chat_threads_modify on public.chat_threads;
drop policy if exists chat_messages_select on public.chat_messages;
drop policy if exists chat_messages_modify on public.chat_messages;
drop policy if exists chat_thread_members_select on public.chat_thread_members;
drop policy if exists chat_thread_members_modify on public.chat_thread_members;

-- Scheduling tables
drop policy if exists treatment_plans_select on public.treatment_plans;
drop policy if exists treatment_plans_modify on public.treatment_plans;
drop policy if exists waitlists_select on public.waitlists;
drop policy if exists waitlists_modify on public.waitlists;
drop policy if exists operating_hours_select on public.operating_hours;
drop policy if exists operating_hours_modify on public.operating_hours;
drop policy if exists time_intervals_select on public.time_intervals;
drop policy if exists time_intervals_modify on public.time_intervals;
drop policy if exists rooms_select on public.rooms;
drop policy if exists rooms_modify on public.rooms;
drop policy if exists resources_select on public.resources;
drop policy if exists resources_modify on public.resources;

-- Forms & Charting tables
drop policy if exists charts_select on public.charts;
drop policy if exists charts_modify on public.charts;
drop policy if exists form_templates_select on public.form_templates;
drop policy if exists form_templates_modify on public.form_templates;
drop policy if exists form_responses_select on public.form_responses;
drop policy if exists form_responses_modify on public.form_responses;
drop policy if exists form_data_select on public.form_data;
drop policy if exists form_data_modify on public.form_data;
drop policy if exists form_details_select on public.form_details;
drop policy if exists form_details_modify on public.form_details;
drop policy if exists intake_forms_select on public.intake_forms;
drop policy if exists intake_forms_modify on public.intake_forms;

-- Insurance tables
drop policy if exists insurers_select on public.insurers;
drop policy if exists insurers_modify on public.insurers;
drop policy if exists insurance_plans_select on public.insurance_plans;
drop policy if exists insurance_plans_modify on public.insurance_plans;
drop policy if exists user_insurance_modify on public.user_insurance;
drop policy if exists patient_insurance_select on public.patient_insurance;
drop policy if exists patient_insurance_modify on public.patient_insurance;
drop policy if exists provider_insurance_select on public.provider_insurance;
drop policy if exists provider_insurance_modify on public.provider_insurance;
drop policy if exists claims_select on public.claims;
drop policy if exists claims_modify on public.claims;
drop policy if exists claim_items_select on public.claim_items;
drop policy if exists claim_items_modify on public.claim_items;
drop policy if exists claim_payments_select on public.claim_payments;
drop policy if exists claim_payments_modify on public.claim_payments;
drop policy if exists eligibility_checks_select on public.eligibility_checks;
drop policy if exists eligibility_checks_modify on public.eligibility_checks;
drop policy if exists pre_authorizations_select on public.pre_authorizations;
drop policy if exists pre_authorizations_modify on public.pre_authorizations;
drop policy if exists insurance_documents_select on public.insurance_documents;
drop policy if exists insurance_documents_modify on public.insurance_documents;

-- Booking Policies tables
drop policy if exists booking_policy_presets_select on public.booking_policy_presets;
drop policy if exists booking_policy_presets_modify on public.booking_policy_presets;
drop policy if exists booking_policies_select on public.booking_policies;
drop policy if exists booking_policies_modify on public.booking_policies;
drop policy if exists booking_portals_select on public.booking_portals;
drop policy if exists booking_portals_modify on public.booking_portals;

-- Services & Products tables
drop policy if exists discipline_offerings_select on public.discipline_offerings;
drop policy if exists discipline_offerings_modify on public.discipline_offerings;
drop policy if exists service_offerings_select on public.service_offerings;
drop policy if exists service_offerings_modify on public.service_offerings;
drop policy if exists item_prices_select on public.item_prices;
drop policy if exists item_prices_modify on public.item_prices;
drop policy if exists items_catalog_select on public.items_catalog;
drop policy if exists items_catalog_modify on public.items_catalog;
drop policy if exists service_details_select on public.service_details;
drop policy if exists service_details_modify on public.service_details;
drop policy if exists product_details_select on public.product_details;
drop policy if exists product_details_modify on public.product_details;
drop policy if exists income_categories_select on public.income_categories;
drop policy if exists income_categories_modify on public.income_categories;
drop policy if exists suppliers_select on public.suppliers;
drop policy if exists suppliers_modify on public.suppliers;
drop policy if exists product_inventory_select on public.product_inventory;
drop policy if exists product_inventory_modify on public.product_inventory;

-- Other tables
drop policy if exists location_taxes_select on public.location_taxes;
drop policy if exists location_taxes_modify on public.location_taxes;
drop policy if exists presence_select on public.presence;
drop policy if exists presence_modify on public.presence;

-- orgs: Consolidate orgs_select, orgs_insert, orgs_update into orgs_all
-- Note: orgs_insert is for service_role, so we need to keep it separate
-- But we can consolidate orgs_select and orgs_update
drop policy if exists orgs_select on public.orgs;
drop policy if exists orgs_update on public.orgs;
-- orgs_insert is kept separate for service_role access
-- orgs_all will be created below if it doesn't exist

-- ============================================================================
-- Create consolidated _all policies for tables that don't have them yet
-- ============================================================================

-- ownership_groups: Create _all policy if it doesn't exist
-- (It should already exist from initial schema, but ensure it covers all operations)
drop policy if exists ownership_groups_all on public.ownership_groups;
create policy ownership_groups_all on public.ownership_groups
  for all
  using (
    public.user_can_access_org(org_id)
    and exists (
      select 1
      from public.org_memberships m
      where m.org_id = ownership_groups.org_id
        and m.user_id = (select auth.uid())
        and m.role in ('superadmin','org_admin')
    )
  )
  with check (
    public.user_can_access_org(org_id)
    and exists (
      select 1
      from public.org_memberships m
      where m.org_id = ownership_groups.org_id
        and m.user_id = (select auth.uid())
        and m.role in ('superadmin','org_admin')
    )
  );

-- locations: Create _all policy
drop policy if exists locations_all on public.locations;
create policy locations_all on public.locations
  for all
  using (
    public.user_can_access_org(org_id)
    and exists (
      select 1
      from public.org_memberships m
      where m.org_id = locations.org_id
        and m.user_id = (select auth.uid())
        and m.role in ('superadmin','org_admin','staff')
    )
  )
  with check (
    public.user_can_access_org(org_id)
    and exists (
      select 1
      from public.org_memberships m
      where m.org_id = locations.org_id
        and m.user_id = (select auth.uid())
        and m.role in ('superadmin','org_admin','staff')
    )
  );

-- staff_members: Create _all policy
drop policy if exists staff_all on public.staff_members;
create policy staff_all on public.staff_members
  for all
  using (
    public.user_can_access_org(org_id)
    and exists (
      select 1
      from public.org_memberships m
      where m.org_id = staff_members.org_id
        and m.user_id = (select auth.uid())
        and m.role in ('superadmin','org_admin','staff')
    )
  )
  with check (
    public.user_can_access_org(org_id)
    and exists (
      select 1
      from public.org_memberships m
      where m.org_id = staff_members.org_id
        and m.user_id = (select auth.uid())
        and m.role in ('superadmin','org_admin','staff')
    )
  );

-- patients: Create _all policy
drop policy if exists patients_all on public.patients;
create policy patients_all on public.patients
  for all
  using (
    public.user_can_access_org(org_id)
    and exists (
      select 1
      from public.org_memberships m
      where m.org_id = patients.org_id
        and m.user_id = (select auth.uid())
        and m.role in ('superadmin','org_admin','staff')
    )
  )
  with check (
    public.user_can_access_org(org_id)
    and exists (
      select 1
      from public.org_memberships m
      where m.org_id = patients.org_id
        and m.user_id = (select auth.uid())
        and m.role in ('superadmin','org_admin','staff')
    )
  );

-- patient_files: Create _all policy
drop policy if exists patient_files_all on public.patient_files;
create policy patient_files_all on public.patient_files
  for all
  using (
    exists (
      select 1
      from public.patients p
      where p.id = patient_files.patient_id
        and public.user_can_access_org(p.org_id)
        and exists (
          select 1
          from public.org_memberships m
          where m.org_id = p.org_id
            and m.user_id = (select auth.uid())
            and m.role in ('superadmin','org_admin','staff')
        )
    )
  )
  with check (
    exists (
      select 1
      from public.patients p
      where p.id = patient_files.patient_id
        and public.user_can_access_org(p.org_id)
        and exists (
          select 1
          from public.org_memberships m
          where m.org_id = p.org_id
            and m.user_id = (select auth.uid())
            and m.role in ('superadmin','org_admin','staff')
        )
    )
  );

-- invoices: Create _all policy
drop policy if exists invoices_all on public.invoices;
create policy invoices_all on public.invoices
  for all
  using (
    public.user_can_access_org(org_id)
    and exists (
      select 1
      from public.org_memberships m
      where m.org_id = invoices.org_id
        and m.user_id = (select auth.uid())
        and m.role in ('superadmin','org_admin','staff')
    )
  )
  with check (
    public.user_can_access_org(org_id)
    and exists (
      select 1
      from public.org_memberships m
      where m.org_id = invoices.org_id
        and m.user_id = (select auth.uid())
        and m.role in ('superadmin','org_admin','staff')
    )
  );

-- invoice_items: Create _all policy
drop policy if exists invoice_items_all on public.invoice_items;
create policy invoice_items_all on public.invoice_items
  for all
  using (
    exists (
      select 1
      from public.invoices i
      where i.id = invoice_items.invoice_id
        and public.user_can_access_org(i.org_id)
        and exists (
          select 1
          from public.org_memberships m
          where m.org_id = i.org_id
            and m.user_id = (select auth.uid())
            and m.role in ('superadmin','org_admin','staff')
        )
    )
  )
  with check (
    exists (
      select 1
      from public.invoices i
      where i.id = invoice_items.invoice_id
        and public.user_can_access_org(i.org_id)
        and exists (
          select 1
          from public.org_memberships m
          where m.org_id = i.org_id
            and m.user_id = (select auth.uid())
            and m.role in ('superadmin','org_admin','staff')
        )
    )
  );

-- payment_methods: Create _all policy
drop policy if exists payment_methods_all on public.payment_methods;
create policy payment_methods_all on public.payment_methods
  for all
  using (
    exists (
      select 1
      from public.patients p
      where p.id = payment_methods.patient_id
        and public.user_can_access_org(p.org_id)
        and exists (
          select 1
          from public.org_memberships m
          where m.org_id = p.org_id
            and m.user_id = (select auth.uid())
            and m.role in ('superadmin','org_admin','staff')
        )
    )
  )
  with check (
    exists (
      select 1
      from public.patients p
      where p.id = payment_methods.patient_id
        and public.user_can_access_org(p.org_id)
        and exists (
          select 1
          from public.org_memberships m
          where m.org_id = p.org_id
            and m.user_id = (select auth.uid())
            and m.role in ('superadmin','org_admin','staff')
        )
    )
  );

-- payments: Create _all policy
drop policy if exists payments_all on public.payments;
create policy payments_all on public.payments
  for all
  using (
    exists (
      select 1
      from public.invoices i
      where i.id = payments.invoice_id
        and public.user_can_access_org(i.org_id)
        and exists (
          select 1
          from public.org_memberships m
          where m.org_id = i.org_id
            and m.user_id = (select auth.uid())
            and m.role in ('superadmin','org_admin','staff')
        )
    )
  )
  with check (
    exists (
      select 1
      from public.invoices i
      where i.id = payments.invoice_id
        and public.user_can_access_org(i.org_id)
        and exists (
          select 1
          from public.org_memberships m
          where m.org_id = i.org_id
            and m.user_id = (select auth.uid())
            and m.role in ('superadmin','org_admin','staff')
        )
    )
  );

-- gift_cards: Create _all policy
drop policy if exists gift_cards_all on public.gift_cards;
create policy gift_cards_all on public.gift_cards
  for all
  using (
    public.user_can_access_org(org_id)
    and exists (
      select 1
      from public.org_memberships m
      where m.org_id = gift_cards.org_id
        and m.user_id = (select auth.uid())
        and m.role in ('superadmin','org_admin','staff')
    )
  )
  with check (
    public.user_can_access_org(org_id)
    and exists (
      select 1
      from public.org_memberships m
      where m.org_id = gift_cards.org_id
        and m.user_id = (select auth.uid())
        and m.role in ('superadmin','org_admin','staff')
    )
  );

-- roles: Create _all policy
drop policy if exists roles_all on public.roles;
create policy roles_all on public.roles
  for all
  using (
    public.user_can_access_org(org_id)
    and exists (
      select 1
      from public.org_memberships m
      where m.org_id = roles.org_id
        and m.user_id = (select auth.uid())
        and m.role in ('superadmin','org_admin')
    )
  )
  with check (
    public.user_can_access_org(org_id)
    and exists (
      select 1
      from public.org_memberships m
      where m.org_id = roles.org_id
        and m.user_id = (select auth.uid())
        and m.role in ('superadmin','org_admin')
    )
  );

-- permissions: Create _all policy (superadmin only)
drop policy if exists permissions_all on public.permissions;
create policy permissions_all on public.permissions
  for all
  using (
    exists (
      select 1
      from public.org_memberships m
      where m.user_id = (select auth.uid())
        and m.role = 'superadmin'
    )
  )
  with check (
    exists (
      select 1
      from public.org_memberships m
      where m.user_id = (select auth.uid())
        and m.role = 'superadmin'
    )
  );

-- role_permissions: Create _all policy
drop policy if exists role_permissions_all on public.role_permissions;
create policy role_permissions_all on public.role_permissions
  for all
  using (
    exists (
      select 1
      from public.roles r
      join public.org_memberships m on m.org_id = r.org_id
      where r.id = role_permissions.role_id
        and m.user_id = (select auth.uid())
        and m.role in ('superadmin','org_admin')
    )
  )
  with check (
    exists (
      select 1
      from public.roles r
      join public.org_memberships m on m.org_id = r.org_id
      where r.id = role_permissions.role_id
        and m.user_id = (select auth.uid())
        and m.role in ('superadmin','org_admin')
    )
  );

-- chat_threads: Create _all policy
drop policy if exists chat_threads_all on public.chat_threads;
create policy chat_threads_all on public.chat_threads
  for all
  using (
    public.user_in_chat(id)
  )
  with check (
    public.user_in_chat(id)
  );

-- chat_messages: Create _all policy
drop policy if exists chat_messages_all on public.chat_messages;
create policy chat_messages_all on public.chat_messages
  for all
  using (
    public.user_in_chat(thread_id)
  )
  with check (
    public.user_in_chat(thread_id)
  );

-- chat_thread_members: Create _all policy
drop policy if exists chat_thread_members_all on public.chat_thread_members;
create policy chat_thread_members_all on public.chat_thread_members
  for all
  using (
    public.user_in_chat(thread_id)
  )
  with check (
    public.user_in_chat(thread_id)
  );

-- treatment_plans: Create _all policy (already exists from 20251201220000, but ensure it's complete)
-- waitlists: Create _all policy (already exists from 20251201220000, but ensure it's complete)
-- operating_hours: Create _all policy (already exists from 20251201220000, but ensure it's complete)
-- time_intervals: Create _all policy (already exists from 20251201220000, but ensure it's complete)
-- rooms: Create _all policy
drop policy if exists rooms_all on public.rooms;
create policy rooms_all on public.rooms
  for all
  using (
    public.user_can_access_location(location_id)
    and exists (
      select 1
      from public.locations l
      join public.org_memberships m on m.org_id = l.org_id
      where l.id = rooms.location_id
        and m.user_id = (select auth.uid())
        and m.role in ('superadmin','org_admin','staff')
    )
  )
  with check (
    public.user_can_access_location(location_id)
    and exists (
      select 1
      from public.locations l
      join public.org_memberships m on m.org_id = l.org_id
      where l.id = rooms.location_id
        and m.user_id = (select auth.uid())
        and m.role in ('superadmin','org_admin','staff')
    )
  );

-- resources: Create _all policy
drop policy if exists resources_all on public.resources;
create policy resources_all on public.resources
  for all
  using (
    public.user_can_access_location(location_id)
    and exists (
      select 1
      from public.locations l
      join public.org_memberships m on m.org_id = l.org_id
      where l.id = resources.location_id
        and m.user_id = (select auth.uid())
        and m.role in ('superadmin','org_admin','staff')
    )
  )
  with check (
    public.user_can_access_location(location_id)
    and exists (
      select 1
      from public.locations l
      join public.org_memberships m on m.org_id = l.org_id
      where l.id = resources.location_id
        and m.user_id = (select auth.uid())
        and m.role in ('superadmin','org_admin','staff')
    )
  );

-- charts: Create _all policy
drop policy if exists charts_all on public.charts;
create policy charts_all on public.charts
  for all
  using (
    public.user_can_access_org(org_id)
    and exists (
      select 1
      from public.org_memberships m
      where m.org_id = charts.org_id
        and m.user_id = (select auth.uid())
        and m.role in ('superadmin','org_admin','staff')
    )
  )
  with check (
    public.user_can_access_org(org_id)
    and exists (
      select 1
      from public.org_memberships m
      where m.org_id = charts.org_id
        and m.user_id = (select auth.uid())
        and m.role in ('superadmin','org_admin','staff')
    )
  );

-- form_templates: Create _all policy
drop policy if exists form_templates_all on public.form_templates;
create policy form_templates_all on public.form_templates
  for all
  using (
    public.user_can_access_org(org_id)
    and exists (
      select 1
      from public.org_memberships m
      where m.org_id = form_templates.org_id
        and m.user_id = (select auth.uid())
        and m.role in ('superadmin','org_admin','staff')
    )
  )
  with check (
    public.user_can_access_org(org_id)
    and exists (
      select 1
      from public.org_memberships m
      where m.org_id = form_templates.org_id
        and m.user_id = (select auth.uid())
        and m.role in ('superadmin','org_admin','staff')
    )
  );

-- form_responses: Create _all policy
drop policy if exists form_responses_all on public.form_responses;
create policy form_responses_all on public.form_responses
  for all
  using (
    exists (
      select 1
      from public.charts c
      where c.id = form_responses.chart_id
        and public.user_can_access_org(c.org_id)
        and exists (
          select 1
          from public.org_memberships m
          where m.org_id = c.org_id
            and m.user_id = (select auth.uid())
            and m.role in ('superadmin','org_admin','staff')
        )
    )
  )
  with check (
    exists (
      select 1
      from public.charts c
      where c.id = form_responses.chart_id
        and public.user_can_access_org(c.org_id)
        and exists (
          select 1
          from public.org_memberships m
          where m.org_id = c.org_id
            and m.user_id = (select auth.uid())
            and m.role in ('superadmin','org_admin','staff')
        )
    )
  );

-- form_data: Create _all policy
drop policy if exists form_data_all on public.form_data;
create policy form_data_all on public.form_data
  for all
  using (
    exists (
      select 1
      from public.form_responses fr
      join public.charts c on c.id = fr.chart_id
      where fr.id = form_data.response_id
        and public.user_can_access_org(c.org_id)
        and exists (
          select 1
          from public.org_memberships m
          where m.org_id = c.org_id
            and m.user_id = (select auth.uid())
            and m.role in ('superadmin','org_admin','staff')
        )
    )
  )
  with check (
    exists (
      select 1
      from public.form_responses fr
      join public.charts c on c.id = fr.chart_id
      where fr.id = form_data.response_id
        and public.user_can_access_org(c.org_id)
        and exists (
          select 1
          from public.org_memberships m
          where m.org_id = c.org_id
            and m.user_id = (select auth.uid())
            and m.role in ('superadmin','org_admin','staff')
        )
    )
  );

-- form_details: Create _all policy
drop policy if exists form_details_all on public.form_details;
create policy form_details_all on public.form_details
  for all
  using (
    exists (
      select 1
      from public.form_templates ft
      where ft.id = form_details.template_id
        and public.user_can_access_org(ft.org_id)
        and exists (
          select 1
          from public.org_memberships m
          where m.org_id = ft.org_id
            and m.user_id = (select auth.uid())
            and m.role in ('superadmin','org_admin','staff')
        )
    )
  )
  with check (
    exists (
      select 1
      from public.form_templates ft
      where ft.id = form_details.template_id
        and public.user_can_access_org(ft.org_id)
        and exists (
          select 1
          from public.org_memberships m
          where m.org_id = ft.org_id
            and m.user_id = (select auth.uid())
            and m.role in ('superadmin','org_admin','staff')
        )
    )
  );

-- intake_forms: Create _all policy
drop policy if exists intake_forms_all on public.intake_forms;
create policy intake_forms_all on public.intake_forms
  for all
  using (
    exists (
      select 1
      from public.patients p
      where p.id = intake_forms.patient_id
        and public.user_can_access_org(p.org_id)
        and exists (
          select 1
          from public.org_memberships m
          where m.org_id = p.org_id
            and m.user_id = (select auth.uid())
            and m.role in ('superadmin','org_admin','staff')
        )
    )
  )
  with check (
    exists (
      select 1
      from public.patients p
      where p.id = intake_forms.patient_id
        and public.user_can_access_org(p.org_id)
        and exists (
          select 1
          from public.org_memberships m
          where m.org_id = p.org_id
            and m.user_id = (select auth.uid())
            and m.role in ('superadmin','org_admin','staff')
        )
    )
  );

-- insurers: Create _all policy (global table, superadmin/org_admin only)
drop policy if exists insurers_all on public.insurers;
create policy insurers_all on public.insurers
  for all
  using (
    exists (
      select 1
      from public.org_memberships m
      where m.user_id = (select auth.uid())
        and m.role in ('superadmin','org_admin')
    )
  )
  with check (
    exists (
      select 1
      from public.org_memberships m
      where m.user_id = (select auth.uid())
        and m.role in ('superadmin','org_admin')
    )
  );

-- insurance_plans: Create _all policy (global table, superadmin/org_admin only)
drop policy if exists insurance_plans_all on public.insurance_plans;
create policy insurance_plans_all on public.insurance_plans
  for all
  using (
    exists (
      select 1
      from public.org_memberships m
      where m.user_id = (select auth.uid())
        and m.role in ('superadmin','org_admin')
    )
  )
  with check (
    exists (
      select 1
      from public.org_memberships m
      where m.user_id = (select auth.uid())
        and m.role in ('superadmin','org_admin')
    )
  );

-- user_insurance: Create _all policy
drop policy if exists user_insurance_all on public.user_insurance;
create policy user_insurance_all on public.user_insurance
  for all
  using (
    (select auth.uid()) = user_id
    or exists (
      select 1
      from public.org_memberships m
      where m.user_id = (select auth.uid())
        and m.role in ('superadmin','org_admin','staff')
    )
  )
  with check (
    (select auth.uid()) = user_id
    or exists (
      select 1
      from public.org_memberships m
      where m.user_id = (select auth.uid())
        and m.role in ('superadmin','org_admin','staff')
    )
  );

-- patient_insurance: Create _all policy
drop policy if exists patient_insurance_all on public.patient_insurance;
create policy patient_insurance_all on public.patient_insurance
  for all
  using (
    exists (
      select 1
      from public.patients p
      where p.id = patient_insurance.patient_id
        and public.user_can_access_org(p.org_id)
        and exists (
          select 1
          from public.org_memberships m
          where m.org_id = p.org_id
            and m.user_id = (select auth.uid())
            and m.role in ('superadmin','org_admin','staff')
        )
    )
  )
  with check (
    exists (
      select 1
      from public.patients p
      where p.id = patient_insurance.patient_id
        and public.user_can_access_org(p.org_id)
        and exists (
          select 1
          from public.org_memberships m
          where m.org_id = p.org_id
            and m.user_id = (select auth.uid())
            and m.role in ('superadmin','org_admin','staff')
        )
    )
  );

-- provider_insurance: Create _all policy
drop policy if exists provider_insurance_all on public.provider_insurance;
create policy provider_insurance_all on public.provider_insurance
  for all
  using (
    exists (
      select 1
      from public.staff_members s
      where s.id = provider_insurance.staff_id
        and public.user_can_access_org(s.org_id)
        and exists (
          select 1
          from public.org_memberships m
          where m.org_id = s.org_id
            and m.user_id = (select auth.uid())
            and m.role in ('superadmin','org_admin','staff')
        )
    )
  )
  with check (
    exists (
      select 1
      from public.staff_members s
      where s.id = provider_insurance.staff_id
        and public.user_can_access_org(s.org_id)
        and exists (
          select 1
          from public.org_memberships m
          where m.org_id = s.org_id
            and m.user_id = (select auth.uid())
            and m.role in ('superadmin','org_admin','staff')
        )
    )
  );

-- claims: Create _all policy
drop policy if exists claims_all on public.claims;
create policy claims_all on public.claims
  for all
  using (
    public.user_can_access_org(org_id)
    and exists (
      select 1
      from public.org_memberships m
      where m.org_id = claims.org_id
        and m.user_id = (select auth.uid())
        and m.role in ('superadmin','org_admin','staff')
    )
  )
  with check (
    public.user_can_access_org(org_id)
    and exists (
      select 1
      from public.org_memberships m
      where m.org_id = claims.org_id
        and m.user_id = (select auth.uid())
        and m.role in ('superadmin','org_admin','staff')
    )
  );

-- claim_items: Create _all policy
drop policy if exists claim_items_all on public.claim_items;
create policy claim_items_all on public.claim_items
  for all
  using (
    exists (
      select 1
      from public.claims c
      where c.id = claim_items.claim_id
        and public.user_can_access_org(c.org_id)
        and exists (
          select 1
          from public.org_memberships m
          where m.org_id = c.org_id
            and m.user_id = (select auth.uid())
            and m.role in ('superadmin','org_admin','staff')
        )
    )
  )
  with check (
    exists (
      select 1
      from public.claims c
      where c.id = claim_items.claim_id
        and public.user_can_access_org(c.org_id)
        and exists (
          select 1
          from public.org_memberships m
          where m.org_id = c.org_id
            and m.user_id = (select auth.uid())
            and m.role in ('superadmin','org_admin','staff')
        )
    )
  );

-- claim_payments: Create _all policy
drop policy if exists claim_payments_all on public.claim_payments;
create policy claim_payments_all on public.claim_payments
  for all
  using (
    exists (
      select 1
      from public.claims c
      where c.id = claim_payments.claim_id
        and public.user_can_access_org(c.org_id)
        and exists (
          select 1
          from public.org_memberships m
          where m.org_id = c.org_id
            and m.user_id = (select auth.uid())
            and m.role in ('superadmin','org_admin','staff')
        )
    )
  )
  with check (
    exists (
      select 1
      from public.claims c
      where c.id = claim_payments.claim_id
        and public.user_can_access_org(c.org_id)
        and exists (
          select 1
          from public.org_memberships m
          where m.org_id = c.org_id
            and m.user_id = (select auth.uid())
            and m.role in ('superadmin','org_admin','staff')
        )
    )
  );

-- eligibility_checks: Create _all policy
drop policy if exists eligibility_checks_all on public.eligibility_checks;
create policy eligibility_checks_all on public.eligibility_checks
  for all
  using (
    public.user_can_access_org(org_id)
    and exists (
      select 1
      from public.org_memberships m
      where m.org_id = eligibility_checks.org_id
        and m.user_id = (select auth.uid())
        and m.role in ('superadmin','org_admin','staff')
    )
  )
  with check (
    public.user_can_access_org(org_id)
    and exists (
      select 1
      from public.org_memberships m
      where m.org_id = eligibility_checks.org_id
        and m.user_id = (select auth.uid())
        and m.role in ('superadmin','org_admin','staff')
    )
  );

-- pre_authorizations: Create _all policy
drop policy if exists pre_authorizations_all on public.pre_authorizations;
create policy pre_authorizations_all on public.pre_authorizations
  for all
  using (
    public.user_can_access_org(org_id)
    and exists (
      select 1
      from public.org_memberships m
      where m.org_id = pre_authorizations.org_id
        and m.user_id = (select auth.uid())
        and m.role in ('superadmin','org_admin','staff')
    )
  )
  with check (
    public.user_can_access_org(org_id)
    and exists (
      select 1
      from public.org_memberships m
      where m.org_id = pre_authorizations.org_id
        and m.user_id = (select auth.uid())
        and m.role in ('superadmin','org_admin','staff')
    )
  );

-- insurance_documents: Create _all policy
drop policy if exists insurance_documents_all on public.insurance_documents;
create policy insurance_documents_all on public.insurance_documents
  for all
  using (
    exists (
      select 1
      from public.claims c
      where c.id = insurance_documents.claim_id
        and public.user_can_access_org(c.org_id)
        and exists (
          select 1
          from public.org_memberships m
          where m.org_id = c.org_id
            and m.user_id = (select auth.uid())
            and m.role in ('superadmin','org_admin','staff')
        )
    )
  )
  with check (
    exists (
      select 1
      from public.claims c
      where c.id = insurance_documents.claim_id
        and public.user_can_access_org(c.org_id)
        and exists (
          select 1
          from public.org_memberships m
          where m.org_id = c.org_id
            and m.user_id = (select auth.uid())
            and m.role in ('superadmin','org_admin','staff')
        )
    )
  );

-- booking_policy_presets: Create _all policy (global table, superadmin/org_admin only)
drop policy if exists booking_policy_presets_all on public.booking_policy_presets;
create policy booking_policy_presets_all on public.booking_policy_presets
  for all
  using (
    exists (
      select 1
      from public.org_memberships m
      where m.user_id = (select auth.uid())
        and m.role in ('superadmin','org_admin')
    )
  )
  with check (
    exists (
      select 1
      from public.org_memberships m
      where m.user_id = (select auth.uid())
        and m.role in ('superadmin','org_admin')
    )
  );

-- booking_policies: Create _all policy
drop policy if exists booking_policies_all on public.booking_policies;
create policy booking_policies_all on public.booking_policies
  for all
  using (
    public.user_can_access_org(org_id)
    and exists (
      select 1
      from public.org_memberships m
      where m.org_id = booking_policies.org_id
        and m.user_id = (select auth.uid())
        and m.role in ('superadmin','org_admin')
    )
  )
  with check (
    public.user_can_access_org(org_id)
    and exists (
      select 1
      from public.org_memberships m
      where m.org_id = booking_policies.org_id
        and m.user_id = (select auth.uid())
        and m.role in ('superadmin','org_admin')
    )
  );

-- booking_portals: Create _all policy
drop policy if exists booking_portals_all on public.booking_portals;
create policy booking_portals_all on public.booking_portals
  for all
  using (
    public.user_can_access_org(org_id)
    and exists (
      select 1
      from public.org_memberships m
      where m.org_id = booking_portals.org_id
        and m.user_id = (select auth.uid())
        and m.role in ('superadmin','org_admin')
    )
  )
  with check (
    public.user_can_access_org(org_id)
    and exists (
      select 1
      from public.org_memberships m
      where m.org_id = booking_portals.org_id
        and m.user_id = (select auth.uid())
        and m.role in ('superadmin','org_admin')
    )
  );

-- discipline_offerings: Create _all policy
drop policy if exists discipline_offerings_all on public.discipline_offerings;
create policy discipline_offerings_all on public.discipline_offerings
  for all
  using (
    public.user_can_access_org(org_id)
    and exists (
      select 1
      from public.org_memberships m
      where m.org_id = discipline_offerings.org_id
        and m.user_id = (select auth.uid())
        and m.role in ('superadmin','org_admin','staff')
    )
  )
  with check (
    public.user_can_access_org(org_id)
    and exists (
      select 1
      from public.org_memberships m
      where m.org_id = discipline_offerings.org_id
        and m.user_id = (select auth.uid())
        and m.role in ('superadmin','org_admin','staff')
    )
  );

-- service_offerings: Create _all policy
drop policy if exists service_offerings_all on public.service_offerings;
create policy service_offerings_all on public.service_offerings
  for all
  using (
    public.user_can_access_org(org_id)
    and exists (
      select 1
      from public.org_memberships m
      where m.org_id = service_offerings.org_id
        and m.user_id = (select auth.uid())
        and m.role in ('superadmin','org_admin','staff')
    )
  )
  with check (
    public.user_can_access_org(org_id)
    and exists (
      select 1
      from public.org_memberships m
      where m.org_id = service_offerings.org_id
        and m.user_id = (select auth.uid())
        and m.role in ('superadmin','org_admin','staff')
    )
  );

-- item_prices: Create _all policy
drop policy if exists item_prices_all on public.item_prices;
create policy item_prices_all on public.item_prices
  for all
  using (
    exists (
      select 1
      from public.items_catalog ic
      where ic.id = item_prices.item_id
        and public.user_can_access_org(ic.org_id)
        and exists (
          select 1
          from public.org_memberships m
          where m.org_id = ic.org_id
            and m.user_id = (select auth.uid())
            and m.role in ('superadmin','org_admin','staff')
        )
    )
  )
  with check (
    exists (
      select 1
      from public.items_catalog ic
      where ic.id = item_prices.item_id
        and public.user_can_access_org(ic.org_id)
        and exists (
          select 1
          from public.org_memberships m
          where m.org_id = ic.org_id
            and m.user_id = (select auth.uid())
            and m.role in ('superadmin','org_admin','staff')
        )
    )
  );

-- items_catalog: Create _all policy
drop policy if exists items_catalog_all on public.items_catalog;
create policy items_catalog_all on public.items_catalog
  for all
  using (
    public.user_can_access_org(org_id)
    and exists (
      select 1
      from public.org_memberships m
      where m.org_id = items_catalog.org_id
        and m.user_id = (select auth.uid())
        and m.role in ('superadmin','org_admin','staff')
    )
  )
  with check (
    public.user_can_access_org(org_id)
    and exists (
      select 1
      from public.org_memberships m
      where m.org_id = items_catalog.org_id
        and m.user_id = (select auth.uid())
        and m.role in ('superadmin','org_admin','staff')
    )
  );

-- service_details: Create _all policy
drop policy if exists service_details_all on public.service_details;
create policy service_details_all on public.service_details
  for all
  using (
    exists (
      select 1
      from public.items_catalog ic
      where ic.id = service_details.item_id
        and public.user_can_access_org(ic.org_id)
        and exists (
          select 1
          from public.org_memberships m
          where m.org_id = ic.org_id
            and m.user_id = (select auth.uid())
            and m.role in ('superadmin','org_admin','staff')
        )
    )
  )
  with check (
    exists (
      select 1
      from public.items_catalog ic
      where ic.id = service_details.item_id
        and public.user_can_access_org(ic.org_id)
        and exists (
          select 1
          from public.org_memberships m
          where m.org_id = ic.org_id
            and m.user_id = (select auth.uid())
            and m.role in ('superadmin','org_admin','staff')
        )
    )
  );

-- product_details: Create _all policy
drop policy if exists product_details_all on public.product_details;
create policy product_details_all on public.product_details
  for all
  using (
    exists (
      select 1
      from public.items_catalog ic
      where ic.id = product_details.item_id
        and public.user_can_access_org(ic.org_id)
        and exists (
          select 1
          from public.org_memberships m
          where m.org_id = ic.org_id
            and m.user_id = (select auth.uid())
            and m.role in ('superadmin','org_admin','staff')
        )
    )
  )
  with check (
    exists (
      select 1
      from public.items_catalog ic
      where ic.id = product_details.item_id
        and public.user_can_access_org(ic.org_id)
        and exists (
          select 1
          from public.org_memberships m
          where m.org_id = ic.org_id
            and m.user_id = (select auth.uid())
            and m.role in ('superadmin','org_admin','staff')
        )
    )
  );

-- income_categories: Create _all policy
drop policy if exists income_categories_all on public.income_categories;
create policy income_categories_all on public.income_categories
  for all
  using (
    exists (
      select 1
      from public.items_catalog ic
      where ic.id = income_categories.item_id
        and public.user_can_access_org(ic.org_id)
        and exists (
          select 1
          from public.org_memberships m
          where m.org_id = ic.org_id
            and m.user_id = (select auth.uid())
            and m.role in ('superadmin','org_admin','staff')
        )
    )
  )
  with check (
    exists (
      select 1
      from public.items_catalog ic
      where ic.id = income_categories.item_id
        and public.user_can_access_org(ic.org_id)
        and exists (
          select 1
          from public.org_memberships m
          where m.org_id = ic.org_id
            and m.user_id = (select auth.uid())
            and m.role in ('superadmin','org_admin','staff')
        )
    )
  );

-- suppliers: Create _all policy
drop policy if exists suppliers_all on public.suppliers;
create policy suppliers_all on public.suppliers
  for all
  using (
    exists (
      select 1
      from public.items_catalog ic
      where ic.id = suppliers.item_id
        and public.user_can_access_org(ic.org_id)
        and exists (
          select 1
          from public.org_memberships m
          where m.org_id = ic.org_id
            and m.user_id = (select auth.uid())
            and m.role in ('superadmin','org_admin','staff')
        )
    )
  )
  with check (
    exists (
      select 1
      from public.items_catalog ic
      where ic.id = suppliers.item_id
        and public.user_can_access_org(ic.org_id)
        and exists (
          select 1
          from public.org_memberships m
          where m.org_id = ic.org_id
            and m.user_id = (select auth.uid())
            and m.role in ('superadmin','org_admin','staff')
        )
    )
  );

-- product_inventory: Create _all policy
drop policy if exists product_inventory_all on public.product_inventory;
create policy product_inventory_all on public.product_inventory
  for all
  using (
    exists (
      select 1
      from public.items_catalog ic
      left join public.locations l on l.id = product_inventory.location_id
      where ic.id = product_inventory.product_id
        and (
          (product_inventory.location_id is null and public.user_can_access_org(ic.org_id))
          or (product_inventory.location_id is not null and public.user_can_access_location(product_inventory.location_id))
        )
        and exists (
          select 1
          from public.org_memberships m
          where m.org_id = coalesce(l.org_id, ic.org_id)
            and m.user_id = (select auth.uid())
            and m.role in ('superadmin','org_admin','staff')
        )
    )
  )
  with check (
    exists (
      select 1
      from public.items_catalog ic
      left join public.locations l on l.id = product_inventory.location_id
      where ic.id = product_inventory.product_id
        and (
          (product_inventory.location_id is null and public.user_can_access_org(ic.org_id))
          or (product_inventory.location_id is not null and public.user_can_access_location(product_inventory.location_id))
        )
        and exists (
          select 1
          from public.org_memberships m
          where m.org_id = coalesce(l.org_id, ic.org_id)
            and m.user_id = (select auth.uid())
            and m.role in ('superadmin','org_admin','staff')
        )
    )
  );

-- location_taxes: Create _all policy
drop policy if exists location_taxes_all on public.location_taxes;
create policy location_taxes_all on public.location_taxes
  for all
  using (
    public.user_can_access_location(location_id)
    and exists (
      select 1
      from public.locations l
      join public.org_memberships m on m.org_id = l.org_id
      where l.id = location_taxes.location_id
        and m.user_id = (select auth.uid())
        and m.role in ('superadmin','org_admin')
    )
  )
  with check (
    public.user_can_access_location(location_id)
    and exists (
      select 1
      from public.locations l
      join public.org_memberships m on m.org_id = l.org_id
      where l.id = location_taxes.location_id
        and m.user_id = (select auth.uid())
        and m.role in ('superadmin','org_admin')
    )
  );

-- presence: Create _all policy
drop policy if exists presence_all on public.presence;
create policy presence_all on public.presence
  for all
  using (
    public.user_can_access_org(org_id)
    and (
      (select auth.uid()) = user_id
      or exists (
        select 1
        from public.org_memberships m
        where m.org_id = presence.org_id
          and m.user_id = (select auth.uid())
          and m.role in ('superadmin','org_admin','staff')
      )
    )
  )
  with check (
    public.user_can_access_org(org_id)
    and (
      (select auth.uid()) = user_id
      or exists (
        select 1
        from public.org_memberships m
        where m.org_id = presence.org_id
          and m.user_id = (select auth.uid())
          and m.role in ('superadmin','org_admin','staff')
      )
    )
  );

-- orgs: Create _all policy (but keep orgs_insert for service_role)
drop policy if exists orgs_all on public.orgs;
create policy orgs_all on public.orgs
  for all
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

-- Note: orgs_insert is kept separate for service_role access (from initial schema)

