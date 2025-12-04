-- Tighten RLS for invites/join-requests, patients, scheduling, notifications using existing roles/helpers.
-- Assumes helpers: user_can_access_org(org_id), user_can_access_location(location_id) and enum user_role (superadmin, org_admin, staff, patient)

-- Invites: only org_admin/superadmin of same org can modify; org members can view
drop policy if exists org_staff_invites_all on public.org_staff_invites;
drop policy if exists org_staff_invites_select on public.org_staff_invites;
drop policy if exists org_staff_invites_modify on public.org_staff_invites;
create policy org_staff_invites_select on public.org_staff_invites
  for select using (public.user_can_access_org(org_id));
create policy org_staff_invites_modify on public.org_staff_invites
  for all
  using (
    public.user_can_access_org(org_id)
    and exists (
      select 1
      from public.org_memberships m
      where m.org_id = org_staff_invites.org_id
        and m.user_id = auth.uid()
        and m.role in ('superadmin','org_admin')
    )
  )
  with check (
    public.user_can_access_org(org_id)
    and exists (
      select 1
      from public.org_memberships m
      where m.org_id = org_staff_invites.org_id
        and m.user_id = auth.uid()
        and m.role in ('superadmin','org_admin')
    )
  );

-- Join requests: org_admin/superadmin can modify; org members can view
drop policy if exists org_join_requests_all on public.org_join_requests;
drop policy if exists org_join_requests_select on public.org_join_requests;
drop policy if exists org_join_requests_modify on public.org_join_requests;
create policy org_join_requests_select on public.org_join_requests
  for select using (public.user_can_access_org(org_id));
create policy org_join_requests_modify on public.org_join_requests
  for all
  using (
    public.user_can_access_org(org_id)
    and exists (
      select 1
      from public.org_memberships m
      where m.org_id = org_join_requests.org_id
        and m.user_id = auth.uid()
        and m.role in ('superadmin','org_admin')
    )
  )
  with check (
    public.user_can_access_org(org_id)
    and exists (
      select 1
      from public.org_memberships m
      where m.org_id = org_join_requests.org_id
        and m.user_id = auth.uid()
        and m.role in ('superadmin','org_admin')
    )
  );

-- Patients: org scope + role in superadmin/org_admin/staff
drop policy if exists patients_all on public.patients;
create policy patients_all on public.patients
  for all
  using (
    public.user_can_access_org(org_id)
    and exists (
      select 1 from public.org_memberships m where m.org_id = patients.org_id and m.user_id = auth.uid() and m.role in ('superadmin','org_admin','staff')
    )
  )
  with check (
    public.user_can_access_org(org_id)
    and exists (
      select 1 from public.org_memberships m where m.org_id = patients.org_id and m.user_id = auth.uid() and m.role in ('superadmin','org_admin','staff')
    )
  );

-- Patient notes/relationships/consents: same as patients
drop policy if exists patient_notes_all on public.patient_notes;
create policy patient_notes_all on public.patient_notes
  for all using (
    public.user_can_access_org(org_id)
    and exists (select 1 from public.org_memberships m where m.org_id = patient_notes.org_id and m.user_id = auth.uid() and m.role in ('superadmin','org_admin','staff'))
  ) with check (
    public.user_can_access_org(org_id)
    and exists (select 1 from public.org_memberships m where m.org_id = patient_notes.org_id and m.user_id = auth.uid() and m.role in ('superadmin','org_admin','staff'))
  );

drop policy if exists patient_relationships_all on public.patient_relationships;
create policy patient_relationships_all on public.patient_relationships
  for all using (
    public.user_can_access_org(org_id)
    and exists (select 1 from public.org_memberships m where m.org_id = patient_relationships.org_id and m.user_id = auth.uid() and m.role in ('superadmin','org_admin','staff'))
  ) with check (
    public.user_can_access_org(org_id)
    and exists (select 1 from public.org_memberships m where m.org_id = patient_relationships.org_id and m.user_id = auth.uid() and m.role in ('superadmin','org_admin','staff'))
  );

