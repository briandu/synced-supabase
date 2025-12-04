-- Add notification preferences to profiles and patients tables

-- Add notification preferences to profiles
do $$
begin
  if not exists (select 1 from information_schema.columns where table_schema = 'public' and table_name = 'profiles' and column_name = 'email_notifications_enabled') then
    alter table public.profiles add column email_notifications_enabled boolean default true;
  end if;
  if not exists (select 1 from information_schema.columns where table_schema = 'public' and table_name = 'profiles' and column_name = 'sms_notifications_enabled') then
    alter table public.profiles add column sms_notifications_enabled boolean default true;
  end if;
  if not exists (select 1 from information_schema.columns where table_schema = 'public' and table_name = 'profiles' and column_name = 'push_notifications_enabled') then
    alter table public.profiles add column push_notifications_enabled boolean default true;
  end if;
  if not exists (select 1 from information_schema.columns where table_schema = 'public' and table_name = 'profiles' and column_name = 'notification_preferences') then
    alter table public.profiles add column notification_preferences jsonb default '{}'::jsonb;
  end if;
end;
$$;

-- Add notification preferences to patients
do $$
begin
  if not exists (select 1 from information_schema.columns where table_schema = 'public' and table_name = 'patients' and column_name = 'email_notifications_enabled') then
    alter table public.patients add column email_notifications_enabled boolean default true;
  end if;
  if not exists (select 1 from information_schema.columns where table_schema = 'public' and table_name = 'patients' and column_name = 'sms_notifications_enabled') then
    alter table public.patients add column sms_notifications_enabled boolean default true;
  end if;
  if not exists (select 1 from information_schema.columns where table_schema = 'public' and table_name = 'patients' and column_name = 'push_notifications_enabled') then
    alter table public.patients add column push_notifications_enabled boolean default true;
  end if;
  if not exists (select 1 from information_schema.columns where table_schema = 'public' and table_name = 'patients' and column_name = 'notification_preferences') then
    alter table public.patients add column notification_preferences jsonb default '{}'::jsonb;
  end if;
end;
$$;

-- Add indexes for notification preferences queries
create index if not exists idx_profiles_email_notifications on public.profiles(email_notifications_enabled) where email_notifications_enabled = true;
create index if not exists idx_profiles_sms_notifications on public.profiles(sms_notifications_enabled) where sms_notifications_enabled = true;
create index if not exists idx_profiles_push_notifications on public.profiles(push_notifications_enabled) where push_notifications_enabled = true;

create index if not exists idx_patients_email_notifications on public.patients(email_notifications_enabled) where email_notifications_enabled = true;
create index if not exists idx_patients_sms_notifications on public.patients(sms_notifications_enabled) where sms_notifications_enabled = true;
create index if not exists idx_patients_push_notifications on public.patients(push_notifications_enabled) where push_notifications_enabled = true;


