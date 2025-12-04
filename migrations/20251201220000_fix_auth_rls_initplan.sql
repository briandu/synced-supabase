-- Fix auth_rls_initplan performance warnings
-- Replace direct auth.uid() calls with (select auth.uid()) to prevent re-evaluation per row
-- This improves query performance at scale by evaluating auth.uid() once per query instead of once per row

-- ============================================================================
-- Initial Schema Policies (20250101000000_initial_schema.sql)
-- ============================================================================

-- profiles: self-select and self-update
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

-- org_memberships
drop policy if exists org_memberships_select on public.org_memberships;
drop policy if exists org_memberships_modify on public.org_memberships;
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
create policy org_memberships_modify on public.org_memberships
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

-- ============================================================================
-- RLS Tighten Core Policies (20251128180000_rls_tighten_core.sql)
-- ============================================================================

-- org_staff_invites
drop policy if exists org_staff_invites_modify on public.org_staff_invites;
create policy org_staff_invites_modify on public.org_staff_invites
  for all
  using (
    public.user_can_access_org(org_id)
    and exists (
      select 1
      from public.org_memberships m
      where m.org_id = org_staff_invites.org_id
        and m.user_id = (select auth.uid())
        and m.role in ('superadmin','org_admin')
    )
  )
  with check (
    public.user_can_access_org(org_id)
    and exists (
      select 1
      from public.org_memberships m
      where m.org_id = org_staff_invites.org_id
        and m.user_id = (select auth.uid())
        and m.role in ('superadmin','org_admin')
    )
  );

-- org_join_requests
drop policy if exists org_join_requests_modify on public.org_join_requests;
create policy org_join_requests_modify on public.org_join_requests
  for all
  using (
    public.user_can_access_org(org_id)
    and exists (
      select 1
      from public.org_memberships m
      where m.org_id = org_join_requests.org_id
        and m.user_id = (select auth.uid())
        and m.role in ('superadmin','org_admin')
    )
  )
  with check (
    public.user_can_access_org(org_id)
    and exists (
      select 1
      from public.org_memberships m
      where m.org_id = org_join_requests.org_id
        and m.user_id = (select auth.uid())
        and m.role in ('superadmin','org_admin')
    )
  );

-- patients
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

-- patient_notes
drop policy if exists patient_notes_all on public.patient_notes;
create policy patient_notes_all on public.patient_notes
  for all
  using (
    public.user_can_access_org(org_id)
    and exists (
      select 1
      from public.org_memberships m
      where m.org_id = patient_notes.org_id
        and m.user_id = (select auth.uid())
        and m.role in ('superadmin','org_admin','staff')
    )
  )
  with check (
    public.user_can_access_org(org_id)
    and exists (
      select 1
      from public.org_memberships m
      where m.org_id = patient_notes.org_id
        and m.user_id = (select auth.uid())
        and m.role in ('superadmin','org_admin','staff')
    )
  );

-- patient_relationships
drop policy if exists patient_relationships_all on public.patient_relationships;
create policy patient_relationships_all on public.patient_relationships
  for all
  using (
    public.user_can_access_org(org_id)
    and exists (
      select 1
      from public.org_memberships m
      where m.org_id = patient_relationships.org_id
        and m.user_id = (select auth.uid())
        and m.role in ('superadmin','org_admin','staff')
    )
  )
  with check (
    public.user_can_access_org(org_id)
    and exists (
      select 1
      from public.org_memberships m
      where m.org_id = patient_relationships.org_id
        and m.user_id = (select auth.uid())
        and m.role in ('superadmin','org_admin','staff')
    )
  );

-- patient_consents
drop policy if exists patient_consents_all on public.patient_consents;
create policy patient_consents_all on public.patient_consents
  for all
  using (
    public.user_can_access_org(org_id)
    and exists (
      select 1
      from public.org_memberships m
      where m.org_id = patient_consents.org_id
        and m.user_id = (select auth.uid())
        and m.role in ('superadmin','org_admin','staff')
    )
  )
  with check (
    public.user_can_access_org(org_id)
    and exists (
      select 1
      from public.org_memberships m
      where m.org_id = patient_consents.org_id
        and m.user_id = (select auth.uid())
        and m.role in ('superadmin','org_admin','staff')
    )
  );

-- appointments
drop policy if exists appointments_all on public.appointments;
create policy appointments_all on public.appointments
  for all
  using (
    public.user_can_access_org(org_id)
    and (
      exists (
        select 1
        from public.org_memberships m
        where m.org_id = appointments.org_id
          and m.user_id = (select auth.uid())
          and m.role in ('superadmin','org_admin')
      )
      or exists (
        select 1
        from public.staff_members sm
        where sm.id = appointments.staff_id
          and sm.user_id = (select auth.uid())
      )
    )
  )
  with check (
    public.user_can_access_org(org_id)
    and (
      exists (
        select 1
        from public.org_memberships m
        where m.org_id = appointments.org_id
          and m.user_id = (select auth.uid())
          and m.role in ('superadmin','org_admin')
      )
      or exists (
        select 1
        from public.staff_members sm
        where sm.id = appointments.staff_id
          and sm.user_id = (select auth.uid())
      )
    )
  );

