# Onboarding Backend Integration Guide

This guide explains how to integrate the `complete_onboarding_transaction` backend function into your front-end application.

## Overview

The onboarding process has been moved from multiple GraphQL mutations to a single PostgreSQL function that executes all operations atomically. This guide shows you how to update your front-end code to use the new approach.

## Migration Steps

### Step 1: Upload Files First

**Before** (Old Approach):
```javascript
// Files were uploaded in between other operations
const orgResult = await createOrganization(...);
// Upload org logo after org is created
if (orgLogoFile) {
  const { name, url } = await uploadParseFileREST(orgLogoFile);
  await updateOrganization({ logo: url });
}
```

**After** (New Approach):
```javascript
// Upload ALL files FIRST, get URLs
let orgLogoUrl = null;
let locationImageUrl = null;

if (finalOnboardingData.orgLogo) {
  const orgLogoFile = dataURLtoFile(finalOnboardingData.orgLogo, 'organization-logo.jpg');
  if (orgLogoFile) {
    const { name, url } = await uploadParseFileREST(orgLogoFile);
    orgLogoUrl = url;
  }
}

if (finalOnboardingData.locationImage) {
  const locationImageFile = dataURLtoFile(finalOnboardingData.locationImage, 'location-featured-image.jpg');
  if (locationImageFile) {
    const { name, url } = await uploadParseFileREST(locationImageFile);
    locationImageUrl = url;
  }
}

// Then call the function with URLs
const { data, error } = await supabase.rpc('complete_onboarding_transaction', {
  // ... all params including orgLogoUrl and locationImageUrl
});
```

### Step 2: Replace GraphQL Mutations with Single RPC Call

**Before** (Old Approach - Multiple Mutations):
```javascript
// 1. Create org
const orgResult = await createOrganization({ variables: { input: orgInput } });

// 2. Create staff location with nested resources
const staffLocationResult = await createStaffLocationWithNestedResources({
  variables: { staffLocationInput }
});

// 3. Upload location image
await updateLocation({ variables: { input: { featuredImage: ... } } });

// 4. Create operating hours
await Promise.all(operatingHours.map(hour => 
  createOperatingHour({ variables: { input: hour } })
));

// 5. Get owner role
const { data: roleData } = await getOwnerRole({ variables: { name: 'Owner' } });

// 6. Create staff permission
await createStaffPermission({ variables: { input: { roleId: ownerRole.id } } });

// 7. Update user onboarding status
await updateUserOnboardingStatus({ variables: { input: { isOnboardingComplete: true } } });
```

**After** (New Approach - Single RPC Call):
```javascript
const { data, error } = await supabaseClient.rpc('complete_onboarding_transaction', {
  p_user_id: user.id,
  p_org_name: finalOnboardingData.organizationName,
  p_org_subdomain: finalOnboardingData.subdomain,
  p_org_website: finalOnboardingData.website,
  p_org_previous_software: finalOnboardingData.previousSoftware,
  p_org_recommendation_source: data.recommendationSource,
  p_org_account_type: finalOnboardingData.accountType,
  p_org_company_size: finalOnboardingData.teamSize,
  p_org_logo_url: orgLogoUrl,
  p_location_name: finalOnboardingData.locationName || finalOnboardingData.organizationName,
  p_location_address_line1: finalOnboardingData.address,
  p_location_address_line2: null,
  p_location_city: finalOnboardingData.city,
  p_location_province_state: finalOnboardingData.state,
  p_location_postal_zip_code: finalOnboardingData.postalZipCode,
  p_location_country: finalOnboardingData.country,
  p_location_timezone: 'America/Toronto',
  p_location_image_url: locationImageUrl,
  p_operating_hours: finalOnboardingData.operatingHours,
  p_staff_first_name: currentUserFirstName,
  p_staff_last_name: currentUserLastName,
  p_staff_email: user.email,
});

if (error) {
  enqueueSnackbar('Onboarding failed. Please try again.', { variant: 'error' });
  return;
}

// Success! All data was created
console.log('Created IDs:', data);
```

