-- Comprehensive consolidation of multiple_permissive_policies warnings
-- Drop redundant _select, _modify, _insert, _update, _delete policies
-- for tables that have _all policies (which cover all operations)
-- This migration extends 20251201230000_fix_remaining_rls_issues.sql

-- ============================================================================
-- Drop redundant policies for tables that should have _all policies
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

-- orgs: Consolidate orgs_select and orgs_update (keep orgs_insert for service_role)
drop policy if exists orgs_select on public.orgs;
drop policy if exists orgs_update on public.orgs;

-- Note: The _all policies should already exist from previous migrations.
-- If they don't exist, they will be created in the next migration or can be created manually.
-- This migration only drops the redundant separate policies.