drop policy if exists patient_consents_all on public.patient_consents;
create policy patient_consents_all on public.patient_consents
  for all using (
    public.user_can_access_org(org_id)
    and exists (select 1 from public.org_memberships m where m.org_id = patient_consents.org_id and m.user_id = auth.uid() and m.role in ('superadmin','org_admin','staff'))
  ) with check (
    public.user_can_access_org(org_id)
    and exists (select 1 from public.org_memberships m where m.org_id = patient_consents.org_id and m.user_id = auth.uid() and m.role in ('superadmin','org_admin','staff'))
  );

-- Appointments: org scope AND either admin or staff assigned; require location access when location_id present
drop policy if exists appointments_all on public.appointments;
create policy appointments_all on public.appointments
  for all using (
    public.user_can_access_org(org_id)
    and (
      exists (select 1 from public.org_memberships m where m.org_id = appointments.org_id and m.user_id = auth.uid() and m.role in ('superadmin','org_admin'))
      or exists (select 1 from public.staff_members sm where sm.id = appointments.staff_id and sm.user_id = auth.uid())
    )
    and (location_id is null or public.user_can_access_location(location_id))
  )
  with check (
    public.user_can_access_org(org_id)
    and (
      exists (select 1 from public.org_memberships m where m.org_id = appointments.org_id and m.user_id = auth.uid() and m.role in ('superadmin','org_admin'))
      or exists (select 1 from public.staff_members sm where sm.id = appointments.staff_id and sm.user_id = auth.uid())
    )
    and (location_id is null or public.user_can_access_location(location_id))
  );

-- Availability/shifts/breaks/time_off/tasks: similar to appointments
drop policy if exists availability_blocks_all on public.availability_blocks;
create policy availability_blocks_all on public.availability_blocks
  for all using (
    public.user_can_access_org(org_id)
    and (
      exists (select 1 from public.org_memberships m where m.org_id = availability_blocks.org_id and m.user_id = auth.uid() and m.role in ('superadmin','org_admin'))
      or exists (select 1 from public.staff_members sm where sm.id = availability_blocks.staff_id and sm.user_id = auth.uid())
    )
    and (location_id is null or public.user_can_access_location(location_id))
  )
  with check (
    public.user_can_access_org(org_id)
    and (
      exists (select 1 from public.org_memberships m where m.org_id = availability_blocks.org_id and m.user_id = auth.uid() and m.role in ('superadmin','org_admin'))
      or exists (select 1 from public.staff_members sm where sm.id = availability_blocks.staff_id and sm.user_id = auth.uid())
    )
    and (location_id is null or public.user_can_access_location(location_id))
  );

-- staff_shifts: derive org via staff_members
drop policy if exists staff_shifts_all on public.staff_shifts;
create policy staff_shifts_all on public.staff_shifts
  for all using (
    (
      exists (
        select 1 from public.staff_members sm
        where sm.id = staff_shifts.staff_id
          and sm.user_id = auth.uid()
          and public.user_can_access_org(sm.org_id)
      )
      or exists (
        select 1 from public.org_memberships m
        join public.staff_members sm on sm.org_id = m.org_id
        where sm.id = staff_shifts.staff_id
          and m.user_id = auth.uid()
          and m.role in ('superadmin','org_admin')
      )
    )
    and (location_id is null or public.user_can_access_location(location_id))
  )
  with check (
    (
      exists (
        select 1 from public.staff_members sm
        where sm.id = staff_shifts.staff_id
          and sm.user_id = auth.uid()
          and public.user_can_access_org(sm.org_id)
      )
      or exists (
        select 1 from public.org_memberships m
        join public.staff_members sm on sm.org_id = m.org_id
        where sm.id = staff_shifts.staff_id
          and m.user_id = auth.uid()
          and m.role in ('superadmin','org_admin')
      )
    )
    and (location_id is null or public.user_can_access_location(location_id))
  );

