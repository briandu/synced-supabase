-- Create database functions and triggers to send notifications on events
-- These functions will be called from application code or via database triggers

-- Function to send appointment reminder notifications
create or replace function public.send_appointment_reminder_notifications()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  patient_email text;
  patient_phone text;
  patient_user_id uuid;
  location_name text;
  staff_name text;
  appointment_date text;
  appointment_time text;
begin
  -- Only send for scheduled appointments
  if new.status != 'scheduled' then
    return new;
  end if;

  -- Get patient contact info
  select p.email, p.phone, p.patient_user_id
  into patient_email, patient_phone, patient_user_id
  from public.patients p
  where p.id = new.patient_id;

  -- Get location name
  select l.name into location_name
  from public.locations l
  where l.id = new.location_id;

  -- Get staff name
  select concat(sm.first_name, ' ', sm.last_name) into staff_name
  from public.staff_members sm
  where sm.id = new.staff_id;

  -- Format date/time
  appointment_date := to_char(new.starts_at, 'Month DD, YYYY');
  appointment_time := to_char(new.starts_at, 'HH12:MI AM');

  -- Note: Actual email/SMS sending will be handled by application code
  -- This function just creates notification records that can be processed by a job queue
  -- For now, we'll create in-app notifications

  -- Create patient notification
  if patient_user_id is not null then
    insert into public.patient_notifications (
      org_id,
      patient_id,
      type,
      payload
    ) values (
      new.org_id,
      new.patient_id,
      'appointment_reminder',
      jsonb_build_object(
        'appointment_id', new.id,
        'appointment_date', appointment_date,
        'appointment_time', appointment_time,
        'location_name', location_name,
        'staff_name', staff_name
      )
    );
  end if;

  return new;
end;
$$;

-- Trigger to send appointment reminders (can be called on insert/update)
-- Note: We'll handle actual email/SMS sending in application code to avoid blocking database operations
-- This trigger just creates notification records

-- Function to send task assignment notifications
-- This function checks which staff assignment column exists and uses it
create or replace function public.send_task_assignment_notification()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  staff_user_id uuid;
  assigned_staff_id uuid;
  has_assigned_to_staff_id boolean;
  has_staff_id boolean;
begin
  -- Check which columns exist in the staff_tasks table
  select exists (
    select 1 from information_schema.columns
    where table_schema = 'public' and table_name = 'staff_tasks' and column_name = 'assigned_to_staff_id'
  ) into has_assigned_to_staff_id;
  
  select exists (
    select 1 from information_schema.columns
    where table_schema = 'public' and table_name = 'staff_tasks' and column_name = 'staff_id'
  ) into has_staff_id;

  -- Determine which staff ID to use based on what columns exist
  if has_assigned_to_staff_id then
    -- Try to get assigned_to_staff_id using dynamic SQL
    execute format('SELECT ($1).assigned_to_staff_id') using new into assigned_staff_id;
  end if;
  
  -- If assigned_to_staff_id is null or doesn't exist, try staff_id
  if assigned_staff_id is null and has_staff_id then
    execute format('SELECT ($1).staff_id') using new into assigned_staff_id;
  end if;

  -- Skip if no staff assigned
  if assigned_staff_id is null then
    return new;
  end if;

  -- Get staff user_id
  select sm.user_id into staff_user_id
  from public.staff_members sm
  where sm.id = assigned_staff_id;

  -- Create staff notification
  if staff_user_id is not null then
    insert into public.staff_notifications (
      org_id,
      staff_id,
      type,
      payload
    ) values (
      new.org_id,
      assigned_staff_id,
      'task_assigned',
      jsonb_build_object(
        'task_id', new.id,
        'title', new.title,
        'description', new.description,
        'due_at', new.due_at
      )
    );
  end if;

  return new;
end;
$$;

-- Drop and recreate trigger for task assignments
-- No when clause - function will check if staff is assigned
drop trigger if exists task_assignment_notification_trigger on public.staff_tasks;

-- Only create trigger if staff_tasks table exists
do $$
begin
  if exists (select 1 from information_schema.tables where table_schema = 'public' and table_name = 'staff_tasks') then
    execute 'create trigger task_assignment_notification_trigger
      after insert on public.staff_tasks
      for each row
      execute function public.send_task_assignment_notification()';
  end if;
end;
$$;

-- Note: Email/SMS sending for appointments will be handled by application code
-- to avoid blocking database operations and to respect user preferences