-- availability_blocks
drop policy if exists availability_blocks_all on public.availability_blocks;
create policy availability_blocks_all on public.availability_blocks
  for all
  using (
    public.user_can_access_org(org_id)
    and (
      exists (
        select 1
        from public.org_memberships m
        where m.org_id = availability_blocks.org_id
          and m.user_id = (select auth.uid())
          and m.role in ('superadmin','org_admin')
      )
      or exists (
        select 1
        from public.staff_members sm
        where sm.id = availability_blocks.staff_id
          and sm.user_id = (select auth.uid())
      )
    )
  )
  with check (
    public.user_can_access_org(org_id)
    and (
      exists (
        select 1
        from public.org_memberships m
        where m.org_id = availability_blocks.org_id
          and m.user_id = (select auth.uid())
          and m.role in ('superadmin','org_admin')
      )
      or exists (
        select 1
        from public.staff_members sm
        where sm.id = availability_blocks.staff_id
          and sm.user_id = (select auth.uid())
      )
    )
  );

-- staff_shifts
drop policy if exists staff_shifts_all on public.staff_shifts;
create policy staff_shifts_all on public.staff_shifts
  for all
  using (
    (
      exists (
        select 1
        from public.staff_members sm
        where sm.id = staff_shifts.staff_id
          and sm.user_id = (select auth.uid())
          and public.user_can_access_org(sm.org_id)
      )
      or exists (
        select 1
        from public.org_memberships m
        join public.staff_members sm on sm.org_id = m.org_id
        where sm.id = staff_shifts.staff_id
          and m.user_id = (select auth.uid())
          and m.role in ('superadmin','org_admin')
      )
    )
    and (location_id is null or public.user_can_access_location(location_id))
  )
  with check (
    (
      exists (
        select 1
        from public.staff_members sm
        where sm.id = staff_shifts.staff_id
          and sm.user_id = (select auth.uid())
          and public.user_can_access_org(sm.org_id)
      )
      or exists (
        select 1
        from public.org_memberships m
        join public.staff_members sm on sm.org_id = m.org_id
        where sm.id = staff_shifts.staff_id
          and m.user_id = (select auth.uid())
          and m.role in ('superadmin','org_admin')
      )
    )
    and (location_id is null or public.user_can_access_location(location_id))
  );

-- staff_breaks
drop policy if exists staff_breaks_all on public.staff_breaks;
create policy staff_breaks_all on public.staff_breaks
  for all
  using (
    (
      exists (
        select 1
        from public.staff_members sm
        where sm.id = staff_breaks.staff_id
          and sm.user_id = (select auth.uid())
          and public.user_can_access_org(sm.org_id)
      )
      or exists (
        select 1
        from public.org_memberships m
        join public.staff_members sm on sm.org_id = m.org_id
        where sm.id = staff_breaks.staff_id
          and m.user_id = (select auth.uid())
          and m.role in ('superadmin','org_admin')
      )
    )
  )
  with check (
    (
      exists (
        select 1
        from public.staff_members sm
        where sm.id = staff_breaks.staff_id
          and sm.user_id = (select auth.uid())
          and public.user_can_access_org(sm.org_id)
      )
      or exists (
        select 1
        from public.org_memberships m
        join public.staff_members sm on sm.org_id = m.org_id
        where sm.id = staff_breaks.staff_id
          and m.user_id = (select auth.uid())
          and m.role in ('superadmin','org_admin')
      )
    )
  );

-- staff_time_off
drop policy if exists staff_time_off_all on public.staff_time_off;
create policy staff_time_off_all on public.staff_time_off
  for all
  using (
    (
      exists (
        select 1
        from public.staff_members sm
        where sm.id = staff_time_off.staff_id
          and sm.user_id = (select auth.uid())
          and public.user_can_access_org(sm.org_id)
      )
      or exists (
        select 1
        from public.org_memberships m
        join public.staff_members sm on sm.org_id = m.org_id
        where sm.id = staff_time_off.staff_id
          and m.user_id = (select auth.uid())
          and m.role in ('superadmin','org_admin')
      )
    )
  )
  with check (
    (
      exists (
        select 1
        from public.staff_members sm
        where sm.id = staff_time_off.staff_id
          and sm.user_id = (select auth.uid())
          and public.user_can_access_org(sm.org_id)
      )
      or exists (
        select 1
        from public.org_memberships m
        join public.staff_members sm on sm.org_id = m.org_id
        where sm.id = staff_time_off.staff_id
          and m.user_id = (select auth.uid())
          and m.role in ('superadmin','org_admin')
      )
    )
  );

-- staff_tasks
drop policy if exists staff_tasks_all on public.staff_tasks;
create policy staff_tasks_all on public.staff_tasks
  for all
  using (
    public.user_can_access_org(org_id)
    and exists (
      select 1
      from public.org_memberships m
      where m.org_id = staff_tasks.org_id
        and m.user_id = (select auth.uid())
        and m.role in ('superadmin','org_admin','staff')
    )
  )
  with check (
    public.user_can_access_org(org_id)
    and exists (
      select 1
      from public.org_memberships m
      where m.org_id = staff_tasks.org_id
        and m.user_id = (select auth.uid())
        and m.role in ('superadmin','org_admin','staff')
    )
  );

