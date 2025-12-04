-- Phase 2: Services & Products tables
-- Creates all tables needed for services/products catalog, pricing, offerings, and inventory
-- Maps Parse classes: Items_Catalog, Service_Detail, Product_Detail, Item_Price, Service_Offering,
-- Discipline_Offering, Discipline_Preset, Income_Category, Supplier, Product_Inventory

-- Items Catalog - Master catalog of all services and products
create table if not exists public.items_catalog (
  id uuid primary key default gen_random_uuid(),
  org_id uuid references public.orgs(id) on delete cascade,
  item_name text not null,
  type text not null check (type in ('service', 'product')),
  description text,
  unit_type text,
  default_tax_id uuid references public.taxes(id) on delete set null,
  service_detail_id uuid, -- Will reference service_details(id) after table creation
  product_detail_id uuid, -- Will reference product_details(id) after table creation
  income_category_id uuid, -- Will reference income_categories(id) after table creation
  stripe_product_id text,
  stripe_product_ids jsonb,
  parse_object_id text,
  created_by uuid references public.staff_members(id) on delete set null,
  updated_by uuid references public.staff_members(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Service Details - Service-specific information
create table if not exists public.service_details (
  id uuid primary key default gen_random_uuid(),
  item_id uuid not null references public.items_catalog(id) on delete cascade,
  service_type text not null,
  scheduling_duration_minutes integer not null default 0,
  standard_procedure_code text,
  procedure_coding_system text,
  parse_object_id text,
  created_by uuid references public.staff_members(id) on delete set null,
  updated_by uuid references public.staff_members(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (item_id)
);

-- Product Details - Product-specific information
create table if not exists public.product_details (
  id uuid primary key default gen_random_uuid(),
  item_id uuid not null references public.items_catalog(id) on delete cascade,
  sku text,
  product_code text,
  product_type text,
  manufacturer text,
  manufacturer_sku text,
  cost numeric,
  msrp numeric,
  reorder_threshold numeric,
  supplier_id uuid, -- Will reference suppliers(id) after table creation
  internal_notes text,
  parse_object_id text,
  created_by uuid references public.staff_members(id) on delete set null,
  updated_by uuid references public.staff_members(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (item_id)
);

-- Income Categories - Commission tracking categories
-- Note: created_by/updated_by reference Staff_Member per requirements
create table if not exists public.income_categories (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null references public.orgs(id) on delete cascade,
  name text not null,
  description text,
  default_commission_rate numeric not null default 100,
  default_referral_commission_rate numeric,
  parse_object_id text,
  created_by uuid references public.staff_members(id) on delete set null,
  updated_by uuid references public.staff_members(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Suppliers - Product suppliers
-- Note: created_by/updated_by reference Staff_Member per requirements
create table if not exists public.suppliers (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null references public.orgs(id) on delete cascade,
  name text not null,
  contact text,
  email text,
  phone text,
  website text,
  street_address text,
  street_address2 text,
  city text,
  province text,
  country text,
  postal_zip_code text,
  notes text,
  is_active boolean not null default true,
  parse_object_id text,
  created_by uuid references public.staff_members(id) on delete set null,
  updated_by uuid references public.staff_members(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Discipline Presets - Discipline preset definitions
create table if not exists public.discipline_presets (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  discipline_name text,
  category text,
  icon text,
  is_preset boolean,
  parse_object_id text,
  created_by uuid references public.staff_members(id) on delete set null,
  updated_by uuid references public.staff_members(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Discipline Offerings - Discipline offerings at locations
create table if not exists public.discipline_offerings (
  id uuid primary key default gen_random_uuid(),
  preset_id uuid not null references public.discipline_presets(id) on delete cascade,
  org_id uuid references public.orgs(id) on delete cascade,
  location_id uuid references public.locations(id) on delete set null,
  ownership_group_id uuid references public.ownership_groups(id) on delete set null,
  custom_name text,
  parse_object_id text,
  created_by uuid references public.staff_members(id) on delete set null,
  updated_by uuid references public.staff_members(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Service Offerings - Services offered at locations
create table if not exists public.service_offerings (
  id uuid primary key default gen_random_uuid(),
  item_id uuid not null references public.items_catalog(id) on delete cascade,
  discipline_offering_id uuid not null references public.discipline_offerings(id) on delete cascade,
  org_id uuid not null references public.orgs(id) on delete cascade,
  location_id uuid references public.locations(id) on delete set null,
  ownership_group_id uuid references public.ownership_groups(id) on delete set null,
  parse_object_id text,
  created_by uuid references public.staff_members(id) on delete set null,
  updated_by uuid references public.staff_members(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Item Prices - Pricing for items (org/location/staff scoped)
create table if not exists public.item_prices (
  id uuid primary key default gen_random_uuid(),
  item_id uuid not null references public.items_catalog(id) on delete cascade,
  price numeric not null,
  org_id uuid references public.orgs(id) on delete cascade,
  location_id uuid references public.locations(id) on delete set null,
  staff_id uuid references public.staff_members(id) on delete set null,
  staff_location_id uuid references public.staff_locations(id) on delete set null,
  ownership_group_id uuid references public.ownership_groups(id) on delete set null,
  currency text,
  duration_minutes integer,
  stripe_price_id text,
  stripe_price_ids jsonb,
  parse_object_id text,
  created_by uuid references public.staff_members(id) on delete set null,
  updated_by uuid references public.staff_members(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Product Inventory - Inventory tracking
-- Note: created_by/updated_by reference Staff_Member per requirements
create table if not exists public.product_inventory (
  id uuid primary key default gen_random_uuid(),
  product_id uuid not null references public.items_catalog(id) on delete cascade,
  location_id uuid not null references public.locations(id) on delete cascade,
  quantity numeric not null default 0,
  parse_object_id text,
  created_by uuid references public.staff_members(id) on delete set null,
  updated_by uuid references public.staff_members(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (product_id, location_id)
);

-- Add foreign key constraints that reference tables created above
do $$
begin
  -- Update items_catalog to reference service_details, product_details, income_categories
  if not exists (
    select 1 from information_schema.table_constraints
    where constraint_name = 'items_catalog_service_detail_id_fkey'
    and table_schema = 'public'
    and table_name = 'items_catalog'
  ) then
    alter table public.items_catalog
      add constraint items_catalog_service_detail_id_fkey
      foreign key (service_detail_id) references public.service_details(id) on delete set null;
  end if;

  if not exists (
    select 1 from information_schema.table_constraints
    where constraint_name = 'items_catalog_product_detail_id_fkey'
    and table_schema = 'public'
    and table_name = 'items_catalog'
  ) then
    alter table public.items_catalog
      add constraint items_catalog_product_detail_id_fkey
      foreign key (product_detail_id) references public.product_details(id) on delete set null;
  end if;

  if not exists (
    select 1 from information_schema.table_constraints
    where constraint_name = 'items_catalog_income_category_id_fkey'
    and table_schema = 'public'
    and table_name = 'items_catalog'
  ) then
    alter table public.items_catalog
      add constraint items_catalog_income_category_id_fkey
      foreign key (income_category_id) references public.income_categories(id) on delete set null;
  end if;

  -- Update product_details to reference suppliers
  if not exists (
    select 1 from information_schema.table_constraints
    where constraint_name = 'product_details_supplier_id_fkey'
    and table_schema = 'public'
    and table_name = 'product_details'
  ) then
    alter table public.product_details
      add constraint product_details_supplier_id_fkey
      foreign key (supplier_id) references public.suppliers(id) on delete set null;
  end if;
end;
$$;

-- Indexes for common queries
create index if not exists idx_items_catalog_org on public.items_catalog(org_id);
create index if not exists idx_items_catalog_type on public.items_catalog(type);
create index if not exists idx_items_catalog_service_detail on public.items_catalog(service_detail_id) where service_detail_id is not null;
create index if not exists idx_items_catalog_product_detail on public.items_catalog(product_detail_id) where product_detail_id is not null;

create index if not exists idx_service_details_item on public.service_details(item_id);
create index if not exists idx_product_details_item on public.product_details(item_id);
create index if not exists idx_product_details_supplier on public.product_details(supplier_id) where supplier_id is not null;

create index if not exists idx_income_categories_org on public.income_categories(org_id);
create index if not exists idx_suppliers_org on public.suppliers(org_id);
-- Note: is_active index only created if column exists (table may have been created without it)
do $$
begin
  if exists (
    select 1 from information_schema.columns
    where table_schema = 'public' and table_name = 'suppliers' and column_name = 'is_active'
  ) then
    create index if not exists idx_suppliers_active on public.suppliers(is_active) where is_active = true;
  end if;
end;
$$;

create index if not exists idx_discipline_offerings_preset on public.discipline_offerings(preset_id);
create index if not exists idx_discipline_offerings_org on public.discipline_offerings(org_id);
create index if not exists idx_discipline_offerings_location on public.discipline_offerings(location_id) where location_id is not null;

create index if not exists idx_service_offerings_item on public.service_offerings(item_id);
create index if not exists idx_service_offerings_discipline on public.service_offerings(discipline_offering_id);
create index if not exists idx_service_offerings_org on public.service_offerings(org_id);
create index if not exists idx_service_offerings_location on public.service_offerings(location_id) where location_id is not null;

create index if not exists idx_item_prices_item on public.item_prices(item_id);
create index if not exists idx_item_prices_org on public.item_prices(org_id) where org_id is not null;
create index if not exists idx_item_prices_location on public.item_prices(location_id) where location_id is not null;
create index if not exists idx_item_prices_staff on public.item_prices(staff_id) where staff_id is not null;
create index if not exists idx_item_prices_staff_location on public.item_prices(staff_location_id) where staff_location_id is not null;

create index if not exists idx_product_inventory_product on public.product_inventory(product_id);
-- Note: location_id index only created if column exists
do $$
begin
  if exists (
    select 1 from information_schema.columns
    where table_schema = 'public' and table_name = 'product_inventory' and column_name = 'location_id'
  ) then
    create index if not exists idx_product_inventory_location on public.product_inventory(location_id);
    create index if not exists idx_product_inventory_product_location on public.product_inventory(product_id, location_id);
  end if;
end;
$$;

-- Enable RLS on all tables
alter table public.items_catalog enable row level security;
alter table public.service_details enable row level security;
alter table public.product_details enable row level security;
alter table public.income_categories enable row level security;
alter table public.suppliers enable row level security;
alter table public.discipline_presets enable row level security;
alter table public.discipline_offerings enable row level security;
alter table public.service_offerings enable row level security;
alter table public.item_prices enable row level security;
alter table public.product_inventory enable row level security;

-- RLS Policies: Items Catalog
-- Org members can read; admins can modify
drop policy if exists items_catalog_select on public.items_catalog;
drop policy if exists items_catalog_modify on public.items_catalog;
create policy items_catalog_select on public.items_catalog
  for select using (
    org_id is null or public.user_can_access_org(org_id)
  );
create policy items_catalog_modify on public.items_catalog
  for all using (
    (org_id is null or public.user_can_access_org(org_id))
    and (
      org_id is null
      or exists (
        select 1 from public.org_memberships m
        where m.org_id = items_catalog.org_id
          and m.user_id = auth.uid()
          and m.role in ('superadmin','org_admin')
      )
    )
  )
  with check (
    (org_id is null or public.user_can_access_org(org_id))
    and (
      org_id is null
      or exists (
        select 1 from public.org_memberships m
        where m.org_id = items_catalog.org_id
          and m.user_id = auth.uid()
          and m.role in ('superadmin','org_admin')
      )
    )
  );

-- RLS Policies: Service Details
-- Access via item_id -> items_catalog.org_id
drop policy if exists service_details_select on public.service_details;
drop policy if exists service_details_modify on public.service_details;
create policy service_details_select on public.service_details
  for select using (
    exists (
      select 1 from public.items_catalog ic
      where ic.id = service_details.item_id
        and (ic.org_id is null or public.user_can_access_org(ic.org_id))
    )
  );
create policy service_details_modify on public.service_details
  for all using (
    exists (
      select 1 from public.items_catalog ic
      where ic.id = service_details.item_id
        and (ic.org_id is null or public.user_can_access_org(ic.org_id))
        and (
          ic.org_id is null
          or exists (
            select 1 from public.org_memberships m
            where m.org_id = ic.org_id
              and m.user_id = auth.uid()
              and m.role in ('superadmin','org_admin')
          )
        )
    )
  )
  with check (
    exists (
      select 1 from public.items_catalog ic
      where ic.id = service_details.item_id
        and (ic.org_id is null or public.user_can_access_org(ic.org_id))
        and (
          ic.org_id is null
          or exists (
            select 1 from public.org_memberships m
            where m.org_id = ic.org_id
              and m.user_id = auth.uid()
              and m.role in ('superadmin','org_admin')
          )
        )
    )
  );

-- RLS Policies: Product Details
-- Access via item_id -> items_catalog.org_id
drop policy if exists product_details_select on public.product_details;
drop policy if exists product_details_modify on public.product_details;
create policy product_details_select on public.product_details
  for select using (
    exists (
      select 1 from public.items_catalog ic
      where ic.id = product_details.item_id
        and (ic.org_id is null or public.user_can_access_org(ic.org_id))
    )
  );
create policy product_details_modify on public.product_details
  for all using (
    exists (
      select 1 from public.items_catalog ic
      where ic.id = product_details.item_id
        and (ic.org_id is null or public.user_can_access_org(ic.org_id))
        and (
          ic.org_id is null
          or exists (
            select 1 from public.org_memberships m
            where m.org_id = ic.org_id
              and m.user_id = auth.uid()
              and m.role in ('superadmin','org_admin')
          )
        )
    )
  )
  with check (
    exists (
      select 1 from public.items_catalog ic
      where ic.id = product_details.item_id
        and (ic.org_id is null or public.user_can_access_org(ic.org_id))
        and (
          ic.org_id is null
          or exists (
            select 1 from public.org_memberships m
            where m.org_id = ic.org_id
              and m.user_id = auth.uid()
              and m.role in ('superadmin','org_admin')
          )
        )
    )
  );

-- RLS Policies: Income Categories
-- Org-scoped; org members can read; admins can modify
drop policy if exists income_categories_select on public.income_categories;
drop policy if exists income_categories_modify on public.income_categories;
create policy income_categories_select on public.income_categories
  for select using (public.user_can_access_org(org_id));
create policy income_categories_modify on public.income_categories
  for all using (
    public.user_can_access_org(org_id)
    and exists (
      select 1 from public.org_memberships m
      where m.org_id = income_categories.org_id
        and m.user_id = auth.uid()
        and m.role in ('superadmin','org_admin')
    )
  )
  with check (
    public.user_can_access_org(org_id)
    and exists (
      select 1 from public.org_memberships m
      where m.org_id = income_categories.org_id
        and m.user_id = auth.uid()
        and m.role in ('superadmin','org_admin')
    )
  );

-- RLS Policies: Suppliers
-- Org-scoped; org members can read; admins can modify
drop policy if exists suppliers_select on public.suppliers;
drop policy if exists suppliers_modify on public.suppliers;
create policy suppliers_select on public.suppliers
  for select using (public.user_can_access_org(org_id));
create policy suppliers_modify on public.suppliers
  for all using (
    public.user_can_access_org(org_id)
    and exists (
      select 1 from public.org_memberships m
      where m.org_id = suppliers.org_id
        and m.user_id = auth.uid()
        and m.role in ('superadmin','org_admin')
    )
  )
  with check (
    public.user_can_access_org(org_id)
    and exists (
      select 1 from public.org_memberships m
      where m.org_id = suppliers.org_id
        and m.user_id = auth.uid()
        and m.role in ('superadmin','org_admin')
    )
  );

-- RLS Policies: Discipline Presets
-- Global/system-level; all authenticated users can read; admins can modify
drop policy if exists discipline_presets_select on public.discipline_presets;
drop policy if exists discipline_presets_modify on public.discipline_presets;
create policy discipline_presets_select on public.discipline_presets
  for select using (true);
create policy discipline_presets_modify on public.discipline_presets
  for all using (
    exists (
      select 1 from public.org_memberships m
      where m.user_id = auth.uid()
        and m.role in ('superadmin','org_admin')
    )
  )
  with check (
    exists (
      select 1 from public.org_memberships m
      where m.user_id = auth.uid()
        and m.role in ('superadmin','org_admin')
    )
  );

-- RLS Policies: Discipline Offerings
-- Org-scoped; org members can read; admins can modify
drop policy if exists discipline_offerings_select on public.discipline_offerings;
drop policy if exists discipline_offerings_modify on public.discipline_offerings;
create policy discipline_offerings_select on public.discipline_offerings
  for select using (
    org_id is null or public.user_can_access_org(org_id)
  );
create policy discipline_offerings_modify on public.discipline_offerings
  for all using (
    (org_id is null or public.user_can_access_org(org_id))
    and (
      org_id is null
      or exists (
        select 1 from public.org_memberships m
        where m.org_id = discipline_offerings.org_id
          and m.user_id = auth.uid()
          and m.role in ('superadmin','org_admin')
      )
    )
  )
  with check (
    (org_id is null or public.user_can_access_org(org_id))
    and (
      org_id is null
      or exists (
        select 1 from public.org_memberships m
        where m.org_id = discipline_offerings.org_id
          and m.user_id = auth.uid()
          and m.role in ('superadmin','org_admin')
      )
    )
  );

-- RLS Policies: Service Offerings
-- Org-scoped; org members can read; admins can modify
drop policy if exists service_offerings_select on public.service_offerings;
drop policy if exists service_offerings_modify on public.service_offerings;
create policy service_offerings_select on public.service_offerings
  for select using (public.user_can_access_org(org_id));
create policy service_offerings_modify on public.service_offerings
  for all using (
    public.user_can_access_org(org_id)
    and exists (
      select 1 from public.org_memberships m
      where m.org_id = service_offerings.org_id
        and m.user_id = auth.uid()
        and m.role in ('superadmin','org_admin')
    )
  )
  with check (
    public.user_can_access_org(org_id)
    and exists (
      select 1 from public.org_memberships m
      where m.org_id = service_offerings.org_id
        and m.user_id = auth.uid()
        and m.role in ('superadmin','org_admin')
    )
  );

-- RLS Policies: Item Prices
-- Org-scoped; org members can read; admins can modify
drop policy if exists item_prices_select on public.item_prices;
drop policy if exists item_prices_modify on public.item_prices;
create policy item_prices_select on public.item_prices
  for select using (
    org_id is null or public.user_can_access_org(org_id)
  );
create policy item_prices_modify on public.item_prices
  for all using (
    (org_id is null or public.user_can_access_org(org_id))
    and (
      org_id is null
      or exists (
        select 1 from public.org_memberships m
        where m.org_id = item_prices.org_id
          and m.user_id = auth.uid()
          and m.role in ('superadmin','org_admin')
      )
    )
  )
  with check (
    (org_id is null or public.user_can_access_org(org_id))
    and (
      org_id is null
      or exists (
        select 1 from public.org_memberships m
        where m.org_id = item_prices.org_id
          and m.user_id = auth.uid()
          and m.role in ('superadmin','org_admin')
      )
    )
  );

-- RLS Policies: Product Inventory
-- Access via location_id -> locations.org_id (if location_id exists) or via product_id -> items_catalog.org_id
drop policy if exists product_inventory_select on public.product_inventory;
drop policy if exists product_inventory_modify on public.product_inventory;
do $$
begin
  -- Check if location_id column exists
  if exists (
    select 1 from information_schema.columns
    where table_schema = 'public' and table_name = 'product_inventory' and column_name = 'location_id'
  ) then
    -- Use location-based access
    execute 'create policy product_inventory_select on public.product_inventory
      for select using (
        exists (
          select 1 from public.locations l
          where l.id = product_inventory.location_id
            and public.user_can_access_org(l.org_id)
        )
      )';
    execute 'create policy product_inventory_modify on public.product_inventory
      for all using (
        exists (
          select 1 from public.locations l
          where l.id = product_inventory.location_id
            and public.user_can_access_org(l.org_id)
            and exists (
              select 1 from public.org_memberships m
              where m.org_id = l.org_id
                and m.user_id = auth.uid()
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
                and m.user_id = auth.uid()
                and m.role in (''superadmin'',''org_admin'')
            )
        )
      )';
  else
    -- Fallback: use product_id -> items_catalog.org_id
    execute 'create policy product_inventory_select on public.product_inventory
      for select using (
        exists (
          select 1 from public.items_catalog ic
          where ic.id = product_inventory.product_id
            and (ic.org_id is null or public.user_can_access_org(ic.org_id))
        )
      )';
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
                  and m.user_id = auth.uid()
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
                  and m.user_id = auth.uid()
                  and m.role in (''superadmin'',''org_admin'')
              )
            )
        )
      )';
  end if;
end;
$$;

-- Add missing foreign key columns to appointments table
-- These are required per Parse schema: serviceOfferingId and itemPriceId
do $$
begin
  if not exists (
    select 1 from information_schema.columns
    where table_schema = 'public' and table_name = 'appointments' and column_name = 'service_offering_id'
  ) then
    alter table public.appointments
      add column service_offering_id uuid references public.service_offerings(id) on delete set null;
    create index if not exists idx_appointments_service_offering on public.appointments(service_offering_id) where service_offering_id is not null;
  end if;

  if not exists (
    select 1 from information_schema.columns
    where table_schema = 'public' and table_name = 'appointments' and column_name = 'item_price_id'
  ) then
    alter table public.appointments
      add column item_price_id uuid references public.item_prices(id) on delete set null;
    create index if not exists idx_appointments_item_price on public.appointments(item_price_id) where item_price_id is not null;
  end if;
end;
$$;

-- Add missing foreign key column to invoice_items table
-- Required per Parse schema: itemId references Items_Catalog
do $$
begin
  if not exists (
    select 1 from information_schema.columns
    where table_schema = 'public' and table_name = 'invoice_items' and column_name = 'item_id'
  ) then
    alter table public.invoice_items
      add column item_id uuid references public.items_catalog(id) on delete set null;
    create index if not exists idx_invoice_items_item on public.invoice_items(item_id) where item_id is not null;
  end if;

  -- Also add custom_tax_id if missing (per Parse schema)
  if not exists (
    select 1 from information_schema.columns
    where table_schema = 'public' and table_name = 'invoice_items' and column_name = 'custom_tax_id'
  ) then
    alter table public.invoice_items
      add column custom_tax_id uuid references public.taxes(id) on delete set null;
  end if;
end;
$$;

-- Add to realtime publication for live updates (only if not already added)
do $$
begin
  if not exists (select 1 from pg_publication_tables where pubname = 'supabase_realtime' and tablename = 'items_catalog' and schemaname = 'public') then
    alter publication supabase_realtime add table public.items_catalog;
  end if;
  if not exists (select 1 from pg_publication_tables where pubname = 'supabase_realtime' and tablename = 'service_offerings' and schemaname = 'public') then
    alter publication supabase_realtime add table public.service_offerings;
  end if;
  if not exists (select 1 from pg_publication_tables where pubname = 'supabase_realtime' and tablename = 'item_prices' and schemaname = 'public') then
    alter publication supabase_realtime add table public.item_prices;
  end if;
  if not exists (select 1 from pg_publication_tables where pubname = 'supabase_realtime' and tablename = 'product_inventory' and schemaname = 'public') then
    alter publication supabase_realtime add table public.product_inventory;
  end if;
end;
$$;