### Step 3: Update Operating Hours Format

The backend expects a JSONB array with a specific structure:

```javascript
// Convert from front-end format to backend format
const operatingHoursForBackend = finalOnboardingData.operatingHours?.map(dayData => {
  if (!dayData || dayData.day === undefined) return null;

  if (dayData.isOpen && dayData.intervals && dayData.intervals.length > 0) {
    const interval = dayData.intervals[0];
    return {
      day: dayData.day,
      is_open: true,
      start_time: interval.start, // e.g., "09:00"
      end_time: interval.end,     // e.g., "17:00"
    };
  }

  return {
    day: dayData.day,
    is_open: false,
    start_time: '09:00',
    end_time: '17:00',
  };
}).filter(Boolean); // Remove null entries
```

### Step 4: Update Error Handling

**Before** (Old Approach):
```javascript
try {
  const orgResult = await createOrganization(...);
  // If this fails, we have partial data
  
  const locationResult = await createLocation(...);
  // If this fails, we have org but no location
  
  // ... more operations
} catch (error) {
  // Cleanup is difficult - what succeeded and what failed?
  enqueueSnackbar('Onboarding failed', { variant: 'error' });
}
```

**After** (New Approach):
```javascript
const { data, error } = await supabaseClient.rpc('complete_onboarding_transaction', {
  // ... params
});

if (error) {
  // Transaction automatically rolled back - no partial data
  console.error('Onboarding error:', error.message);
  enqueueSnackbar('Onboarding failed: ' + error.message, { variant: 'error' });
  return;
}

// Success! All data was created atomically
enqueueSnackbar('Onboarding complete!', { variant: 'success' });
router.push('/dashboard');
```

## Complete Example

Here's a complete example of the refactored onboarding submission:

```javascript
const onSubmit = async (data) => {
  const finalOnboardingData = { ...existingData, recommendation_source: data.recommendationSource };

  // Prepare staff name
  let currentUserFirstName = finalOnboardingData.firstName || firstName || 'User';
  let currentUserLastName = finalOnboardingData.lastName || '';

  // Validate user ID
  if (!user.id) {
    enqueueSnackbar('User ID is not available. Cannot complete onboarding.', { variant: 'error' });
    return;
  }

  try {
    // STEP 1: Upload files first
    setUploading(true);
    let orgLogoUrl = null;
    let locationImageUrl = null;

    // Upload org logo
    if (finalOnboardingData.orgLogo) {
      const orgLogoFile = dataURLtoFile(finalOnboardingData.orgLogo, 'organization-logo.jpg');
      if (orgLogoFile) {
        try {
          const { name, url } = await uploadParseFileREST(orgLogoFile);
          orgLogoUrl = url;
        } catch (e) {
          enqueueSnackbar('Could not upload organization logo, but onboarding will continue.', {
            variant: 'warning',
          });
        }
      }
    }

    // Upload location image
    if (finalOnboardingData.locationImage) {
      const locationImageFile = dataURLtoFile(finalOnboardingData.locationImage, 'location-image.jpg');
      if (locationImageFile) {
        try {
          const { name, url } = await uploadParseFileREST(locationImageFile);
          locationImageUrl = url;
        } catch (e) {
          enqueueSnackbar('Could not upload location image, but onboarding will continue.', {
            variant: 'warning',
          });
        }
      }
    }

    setUploading(false);

    // STEP 2: Prepare operating hours
    const operatingHours = finalOnboardingData.operatingHours?.map(dayData => {
      if (!dayData || dayData.day === undefined) return null;

      if (dayData.isOpen && dayData.intervals && dayData.intervals.length > 0) {
        const interval = dayData.intervals[0];
        return {
          day: dayData.day,
          is_open: true,
          start_time: interval.start,
          end_time: interval.end,
        };
      }

      return {
        day: dayData.day,
        is_open: false,
        start_time: '09:00',
        end_time: '17:00',
      };
    }).filter(Boolean);