-- staff_notifications
drop policy if exists staff_notifications_all on public.staff_notifications;
create policy staff_notifications_all on public.staff_notifications
  for all
  using (
    public.user_can_access_org(org_id)
    and (
      exists (
        select 1
        from public.org_memberships m
        where m.org_id = staff_notifications.org_id
          and m.user_id = (select auth.uid())
          and m.role in ('superadmin','org_admin')
      )
      or exists (
        select 1
        from public.staff_members sm
        where sm.id = staff_notifications.staff_id
          and sm.user_id = (select auth.uid())
      )
    )
  )
  with check (
    public.user_can_access_org(org_id)
    and (
      exists (
        select 1
        from public.org_memberships m
        where m.org_id = staff_notifications.org_id
          and m.user_id = (select auth.uid())
          and m.role in ('superadmin','org_admin')
      )
      or exists (
        select 1
        from public.staff_members sm
        where sm.id = staff_notifications.staff_id
          and sm.user_id = (select auth.uid())
      )
    )
  );

-- patient_notifications
drop policy if exists patient_notifications_all on public.patient_notifications;
create policy patient_notifications_all on public.patient_notifications
  for all
  using (
    public.user_can_access_org(org_id)
    and (
      exists (
        select 1
        from public.org_memberships m
        where m.org_id = patient_notifications.org_id
          and m.user_id = (select auth.uid())
          and m.role in ('superadmin','org_admin')
      )
      or exists (
        select 1
        from public.patients p
        where p.id = patient_notifications.patient_id
          and p.patient_user_id = (select auth.uid())
      )
    )
  )
  with check (
    public.user_can_access_org(org_id)
    and (
      exists (
        select 1
        from public.org_memberships m
        where m.org_id = patient_notifications.org_id
          and m.user_id = (select auth.uid())
          and m.role in ('superadmin','org_admin')
      )
      or exists (
        select 1
        from public.patients p
        where p.id = patient_notifications.patient_id
          and p.patient_user_id = (select auth.uid())
      )
    )
  );

-- staff_permissions
drop policy if exists staff_permissions_select on public.staff_permissions;
drop policy if exists staff_permissions_modify on public.staff_permissions;
create policy staff_permissions_select on public.staff_permissions
  for select
  using (
    exists (
      select 1
      from public.staff_members sm
      where sm.id = staff_permissions.staff_id
        and public.user_can_access_org(sm.org_id)
        and (
          sm.user_id = (select auth.uid())
          or exists (
            select 1
            from public.org_memberships m
            where m.org_id = sm.org_id
              and m.user_id = (select auth.uid())
          )
        )
    )
  );
create policy staff_permissions_modify on public.staff_permissions
  for all
  using (
    exists (
      select 1
      from public.staff_members sm
      where sm.id = staff_permissions.staff_id
        and public.user_can_access_org(sm.org_id)
        and exists (
          select 1
          from public.org_memberships m
          where m.org_id = sm.org_id
            and m.user_id = (select auth.uid())
            and m.role in ('superadmin','org_admin')
        )
    )
  )
  with check (
    exists (
      select 1
      from public.staff_members sm
      where sm.id = staff_permissions.staff_id
        and public.user_can_access_org(sm.org_id)
        and exists (
          select 1
          from public.org_memberships m
          where m.org_id = sm.org_id
            and m.user_id = (select auth.uid())
            and m.role in ('superadmin','org_admin')
        )
    )
  );

-- disciplines
drop policy if exists disciplines_modify on public.disciplines;
create policy disciplines_modify on public.disciplines
  for all
  using (
    public.user_can_access_org(org_id)
    and exists (
      select 1
      from public.org_memberships m
      where m.org_id = disciplines.org_id
        and m.user_id = (select auth.uid())
        and m.role in ('superadmin','org_admin')
    )
  )
  with check (
    public.user_can_access_org(org_id)
    and exists (
      select 1
      from public.org_memberships m
      where m.org_id = disciplines.org_id
        and m.user_id = (select auth.uid())
        and m.role in ('superadmin','org_admin')
    )
  );

-- services
drop policy if exists services_modify on public.services;
create policy services_modify on public.services
  for all
  using (
    public.user_can_access_org(org_id)
    and exists (
      select 1
      from public.org_memberships m
      where m.org_id = services.org_id
        and m.user_id = (select auth.uid())
        and m.role in ('superadmin','org_admin')
    )
  )
  with check (
    public.user_can_access_org(org_id)
    and exists (
      select 1
      from public.org_memberships m
      where m.org_id = services.org_id
        and m.user_id = (select auth.uid())
        and m.role in ('superadmin','org_admin')
    )
  );

-- credit_memos
drop policy if exists credit_memos_modify on public.credit_memos;
create policy credit_memos_modify on public.credit_memos
  for all
  using (
    public.user_can_access_org(org_id)
    and exists (
      select 1
      from public.org_memberships m
      where m.org_id = credit_memos.org_id
        and m.user_id = (select auth.uid())
        and m.role in ('superadmin','org_admin')
    )
  )
  with check (
    public.user_can_access_org(org_id)
    and exists (
      select 1
      from public.org_memberships m
      where m.org_id = credit_memos.org_id
        and m.user_id = (select auth.uid())
        and m.role in ('superadmin','org_admin')
    )
  );

-- discounts
drop policy if exists discounts_modify on public.discounts;
create policy discounts_modify on public.discounts
  for all
  using (
    public.user_can_access_org(org_id)
    and exists (
      select 1
      from public.org_memberships m
      where m.org_id = discounts.org_id
        and m.user_id = (select auth.uid())
        and m.role in ('superadmin','org_admin')
    )
  )
  with check (
    public.user_can_access_org(org_id)
    and exists (
      select 1
      from public.org_memberships m
      where m.org_id = discounts.org_id
        and m.user_id = (select auth.uid())
        and m.role in ('superadmin','org_admin')
    )
  );