-- staff_breaks: derive org via staff_members
drop policy if exists staff_breaks_all on public.staff_breaks;
create policy staff_breaks_all on public.staff_breaks
  for all using (
    (
      exists (
        select 1 from public.staff_members sm
        where sm.id = staff_breaks.staff_id
          and sm.user_id = auth.uid()
          and public.user_can_access_org(sm.org_id)
      )
      or exists (
        select 1 from public.org_memberships m
        join public.staff_members sm on sm.org_id = m.org_id
        where sm.id = staff_breaks.staff_id
          and m.user_id = auth.uid()
          and m.role in ('superadmin','org_admin')
      )
    )
  )
  with check (
    (
      exists (
        select 1 from public.staff_members sm
        where sm.id = staff_breaks.staff_id
          and sm.user_id = auth.uid()
          and public.user_can_access_org(sm.org_id)
      )
      or exists (
        select 1 from public.org_memberships m
        join public.staff_members sm on sm.org_id = m.org_id
        where sm.id = staff_breaks.staff_id
          and m.user_id = auth.uid()
          and m.role in ('superadmin','org_admin')
      )
    )
  );

-- staff_time_off: derive org via staff_members
drop policy if exists staff_time_off_all on public.staff_time_off;
create policy staff_time_off_all on public.staff_time_off
  for all using (
    exists (
      select 1 from public.staff_members sm
      where sm.id = staff_time_off.staff_id
        and public.user_can_access_org(sm.org_id)
        and (
          sm.user_id = auth.uid()
          or exists (
            select 1 from public.org_memberships m
            where m.org_id = sm.org_id
              and m.user_id = auth.uid()
              and m.role in ('superadmin','org_admin')
          )
        )
    )
  )
  with check (
    exists (
      select 1 from public.staff_members sm
      where sm.id = staff_time_off.staff_id
        and public.user_can_access_org(sm.org_id)
        and (
          sm.user_id = auth.uid()
          or exists (
            select 1 from public.org_memberships m
            where m.org_id = sm.org_id
              and m.user_id = auth.uid()
              and m.role in ('superadmin','org_admin')
          )
        )
    )
  );

drop policy if exists staff_tasks_all on public.staff_tasks;
create policy staff_tasks_all on public.staff_tasks
  for all using (
    public.user_can_access_org(org_id)
    and exists (select 1 from public.org_memberships m where m.org_id = staff_tasks.org_id and m.user_id = auth.uid() and m.role in ('superadmin','org_admin','staff'))
  )
  with check (
    public.user_can_access_org(org_id)
    and exists (select 1 from public.org_memberships m where m.org_id = staff_tasks.org_id and m.user_id = auth.uid() and m.role in ('superadmin','org_admin','staff'))
  );

-- Notifications: staff notifications visible to admin or matching staff; patient notifications to admin or matching patient
drop policy if exists staff_notifications_all on public.staff_notifications;
create policy staff_notifications_all on public.staff_notifications
  for all using (
    public.user_can_access_org(org_id)
    and (
      exists (select 1 from public.org_memberships m where m.org_id = staff_notifications.org_id and m.user_id = auth.uid() and m.role in ('superadmin','org_admin'))
      or exists (select 1 from public.staff_members sm where sm.id = staff_notifications.staff_id and sm.user_id = auth.uid())
    )
  )
  with check (
    public.user_can_access_org(org_id)
    and (
      exists (select 1 from public.org_memberships m where m.org_id = staff_notifications.org_id and m.user_id = auth.uid() and m.role in ('superadmin','org_admin'))
      or exists (select 1 from public.staff_members sm where sm.id = staff_notifications.staff_id and sm.user_id = auth.uid())
    )
  );

