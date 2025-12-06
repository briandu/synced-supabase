# complete_onboarding_transaction Function

## Overview

The `complete_onboarding_transaction` function handles the complete onboarding process for a new organization in a single atomic database transaction. This ensures data integrity - if any step fails, all changes are automatically rolled back.

## Purpose

This function replaces the previous approach of multiple separate GraphQL mutations from the frontend, which could leave partial/broken data if any step failed. By executing all operations in a single PostgreSQL function, we guarantee:

- **Atomicity**: All operations succeed or fail together
- **Data Integrity**: No orphaned records or broken relationships
- **Performance**: Single database round-trip instead of 8+ separate queries
- **Consistency**: Centralized business logic in the database

## Function Signature

```sql
complete_onboarding_transaction(
  p_user_id uuid,                        -- REQUIRED: Current user's ID
  p_org_name text,                       -- REQUIRED: Organization name
  p_org_subdomain text default null,     -- Organization subdomain (must be unique)
  p_org_website text default null,
  p_org_previous_software text default null,
  p_org_recommendation_source text default null,
  p_org_account_type text default null,
  p_org_company_size text default null,
  p_org_logo_url text default null,      -- URL from pre-uploaded logo file
  p_location_name text,                  -- REQUIRED: Location name
  p_location_address_line1 text default null,
  p_location_address_line2 text default null,
  p_location_city text default null,
  p_location_province_state text default null,
  p_location_postal_zip_code text default null,
  p_location_country text default null,
  p_location_timezone text default 'America/Toronto',
  p_location_image_url text default null, -- URL from pre-uploaded location image
  p_operating_hours jsonb default null,   -- Array of operating hours objects
  p_staff_first_name text,                -- REQUIRED: Staff member first name
  p_staff_last_name text,                 -- REQUIRED: Staff member last name
  p_staff_email text                      -- REQUIRED: Staff member email
) returns jsonb
```

## Parameters

### Required Parameters

| Parameter | Type | Description |
|-----------|------|-------------|
| `p_user_id` | `uuid` | The authenticated user's ID from `auth.users` |
| `p_org_name` | `text` | Organization/company name |
| `p_location_name` | `text` | Name of the primary location |
| `p_staff_first_name` | `text` | First name of the staff member being created |
| `p_staff_last_name` | `text` | Last name of the staff member |
| `p_staff_email` | `text` | Email address of the staff member |

### Optional Parameters

#### Organization Fields
- `p_org_subdomain` - Unique subdomain for the organization (e.g., "myclinic")
- `p_org_website` - Organization website URL
- `p_org_previous_software` - Previous software used (for analytics)
- `p_org_recommendation_source` - How they heard about the platform
- `p_org_account_type` - Type of account (e.g., "clinic", "practice")
- `p_org_company_size` - Company size category
- `p_org_logo_url` - URL to uploaded organization logo

#### Location Fields
- `p_location_address_line1` - Street address line 1
- `p_location_address_line2` - Street address line 2
- `p_location_city` - City
- `p_location_province_state` - Province/State
- `p_location_postal_zip_code` - Postal/ZIP code
- `p_location_country` - Country
- `p_location_timezone` - Timezone (defaults to 'America/Toronto')
- `p_location_image_url` - URL to uploaded location image

#### Operating Hours
- `p_operating_hours` - JSONB array of operating hours objects

Operating hours format:
```json
[
  {
    "day": 0,           // 0 = Sunday, 1 = Monday, ... 6 = Saturday
    "is_open": false,
    "start_time": "09:00",
    "end_time": "17:00"
  },
  {
    "day": 1,
    "is_open": true,
    "start_time": "09:00",
    "end_time": "17:00"
  }
  // ... more days
]
```

## Return Value

Returns a JSONB object with the following structure:

```json
{
  "success": true,
  "org_id": "uuid",
  "ownership_group_id": "uuid",
  "location_id": "uuid",
  "staff_member_id": "uuid",
  "staff_location_id": "uuid"
}
```