-- taxes
drop policy if exists taxes_modify on public.taxes;
create policy taxes_modify on public.taxes
  for all
  using (
    public.user_can_access_org(org_id)
    and exists (
      select 1
      from public.org_memberships m
      where m.org_id = taxes.org_id
        and m.user_id = (select auth.uid())
        and m.role in ('superadmin','org_admin')
    )
  )
  with check (
    public.user_can_access_org(org_id)
    and exists (
      select 1
      from public.org_memberships m
      where m.org_id = taxes.org_id
        and m.user_id = (select auth.uid())
        and m.role in ('superadmin','org_admin')
    )
  );

-- fees
drop policy if exists fees_modify on public.fees;
create policy fees_modify on public.fees
  for all
  using (
    public.user_can_access_org(org_id)
    and exists (
      select 1
      from public.org_memberships m
      where m.org_id = fees.org_id
        and m.user_id = (select auth.uid())
        and m.role in ('superadmin','org_admin')
    )
  )
  with check (
    public.user_can_access_org(org_id)
    and exists (
      select 1
      from public.org_memberships m
      where m.org_id = fees.org_id
        and m.user_id = (select auth.uid())
        and m.role in ('superadmin','org_admin')
    )
  );

-- transactions
drop policy if exists transactions_modify on public.transactions;
create policy transactions_modify on public.transactions
  for all
  using (
    public.user_can_access_org(org_id)
    and exists (
      select 1
      from public.org_memberships m
      where m.org_id = transactions.org_id
        and m.user_id = (select auth.uid())
        and m.role in ('superadmin','org_admin')
    )
  )
  with check (
    public.user_can_access_org(org_id)
    and exists (
      select 1
      from public.org_memberships m
      where m.org_id = transactions.org_id
        and m.user_id = (select auth.uid())
        and m.role in ('superadmin','org_admin')
    )
  );

-- permissions
drop policy if exists permissions_modify on public.permissions;
create policy permissions_modify on public.permissions
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

-- role_permissions
drop policy if exists role_permissions_modify on public.role_permissions;
create policy role_permissions_modify on public.role_permissions
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

-- onesignal_devices
-- Note: Skipping onesignal_devices policy update - table structure needs verification
-- If this table exists and has auth.uid() calls, update manually based on actual schema

-- ============================================================================
-- Scheduling Details Policies (20251201140000_phase2_scheduling_details.sql)
-- ============================================================================

-- treatment_plans
drop policy if exists treatment_plans_modify on public.treatment_plans;
create policy treatment_plans_modify on public.treatment_plans
  for all
  using (
    public.user_can_access_org(org_id)
    and exists (
      select 1
      from public.org_memberships m
      where m.org_id = treatment_plans.org_id
        and m.user_id = (select auth.uid())
        and m.role in ('superadmin','org_admin','staff')
    )
  )
  with check (
    public.user_can_access_org(org_id)
    and exists (
      select 1
      from public.org_memberships m
      where m.org_id = treatment_plans.org_id
        and m.user_id = (select auth.uid())
        and m.role in ('superadmin','org_admin','staff')
    )
  );

-- waitlists
drop policy if exists waitlists_modify on public.waitlists;
create policy waitlists_modify on public.waitlists
  for all
  using (
    public.user_can_access_org(org_id)
    and exists (
      select 1
      from public.org_memberships m
      where m.org_id = waitlists.org_id
        and m.user_id = (select auth.uid())
        and m.role in ('superadmin','org_admin','staff')
    )
  )
  with check (
    public.user_can_access_org(org_id)
    and exists (
      select 1
      from public.org_memberships m
      where m.org_id = waitlists.org_id
        and m.user_id = (select auth.uid())
        and m.role in ('superadmin','org_admin','staff')
    )
  );

-- operating_hours
drop policy if exists operating_hours_modify on public.operating_hours;
create policy operating_hours_modify on public.operating_hours
  for all
  using (
    exists (
      select 1
      from public.locations l
      where l.id = operating_hours.location_id
        and public.user_can_access_org(l.org_id)
        and exists (
          select 1
          from public.org_memberships m
          where m.org_id = l.org_id
            and m.user_id = (select auth.uid())
            and m.role in ('superadmin','org_admin')
        )
    )
  )
  with check (
    exists (
      select 1
      from public.locations l
      where l.id = operating_hours.location_id
        and public.user_can_access_org(l.org_id)
        and exists (
          select 1
          from public.org_memberships m
          where m.org_id = l.org_id
            and m.user_id = (select auth.uid())
            and m.role in ('superadmin','org_admin')
        )
    )
  );

-- time_intervals
drop policy if exists time_intervals_modify on public.time_intervals;
create policy time_intervals_modify on public.time_intervals
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

-- rooms
drop policy if exists rooms_modify on public.rooms;
create policy rooms_modify on public.rooms
  for all
  using (
    exists (
      select 1
      from public.locations l
      where l.id = rooms.location_id
        and public.user_can_access_org(l.org_id)
        and exists (
          select 1
          from public.org_memberships m
          where m.org_id = l.org_id
            and m.user_id = (select auth.uid())
            and m.role in ('superadmin','org_admin')
        )
    )
  )
  with check (
    exists (
      select 1
      from public.locations l
      where l.id = rooms.location_id
        and public.user_can_access_org(l.org_id)
        and exists (
          select 1
          from public.org_memberships m
          where m.org_id = l.org_id
            and m.user_id = (select auth.uid())
            and m.role in ('superadmin','org_admin')
        )
    )
  );

