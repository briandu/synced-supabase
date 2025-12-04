# Storage Migration Status

## Current Status: ✅ **MOSTLY COMPLETE**

File uploads are already using Supabase Storage! The migration is nearly complete, with only database record creation remaining.

## What's Already Done

### ✅ File Uploads to Supabase Storage

The `uploadParseFileREST` function in `src/app/utils/parseFileUpload.js` already uses Supabase Storage:

```javascript
// Already using Supabase Storage
const { data, error } = await supabaseClient.storage
  .from(bucket)
  .upload(path, processedFile, {
    cacheControl: '3600',
    upsert: false,
  });
```

**Buckets in use:**
- `patient-files` - Patient file uploads
- `profile-pictures` - Profile picture uploads  
- `charting-assets` - Charting file uploads

**Components already using Supabase Storage:**
- `PatientFiles.js` - Patient file uploads
- `ChartingFileImage.js` - Charting file uploads
- `StaffProfileEdit.js` - Profile picture uploads

### ✅ Storage Utilities

`src/lib/supabaseStorage.js` provides helper functions:
- `uploadPublicFile()` - Upload with public access
- `uploadServerFile()` - Server-side uploads
- `getSignedUrl()` - Generate signed URLs

## What Needs to Be Done

### ⚠️ Database Record Creation

Currently, file metadata is still being saved to Parse via GraphQL mutations. We need to:

1. **Create Supabase mutations for patient_files**
   - The `patient_files` table exists in Supabase schema
   - Need to create GraphQL mutations to insert/update/delete records
   - Update components to use Supabase mutations when feature flag is enabled

2. **Update PatientFiles component**
   - Use feature flag to select between Parse and Supabase mutations
   - Normalize response data for both formats

3. **Update ChartingFileImage component**
   - Similar updates for charting file records

## Migration Steps

### Step 1: Create Supabase GraphQL Mutations

Add to `src/app/graphql/patient_files.graphql.js` (or create if doesn't exist):

```javascript
export const CREATE_PATIENT_FILE_SUPA = gql`
  mutation CreatePatientFileSupa($object: patient_files_insert_input!) {
    insert_patient_files_one(object: $object) {
      id
      patientId
      fileName
      fileUrl
      fileType
      fileSize
      description
      createdAt
      updatedAt
    }
  }
`;

export const UPDATE_PATIENT_FILE_SUPA = gql`
  mutation UpdatePatientFileSupa($id: uuid!, $object: patient_files_set_input!) {
    update_patient_files_by_pk(pk_columns: { id: $id }, _set: $object) {
      id
      description
      updatedAt
    }
  }
`;

export const DELETE_PATIENT_FILE_SUPA = gql`
  mutation DeletePatientFileSupa($id: uuid!) {
    delete_patient_files_by_pk(id: $id) {
      id
    }
  }
`;

export const GET_PATIENT_FILES_SUPA = gql`
  query GetPatientFilesSupa($patientId: uuid!) {
    patient_files(
      where: { patient_id: { _eq: $patientId } }
      order_by: { createdAt: desc }
    ) {
      id
      patientId
      fileName
      fileUrl
      fileType
      fileSize
      description
      createdAt
      updatedAt
    }
  }
`;
```

### Step 2: Update PatientFiles Component

```javascript
import { isSupabaseEnabled } from '@/lib/featureFlags';
import { selectQuery } from '@/utils/graphql/querySelector';
import {
  CREATE_PATIENT_FILE,
  CREATE_PATIENT_FILE_SUPA,  // New
  DELETE_PATIENT_FILE,
  DELETE_PATIENT_FILE_SUPA,  // New
  GET_PATIENT_FILES,
  GET_PATIENT_FILES_SUPA,    // New
} from '@/app/graphql/patient_files.graphql';

// In component:
const isSupabase = isSupabaseEnabled('storage');

const createMutation = selectQuery({
  parse: CREATE_PATIENT_FILE,
  supabase: CREATE_PATIENT_FILE_SUPA,
}, 'storage');

const [createPatientFile] = useMutation(createMutation);

// When creating file record:
if (isSupabase) {
  await createPatientFile({
    variables: {
      object: {
        patient_id: patientId,
        file_name: file.name,
        file_url: url,
        file_type: file.type,
        file_size: file.size,
        description: description || null,
      },
    },
  });
} else {
  // Parse mutation (existing code)
  await createPatientFile({
    variables: {
      input: {
        fields: {
          patientId: { link: patientId },
          file: { file: { __type: 'File', name, url } },
          // ... rest of Parse fields
        },
      },
    },
  });
}
```

### Step 3: Test File Operations

- [ ] Upload file (creates Supabase record)
- [ ] View file list (queries Supabase)
- [ ] Update file description (updates Supabase record)
- [ ] Delete file (deletes Supabase record and storage file)
- [ ] Download file (uses Supabase signed URL)

## Storage Bucket Configuration

Ensure buckets are configured in Supabase Dashboard:

1. **patient-files**
   - Public: No
   - File size limit: 50MB (or as needed)
   - Allowed MIME types: All (or restrict as needed)

2. **profile-pictures**
   - Public: Yes (for public profile pictures)
   - File size limit: 5MB
   - Allowed MIME types: image/*

3. **charting-assets**
   - Public: No
   - File size limit: 50MB
   - Allowed MIME types: All

## RLS Policies

Ensure RLS policies are set for `patient_files` table:

```sql
-- Allow users to read patient files for patients they can access
CREATE POLICY patient_files_select ON patient_files
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM patients p
      WHERE p.id = patient_files.patient_id
        AND user_can_access_org(p.org_id)
    )
  );

-- Allow staff to create patient files
CREATE POLICY patient_files_insert ON patient_files
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM patients p
      WHERE p.id = patient_files.patient_id
        AND user_can_access_org(p.org_id)
    )
  );

-- Allow staff to update/delete patient files
CREATE POLICY patient_files_modify ON patient_files
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM patients p
      WHERE p.id = patient_files.patient_id
        AND user_can_access_org(p.org_id)
    )
  );
```

## Environment Variables

```bash
# Supabase Storage buckets
SUPABASE_STORAGE_BUCKET_PATIENT_FILES=patient-files
SUPABASE_STORAGE_BUCKET_PROFILE_PICTURES=profile-pictures
SUPABASE_STORAGE_BUCKET_CHARTING_ASSETS=charting-assets

# Feature flag
NEXT_PUBLIC_SUPABASE_FEATURE_STORAGE=true
```

## Summary

**Status:** 90% Complete
- ✅ File uploads to Supabase Storage
- ✅ Storage utilities
- ⚠️ Database record creation (needs Supabase mutations)
- ⚠️ Component updates (needs feature flag support)

**Next Steps:**
1. Create Supabase GraphQL mutations for patient_files
2. Update PatientFiles component with feature flags
3. Test end-to-end file operations
4. Update other file upload components (charting, profile pictures)