### Return Fields

| Field | Type | Description |
|-------|------|-------------|
| `success` | `boolean` | Always `true` on success |
| `org_id` | `uuid` | ID of the created organization |
| `ownership_group_id` | `uuid` | ID of the created ownership group |
| `location_id` | `uuid` | ID of the created location |
| `staff_member_id` | `uuid` | ID of the created staff member |
| `staff_location_id` | `uuid` | ID of the staff-location link |

## Transaction Operations

The function performs the following operations in a single transaction:

1. **Validation** - Validates all required inputs
2. **Duplicate Check** - Checks for existing subdomain (if provided)
3. **Create Ownership Group** - Creates ownership group for the organization
4. **Create Organization** - Creates the organization record
5. **Create Org Membership** - Links user to organization with 'org_admin' role
6. **Create Location** - Creates the primary location (marked as HQ)
7. **Create Staff Member** - Creates staff record linked to user
8. **Create Staff-Location Link** - Links staff to location
9. **Create Operating Hours** - Creates operating hours records (if provided)
10. **Assign Owner Role** - Assigns Owner role if it exists in the org
11. **Update Profile** - Sets `is_onboarding_complete = true` on user profile

## Error Handling

The function will raise an exception and rollback all changes if:

- Any required parameter is missing or empty
- The subdomain already exists
- Any database constraint is violated
- Any insert/update operation fails

Error format:
```
Error completing onboarding: [specific error message]
```

## Usage Example

### From JavaScript/TypeScript (Supabase Client)

```javascript
import { createClient } from '@supabase/supabase-js';

const supabase = createClient(supabaseUrl, supabaseKey);

// Upload files first (if needed)
let orgLogoUrl = null;
if (orgLogoFile) {
  const { data } = await supabase.storage
    .from('org-logos')
    .upload(`logos/${Date.now()}-${orgLogoFile.name}`, orgLogoFile);
  
  const { data: { publicUrl } } = supabase.storage
    .from('org-logos')
    .getPublicUrl(data.path);
  
  orgLogoUrl = publicUrl;
}

// Call the RPC function
const { data, error } = await supabase.rpc('complete_onboarding_transaction', {
  p_user_id: user.id,
  p_org_name: 'My Clinic',
  p_org_subdomain: 'myclinic',
  p_org_website: 'https://myclinic.com',
  p_org_logo_url: orgLogoUrl,
  p_location_name: 'Main Office',
  p_location_address_line1: '123 Main St',
  p_location_city: 'Toronto',
  p_location_province_state: 'ON',
  p_location_postal_zip_code: 'M1A 1A1',
  p_location_country: 'Canada',
  p_location_timezone: 'America/Toronto',
  p_operating_hours: [
    { day: 0, is_open: false, start_time: '09:00', end_time: '17:00' },
    { day: 1, is_open: true, start_time: '09:00', end_time: '17:00' },
    { day: 2, is_open: true, start_time: '09:00', end_time: '17:00' },
    { day: 3, is_open: true, start_time: '09:00', end_time: '17:00' },
    { day: 4, is_open: true, start_time: '09:00', end_time: '17:00' },
    { day: 5, is_open: true, start_time: '09:00', end_time: '17:00' },
    { day: 6, is_open: false, start_time: '09:00', end_time: '17:00' },
  ],
  p_staff_first_name: 'John',
  p_staff_last_name: 'Doe',
  p_staff_email: user.email,
});

if (error) {
  console.error('Onboarding failed:', error.message);
} else {
  console.log('Onboarding successful:', data);
  // Redirect to dashboard or next step
}
```

## Prerequisites

1. **Owner Role**: The function will assign the "Owner" role to the staff member if a role named "Owner" exists in the organization's roles table. If no Owner role exists, this step is skipped (no error).

2. **User Profile**: A profile record must exist for the user in the `profiles` table.

3. **File Uploads**: Files (org logo, location image) must be uploaded BEF
