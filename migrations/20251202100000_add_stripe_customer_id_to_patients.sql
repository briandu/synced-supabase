-- Add stripe_customer_id column to patients table for Stripe integration
-- This allows linking patients to Stripe customers for payment processing

alter table public.patients
  add column if not exists stripe_customer_id text;

-- Add index for faster lookups by Stripe customer ID
create index if not exists idx_patients_stripe_customer_id
  on public.patients(stripe_customer_id)
  where stripe_customer_id is not null;

-- Add comment for documentation
comment on column public.patients.stripe_customer_id is 'Stripe customer ID for payment processing';