-- resources
drop policy if exists resources_modify on public.resources;
create policy resources_modify on public.resources
  for all
  using (
    exists (
      select 1
      from public.locations l
      where l.id = resources.location_id
        and public.user_can_access_org(l.org_id)
        and exists (
          select 1
          from public.org_memberships m
          where m.org_id = l.org_id
            and m.user_id = (select auth.uid())
            and m.role in ('superadmin','org_admin')
        )
    )
  )
  with check (
    exists (
      select 1
      from public.locations l
      where l.id = resources.location_id
        and public.user_can_access_org(l.org_id)
        and exists (
          select 1
          from public.org_memberships m
          where m.org_id = l.org_id
            and m.user_id = (select auth.uid())
            and m.role in ('superadmin','org_admin')
        )
    )
  );

-- ============================================================================
-- Forms & Charting Policies (20251201150000_phase2_forms_charting.sql)
-- ============================================================================

-- charts
drop policy if exists charts_modify on public.charts;
create policy charts_modify on public.charts
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

-- form_templates
drop policy if exists form_templates_modify on public.form_templates;
create policy form_templates_modify on public.form_templates
  for all
  using (
    public.user_can_access_org(org_id)
    and exists (
      select 1
      from public.org_memberships m
      where m.org_id = form_templates.org_id
        and m.user_id = (select auth.uid())
        and m.role in ('superadmin','org_admin')
    )
  )
  with check (
    public.user_can_access_org(org_id)
    and exists (
      select 1
      from public.org_memberships m
      where m.org_id = form_templates.org_id
        and m.user_id = (select auth.uid())
        and m.role in ('superadmin','org_admin')
    )
  );

-- form_responses
drop policy if exists form_responses_modify on public.form_responses;
create policy form_responses_modify on public.form_responses
  for all
  using (
    public.user_can_access_org(org_id)
    and exists (
      select 1
      from public.org_memberships m
      where m.org_id = form_responses.org_id
        and m.user_id = (select auth.uid())
        and m.role in ('superadmin','org_admin','staff')
    )
  )
  with check (
    public.user_can_access_org(org_id)
    and exists (
      select 1
      from public.org_memberships m
      where m.org_id = form_responses.org_id
        and m.user_id = (select auth.uid())
        and m.role in ('superadmin','org_admin','staff')
    )
  );

-- form_data
drop policy if exists form_data_modify on public.form_data;
create policy form_data_modify on public.form_data
  for all
  using (
    public.user_can_access_org(org_id)
    and exists (
      select 1
      from public.org_memberships m
      where m.org_id = form_data.org_id
        and m.user_id = (select auth.uid())
        and m.role in ('superadmin','org_admin','staff')
    )
  )
  with check (
    public.user_can_access_org(org_id)
    and exists (
      select 1
      from public.org_memberships m
      where m.org_id = form_data.org_id
        and m.user_id = (select auth.uid())
        and m.role in ('superadmin','org_admin','staff')
    )
  );

-- form_details
drop policy if exists form_details_modify on public.form_details;
create policy form_details_modify on public.form_details
  for all
  using (
    public.user_can_access_org(org_id)
    and exists (
      select 1
      from public.org_memberships m
      where m.org_id = form_details.org_id
        and m.user_id = (select auth.uid())
        and m.role in ('superadmin','org_admin','staff')
    )
  )
  with check (
    public.user_can_access_org(org_id)
    and exists (
      select 1
      from public.org_memberships m
      where m.org_id = form_details.org_id
        and m.user_id = (select auth.uid())
        and m.role in ('superadmin','org_admin','staff')
    )
  );

-- intake_forms
drop policy if exists intake_forms_modify on public.intake_forms;
create policy intake_forms_modify on public.intake_forms
  for all
  using (
    public.user_can_access_org(org_id)
    and exists (
      select 1
      from public.org_memberships m
      where m.org_id = intake_forms.org_id
        and m.user_id = (select auth.uid())
        and m.role in ('superadmin','org_admin','staff')
    )
  )
  with check (
    public.user_can_access_org(org_id)
    and exists (
      select 1
      from public.org_memberships m
      where m.org_id = intake_forms.org_id
        and m.user_id = (select auth.uid())
        and m.role in ('superadmin','org_admin','staff')
    )
  );

-- ============================================================================
-- Insurance Policies (20251201160000_phase2_insurance.sql)
-- ============================================================================

-- insurers
drop policy if exists insurers_modify on public.insurers;
create policy insurers_modify on public.insurers
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

-- insurance_plans
drop policy if exists insurance_plans_modify on public.insurance_plans;
create policy insurance_plans_modify on public.insurance_plans
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

-- user_insurance
drop policy if exists user_insurance_modify on public.user_insurance;
create policy user_insurance_modify on public.user_insurance
  for all
  using (
    (select auth.uid()) = user_id
    or exists (
      select 1
      from public.org_memberships m
      where m.user_id = (select auth.uid())
        and m.role in ('superadmin','org_admin')
    )
  )
  with check (
    (select auth.uid()) = user_id
    or exists (
      select 1
      from public.org_memberships m
      where m.user_id = (select auth.uid())
        and m.role in ('superadmin','org_admin')
    )
  );

