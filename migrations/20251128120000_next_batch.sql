-- Next batch of Supabase schema changes (apply once; keep idempotent ALTER/CREATE statements here).
-- Add future deltas below; when applied, create the next numbered file rather than reusing this one.

-- Add tax tables used for Supabase-native tax calculations
do $$
begin
  if not exists (select 1 from information_schema.tables where table_schema = 'public' and table_name = 'taxes') then
    create table public.taxes (
      id uuid primary key default gen_random_uuid(),
      org_id uuid not null references public.orgs(id) on delete cascade,
      name text not null,
      rate numeric not null,
      is_active boolean not null default true,
      parse_object_id text,
      created_by uuid references public.staff_members(id),
      updated_by uuid references public.staff_members(id),
      created_at timestamptz not null default now(),
      updated_at timestamptz not null default now()
    );
    create index idx_taxes_org on public.taxes(org_id);
  end if;

  if not exists (select 1 from information_schema.tables where table_schema = 'public' and table_name = 'location_taxes') then
    create table public.location_taxes (
      id uuid primary key default gen_random_uuid(),
      location_id uuid not null references public.locations(id) on delete cascade,
      tax_id uuid not null references public.taxes(id) on delete cascade,
      unique (location_id, tax_id)
    );
    create index idx_location_taxes_location on public.location_taxes(location_id);
    create index idx_location_taxes_tax on public.location_taxes(tax_id);
  end if;
end;
$$;
