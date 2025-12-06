-- Promoted from supabase/pending.sql (Stripe location metadata, gift card fields, staff/location active flags)
-- Safe to rerun: guards on every alter

-- Adds Stripe Connect metadata to locations (if missing)
do $$
begin
  if not exists (select 1 from information_schema.columns where table_schema = 'public' and table_name = 'locations' and column_name = 'stripe_account_status') then
    alter table public.locations add column stripe_account_status text;
  end if;
  if not exists (select 1 from information_schema.columns where table_schema = 'public' and table_name = 'locations' and column_name = 'stripe_onboarding_completed') then
    alter table public.locations add column stripe_onboarding_completed boolean not null default false;
  end if;
  if not exists (select 1 from information_schema.columns where table_schema = 'public' and table_name = 'locations' and column_name = 'stripe_account_type') then
    alter table public.locations add column stripe_account_type text;
  end if;
  if not exists (select 1 from information_schema.columns where table_schema = 'public' and table_name = 'locations' and column_name = 'stripe_account_country') then
    alter table public.locations add column stripe_account_country text;
  end if;
  if not exists (select 1 from information_schema.columns where table_schema = 'public' and table_name = 'locations' and column_name = 'stripe_account_email') then
    alter table public.locations add column stripe_account_email text;
  end if;
  if not exists (select 1 from information_schema.columns where table_schema = 'public' and table_name = 'locations' and column_name = 'stripe_onboarding_started_at') then
    alter table public.locations add column stripe_onboarding_started_at timestamptz;
  end if;
  if not exists (select 1 from information_schema.columns where table_schema = 'public' and table_name = 'locations' and column_name = 'stripe_onboarding_completed_at') then
    alter table public.locations add column stripe_onboarding_completed_at timestamptz;
  end if;
  if not exists (select 1 from information_schema.columns where table_schema = 'public' and table_name = 'locations' and column_name = 'stripe_account_created_at') then
    alter table public.locations add column stripe_account_created_at timestamptz;
  end if;
  if not exists (select 1 from information_schema.columns where table_schema = 'public' and table_name = 'locations' and column_name = 'stripe_charges_enabled') then
    alter table public.locations add column stripe_charges_enabled boolean;
  end if;
  if not exists (select 1 from information_schema.columns where table_schema = 'public' and table_name = 'locations' and column_name = 'stripe_payouts_enabled') then
    alter table public.locations add column stripe_payouts_enabled boolean;
  end if;
  if not exists (select 1 from information_schema.columns where table_schema = 'public' and table_name = 'locations' and column_name = 'stripe_account_metadata') then
    alter table public.locations add column stripe_account_metadata jsonb;
  end if;
end;
$$;

-- Extend gift_cards with operational fields
do $$
begin
  if not exists (select 1 from information_schema.columns where table_schema = 'public' and table_name = 'gift_cards' and column_name = 'patient_id') then
    alter table public.gift_cards add column patient_id uuid references public.patients(id) on delete set null;
  end if;
  if not exists (select 1 from information_schema.columns where table_schema = 'public' and table_name = 'gift_cards' and column_name = 'location_id') then
    alter table public.gift_cards add column location_id uuid references public.locations(id) on delete set null;
  end if;
  if not exists (select 1 from information_schema.columns where table_schema = 'public' and table_name = 'gift_cards' and column_name = 'status') then
    alter table public.gift_cards add column status text not null default 'active';
  end if;
  if not exists (select 1 from information_schema.columns where table_schema = 'public' and table_name = 'gift_cards' and column_name = 'initial_amount_cents') then
    alter table public.gift_cards add column initial_amount_cents integer not null default 0;
  end if;
  if not exists (select 1 from information_schema.columns where table_schema = 'public' and table_name = 'gift_cards' and column_name = 'loaded_by') then
    alter table public.gift_cards add column loaded_by uuid references public.staff_members(id) on delete set null;
  end if;
  if not exists (select 1 from information_schema.columns where table_schema = 'public' and table_name = 'gift_cards' and column_name = 'loaded_by_name') then
    alter table public.gift_cards add column loaded_by_name text;
  end if;
  if not exists (select 1 from information_schema.columns where table_schema = 'public' and table_name = 'gift_cards' and column_name = 'notes') then
    alter table public.gift_cards add column notes text;
  end if;
  if not exists (select 1 from information_schema.columns where table_schema = 'public' and table_name = 'gift_cards' and column_name = 'transactions') then
    alter table public.gift_cards add column transactions jsonb not null default '[]'::jsonb;
  end if;
  if not exists (select 1 from information_schema.columns where table_schema = 'public' and table_name = 'gift_cards' and column_name = 'last_used_at') then
    alter table public.gift_cards add column last_used_at timestamptz;
  end if;
  if not exists (select 1 from information_schema.columns where table_schema = 'public' and table_name = 'gift_cards' and column_name = 'issued_at') then
    alter table public.gift_cards add column issued_at timestamptz;
  end if;
  if not exists (select 1 from information_schema.columns where table_schema = 'public' and table_name = 'gift_cards' and column_name = 'deactivated_at') then
    alter table public.gift_cards add column deactivated_at timestamptz;
  end if;
  if not exists (select 1 from information_schema.columns where table_schema = 'public' and table_name = 'gift_cards' and column_name = 'deactivation_reason') then
    alter table public.gift_cards add column deactivation_reason text;
  end if;
end;
$$;

-- Staff/location active flags and staff metadata
do $$
begin
  if not exists (select 1 from information_schema.columns where table_schema = 'public' and table_name = 'staff_members' and column_name = 'is_active') then
    alter table public.staff_members add column is_active boolean not null default true;
  end if;
  if not exists (select 1 from information_schema.columns where table_schema = 'public' and table_name = 'staff_members' and column_name = 'preferred_name') then
    alter table public.staff_members add column preferred_name text;
  end if;
  if not exists (select 1 from information_schema.columns where table_schema = 'public' and table_name = 'staff_members' and column_name = 'work_email') then
    alter table public.staff_members add column work_email text;
  end if;
  if not exists (select 1 from information_schema.columns where table_schema = 'public' and table_name = 'staff_members' and column_name = 'title') then
    alter table public.staff_members add column title text;
  end if;
  if not exists (select 1 from information_schema.columns where table_schema = 'public' and table_name = 'staff_locations' and column_name = 'is_active') then
    alter table public.staff_locations add column is_active boolean not null default true;
  end if;
  if not exists (select 1 from information_schema.columns where table_schema = 'public' and table_name = 'locations' and column_name = 'is_active') then
    alter table public.locations add column is_active boolean not null default true;
  end if;
end;
$$;