drop policy if exists patient_notifications_all on public.patient_notifications;
create policy patient_notifications_all on public.patient_notifications
  for all using (
    public.user_can_access_org(org_id)
    and (
      exists (select 1 from public.org_memberships m where m.org_id = patient_notifications.org_id and m.user_id = auth.uid() and m.role in ('superadmin','org_admin'))
      or exists (select 1 from public.patients p where p.id = patient_notifications.patient_id and p.patient_user_id = auth.uid())
    )
  )
  with check (
    public.user_can_access_org(org_id)
    and (
      exists (select 1 from public.org_memberships m where m.org_id = patient_notifications.org_id and m.user_id = auth.uid() and m.role in ('superadmin','org_admin'))
      or exists (select 1 from public.patients p where p.id = patient_notifications.patient_id and p.patient_user_id = auth.uid())
    )
  );

-- Staff permissions: admins only; staff can view their own rows
drop policy if exists staff_permissions_all on public.staff_permissions;
drop policy if exists staff_permissions_select on public.staff_permissions;
drop policy if exists staff_permissions_modify on public.staff_permissions;
create policy staff_permissions_select on public.staff_permissions
  for select using (
    exists (
      select 1 from public.staff_members sm
      where sm.id = staff_permissions.staff_id
        and public.user_can_access_org(sm.org_id)
        and (
          sm.user_id = auth.uid()
          or exists (select 1 from public.org_memberships m where m.org_id = sm.org_id and m.user_id = auth.uid())
        )
    )
  );
create policy staff_permissions_modify on public.staff_permissions
  for all using (
    exists (
      select 1 from public.staff_members sm
      where sm.id = staff_permissions.staff_id
        and public.user_can_access_org(sm.org_id)
        and exists (
          select 1 from public.org_memberships m
          where m.org_id = sm.org_id
            and m.user_id = auth.uid()
            and m.role in ('superadmin','org_admin')
        )
    )
  )
  with check (
    exists (
      select 1 from public.staff_members sm
      where sm.id = staff_permissions.staff_id
        and public.user_can_access_org(sm.org_id)
        and exists (
          select 1 from public.org_memberships m
          where m.org_id = sm.org_id
            and m.user_id = auth.uid()
            and m.role in ('superadmin','org_admin')
        )
    )
  );

-- Disciplines / Services: org members can read; admins modify
drop policy if exists disciplines_all on public.disciplines;
drop policy if exists disciplines_select on public.disciplines;
drop policy if exists disciplines_modify on public.disciplines;
create policy disciplines_select on public.disciplines
  for select using (public.user_can_access_org(org_id));
create policy disciplines_modify on public.disciplines
  for all using (
    public.user_can_access_org(org_id)
    and exists (
      select 1 from public.org_memberships m
      where m.org_id = disciplines.org_id
        and m.user_id = auth.uid()
        and m.role in ('superadmin','org_admin')
    )
  )
  with check (
    public.user_can_access_org(org_id)
    and exists (
      select 1 from public.org_memberships m
      where m.org_id = disciplines.org_id
        and m.user_id = auth.uid()
        and m.role in ('superadmin','org_admin')
    )
  );

drop policy if exists services_all on public.services;
drop policy if exists services_select on public.services;
drop policy if exists services_modify on public.services;
create policy services_select on public.services
  for select using (public.user_can_access_org(org_id));
create policy services_modify on public.services
  for all using (
    public.user_can_access_org(org_id)
    and exists (
      select 1 from public.org_memberships m
      where m.org_id = services.org_id
        and m.user_id = auth.uid()
        and m.role in ('superadmin','org_admin')
    )
  )
  with check (
    public.user_can_access_org(org_id)
    and exists (
      select 1 from public.org_memberships m
      where m.org_id = services.org_id
        and m.user_id = auth.uid()
        and m.role in ('superadmin','org_admin')
    )
  );

-- Billing/insurance scaffolding: admin-only modifications, org read
drop policy if exists credit_memos_all on public.credit_memos;
drop policy if exists credit_memos_select on public.credit_memos;
drop policy if exists credit_memos_modify on public.credit_memos;
create policy credit_memos_select on public.credit_memos
  for select using (public.user_can_access_org(org_id));
