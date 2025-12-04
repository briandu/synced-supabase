-- Create notification_deliveries table for tracking email/SMS/push delivery status

create table if not exists public.notification_deliveries (
  id uuid primary key default gen_random_uuid(),
  notification_type text not null, -- 'email', 'sms', 'push'
  recipient_email text,
  recipient_phone text, -- E.164 format
  subject text, -- For email/push
  message_id text, -- AWS SES message ID, AWS SNS message ID, or OneSignal notification ID
  status text not null default 'pending', -- 'pending', 'sent', 'delivered', 'failed', 'bounced', 'complained'
  error_message text,
  org_id uuid references public.orgs(id) on delete set null,
  staff_id uuid references public.staff_members(id) on delete set null,
  patient_id uuid references public.patients(id) on delete set null,
  notification_metadata jsonb default '{}'::jsonb,
  sent_at timestamptz not null default now(),
  delivered_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Add indexes
create index if not exists idx_notification_deliveries_type on public.notification_deliveries(notification_type);
create index if not exists idx_notification_deliveries_status on public.notification_deliveries(status);
create index if not exists idx_notification_deliveries_org on public.notification_deliveries(org_id);
create index if not exists idx_notification_deliveries_staff on public.notification_deliveries(staff_id);
create index if not exists idx_notification_deliveries_patient on public.notification_deliveries(patient_id);
create index if not exists idx_notification_deliveries_message_id on public.notification_deliveries(message_id);
create index if not exists idx_notification_deliveries_sent_at on public.notification_deliveries(sent_at);

-- Enable RLS
alter table public.notification_deliveries enable row level security;

-- RLS policies: org-scoped access
drop policy if exists notification_deliveries_select on public.notification_deliveries;
create policy notification_deliveries_select on public.notification_deliveries
  for select using (
    public.user_can_access_org(org_id)
    or staff_id in (select id from public.staff_members where user_id = (select auth.uid()))
    or patient_id in (select id from public.patients where patient_user_id = (select auth.uid()))
  );

drop policy if exists notification_deliveries_insert on public.notification_deliveries;
create policy notification_deliveries_insert on public.notification_deliveries
  for insert with check (
    public.user_can_access_org(org_id)
  );

drop policy if exists notification_deliveries_update on public.notification_deliveries;
create policy notification_deliveries_update on public.notification_deliveries
  for update using (
    public.user_can_access_org(org_id)
  );


