# Missing Parse Fields Migration Summary

**Date:** January 6, 2025  
**Migration File:** `migrations/20251202180000_add_missing_parse_fields.sql`  
**Status:** ✅ Created

---

## Overview

This migration adds fields that were present in the Parse database but were missing in the Supabase migration. The analysis revealed that many fields were not migrated, likely due to an incomplete initial migration rather than intentional exclusions.

---

## Fields Added by Category

### 1. Audit Fields (updated_by)

Added `updated_by` column to all tables to track who last modified each record:

- ✅ `orgs.updated_by`
- ✅ `ownership_groups.updated_by`
- ✅ `locations.updated_by`
- ✅ `staff_members.updated_by`
- ✅ `staff_locations.updated_by`
- ✅ `org_memberships.updated_at` and `org_memberships.updated_by`

### 2. Branding Fields

**Organizations (`orgs`):**
- ✅ `currency` - Organization currency code
- ✅ `primary_color` - Primary brand color (hex)
- ✅ `secondary_color` - Secondary brand color (hex)

**Locations (`locations`):**
- ✅ `currency` - Location currency code
- ✅ `primary_color` - Primary brand color for location
- ✅ `secondary_color` - Secondary brand color for location

### 3. Ownership Groups

**Additional fields:**
- ✅ `legal_name` - Legal name of ownership group
- ✅ `tax_number` - Tax identification number

### 4. Locations - Contact & Address Fields

**Contact Information:**
- ✅ `operating_name` - Operating/trading name
- ✅ `legal_name` - Legal name
- ✅ `phone_number` - Phone number
- ✅ `fax_number` - Fax number
- ✅ `email` - Location email
- ✅ `website` - Location website

**Billing Address:**
- ✅ `billing_address_line1`
- ✅ `billing_address_line2`
- ✅ `billing_city`
- ✅ `billing_province_state`
- ✅ `billing_country`
- ✅ `billing_postal_zip_code`
- ✅ `use_location_for_billing` (boolean, default: true)

**Additional:**
- ✅ `tax_number` - Tax identification number
- ✅ `key_contact_id` - Key contact user reference
- ✅ `logo_url` - Location logo (separate from featured image)
- ✅ `short_description` - Short description
- ✅ `long_description` - Long description
- ✅ `operating_hours` - Operating hours (JSONB array)

### 5. Staff Members

**Name Fields:**
- ✅ `middle_name` - Middle name
- ✅ `prefix` - Name prefix (Dr., Mr., Ms., etc.)

**Personal Information:**
- ✅ `bio` - Biography/professional summary
- ✅ `date_of_birth` - Date of birth
- ✅ `gender` - Gender
- ✅ `is_provider` - Provider flag
- ✅ `firebase_uid` - Firebase UID (for migration compatibility)

**Address Fields:**
- ✅ `address_line1`
- ✅ `address_line2`
- ✅ `city`
- ✅ `province_state`
- ✅ `country`
- ✅ `postal_zip_code`

**Contact Fields:**
- ✅ `mobile` - Mobile phone number
- ✅ `work_phone` - Work phone (separate from `phone`)

**Media:**
- ✅ `profile_picture_url` - Profile picture URL
- ✅ `signature` - Digital signature

### 6. Staff Locations

**Role & Status:**
- ✅ `role_id` - Role at this specific location
- ✅ `is_provider` - Provider status at this location

**Location-Specific Details:**
- ✅ `title` - Job title at this location
- ✅ `bio` - Biography specific to this location
- ✅ `work_email` - Work email at this location
- ✅ `work_phone` - Work phone at this location

**Employment Details:**
- ✅ `start_date` - Employment start date
- ✅ `end_date` - Employment end date (null if current)
- ✅ `employment_type` - Type of employment (full-time, part-time, contractor)

---

## Migration Details

### File Structure

The migration is organized into logical sections:
1. Audit fields (updated_by)
2. Branding fields (currency, colors)
3. Ownership groups additional fields
4. Locations contact/address/descriptive fields
5. Staff members additional fields
6. Staff locations location-specific fields

### Safety Features

- ✅ All ALTER statements are wrapped in `DO $$` blocks with existence checks
- ✅ Safe to rerun - checks for column existence before adding
- ✅ Foreign key constraints properly defined
- ✅ Default values set where appropriate
- ✅ Comments added for documentation

### Foreign Key References

All foreign keys properly reference:
- `auth.users(id)` for user references
- `public.roles(id)` for role references
- Proper `on delete set null` or `on delete cascade` as appropriate

---

## Fields NOT Added (Intentionally or Not Applicable)

### Parse File Fields
- `logo` (File) → Using `logo_url` instead (Supabase Storage pattern)
- `featuredImage` (File) → Already using `featured_image_url`
- `profilePicture` (File) → Using `profile_picture_url`

### Provider Credentials
- `providerCredentialId` in `staff_locations` → Commented out (requires `provider_credentials` table to exist first)

### Profiles Table
- Many `_User` fields intentionally simplified in `profiles` table
- Some fields may be handled by Supabase Auth (`username`, `email_verified`, etc.)

---

## Next Steps

1. **Review Migration** - Review the migration file before applying
2. **Test Migration** - Test on a development/staging database first
3. **Apply Migration** - Run the migration on your Supabase database
4. **Update Functions** - Update any functions that create/update these tables to include new fields
5. **Update Frontend** - Update frontend code to use new fields where applicable
6. **Data Migration** - If migrating from Parse, create scripts to backfill data into new fields

---

## Related Files

- Migration file: `migrations/20251202180000_add_missing_parse_fields.sql`
- Parse schema reference: `docs/SUPABASE_MIGRATION_REQUIREMENTS.md`
- Onboarding migration: `migrations/20251202160000_add_onboarding_columns.sql`

---

## Notes

- All fields are nullable unless specified with `not null default`
- JSONB fields (`operating_hours`) can store complex structured data
- Date fields use PostgreSQL `date` type (not `timestamptz`)
- Text fields have no length limits (PostgreSQL best practice)