create policy credit_memos_modify on public.credit_memos
  for all using (
    public.user_can_access_org(org_id)
    and exists (select 1 from public.org_memberships m where m.org_id = credit_memos.org_id and m.user_id = auth.uid() and m.role in ('superadmin','org_admin'))
  )
  with check (
    public.user_can_access_org(org_id)
    and exists (select 1 from public.org_memberships m where m.org_id = credit_memos.org_id and m.user_id = auth.uid() and m.role in ('superadmin','org_admin'))
  );

drop policy if exists discounts_all on public.discounts;
drop policy if exists discounts_select on public.discounts;
drop policy if exists discounts_modify on public.discounts;
create policy discounts_select on public.discounts
  for select using (public.user_can_access_org(org_id));
create policy discounts_modify on public.discounts
  for all using (
    public.user_can_access_org(org_id)
    and exists (select 1 from public.org_memberships m where m.org_id = discounts.org_id and m.user_id = auth.uid() and m.role in ('superadmin','org_admin'))
  )
  with check (
    public.user_can_access_org(org_id)
    and exists (select 1 from public.org_memberships m where m.org_id = discounts.org_id and m.user_id = auth.uid() and m.role in ('superadmin','org_admin'))
  );

drop policy if exists taxes_all on public.taxes;
drop policy if exists taxes_select on public.taxes;
drop policy if exists taxes_modify on public.taxes;
create policy taxes_select on public.taxes
  for select using (public.user_can_access_org(org_id));
create policy taxes_modify on public.taxes
  for all using (
    public.user_can_access_org(org_id)
    and exists (select 1 from public.org_memberships m where m.org_id = taxes.org_id and m.user_id = auth.uid() and m.role in ('superadmin','org_admin'))
  )
  with check (
    public.user_can_access_org(org_id)
    and exists (select 1 from public.org_memberships m where m.org_id = taxes.org_id and m.user_id = auth.uid() and m.role in ('superadmin','org_admin'))
  );

drop policy if exists fees_all on public.fees;
drop policy if exists fees_select on public.fees;
drop policy if exists fees_modify on public.fees;
create policy fees_select on public.fees
  for select using (public.user_can_access_org(org_id));
create policy fees_modify on public.fees
  for all using (
    public.user_can_access_org(org_id)
    and exists (select 1 from public.org_memberships m where m.org_id = fees.org_id and m.user_id = auth.uid() and m.role in ('superadmin','org_admin'))
  )
  with check (
    public.user_can_access_org(org_id)
    and exists (select 1 from public.org_memberships m where m.org_id = fees.org_id and m.user_id = auth.uid() and m.role in ('superadmin','org_admin'))
  );

drop policy if exists transactions_all on public.transactions;
drop policy if exists transactions_select on public.transactions;
drop policy if exists transactions_modify on public.transactions;
create policy transactions_select on public.transactions
  for select using (public.user_can_access_org(org_id));
create policy transactions_modify on public.transactions
  for all using (
    public.user_can_access_org(org_id)
    and exists (select 1 from public.org_memberships m where m.org_id = transactions.org_id and m.user_id = auth.uid() and m.role in ('superadmin','org_admin'))
  )
  with check (
    public.user_can_access_org(org_id)
    and exists (select 1 from public.org_memberships m where m.org_id = transactions.org_id and m.user_id = auth.uid() and m.role in ('superadmin','org_admin'))
  );

drop policy if exists insurance_claims_all on public.insurance_claims;
drop policy if exists insurance_claims_select on public.insurance_claims;
drop policy if exists insurance_claims_modify on public.insurance_claims;
create policy insurance_claims_select on public.insurance_claims
  for select using (public.user_can_access_org(org_id));
create policy insurance_claims_modify on public.insurance_claims
  for all using (
    public.user_can_access_org(org_id)
    and exists (select 1 from public.org_memberships m where m.org_id = insurance_claims.org_id and m.user_id = auth.uid() and m.role in ('superadmin','org_admin'))
  )
  with check (
    public.user_can_access_org(org_id)
    and exists (select 1 from public.org_memberships m where m.org_id = insurance_claims.org_id and m.user_id = auth.uid() and m.role in ('superadmin','org_admin'))
  );
