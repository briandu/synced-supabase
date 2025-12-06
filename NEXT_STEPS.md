# Next Steps for Onboarding Transaction Function

## ✅ What's Complete (Backend)

All backend work is **complete and ready to use**:

1. ✅ Database schema migrations created
2. ✅ `complete_onboarding_transaction` function implemented
3. ✅ Comprehensive test suite written
4. ✅ Complete documentation created
5. ✅ README updated

## 📋 What's Next (Frontend Integration)

The remaining work is in the **frontend repository** (`synced-admin-portal`):

### Step 1: Apply Migrations to Database

```bash
cd c:\Users\Brian Du\Synced\Code\synced-supabase
supabase db push
```

This will apply:
- `20251202160000_add_onboarding_columns.sql` - Adds missing schema columns
- `20251202170000_complete_onboarding_transaction.sql` - Creates the function

### Step 2: Test the Backend Function (Optional but Recommended)

```bash
cd c:\Users\Brian Du\Synced\Code\synced-supabase\tests

# Copy .env.example to .env
cp .env.example .env

# Edit .env with your Supabase credentials
# SUPABASE_URL=https://your-project.supabase.co
# SUPABASE_SERVICE_ROLE_KEY=your-service-role-key

# Install dependencies
npm install

# Run tests
npm test
```

### Step 3: Update Frontend Code

**File to Edit**: `c:\Users\Brian Du\Seedwell\Coding\synced-admin-portal\src\pages\onboarding\recommendation-source.js`

**Reference Guide**: `docs/integration/onboarding-backend-integration.md`

**Changes Required**:

1. **Import Supabase Client** (if not already imported)
   ```javascript
   import { supabaseClient } from '@/lib/supabaseClient';
   ```

2. **Restructure the `onSubmit` function**:
   
   a. Upload files FIRST (before function call):
   ```javascript
   // Upload org logo
   let orgLogoUrl = null;
   if (finalOnboardingData.orgLogo) {
     const orgLogoFile = dataURLtoFile(finalOnboardingData.orgLogo, 'org-logo.jpg');
     if (orgLogoFile) {
       const { name, url } = await uploadParseFileREST(orgLogoFile);
       orgLogoUrl = url;
     }
   }

   // Upload location image
   let locationImageUrl = null;
   if (finalOnboardingData.locationImage) {
     const locationImageFile = dataURLtoFile(finalOnboardingData.locationImage, 'location-image.jpg');
     if (locationImageFile) {
       const { name, url } = await uploadParseFileREST(locationImageFile);
       locationImageUrl = url;
     }
   }
   ```

   b. Convert operating hours to backend format:
   ```javascript
   const operatingHours = finalOnboardingData.operatingHours?.map(dayData => {
     if (!dayData || dayData.day === undefined) return null;
     
     if (dayData.isOpen && dayData.intervals?.length > 0) {
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
   ```

   c. Replace ALL GraphQL mutations with single RPC call:
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
     p_location_city: finalOnboardingData.city,
     p_location_province_state: finalOnboardingData.state,
     p_location_postal_zip_code: finalOnboardingData.postalZipCode,
     p_location_country: finalOnboardingData.country,
     p_location_timezone: 'America/Toronto',
     p_location_image_url: locationImageUrl,
     p_operating_hours: operatingHours,
     p_staff_first_name: currentUserFirstName,
     p_staff_last_name: currentUserLastName,
     p_staff_email: user.email,
   });

   if (error) {
     enqueueSnackbar('Onboarding failed: ' + error.message, { variant: 'error' });
     return;
   }

   // Success!
   enqueueSnackbar('Onboarding complete!', { variant: 'success' });
   
   // Reset Redux state
   dispatch(resetOnboarding());
   dispatch(resetStaffOnboarding());
   dispatch(resetFlowType());
   await persistor.flush();
   
   // Redirect
   router.push('/dashboard');
   ```

3. **Remove Old Code**:
   - Delete `createOrganization` mutation call (lines ~206-217)
   - Delete `createStaffLocationWithNestedResources` mutation call (lines ~278-285)
   - Delete `getOrg` lazy query and related code (lines ~152-163)
   - Delete `getStaffMember` lazy query and related code (lines ~221-234)
   - Delete `updateLocation` mutation call (lines ~312-321)
   - Delete `createOperatingHour` mutations loop (lines ~336-395)
   - Delete `getOwnerRole` query and `createStaffPermission` mutation (lines ~431-454)
   - Delete `updateUserOnboardingStatus` mutation (lines ~456-466)

4. **Update Loading States**:
   Replace:
   ```javascript
   const overallLoading = creatingOrg || creatingStaffLocation || updatingUser || uploading || ...
   ```
   
   With:
   ```javascript
   const [isOnboarding, setIsOnboarding] = useState(false);
   const overallLoading = uploading || isOnboarding;
   ```

### Step 4: Test End-to-End

1. **Test Happy Path**:
   - Complete onboarding with all fields filled
   - Verify org, location, staff member, and operating hours are created
   - Verify user is redirected to dashboard
   - Verify no errors in console

2. **Test Error Cases**:
   - Try with missing required fields
   - Try with duplicate subdomain
   - Verify proper error messages
   - Verify no partial data left in database

3. **Test Transaction Rollback**:
   - Temporarily modify the function to fail mid-transaction
   - Verify all changes are rolled back
   - Verify no orphaned records

### Step 5: Clean Up (Optional)

Remove unused GraphQL mutations from `src/app/graphql/organization.graphql.js`:
- `CREATE_ORGANIZATION_MUTATION`
- `CREATE_STAFF_LOCATION_WITH_NESTED_RESOURCES_MUTATION`
- `GET_ORG_BY_NAME_OR_SUBDOMAIN`
- `GET_STAFF_MEMBER_BY_USER_AND_ORG_ID`
- `CREATE_STAFF_PERMISSION`
- `GET_ROLE_BY_NAME`
- `UPDATE_USER_ONBOARDING_STATUS_MUTATION`

**Note**: Only remove if not used elsewhere in the application.

## 📚 Documentation Reference

All documentation is in the `c:\Users\Brian Du\Synced\Code\synced-supabase\docs\` directory:

1. **`functions/complete_onboarding_transaction.md`** - Complete function reference
2. **`integration/onboarding-backend-integration.md`** - Frontend integration guide (DETAILED EXAMPLES!)
3. **`testing/function-testing-guide.md`** - How to test database functions

## 🎯 Success Criteria

Frontend integration is complete when:

- [ ] User can complete onboarding successfully
- [ ] All data is created in database (org, location, staff, operating hours)
- [ ] User is redirected to dashboard
- [ ] User's `is_onboarding_complete` is set to `true`
- [ ] No errors in browser console
- [ ] Transaction rolls back on errors (no partial data)
- [ ] Duplicate subdomain is prevented
- [ ] All edge cases handled properly

## 🆘 Troubleshooting

### "Function does not exist"
```bash
# Apply migrations
cd c:\Users\Brian Du\Synced\Code\synced-supabase
supabase db push
```

### "Permission denied"
Check that user is authenticated before calling function:
```javascript
const { data: { user } } = await supabaseClient.auth.getUser();
if (!user) {
  // Handle not authenticated
}
```

### "Transaction failed"
Check error message for specific cause:
```javascript
if (error) {
  console.error('Onboarding error:', error);
  // Error message will indicate what failed
}
```

## 📞 Support

Questions? Check:
1. `docs/integration/onboarding-backend-integration.md` - Complete integration guide with examples
2. `docs/functions/complete_onb