-- patient_insurance
drop policy if exists patient_insurance_modify on public.patient_insurance;
create policy patient_insurance_modify on public.patient_insurance
  for all
  using (
    public.user_can_access_org(org_id)
    and exists (
      select 1
      from public.org_memberships m
      where m.org_id = patient_insurance.org_id
        and m.user_id = (select auth.uid())
        and m.role in ('superadmin','org_admin','staff')
    )
  )
  with check (
    public.user_can_access_org(org_id)
    and exists (
      select 1
      from public.org_memberships m
      where m.org_id = patient_insurance.org_id
        and m.user_id = (select auth.uid())
        and m.role in ('superadmin','org_admin','staff')
    )
  );

-- provider_insurance
drop policy if exists provider_insurance_modify on public.provider_insurance;
create policy provider_insurance_modify on public.provider_insurance
  for all
  using (
    public.user_can_access_org(org_id)
    and exists (
      select 1
      from public.org_memberships m
      where m.org_id = provider_insurance.org_id
        and m.user_id = (select auth.uid())
        and m.role in ('superadmin','org_admin')
    )
  )
  with check (
    public.user_can_access_org(org_id)
    and exists (
      select 1
      from public.org_memberships m
      where m.org_id = provider_insurance.org_id
        and m.user_id = (select auth.uid())
        and m.role in ('superadmin','org_admin')
    )
  );

-- claims
drop policy if exists insurance_claims_modify on public.insurance_claims;
create policy insurance_claims_modify on public.insurance_claims
  for all
  using (
    public.user_can_access_org(org_id)
    and exists (
      select 1
      from public.org_memberships m
      where m.org_id = insurance_claims.org_id
        and m.user_id = (select auth.uid())
        and m.role in ('superadmin','org_admin','staff')
    )
  )
  with check (
    public.user_can_access_org(org_id)
    and exists (
      select 1
      from public.org_memberships m
      where m.org_id = insurance_claims.org_id
        and m.user_id = (select auth.uid())
        and m.role in ('superadmin','org_admin','staff')
    )
  );

-- claim_items
drop policy if exists claim_items_modify on public.claim_items;
create policy claim_items_modify on public.claim_items
  for all
  using (
    public.user_can_access_org(org_id)
    and exists (
      select 1
      from public.org_memberships m
      where m.org_id = claim_items.org_id
        and m.user_id = (select auth.uid())
        and m.role in ('superadmin','org_admin','staff')
    )
  )
  with check (
    public.user_can_access_org(org_id)
    and exists (
      select 1
      from public.org_memberships m
      where m.org_id = claim_items.org_id
        and m.user_id = (select auth.uid())
        and m.role in ('superadmin','org_admin','staff')
    )
  );

-- claim_payments
drop policy if exists claim_payments_modify on public.claim_payments;
create policy claim_payments_modify on public.claim_payments
  for all
  using (
    public.user_can_access_org(org_id)
    and exists (
      select 1
      from public.org_memberships m
      where m.org_id = claim_payments.org_id
        and m.user_id = (select auth.uid())
        and m.role in ('superadmin','org_admin','staff')
    )
  )
  with check (
    public.user_can_access_org(org_id)
    and exists (
      select 1
      from public.org_memberships m
      where m.org_id = claim_payments.org_id
        and m.user_id = (select auth.uid())
        and m.role in ('superadmin','org_admin','staff')
    )
  );

-- eligibility_checks
drop policy if exists eligibility_checks_modify on public.eligibility_checks;
create policy eligibility_checks_modify on public.eligibility_checks
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

-- pre_authorizations
drop policy if exists pre_authorizations_modify on public.pre_authorizations;
create policy pre_authorizations_modify on public.pre_authorizations
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

-- insurance_documents
drop policy if exists insurance_documents_modify on public.insurance_documents;
create policy insurance_documents_modify on public.insurance_documents
  for all
  using (
    public.user_can_access_org(org_id)
    and exists (
      select 1
      from public.org_memberships m
      where m.org_id = insurance_documents.org_id
        and m.user_id = (select auth.uid())
        and m.role in ('superadmin','org_admin','staff')
    )
  )
  with check (
    public.user_can_access_org(org_id)
    and exists (
      select 1
      from public.org_memberships m
      where m.org_id = insurance_documents.org_id
        and m.user_id = (select auth.uid())
        and m.role in ('superadmin','org_admin','staff')
    )
  );

-- ============================================================================
-- Booking Policies (20251201170000_phase2_booking_policies.sql)
-- ============================================================================

-- booking_policy_presets
drop policy if exists booking_policy_presets_modify on public.booking_policy_presets;
create policy booking_policy_presets_modify on public.booking_policy_presets
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

-- booking_policies
drop policy if exists booking_policies_modify on public.booking_policies;
create policy booking_policies_modify on public.booking_policies
  for all
  using (
    (org_id is null or public.user_can_access_org(org_id))
    and (
      org_id is null
      or exists (
        select 1
        from public.org_memberships m
        where m.org_id = booking_policies.org_id
          and m.user_id = (select auth.uid())
          and m.role in ('superadmin','org_admin')
      )
    )
  )
  with check (
    (org_id is null or public.user_can_access_org(org_id))
    and (
      org_id is null
      or exists (
        select 1
        from public.org_memberships m
        where m.org_id = booking_policies.org_id
          and m.user_id = (select auth.uid())
          and m.role in ('superadmin','org_admin')
      )
    )
  );

-- booking_portals
drop policy if exists booking_portals_modify on public.booking_portals;
create policy booking_portals_modify on public.booking_portals
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

-- ============================================================================
-- Services & Products Policies (20251128190000_phase2_services_products.sql)
-- ============================================================================

-- discipline_offerings
drop policy if exists discipline_offerings_modify on public.discipline_offerings;
create policy discipline_offerings_modify on public.discipline_offerings
  for all
  using (
    (org_id is null or public.user_can_access_org(org_id))
    and (
      org_id is null
      or exists (
        select 1
        from public.org_memberships m
        where m.org_id = discipline_offerings.org_id
          and m.user_id = (select auth.uid())
          and m.role in ('superadmin','org_admin')
      )
    )
  )
  with check (
    (org_id is null or public.user_can_access_org(org_id))
    and (
      org_id is null
      or exists (
        select 1
        from public.org_memberships m
        where m.org_id = discipline_offerings.org_id
          and m.user_id = (select auth.uid())
          and m.role in ('superadmin','org_admin')
      )
    )
  );

-- service_offerings
drop policy if exists service_offerings_modify on public.service_offerings;
create policy service_offerings_modify on public.service_offerings
  for all
  using (
    public.user_can_access_org(org_id)
    and exists (
      select 1
      from public.org_memberships m
      where m.org_id = service_offerings.org_id
        and m.user_id = (select auth.uid())
        and m.role in ('superadmin','org_admin')
    )
  )
  with check (
    public.user_can_access_org(org_id)
    and exists (
      select 1
      from public.org_memberships m
      where m.org_id = service_offerings.org_id
        and m.user_id = (select auth.uid())
        and m.role in ('superadmin','org_admin')
    )
  );

-- item_prices
drop policy if exists item_prices_modify on public.item_prices;
create policy item_prices_modify on public.item_prices
  for all
  using (
    (org_id is null or public.user_can_access_org(org_id))
    and (
      org_id is null
      or exists (
        select 1
        from public.org_memberships m
        where m.org_id = item_prices.org_id
          and m.user_id = (select auth.uid())
          and m.role in ('superadmin','org_admin')
      )
    )
  )
  with check (
    (org_id is null or public.user_can_access_org(org_id))
    and (
      org_id is null
      or exists (
        select 1
        from public.org_memberships m
        where m.org_id = item_prices.org_id
          and m.user_id = (select auth.uid())
          and m.role in ('superadmin','org_admin')
      )
    )
  );

-- items_catalog
drop policy if exists items_catalog_modify on public.items_catalog;
create policy items_catalog_modify on public.items_catalog
  for all
  using (
    public.user_can_access_org(org_id)
    and exists (
      select 1
      from public.org_memberships m
      where m.org_id = items_catalog.org_id
        and m.user_id = (select auth.uid())
        and m.role in ('superadmin','org_admin')
    )
  )
  with check (
    public.user_can_access_org(org_id)
    and exists (
      select 1
      from public.org_memberships m
      where m.org_id = items_catalog.org_id
        and m.user_id = (select auth.uid())
        and m.role in ('superadmin','org_admin')
    )
  );

-- service_details
drop policy if exists service_details_modify on public.service_details;
create policy service_details_modify on public.service_details
  for all
  using (
    exists (
      select 1
      from public.items_catalog ic
      where ic.id = service_details.item_id
        and (ic.org_id is null or public.user_can_access_org(ic.org_id))
        and (
          ic.org_id is null
          or exists (
            select 1
            from public.org_memberships m
            where m.org_id = ic.org_id
              and m.user_id = (select auth.uid())
              and m.role in ('superadmin','org_admin')
          )
        )
    )
  )
  with check (
    exists (
      select 1
      from public.items_catalog ic
      where ic.id = service_details.item_id
        and (ic.org_id is null or public.user_can_access_org(ic.org_id))
        and (
          ic.org_id is null
          or exists (
            select 1
            from public.org_memberships m
            where m.org_id = ic.org_id
              and m.user_id = (select auth.uid())
              and m.role in ('superadmin','org_admin')
          )
        )
    )
  );

-- product_details
drop policy if exists product_details_modify on public.product_details;
create policy product_details_modify on public.product_details
  for all
  using (
    exists (
      select 1
      from public.items_catalog ic
      where ic.id = product_details.item_id
        and (ic.org_id is null or public.user_can_access_org(ic.org_id))
        and (
          ic.org_id is null
          or exists (
            select 1
            from public.org_memberships m
            where m.org_id = ic.org_id
              and m.user_id = (select auth.uid())
              and m.role in ('superadmin','org_admin')
          )
        )
    )
  )
  with check (
    exists (
      select 1
      from public.items_catalog ic
      where ic.id = product_details.item_id
        and (ic.org_id is null or public.user_can_access_org(ic.org_id))
        and (
          ic.org_id is null
          or exists (
            select 1
            from public.org_memberships m
            where m.org_id = ic.org_id
              and m.user_id = (select auth.uid())
              and m.role in ('superadmin','org_admin')
          )
        )
    )
  );

-- income_categories
drop policy if exists income_categories_modify on public.income_categories;
create policy income_categories_modify on public.income_categories
  for all
  using (
    public.user_can_access_org(org_id)
    and exists (
      select 1
      from public.org_memberships m
      where m.org_id = income_categories.org_id
        and m.user_id = (select auth.uid())
        and m.role in ('superadmin','org_admin')
    )
  )
  with check (
    public.user_can_access_org(org_id)
    and exists (
      select 1
      from public.org_memberships m
      where m.org_id = income_categories.org_id
        and m.user_id = (select auth.uid())
        and m.role in ('superadmin','org_admin')
    )
  );

-- suppliers
drop policy if exists suppliers_modify on public.suppliers;
create policy suppliers_modify on public.suppliers
  for all
  using (
    public.user_can_access_org(org_id)
    and exists (
      select 1
      from public.org_memberships m
      where m.org_id = suppliers.org_id
        and m.user_id = (select auth.uid())
        and m.role in ('superadmin','org_admin')
    )
  )
  with check (
    public.user_can_access_org(org_id)
    and exists (
      select 1
      from public.org_memberships m
      where m.org_id = suppliers.org_id
        and m.user_id = (select auth.uid())
        and m.role in ('superadmin','org_admin')
    )
  );

-- discipline_presets
drop policy if exists discipline_presets_modify on public.discipline_presets;
create policy discipline_presets_modify on public.discipline_presets
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

-- product_inventory
-- Note: This policy is conditionally created based on whether location_id column exists
-- The original migration uses dynamic SQL, so we'll recreate it with the fix
drop policy if exists product_inventory_modify on public.product_inventory;
do $$
begin
  -- Check if location_id column exists
  if exists (
    select 1 from information_schema.columns
    where table_schema = 'public' and table_name = 'product_inventory' and column_name = 'location_id'
  ) then
    -- Use location-based access
    execute 'create policy product_inventory_modify on public.product_inventory
      for all using (
        exists (
          select 1 from public.locations l
          where l.id = product_inventory.location_id
            and public.user_can_access_org(l.org_id)
            and exists (
              select 1 from public.org_memberships m
              where m.org_id = l.org_id
                and m.user_id = (select auth.uid())
                and m.role in (''superadmin'',''org_admin'')
            )
        )
      )
      with check (
        exists (
          select 1 from public.locations l
          where l.id = product_inventory.location_id
            and public.user_can_access_org(l.org_id)
            and exists (
              select 1 from public.org_memberships m
              where m.org_id = l.org_id
                and m.user_id = (select auth.uid())
                and m.role in (''superadmin'',''org_admin'')
            )
        )
      )';
  else
    -- Fallback: use product_id -> items_catalog.org_id
    execute 'create policy product_inventory_modify on public.product_inventory
      for all using (
        exists (
          select 1 from public.items_catalog ic
          where ic.id = product_inventory.product_id
            and (ic.org_id is null or public.user_can_access_org(ic.org_id))
            and (
              ic.org_id is null
              or exists (
                select 1 from public.org_memberships m
                where m.org_id = ic.org_id
                  and m.user_id = (select auth.uid())
                  and m.role in (''superadmin'',''org_admin'')
              )
            )
        )
      )
      with check (
        exists (
          select 1 from public.items_catalog ic
          where ic.id = product_inventory.product_id
            and (ic.org_id is null or public.user_can_access_org(ic.org_id))
            and (
              ic.org_id is null
              or exists (
                select 1 from public.org_memberships m
                where m.org_id = ic.org_id
                  and m.user_id = (select auth.uid())
                  and m.role in (''superadmin'',''org_admin'')
              )
            )
        )
      )';
  end if;
end;
$$;

-- ============================================================================
-- Other Policies
-- ============================================================================

-- location_taxes
drop policy if exists location_taxes_modify on public.location_taxes;
create policy location_taxes_modify on public.location_taxes
  for all
  using (
    exists (
      select 1
      from public.locations l
      join public.org_memberships m on m.org_id = l.org_id
      where l.id = location_taxes.location_id
        and m.user_id = (select auth.uid())
        and m.role in ('superadmin', 'org_admin')
    )
  )
  with check (
    exists (
      select 1
      from public.locations l
      join public.org_memberships m on m.org_id = l.org_id
      where l.id = location_taxes.location_id
        and m.user_id = (select auth.uid())
        and m.role in ('superadmin', 'org_admin')
    )
  );

-- presence
drop policy if exists presence_all on public.presence;
drop policy if exists presence_modify on public.presence;
create policy presence_all on public.presence
  for all
  using (
    public.user_can_access_org(org_id)
    and exists (
      select 1
      from public.org_memberships m
      where m.org_id = presence.org_id
        and m.user_id = (select auth.uid())
    )
  )
  with check (
    public.user_can_access_org(org_id)
    and (select auth.uid()) = user_id
  );
create policy presence_modify on public.presence
  for all
  using (
    public.user_can_access_org(org_id)
    and (select auth.uid()) = user_id
  )
  with check (
    public.user_can_access_org(org_id)
    and (select auth.uid()) = user_id
  );

-- orgs (insert policy)
drop policy if exists orgs_insert on public.orgs;
create policy orgs_insert on public.orgs
  for insert
  with check (
    exists (
      select 1
      from public.org_memberships m
      where m.user_id = (select auth.uid())
        and m.role = 'superadmin'
    )
  );

