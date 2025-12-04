# Supabase Migration Requirements Documentation

**Generated:** $(date)  
**Purpose:** Collect all required information and configuration for migrating from Parse Server to Supabase  
**Status:** In Progress - Some items require developer input

---

## Important Parse Schema Notes

### createdBy/updatedBy Field Patterns

**CRITICAL:** In the Parse schema, some classes have `createdBy` and `updatedBy` fields that point to `Staff_Member` instead of `_User`. This was an intentional design decision in the frontend due to Parse ACL (Access Control List) restrictions.

**Reason:** Parse's ACL system often prevents direct access to the `_User` table from the frontend. To work around this limitation while still maintaining audit trails, some classes store pointers to `Staff_Member` instead. This allows the frontend to:

1. Access the person's data (firstName, lastName, etc.) directly
2. Still maintain a reference that can be traced back to the `_User` via `Staff_Member.userId`

**Classes with `createdBy`/`updatedBy` → `Staff_Member`:**

- `Staff_Task` - Both `createdBy` and `updatedBy` point to `Staff_Member`
- `Income_Category` - Both `createdBy` and `updatedBy` point to `Staff_Member`
- `Supplier` - Both `createdBy` and `updatedBy` point to `Staff_Member`
- `Product_Inventory` - Both `createdBy` and `updatedBy` point to `Staff_Member`
- `Fee` - Both `createdBy` and `updatedBy` point to `Staff_Member`

**All other classes** use `createdBy`/`updatedBy` → `_User` as standard.

**Migration Preference:**
**We prefer to switch ALL `createdBy` and `updatedBy` fields to point to `Staff_Member` instead of `_User`** for consistency and to maintain the ability to access person data directly. However, this decision can be questioned if it is flawed - please evaluate the trade-offs:

- **Pros:** Consistent pattern, direct access to staff data, avoids ACL issues
- **Cons:** Requires staff record to exist for all operations, may not work for patient-only operations
- **Alternative:** Use RLS policies in Supabase to allow access to user data without the workaround

**Migration Consideration:** When migrating to Supabase, you'll need to decide whether to:

1. **PREFERRED:** Normalize all `createdBy`/`updatedBy` to point to `staff_members` (requires staff record for all operations)
2. Maintain the dual-reference pattern (user_id + staff_id) for these specific classes
3. Use RLS policies to allow access to user data without the workaround (allows pointing to `users` directly)

---

## 1) Supabase Project

- **Project URL:** https://tepdgpiyjluuddwgboyy.supabase.co

- **Secret key:** 
  - _Stored in environment variable: `SUPABASE_SERVICE_ROLE_KEY` (not committed to git)_
  - _Note: Get from Supabase Dashboard → Settings → API → service_role key (using the new publishable and secret API key formats that Supabase uses now)_
- **Publishable key:** 
  - _Stored in environment variable: `NEXT_PUBLIC_SUPABASE_ANON_KEY` (safe to commit, but using env var is recommended)_
  - _Note: Get from Supabase Dashboard → Settings → API → anon/public key (using the new publishable and secret API key formats that Supabase uses now)_
- **Extensions enabled:**

  - `pg_graphql` - Enabled
  - `pg_net` - Enabled
  - `pgcrypto` or `uuid-ossp` - Enabled (both enabled for whatever needs)

- **Buckets:**

  - `patient-files` - Created
  - `profile-pictures` - Created
  - `charting-assets` - Created
  - Other buckets: (You need to let me know what other buckets needs to be created)

- **Collaborator access granted to:** 
  - _Action Required: Add team members in Supabase Dashboard → Settings → Team_

---

## 2) Parse Exports and Files

- **Parse schema export:** 

  - _Note: Complete Parse schema is embedded in Appendix A below_

- **Parse data dump:** 

  - _Action Required: Export Parse data (consider using `parse-export` tool or Parse Dashboard export)_

- **File storage source:**
  - **Current:** Parse Server file storage (via Parse File objects)
  - **Bucket/path:** TODO
  - **Access keys/role:** TODO
  - **Migration Strategy:**
    - Parse files are stored with URLs like: `https://parseapi.back4app.com/parse/files/{filename}`
    - Need to migrate files to Supabase Storage
    - Parse File objects contain: `name` (filename) and `url` (full URL)
    - _Action Required: Determine Parse file storage backend (S3, Back4App, etc.) and access credentials_

---

## 3) Auth Configuration (Supabase Auth)

**Current Auth System:** Firebase Authentication (integrated with Parse)

**Migration Target:** Supabase Auth

- **SMTP host:** Use default SMTP for now and do custom later when deploying to production

  - _Action Required: Configure SMTP for Supabase Auth email delivery_
  - _Note: Can use Supabase's default SMTP or configure custom SMTP provider_

- **SMTP port:** TODO

  - _Typical: 587 (TLS) or 465 (SSL)_

- **SMTP user:** TODO

- **SMTP password:** TODO

- **From email (auth):** TODO

  - _Example: `noreply@synced.health` or `auth@synced.health`_

- **Google OAuth client ID:** TODO

  - _Status: Not yet set up for Firebase project_
  - _Action Required: Create Google OAuth credentials in Google Cloud Console_
  - _Note: Will need to configure in Supabase Dashboard → Authentication → Providers → Google_

- **Google OAuth client secret:** TODO

  - _Action Required: Get from Google Cloud Console after creating OAuth credentials_

- **Preferred flow:** **Password login** (primary authentication method)

  - _Current: Firebase uses passwordless email links (`sendSignInLinkToEmail`) for staff/user invitations only_
  - _Important: Email link authentication is ONLY used for inviting new staff members and new users during onboarding_
  - _For regular login: Users should use email/password authentication_
  - _Action Required: Configure Supabase Auth to support email/password as primary method, with email links available for invitations_

- **Redirect URLs:**
  - **Dev:** `http://localhost:3000` (or your local dev URL)
  - **Stage:** `https://synced-admin-portal.vercel.app`
  - **Prod:** TODO (no production environment yet)
  - _Action Required: Configure in Supabase Dashboard → Authentication → URL Configuration_

---

## 4) RLS / Roles / IDs

### ⚠️ CRITICAL: Parse ACL and Permissions Implementation Status

**IMPORTANT WARNING:** The current Parse ACL (Access Control List) and permissions implementation is **a mess and was not properly implemented initially**. The current implementation in Parse is **NOT a proper reflection of what our intentions were**.

**Current State:**

- Most Parse classes have open CLP (`"*": true`) - meaning no proper access control
- ACLs are inconsistently applied across classes
- Permission system (`Permission`, `Role_Permission`, `Staff_Permission`) exists but is not properly enforced
- Multi-tenant scoping is not properly enforced at the database level

**Intended Implementation:**
We intend to have **ACL and permissioning handled properly with hierarchy levels**:

- **Organization (Org) level** - Top-level tenant isolation
- **Ownership Group (OG) level** - Multi-location group scoping
- **Location level** - Individual location/branch scoping
- **Role-based permissions** - Granular permissions per role
- **Staff-specific permissions** - Override permissions for individual staff members

**Migration Requirement:**

- **This is a critical opportunity to implement proper access control from the ground up in Supabase**
- Use Supabase RLS (Row Level Security) policies to enforce:
  - Organization-level isolation
  - Ownership Group scoping
  - Location-level restrictions
  - Role-based access control
  - Staff-specific permission overrides
- **Do NOT replicate the current Parse ACL mess** - design a proper, hierarchical permission system

### Database Roles (from postgres-dev)

**Current PostgreSQL Roles:**

- `rdsadmin` - Superuser (AWS RDS admin)
- `synced` - Can create roles and databases, can login
- Various `rds_*` roles (AWS RDS system roles)

**Supabase Roles to Create:**

- `org_admin` - Organization administrators
- `staff` - Staff members
- `patient` - Patients
- `superadmin` - System super administrators
- _Action Required: Define role hierarchy and permissions matrix_

### Role Matrix

**TODO:** Define permissions for each role:

- Org Admin: Full access to their organization's data
- Staff: Access to assigned locations/patients
- Patient: Access to own data only
- Superadmin: System-wide access

### Org Scoping Rules

**Current Pattern:** Multi-tenant architecture with:

- `Org` (organization)
- `Ownership_Group` (multi-location groups)
- `Location` (physical locations)

**RLS Strategy:** TODO

- How to restrict data per organization?
- How to handle cross-org access (if any)?
- How to handle ownership group scoping?
- How to implement hierarchical permissions (Org → OG → Location)?
- _Action Required: Design RLS policies for multi-tenancy with proper hierarchy_

### Primary Key Strategy

- **PK strategy:** TODO (UUID | serial)

  - _Recommendation: UUID for distributed systems, better for multi-tenancy_
  - _Current Parse: Uses `objectId` (string, similar to UUID)_

- **Legacy Parse ID storage strategy:** TODO
  - _Action Required: Decide how to store Parse `objectId` in Supabase_
  - _Options:_
    - Store as separate `parse_object_id` column for migration/reference
    - Use as primary key if compatible
    - Map to new UUID and maintain lookup table

---

## 5) Stripe

**Current Setup:** Stripe API integration with connected accounts

- **Stripe test secret key:** 

  - _Environment variable: `STRIPE_SECRET_KEY_TEST` (stored in `.env` file, not committed to git)_
  - _Note: Get from Stripe Dashboard → Developers → API keys → Test mode secret key_

- **Stripe test Publishable key:** 

  - _Environment variable: `STRIPE_PUBLISHABLE_KEY_TEST` (stored in `.env` file, not committed to git)_
  - _Note: Get from Stripe Dashboard → Developers → API keys → Test mode publishable key_

- **Stripe live secret key:** TODO

  - _Action Required: Get from Stripe Dashboard → Developers → API keys → Live mode secret key_
  - _Note: Only use live key in production environment_

- **Webhook endpoint URL(s) to configure:** TODO

  - _Current webhook handler: `src/app/api/stripe/webhook/route.js`_
  - _Current endpoint: `/api/stripe/webhook`_
  - _Staging URL: `https://synced-admin-portal.vercel.app/api/stripe/webhook`_
  - _Action Required: Configure webhook in Stripe Dashboard → Developers → Webhooks_
  - _Note: Webhook secret stored in `STRIPE_WEBHOOK_SECRET` environment variable_

- **Connected accounts to preserve/migrate:** acct_1SUXDfELvDuwsVEt
  - _Status: 1 connected account exists_
  - _Action Required: List all Stripe connected account IDs from Parse `Location` table (`stripeConnectedAccountId` field)_
  - _Migration: Need to preserve `stripeConnectedAccountId` in Supabase `locations` table_

**Stripe Integration Points:**

- Payment processing (`src/pages/api/payments/process.js`)
- Invoice creation with Stripe (`src/pages/api/invoices/ensure-appointment-invoice.js`)
- Connected account onboarding (`src/app/api/stripe-connect/refresh-onboarding/route.js`)
- Payment methods management (`src/app/api/payment-methods/`)
- Webhook handling (`src/app/api/stripe/webhook/route.js`)

---

## 6) Notifications (Email/SMS)

**Current Status:** Email notifications use Firebase Auth's `sendSignInLinkToEmail` for invites

- **Email provider:** AWS SES (Simple Email Service)

  - **AWS Access Key ID:** 
    - _Environment variable: `AWS_ACCESS_KEY_ID` (stored in `.env` file, not committed to git)_
    - _Action Required: Get from AWS Console → IAM → Security credentials_
  - **AWS Secret Access Key:** 
    - _Environment variable: `AWS_SECRET_ACCESS_KEY` (stored in `.env` file, not committed to git)_
    - _Action Required: Get from AWS Console → IAM → Security credentials_
  - **AWS Region:** TODO (e.g., `us-east-1`, `ca-central-1`)
  - **From email/domain (notifications):** TODO
    - _Example: `notifications@synced.health` or `noreply@synced.health`_
    - _Action Required: Verify sender email/domain in AWS SES console_

- **SMS provider:** AWS SNS (Simple Notification Service)

  - **AWS Access Key ID:** 
    - _Environment variable: `AWS_ACCESS_KEY_ID` (stored in `.env` file, not committed to git)_
    - _Action Required: Get from AWS Console → IAM → Security credentials_
  - **AWS Secret Access Key:** 
    - _Environment variable: `AWS_SECRET_ACCESS_KEY` (stored in `.env` file, not committed to git)_
    - _Action Required: Get from AWS Console → IAM → Security credentials_
  - **AWS Region:** TODO (e.g., `us-east-1`, `ca-central-1`)
  - **From number/sender ID:** TODO
    - _Action Required: Configure phone number or sender ID in AWS SNS_

- **In-app notifications provider:** OneSignal (chosen)

  - _Action Required: Provide OneSignal App ID and API key (REST key)_

- **Notification templates/copy:** TODO (or link)
  - _Action Required: Document or provide links to email/SMS templates_
  - _Current: Staff invites use Firebase email links with encoded payload_

**Current Notification Usage:**Okay, yeah, just get everything set up with all the ones that we need.

- Staff invitation emails (Firebase `sendSignInLinkToEmail`)
- Patient appointment notifications (if implemented)
- Staff notifications (Parse `Staff_Notification` class)
- Patient notifications (Parse `Patient_Notification` class)

---

## 7) Domains / CORS

- **Base URLs:**

  - **Dev:** `http://localhost:3000` (or configured local dev URL)
  - **Stage:** `https://synced-admin-portal.vercel.app`
  - **Prod:** TODO (no production environment yet)
  - _Note: Current staging uses Vercel deployment_

- **Allowed CORS origins:** TODO

  - _Action Required: Configure in Supabase Dashboard → Settings → API → CORS settings_
  - _Recommended:_
    - `http://localhost:3000` (dev)
    - `https://synced-admin-portal.vercel.app` (staging)
    - Production URL (when available)

- **Allowed webhook origins (if enforced):** TODO
  - _Action Required: Configure webhook security if enforcing origin validation_
  - _Note: Stripe webhooks should validate signature, not origin_

---

## 8) Feature Priority

### First Migration Slice

**Recommended Priority Order:**

1. **Authentication + User Management**

   - Migrate `_User` → Supabase `auth.users`
   - Migrate `Staff_Member` → `staff_members` table
   - Set up Supabase Auth with email/password and Google OAuth
   - Migrate authentication flows

2. **Organization & Multi-Tenancy**

   - Migrate `Org`, `Ownership_Group`, `Location`
   - Set up RLS policies for org scoping
   - Migrate `Org_Staff_Invite`, `Org_Join_Request`

3. **Patient Management**

   - Migrate `Patient`, `Patient_Relationship`, `Patient_Note`, `Patient_File`
   - Set up RLS for patient data access

4. **Appointments & Scheduling**

   - Migrate `Appointment`, `Treatment_Plan`, `Waitlist`
   - Migrate `Availability_Block`, `Room`, `Resource`
   - Migrate `Staff_Shift`, `Staff_Break`, `Staff_Time_Off`

5. **Billing & Payments**
   - Migrate `Invoice`, `Invoice_Item`, `Payment`, `Payment_Method`
   - Migrate Stripe integration
   - Migrate `Transaction`, `Tax`, `Discount`, `Fee`

### Zero-Tolerance Areas (Must Not Break)

**Critical Paths:**

1. **Authentication** - Users must be able to log in
2. **Appointment Booking** - Core business functionality
3. **Patient Data Access** - HIPAA/compliance critical
4. **Payment Processing** - Revenue critical
5. **Staff Invitations** - Onboarding critical

**TODO:** Add any additional zero-tolerance areas

---

## 9) Testing

- **Supabase test project/DB access:** TODO

  - _Action Required: Create separate Supabase project for testing or use staging database_
  - _Recommendation: Use separate test project to avoid affecting staging data_

- **Seed users/orgs for tests:** TODO

  - _Action Required: Create test data script with:_
    - Test organizations
    - Test staff members
    - Test patients
    - Test appointments
    - Test invoices/payments

- **Test SMTP endpoint (if different):** TODO

  - _Action Required: Configure test SMTP or use Supabase's test email service_
  - _Note: Supabase provides test email service for development_

- **Test SMS endpoint/number (if different):** TODO
  - _Action Required: Configure test SMS number from provider_
  - _Note: Most SMS providers offer test numbers for development_

---

## 10) Additional Migration Considerations

### GraphQL Migration

**Current:** Parse Server GraphQL API

- Endpoint: `/api/graphql` (proxied) or `NEXT_PUBLIC_PARSE_GRAPHQL_ENDPOINT`
- Apollo Client configured in `src/app/configs/apolloClient.js`

**Target:** Supabase PostgREST or pg_graphql

- _Action Required: Decide on API layer (PostgREST REST API vs pg_graphql GraphQL API)_
- _Recommendation: Use PostgREST for simplicity, or pg_graphql if GraphQL is required_

### File Storage Migration

**Current:** Parse File storage

- Files uploaded via Parse REST API
- File URLs: `https://parseapi.back4app.com/parse/files/{filename}`

**Target:** Supabase Storage

- _Action Required: Create migration script to:_
  1. Download files from Parse storage
  2. Upload to Supabase Storage buckets
  3. Update file references in database

### Environment Variables to Migrate

**Current Parse Environment Variables:**

- `NEXT_PUBLIC_PARSE_SERVER_URL`
- `NEXT_PUBLIC_PARSE_APP_ID`
- `NEXT_PUBLIC_PARSE_MASTER_KEY`
- `NEXT_PUBLIC_PARSE_GRAPHQL_ENDPOINT`

**New Supabase Environment Variables Needed:**

- `NEXT_PUBLIC_SUPABASE_URL`
- `NEXT_PUBLIC_SUPABASE_ANON_KEY`
- `SUPABASE_SERVICE_ROLE_KEY` (server-side only)

**Existing Variables to Keep:**

- `STRIPE_SECRET_KEY`
- `STRIPE_WEBHOOK_SECRET`
- `NEXT_PUBLIC_APP_URL`
- `NEXT_PUBLIC_ENVIRONMENT`
- Firebase config (if keeping Firebase for any features)

---

## Next Steps

1. **Fill in all TODO items** in this document
2. **Review Parse schema** (`docs/parse-database-schema.md`) for complete field mappings
3. **Create Supabase project** and configure basic settings
4. **Set up authentication** in Supabase (email/password, Google OAuth)
5. **Design database schema** based on Parse schema
6. **Create RLS policies** for multi-tenancy
7. **Plan data migration** strategy and scripts
8. **Set up testing environment** with seed data
9. **Configure integrations** (Stripe, email, SMS)
10. **Create migration timeline** and execute in phases

---

## References

- Current Auth: Firebase (`src/lib/firebase.js`)
- Current GraphQL: Parse GraphQL (`src/app/configs/apolloClient.js`)
- Stripe Integration: `src/app/api/stripe/`, `src/pages/api/payments/`
- File Upload: `src/app/utils/parseFileUpload.js`

---

## Appendix A: Complete Parse Database Schema

**Source:** `_SCHEMA` table from postgres-dev  
**Total Classes:** 100+ Parse classes documented

This appendix contains the complete Parse database schema documentation, organized by functional domain. Use this as the source of truth for table structures when migrating to Supabase.

**For Migration:**

- Map Parse classes to Supabase tables
- Convert Parse pointers to foreign keys
- Convert Parse Relations to junction tables
- Map Parse File objects to Supabase Storage references

---

### Table of Contents

1. [Core System Classes](#core-system-classes)
2. [Organization & Multi-Tenancy](#organization--multi-tenancy)
3. [User Management](#user-management)
4. [Patient Management](#patient-management)
5. [Staff Management](#staff-management)
6. [Appointments & Scheduling](#appointments--scheduling)
7. [Services & Products](#services--products)
8. [Billing & Payments](#billing--payments)
9. [Insurance](#insurance)
10. [Forms & Charting](#forms--charting)
11. [Notifications](#notifications)
12. [Permissions & Security](#permissions--security)
13. [Other Classes](#other-classes)

---

### Core System Classes

#### `_User`

Base user class for authentication and user profiles.

**Key Fields:**

- `username` (String) - Required
- `email` (String) - Required
- `password` (String)
- `firstName` (String) - Required
- `lastName` (String) - Required
- `middleName` (String)
- `dateOfBirth` (Date)
- `firebaseUid` (String)
- `firebaseUuid` (String)
- `emailVerified` (Boolean)
- `isOnboardingComplete` (Boolean, default: false)
- Address fields: `addressLine1`, `addressLine2`, `city`, `provinceState`, `country`, `postalZipCode`
- Contact fields: `mobile`, `secondaryEmail`, `emergencyContactName`, `emergencyContactPhone`, `emergencyContactRelationship`
- `healthNumber` (String)
- `preferredName` (String)
- `gender` (String)
- `authData` (Object)

**Relations:**

- `users` → `_User` (via `_Role`)

---

#### `_Role`

Role-based access control.

**Key Fields:**

- `name` (String) - Required
- `order` (Number)
- `isPreset` (Boolean, default: false)
- `createdBy` (Pointer → `_User`)
- `updatedBy` (Pointer → `_User`)

**Relations:**

- `users` (Relation → `_User`)
- `roles` (Relation → `_Role`)

**Indexes:**

- `_id_`

**CLP:** Requires authentication for all operations; create/update/delete requires `role:OrgAdmin`.

---

#### `_Session`

User session management.

**Key Fields:**

- `user` (Pointer → `_User`)
- `sessionToken` (String)
- `expiresAt` (Date)
- `createdWith` (Object)
- `installationId` (String)

---

### Organization & Multi-Tenancy

#### `Org`

Organization/tenant entity.

**Key Fields:**

- `orgName` (String)
- `subdomain` (String) - **Required**
- `logo` (File)
- `logoUrl` (String)
- `website` (String)
- `currency` (String)
- `primaryColor` (String)
- `secondaryColor` (String)
- `accountType` (String)
- `companySize` (String)
- `previousSoftware` (String)
- `recommendationSource` (String)
- `createdBy` (Pointer → `_User`)
- `updatedBy` (Pointer → `_User`)

**CLP:** Open access (`*: true`)

---

#### `Ownership_Group`

Ownership group for multi-location organizations.

**Key Fields:**

- `ogName` (String) - **Required**
- `orgId` (Pointer → `Org`) - **Required**
- `legalName` (String)
- `taxNumber` (String)
- `corporateOg` (Boolean, default: false)
- `keyContactId` (Pointer → `_User`)
- `createdBy` (Pointer → `_User`)
- `updatedBy` (Pointer → `_User`)

---

#### `Location`

Physical location/branch.

**Key Fields:**

- `locationName` (String) - **Required**
- `ownershipGroupId` (Pointer → `Ownership_Group`) - **Required**
- `operatingName` (String)
- `legalName` (String)
- `isActive` (Boolean, default: true)
- `ogHq` (Boolean, default: false) - Headquarter flag
- Address fields: `addressLine1`, `addressLine2`, `city`, `provinceState`, `country`, `postalZipCode`
- Billing address fields: `billingAddressLine1`, `billingAddressLine2`, `billingCity`, `billingProvinceState`, `billingCountry`, `billingPostalZipCode`
- `useLocationForBilling` (Boolean, default: true)
- Contact: `phoneNumber`, `faxNumber`, `email`, `website`
- `currency` (String)
- `taxNumber` (String)
- `keyContactId` (Pointer → `_User`)
- `logo` (File)
- `logoUrl` (String)
- `featuredImage` (File)
- `primaryColor` (String)
- `secondaryColor` (String)
- `shortDescription` (String)
- `longDescription` (String)
- `operatingHours` (Array)
- Stripe integration: `stripeConnectedAccountId`, `stripeAccountStatus`, `stripeAccountType`, `stripeAccountEmail`, `stripeAccountCountry`, `stripeChargesEnabled`, `stripePayoutsEnabled`, `stripeOnboardingCompleted`, etc.
- `createdBy` (Pointer → `_User`)
- `updatedBy` (Pointer → `_User`)

---

#### `Org_Join_Request`

Requests to join an organization.

**Key Fields:**

- `targetOrgId` (Pointer → `Org`) - **Required**
- `targetLocationId` (Pointer → `Location`) - **Required**
- `requestingUserId` (String) - **Required**
- `email` (String) - **Required**
- `firstName` (String) - **Required**
- `lastName` (String) - **Required**
- `status` (String, default: "pending") - **Required**
- `message` (String)
- `firebaseUuid` (String)
- `resolvedAt` (Date)
- `resolvedByUserId` (Pointer → `_User`)
- `rejectionReason` (String)

**CLP:** Open access

---

#### `Org_Staff_Invite`

Staff invitation management.

**Key Fields:**

- `orgId` (Pointer → `Org`)
- `staffId` (Pointer → `Staff_Member`)
- `email` (String)
- `status` (String, default: "pending")
- `invitationType` (String)
- `invitedByUserId` (Pointer → `_User`)
- `invitedAt` (Date)
- `acceptedAt` (Date)
- `expiresAt` (Date)
- `disconnectedAt` (String)
- `ownershipGroupId` (Pointer → `Ownership_Group`)

**CLP:** Open access

---

#### `Org_Audit_Event`

Audit logging for organization events.

**Key Fields:**

- `orgId` (String)
- `type` (String)
- `staffId` (String)
- `staffObjectId` (String)
- `timestamp` (String)
- `details` (Object)

---

#### `Org_Security_Setting`

Organization security settings.

**Key Fields:**

- `orgId` (Pointer → `Org`) - **Required**
- `autoSignOutEnabled` (Boolean, default: false)
- `multifactorRequired` (Boolean, default: false)
- `createdBy` (Pointer → `_User`)
- `updatedBy` (Pointer → `_User`)

---

### User Management

#### `User_Relationship`

Relationships between users.

**Key Fields:**

- `userId` (Pointer → `_User`) - **Required**
- `relatedUserId` (Pointer → `_User`) - **Required**
- `relationshipToUser` (String) - **Required**

---

#### `User_Favourited`

User favorites (staff/locations).

**Key Fields:**

- `userId` (Pointer → `_User`) - **Required**
- `staffId` (Pointer → `Staff_Member`)
- `locationId` (Pointer → `Location`)

**CLP:** Open access

---

### Patient Management

#### `Patient`

Patient records.

**Key Fields:**

- `userId` (Pointer → `_User`) - **Required**
- `orgId` (Pointer → `Org`) - **Required**
- `email` (String) - **Required**
- `firstName` (String) - **Required**
- `lastName` (String) - **Required**
- `middleName` (String)
- `preferredName` (String)
- `prefix` (String)
- `pronouns` (String)
- `dateOfBirth` (Date)
- `gender` (String)
- `username` (String)
- `firebaseUid` (String)
- `personalHealthNumber` (String)
- `stripeCustomerId` (String)
- `stripeConnectedCustomers` (Object)
- Address fields: `addressLine1`, `addressLine2`, `city`, `provinceState`, `country`, `postalZipCode`
- Contact: `mobile`, `homePhoneNumber`, `secondaryEmail`
- Emergency contact: `emergencyContactName`, `emergencyContactPhone`, `emergencyContactRelationship`
- `patientSince` (Date)
- `isDeceased` (Boolean, default: false)
- `isBlacklisted` (Boolean, default: false)
- `syncEnabled` (Boolean, default: false)
- `allowNotifications` (Boolean, default: true)
- `notificationPreferences` (String)
- `parentGuardianId` (Pointer → `Patient`)
- `referralType` (String)
- `referralDetail` (String)
- `referralUserId` (Pointer → `_User`)
- `customBookingPolicyId` (Pointer → `Booking_Policy`)
- `isBookingPolicyCustom` (Boolean, default: false)
- `createdBy` (Pointer → `_User`)
- `updatedBy` (Pointer → `_User`)

**CLP:** Open access

---

#### `Patient_Relationship`

Relationships for patients (guardians, etc.).

**Key Fields:**

- `patientId` (Pointer → `Patient`) - **Required**
- `relatedUserId` (Pointer → `_User`)
- `firstName` (String)
- `lastName` (String)
- `email` (String)
- `relationshipToPatient` (String)
- `createdBy` (Pointer → `_User`)
- `updatedBy` (Pointer → `_User`)

**CLP:** Open access

---

#### `Patient_Note`

Notes attached to patients.

**Key Fields:**

- `patientId` (Pointer → `Patient`) - **Required**
- `text` (String) - **Required**
- `isPinned` (Boolean, default: false)
- `createdBy` (Pointer → `_User`)
- `updatedBy` (Pointer → `_User`)

---

#### `Patient_File`

Files attached to patients.

**Key Fields:**

- `patientId` (Pointer → `Patient`) - **Required**
- `file` (File) - **Required**
- `description` (String)
- `createdBy` (Pointer → `_User`)

---

#### `Patient_Notification`

Notifications for patients.

**Key Fields:**

- `patientId` (Pointer → `Patient`) - **Required**
- `type` (String) - **Required**
- `status` (String, default: "pending")
- `details` (String)
- `locationId` (Pointer → `Location`)
- `senderStaffId` (Pointer → `Staff_Member`)
- `createdBy` (Pointer → `_User`)
- `updatedBy` (Pointer → `_User`)

**CLP:** Open access

---

#### `Ownership_Group_Patient`

Junction table for patient-ownership group relationships.

**Key Fields:**

- `patientId` (Pointer → `Patient`) - **Required**
- `ownershipGroupId` (Pointer → `Ownership_Group`) - **Required**
- `isActive` (Boolean, default: true) - **Required**

**CLP:** Open access

---

#### `Patient_Staff`

Patient-provider relationships.

**Key Fields:**

- `patientId` (Pointer → `Patient`) - **Required**
- `staffId` (Pointer → `Staff_Member`) - **Required**
- `orgId` (Pointer → `Org`) - **Required**
- `relationshipType` (String, default: "primary_provider") - **Required**
- `isActive` (Boolean, default: true) - **Required**
- `isPrimary` (Boolean, default: false)
- `startAt` (Date)
- `endAt` (Date)
- `referredAt` (Date)
- `referredByStaffId` (Pointer → `Staff_Member`)
- `notes` (String)
- `createdBy` (Pointer → `_User`) - **Required**
- `updatedBy` (Pointer → `_User`) - **Required**

**CLP:** Open access

---

### Staff Management

#### `Staff_Member`

Staff member records.

**Key Fields:**

- `userId` (Pointer → `_User`) - **Required**
- `orgId` (Pointer → `Org`) - **Required**
- `email` (String) - **Required**
- `firstName` (String)
- `lastName` (String)
- `middleName` (String)
- `preferredName` (String)
- `prefix` (String)
- `title` (String)
- `bio` (String)
- `dateOfBirth` (Date)
- `gender` (String)
- `isActive` (Boolean, default: true)
- `isProvider` (Boolean, default: false)
- `firebaseUid` (String)
- Address fields: `addressLine1`, `addressLine2`, `city`, `provinceState`, `country`, `postalZipCode`
- Contact: `mobile`, `workEmail`, `workPhone`
- `profilePicture` (File)
- `signature` (String)
- `createdBy` (Pointer → `_User`)
- `updatedBy` (Pointer → `_User`)

**Indexes:**

- `_id_`

**CLP:** Open access

---

#### `Staff_Location`

Staff-location assignments.

**Key Fields:**

- `staffId` (Pointer → `Staff_Member`) - **Required**
- `locationId` (Pointer → `Location`) - **Required**
- `roleId` (Pointer → `_Role`)
- `isActive` (Boolean, default: true)
- `isProvider` (Boolean, default: false)
- `title` (String)
- `bio` (String)
- `workEmail` (String)
- `workPhone` (String)
- `startDate` (Date)
- `endDate` (Date)
- `employment_type` (String)
- `providerCredentialId` (Pointer → `Provider_Credential`)
- `createdBy` (Pointer → `_User`)
- `updatedBy` (Pointer → `_User`)

**CLP:** Open access

---

#### `Staff_Shift`

Staff shift schedules.

**Key Fields:**

- `staffId` (Pointer → `Staff_Member`) - **Required**
- `locationId` (Pointer → `Location`) - **Required**
- `roomId` (Pointer → `Room`)
- `isRecurring` (Boolean, default: false)
- `scheduleType` (String)
- `recurringFrequency` (String)
- `recurringEndDate` (Date)
- `weeklyPattern` (String)
- `weeklyTemplateRecurrence` (Object)
- `overrideDate` (Date)
- `overrideIsUnavailable` (Boolean, default: false)
- `overrideIntervals` (String)
- `timezone` (String)
- `createdBy` (Pointer → `_User`)
- `updatedBy` (Pointer → `_User`)

**CLP:** Open access

---

#### `Staff_Break`

Staff break times.

**Key Fields:**

- `staffId` (Pointer → `Staff_Member`) - **Required**
- `locationId` (Pointer → `Location`) - **Required**
- `startTime` (Date) - **Required**
- `endTime` (Date) - **Required**
- `duration` (Pointer → `Time_Interval`)
- `breakNote` (String)
- `isRecurring` (Boolean, default: false)
- `recurringType` (String)
- `recurringEndDate` (Date)
- `createdBy` (Pointer → `_User`)
- `updatedBy` (Pointer → `_User`)

**CLP:** Open access

---

#### `Staff_Time_Off`

Staff time off requests.

**Key Fields:**

- `staffId` (Pointer → `Staff_Member`) - **Required**
- `locationId` (Pointer → `Location`) - **Required**
- `startDate` (Date) - **Required**
- `endDate` (Date) - **Required**
- `startTime` (Date)
- `endTime` (Date)
- `timeOffNote` (String)
- `createdBy` (Pointer → `_User`)
- `updatedBy` (Pointer → `_User`)

**CLP:** Open access

---

#### `Staff_Service`

Staff-service associations.

**Key Fields:**

- `staffId` (Pointer → `Staff_Member`) - **Required**
- `serviceId` (Pointer → `Service_Detail`) - **Required**
- `locationId` (Pointer → `Location`)
- `isEnabled` (Boolean, default: true)
- `createdBy` (Pointer → `_User`)
- `updatedBy` (Pointer → `_User`)

**CLP:** Open access

---

#### `Staff_Notification`

Notifications for staff.

**Key Fields:**

- `staffId` (Pointer → `Staff_Member`) - **Required**
- `type` (String) - **Required**
- `status` (String, default: "unread")
- `details` (String)
- `createdBy` (Pointer → `_User`)
- `updatedBy` (Pointer → `_User`)

**CLP:** Open access

---

#### `Staff_Task`

Tasks assigned to staff.

**Key Fields:**

- `assignedTo` (Pointer → `Staff_Member`) - **Required**
- `task` (String) - **Required**
- `status` (String, default: "pending")
- `dueDate` (Date)
- `createdBy` (Pointer → `Staff_Member`) - **Required**
- `updatedBy` (Pointer → `Staff_Member`) - **Required**

**CLP:** Open access

---

#### `Staff_Commission`

Commission rates for staff.

**Key Fields:**

- `staffId` (Pointer → `Staff_Member`) - **Required**
- `incomeCategoryId` (Pointer → `Income_Category`) - **Required**
- `commissionType` (String) - **Required**
- `percentage` (Number)
- `amount` (Number)
- `createdBy` (Pointer → `_User`)
- `updatedBy` (Pointer → `_User`)

**CLP:** Open access

---

#### `Provider_Credential`

Provider credentials/licenses.

**Key Fields:**

- `userId` (Pointer → `_User`) - **Required**
- `disciplineId` (Pointer → `Discipline`) - **Required**
- `licenseNumber` (String)
- `lastRenewal` (Date)
- `createdBy` (Pointer → `_User`)
- `updatedBy` (Pointer → `_User`)

---

### Appointments & Scheduling

#### `Appointment`

Appointment records.

**Key Fields:**

- `patientId` (Pointer → `Patient`) - **Required**
- `staffId` (Pointer → `Staff_Member`) - **Required**
- `orgId` (Pointer → `Org`) - **Required**
- `locationId` (Pointer → `Location`) - **Required**
- `serviceOfferingId` (Pointer → `Service_Offering`) - **Required**
- `itemPriceId` (Pointer → `Item_Price`) - **Required**
- `startTime` (Date) - **Required**
- `endTime` (Date)
- `duration` (Number)
- `status` (String, default: "scheduled")
- `appointmentType` (String)
- `roomId` (Pointer → `Room`)
- `resourceId` (Pointer → `Resource`)
- `providerId` (Pointer → `Staff_Member`)
- `treatmentPlanId` (Pointer → `Treatment_Plan`)
- `ownershipGroupId` (Pointer → `Ownership_Group`)
- `checkInAt` (Date)
- `checkInBy` (Pointer → `_User`)
- `checkOutAt` (Date)
- `checkOutBy` (Pointer → `_User`)
- `cancellationReason` (String)
- `notes` (String)
- `createdBy` (Pointer → `_User`)
- `updatedBy` (Pointer → `_User`)

**CLP:** Open access

---

#### `Treatment_Plan`

Treatment plans for patients.

**Key Fields:**

- `patientId` (Pointer → `Patient`) - **Required**
- `name` (String) - **Required**
- `startDate` (Date) - **Required**
- `endDate` (Date)
- `primaryStaffId` (Pointer → `Staff_Member`)
- `createdBy` (Pointer → `_User`)
- `updatedBy` (Pointer → `_User`)

**CLP:** Open access

---

#### `Waitlist`

Waitlist entries.

**Key Fields:**

- `patientId` (Pointer → `Patient`) - **Required**
- `orgId` (Pointer → `Org`) - **Required**
- `locationId` (Pointer → `Location`) - **Required**
- `serviceOfferingId` (Pointer → `Service_Offering`) - **Required**
- `staffId` (Pointer → `Staff_Member`)
- `disciplineId` (Pointer → `Discipline`)
- `availabilityStatus` (String, default: "waiting")
- `firstAvailableDate` (Date)
- `preferredStartTime` (String)
- `preferredEndTime` (String)
- `daysAvailable` (String)
- `availabilityRange` (String)
- `waitlistExpiryDate` (Date)
- `notes` (String)
- `createdBy` (Pointer → `_User`)
- `updatedBy` (Pointer → `_User`)

**CLP:** Open access

---

#### `Availability_Block`

Availability blocks for scheduling.

**Key Fields:**

- `locationId` (Pointer → `Location`) - **Required**
- `orgId` (Pointer → `Org`) - **Required**
- `startTime` (Date) - **Required**
- `endTime` (Date) - **Required**
- `status` (String) - **Required**
- `reason` (String) - **Required**
- `staffId` (Pointer → `Staff_Member`)
- `ownershipGroupId` (Pointer → `Ownership_Group`)
- `notes` (String)
- `outcome` (String)
- `outcomeAt` (Date)
- `outcomeBy` (Pointer → `_User`)
- `outcomeRefType` (String)
- `outcomeRefId` (String)
- `cancelReason` (String)
- `expiresAt` (Date)
- `createdBy` (Pointer → `_User`) - **Required**
- `updatedBy` (Pointer → `_User`) - **Required**

**CLP:** Open access

---

#### `Room`

Rooms for appointments.

**Key Fields:**

- `name` (String) - **Required**
- `locationId` (Pointer → `Location`)
- `createdBy` (Pointer → `_User`)
- `updatedBy` (Pointer → `_User`)

---

#### `Resource`

Resources for appointments.

**Key Fields:**

- `name` (String) - **Required**
- `locationId` (Pointer → `Location`) - **Required**
- `createdBy` (Pointer → `_User`)
- `updatedBy` (Pointer → `_User`)

---

#### `Operating_Hour`

Operating hours for locations.

**Key Fields:**

- `locationId` (Pointer → `Location`) - **Required**
- `day` (Number) - **Required** (0-6, Sunday-Saturday)
- `startTime` (Date) - **Required**
- `endTime` (Date) - **Required**
- `isOpen` (Boolean, default: true)

**CLP:** Open access

---

#### `Time_Interval`

Time interval definitions.

**Key Fields:**

- `durationMinutes` (Number, default: 0) - **Required**

**CLP:** Open access

---

### Services & Products

#### `Items_Catalog`

Catalog of items (services/products).

**Key Fields:**

- `itemName` (String) - **Required**
- `type` (String) - **Required** (service/product)
- `orgId` (Pointer → `Org`)
- `description` (String)
- `unitType` (String)
- `defaultTaxId` (Pointer → `Tax`)
- `serviceDetailId` (Pointer → `Service_Detail`)
- `productDetailId` (Pointer → `Product_Detail`)
- `incomeCategoryId` (Pointer → `Income_Category`)
- `stripeProductId` (String)
- `stripeProductIds` (Object)
- `createdBy` (Pointer → `_User`)
- `updatedBy` (Pointer → `_User`)

**CLP:** Open access

---

#### `Service_Detail`

Service-specific details.

**Key Fields:**

- `itemId` (Pointer → `Items_Catalog`)
- `serviceType` (String) - **Required**
- `schedulingDurationMinutes` (Number, default: 0) - **Required**
- `standardProcedureCode` (String)
- `procedureCodingSystem` (String)
- `createdBy` (Pointer → `_User`)
- `updatedBy` (Pointer → `_User`)

**CLP:** Open access

---

#### `Product_Detail`

Product-specific details.

**Key Fields:**

- `sku` (String)
- `productCode` (String)
- `productType` (String)
- `manufacturer` (String)
- `manufacturerSKU` (String)
- `cost` (Number)
- `msrp` (Number)
- `reorderThreshold` (Number)
- `supplierId` (Pointer → `Supplier`)
- `internalNotes` (String)
- `createdBy` (Pointer → `_User`)
- `updatedBy` (Pointer → `_User`)

**CLP:** Open access

---

#### `Item_Price`

Pricing for items.

**Key Fields:**

- `itemId` (Pointer → `Items_Catalog`) - **Required**
- `price` (Number) - **Required**
- `orgId` (Pointer → `Org`)
- `locationId` (Pointer → `Location`)
- `staffId` (Pointer → `Staff_Member`)
- `staffLocationId` (Pointer → `Staff_Location`)
- `ownershipGroupId` (Pointer → `Ownership_Group`)
- `currency` (String)
- `durationMinutes` (Number)
- `stripePriceId` (String)
- `stripePriceIds` (Object)
- `createdBy` (Pointer → `_User`)
- `updatedBy` (Pointer → `_User`)

**CLP:** Open access

---

#### `Service_Offering`

Service offerings at locations.

**Key Fields:**

- `itemId` (Pointer → `Items_Catalog`) - **Required**
- `disciplineOfferingId` (Pointer → `Discipline_Offering`) - **Required**
- `orgId` (Pointer → `Org`) - **Required**
- `locationId` (Pointer → `Location`)
- `ownershipGroupId` (Pointer → `Ownership_Group`)
- `createdBy` (Pointer → `_User`)
- `updatedBy` (Pointer → `_User`)

**CLP:** Open access

---

#### `Discipline_Offering`

Discipline offerings at locations.

**Key Fields:**

- `presetId` (Pointer → `Discipline_Preset`) - **Required**
- `orgId` (Pointer → `Org`)
- `locationId` (Pointer → `Location`)
- `ownershipGroupId` (Pointer → `Ownership_Group`)
- `customName` (String)
- `createdBy` (Pointer → `_User`)
- `updatedBy` (Pointer → `_User`)

**CLP:** Open access

---

#### `Discipline_Preset`

Discipline presets.

**Key Fields:**

- `name` (String) - **Required**
- `disciplineName` (String)
- `category` (String)
- `icon` (String)
- `isPreset` (Boolean)
- `createdBy` (Pointer → `_User`)
- `updatedBy` (Pointer → `_User`)

---

#### `Income_Category`

Income categories for commission tracking.

**Key Fields:**

- `name` (String) - **Required**
- `description` (String)
- `defaultCommissionRate` (Number, default: 100) - **Required**
- `defaultReferralCommissionRate` (Number)
- `createdBy` (Pointer → `Staff_Member`)
- `updatedBy` (Pointer → `Staff_Member`)

**CLP:** Open access

---

#### `Supplier`

Product suppliers.

**Key Fields:**

- `name` (String) - **Required**
- `contact` (String)
- `email` (String)
- `phone` (String)
- `website` (String)
- `streetAddress` (String)
- `streetAddress2` (String)
- `city` (String)
- `province` (String)
- `country` (String)
- `postalZipCode` (String)
- `notes` (String)
- `isActive` (Boolean, default: true)
- `createdBy` (Pointer → `Staff_Member`)
- `updatedBy` (Pointer → `Staff_Member`)

---

#### `Product_Inventory`

Product inventory tracking.

**Key Fields:**

- `productId` (Pointer → `Items_Catalog`) - **Required**
- `locationId` (Pointer → `Location`) - **Required**
- `quantity` (Number, default: 0) - **Required**
- `createdBy` (Pointer → `Staff_Member`)
- `updatedBy` (Pointer → `Staff_Member`)

---

### Billing & Payments

#### `Invoice`

Invoice records.

**Key Fields:**

- `patientId` (Pointer → `Patient`) - **Required**
- `orgId` (Pointer → `Organization`)
- `locationId` (Pointer → `Location`) - **Required**
- `appointmentId` (Pointer → `Appointment`)
- `subtotal` (Number) - **Required**
- `tax` (Number) - **Required**
- `total` (Number) - **Required**
- `balance` (Number, default: 0)
- `amountPaid` (Number, default: 0)
- `status` (String, default: "pending")
- `dateBilled` (Date) - **Required**
- `dateApplied` (Date)
- `finalizedAt` (Date)
- `taxIds` (Array)
- `taxBreakdown` (String)
- `discountId` (Pointer → `Discount`)
- `staffId` (Pointer → `Staff_Member`)
- `invoiceNumber` (String)
- `stripeInvoiceId` (String)
- `stripeStatus` (String)
- `stripeConnectedAccountId` (String)
- `createdBy` (Pointer → `_User`)
- `updatedBy` (Pointer → `_User`)

**CLP:** Open access

---

#### `Invoice_Item`

Line items on invoices.

**Key Fields:**

- `invoiceId` (Pointer → `Invoice`) - **Required**
- `itemId` (Pointer → `Items_Catalog`) - **Required**
- `itemName` (String)
- `count` (Number) - **Required**
- `quantity` (Number)
- `price` (Number)
- `customPrice` (Number)
- `total` (Number)
- `customTaxId` (Pointer → `Tax`)
- `createdBy` (Pointer → `_User`)
- `updatedBy` (Pointer → `_User`)

---

#### `Payment`

Payment records.

**Key Fields:**

- `patientId` (Pointer → `Patient`) - **Required**
- `type` (String) - **Required**
- `amount` (Number) - **Required**
- `paymentDate` (Date) - **Required**
- `paymentMethod` (String) - **Required**
- `paymentMethodId` (Pointer → `Payment_Method`)
- `status` (String)
- `receiptNumber` (String)
- `orgId` (Pointer → `Organization`)
- `locationId` (Pointer → `Location`)
- `userId` (Pointer → `_User`)
- `stripePaymentId` (String)
- `notes` (String)
- `createdBy` (Pointer → `_User`)

---

#### `Payment_Method`

Payment methods for patients.

**Key Fields:**

- `patientId` (Pointer → `Patient`) - **Required**
- `stripePaymentMethodId` (String) - **Required**
- `stripeCustomerId` (String) - **Required**
- `integrationProvider` (String)
- `integrationName` (String)
- `integrationColor` (String)
- `nickname` (String)
- `isDefault` (Boolean, default: false)
- `isActive` (Boolean, default: true)
- `cardBrand` (String)
- `cardLast4` (String)
- `cardExpMonth` (Number)
- `cardExpYear` (Number)
- `cardCountry` (String)
- `cardFunding` (String)
- `cardFingerprint` (String)
- `billingName` (String)
- `billingEmail` (String)
- `billingPhone` (String)
- `billingCountry` (String)
- `billingPostalCode` (String)
- `color` (String)
- `colorName` (String)
- `metadata` (Object)
- `restrictToLocations` (Boolean, default: false)
- `allowedLocations` (Array)
- `usageCount` (Number, default: 0)
- `lastUsedAt` (Date)
- `verifiedAt` (Date)
- `deactivatedAt` (Date)
- `deactivatedBy` (Pointer → `_User`)
- `deactivatedReason` (String)
- `updatedBy` (Pointer → `_User`)

---

#### `Transaction`

Transaction records linking payments, invoices, etc.

**Key Fields:**

- `userId` (Pointer → `_User`) - **Required**
- `type` (String) - **Required**
- `amount` (Number) - **Required**
- `invoiceId` (Pointer → `Invoice`)
- `paymentId` (Pointer → `Payment`)
- `claimId` (Pointer → `Claim`)
- `giftCardId` (Pointer → `Gift_Card`)
- `tipId` (Pointer → `Tip`)
- `paymentMethod` (String)
- `createdBy` (Pointer → `_User`)

---

#### `Tax`

Tax definitions.

**Key Fields:**

- `name` (String) - **Required**
- `taxRate` (Number) - **Required**
- `description` (String)
- `isActive` (Boolean)
- `locationIds` (Array)
- `createdBy` (Pointer → `_User`)
- `updatedBy` (Pointer → `_User`)

---

#### `Discount`

Discount codes/promotions.

**Key Fields:**

- `name` (String) - **Required**
- `code` (String)
- `description` (String)
- `createdBy` (Pointer → `_User`)
- `updatedBy` (Pointer → `_User`)

---

#### `Fee`

Fee definitions.

**Key Fields:**

- `name` (String) - **Required**
- `orgId` (Pointer → `Org`) - **Required**
- `feeType` (String) - **Required**
- `feeCalculationType` (String) - **Required**
- `feeValue` (Number)
- `isActive` (Boolean, default: true)
- `sortOrder` (Number)
- `createdBy` (Pointer → `Staff_Member`)
- `updatedBy` (Pointer → `Staff_Member`)

---

#### `Tip`

Tips for appointments.

**Key Fields:**

- `appointmentId` (Pointer → `Appointment`) - **Required**
- `staffLocationId` (Pointer → `Staff_Location`) - **Required**
- `amount` (Number)
- `createdBy` (Pointer → `_User`)

---

#### `Gift_Card`

Gift cards.

**Key Fields:**

- `invoiceId` (Pointer → `Invoice`) - **Required**
- `itemId` (Pointer → `Items_Catalog`) - **Required**
- `balance` (Number, default: 0) - **Required**
- `initialBalance` (String, default: "0") - **Required**
- `orgId` (Pointer → `Org`)
- `buyerUserId` (Pointer → `_User`)
- `receivingUserId` (Pointer → `_User`)
- `receiverEmail` (String)
- `originationLocationId` (Pointer → `Location`)
- `createdBy` (Pointer → `_User`)
- `updatedBy` (Pointer → `_User`)

---

#### `GiftCard`

Legacy gift card class (alternative implementation).

**Key Fields:**

- `patientId` (Pointer → `Patient`)
- `orgId` (Pointer → `Org`)
- `locationId` (Pointer → `Location`)
- `cardNumber` (String)
- `initialAmount` (Number)
- `currentBalance` (Number)
- `status` (String)
- `issuedAt` (Date)
- `loadedBy` (Pointer → `Staff_Member`)
- `loadedByName` (String)
- `transactions` (Array)
- `notes` (String)

---

#### `Gift_Card_Access`

Gift card access permissions.

**Key Fields:**

- `giftCardId` (Pointer → `Gift_Card`) - **Required**
- `userId` (Pointer → `_User`) - **Required**
- `createdBy` (Pointer → `_User`)
- `updatedBy` (Pointer → `_User`)

---

#### `Credit_Account`

Credit accounts for users.

**Key Fields:**

- `userId` (Pointer → `_User`) - **Required**
- `orgId` (Pointer → `Org`) - **Required**
- `balance` (Number, default: 0) - **Required**
- `createdBy` (Pointer → `_User`)
- `updatedBy` (Pointer → `_User`)

---

#### `Credit_Memo`

Credit memos.

**Key Fields:**

- `userId` (Pointer → `_User`) - **Required**
- `orgId` (Pointer → `Org`) - **Required**
- `amount` (Number) - **Required**
- `createdBy` (Pointer → `_User`)
- `updatedBy` (Pointer → `_User`)

---

#### `Membership_Detail`

Membership plan details.

**Key Fields:**

- `itemId` (Pointer → `Items_Catalog`) - **Required**
- `name` (String) - **Required**
- `createdBy` (Pointer → `_User`)
- `updatedBy` (Pointer → `_User`)

---

#### `Patient_Membership`

Patient membership associations.

**Key Fields:**

- `patientId` (Pointer → `Patient`) - **Required**
- `membershipId` (Pointer → `Membership_Detail`) - **Required**
- `createdBy` (Pointer → `_User`)
- `updatedBy` (Pointer → `_User`)

---

### Insurance

#### `Insurers`

Insurance company master list.

**Key Fields:**

- `name` (String) - **Required**
- `description` (String)
- `address` (String)
- `contactEmail` (String)
- `contactPhone` (String)
- `apiEndpoint` (String)
- `apiCredentials` (String)
- `directBillingEnabled` (Boolean, default: false)
- `createdBy` (Pointer → `_User`)
- `updatedBy` (Pointer → `_User`)

---

#### `Insurer`

Insurance company details (alternative/legacy).

**Key Fields:**

- `name` (String)
- `legalName` (String)
- `type` (String)
- `description` (String)
- `address` (String)
- `apartment` (String)
- `streetAddress` (String)
- `city` (String)
- `provinceState` (String)
- `country` (String)
- `postalZipCode` (String)
- `phoneNumber` (String)
- `contactEmail` (String)
- `contactPhone` (String)
- `directBillingEnabled` (Boolean)
- `defaultUserFee` (Number)
- `defaultPatientPaysRemaining` (Boolean, default: false)
- `displayCoPayField` (Boolean, default: true)
- `displayDeductibleField` (Boolean, default: true)
- `displayCoveragePercentField` (Boolean, default: false)
- `noChargeInvoicesPolicy` (String)

**CLP:** Open access

---

#### `Insurance_Plan`

Insurance plan definitions.

**Key Fields:**

- `insurerId` (Pointer → `Insurers`) - **Required**
- `name` (String) - **Required**
- `planType` (String)
- `maxTreatments` (Number, default: 0)
- `policyEndDate` (Date)
- `coverageDetails` (String)
- `eligibilityCriteria` (String)
- `directBillingConfig` (String)
- `createdBy` (Pointer → `_User`)
- `updatedBy` (Pointer → `_User`)

**CLP:** Open access

---

#### `User_Insurance`

User insurance policies.

**Key Fields:**

- `userId` (Pointer → `_User`) - **Required**
- `insurancePlanId` (Pointer → `Insurance_Plan`) - **Required**
- `policyNumber` (String) - **Required**
- `subscriberName` (String) - **Required**
- `effectiveDate` (Date) - **Required**
- `expirationDate` (Date)
- `memberId` (String)
- `groupNumber` (String)
- `relationshipType` (String) - **Required**
- `isPrimaryHolder` (Boolean, default: false)
- `primaryMemberDOB` (Date)
- `primaryCardHolderFirstName` (String)
- `primaryCardHolderLastName` (String)
- `insuranceCompanyName` (String)
- `isExtendedCoverage` (Boolean, default: false)
- `accidentType` (String)
- `injuryDate` (Date)
- `referralDate` (Date)
- `referralPhysicianName` (String)
- `priorAuthorizationNumber` (String)
- `currentNumberOfTreatments` (Number, default: 0)
- `otherPractitionersSeen` (String)
- `adjusterName` (String)
- `adjusterEmail` (String)
- `adjusterPhone` (String)
- `createdBy` (Pointer → `_User`)
- `updatedBy` (Pointer → `_User`)

---

#### `Patient_Insurance`

Patient-insurance associations.

**Key Fields:**

- `patientId` (Pointer → `Patient`) - **Required**
- `userInsuranceId` (Pointer → `User_Insurance`) - **Required**
- `createdBy` (Pointer → `_User`)
- `updatedBy` (Pointer → `_User`)

---

#### `Provider_Insurance`

Provider insurance credentials.

**Key Fields:**

- `providerCredentialId` (Pointer → `Provider_Credential`) - **Required**
- `insurerId` (Pointer → `Insurers`) - **Required**
- `locationId` (Pointer → `Location`) - **Required**
- `providerType` (String) - **Required**
- `country` (String) - **Required**
- `jurisdiction` (String)
- `npi` (String)
- `provincialBillingNumber` (String)
- `otherIdentifier` (String)
- `createdBy` (Pointer → `_User`)
- `updatedBy` (Pointer → `_User`)

**CLP:** Open access

---

#### `Claim`

Insurance claims.

**Key Fields:**

- `appointmentId` (Pointer → `Appointment`) - **Required**
- `patientInsuranceId` (Pointer → `Patient_Insurance`) - **Required**
- `totalBilled` (Number) - **Required**
- `submissionDate` (Date) - **Required**
- `claimStatus` (String, default: "submitted")
- `totalAllowed` (Number)
- `totalPaid` (Number)
- `billingProviderInsuranceId` (Pointer → `Provider_Insurance`)
- `renderingProviderInsuranceId` (Pointer → `Provider_Insurance`)
- `createdBy` (Pointer → `_User`)
- `updatedBy` (Pointer → `_User`)

---

#### `Claim_Item`

Line items on claims.

**Key Fields:**

- `claimId` (Pointer → `Claim`) - **Required**
- `serviceCode` (String) - **Required**
- `quantity` (Number) - **Required**
- `unitPrice` (Number) - **Required**
- `total` (Number) - **Required**
- `procedureCode` (String)
- `diagnosisCode` (String)
- `description` (String)
- `createdBy` (Pointer → `_User`)
- `updatedBy` (Pointer → `_User`)

---

#### `Claim_Payment`

Payments received for claims.

**Key Fields:**

- `claimId` (Pointer → `Claim`) - **Required**
- `paymentAmount` (Number) - **Required**
- `paymentDate` (Date) - **Required**
- `paymentStatus` (String, default: "pending")
- `EOBDetails` (String)
- `createdBy` (Pointer → `_User`)
- `updatedBy` (Pointer → `_User`)

---

#### `Eligibility_Check`

Insurance eligibility checks.

**Key Fields:**

- `patientInsuranceId` (Pointer → `Patient_Insurance`) - **Required**
- `checkDate` (Date) - **Required**
- `responseDate` (Date)
- `validUntil` (Date)
- `result` (String)

---

#### `Pre_Authorization`

Pre-authorization requests.

**Key Fields:**

- `patientInsuranceId` (Pointer → `Patient_Insurance`) - **Required**
- `serviceCode` (String) - **Required**
- `requestDate` (Date) - **Required**
- `responseDate` (Date)
- `preAuthNumber` (String)
- `status` (String, default: "pending")
- `response` (String)
- `appointmentId` (Pointer → `Appointment`)
- `createdBy` (Pointer → `_User`)
- `updatedBy` (Pointer → `_User`)

---

#### `Insurance_Document`

Insurance-related documents.

**Key Fields:**

- `userInsuranceId` (Pointer → `User_Insurance`) - **Required**
- `documentUrl` (String) - **Required**
- `documentType` (String) - **Required**
- `document` (File)
- `metadata` (String)
- `createdBy` (Pointer → `_User`)

---

### Forms & Charting

#### `Chart`

Chart/clinical notes.

**Key Fields:**

- `patientId` (Pointer → `Patient`) - **Required**
- `status` (String, default: "draft")
- `appointmentId` (Pointer → `Appointment`)
- `treatmentPlanId` (Pointer → `Treatment_Plan`)
- `isStarred` (Boolean, default: false)
- `isBlackBoxed` (Boolean, default: false)
- `isVisibleToPatient` (Boolean, default: false)
- `signedAt` (Date)
- `signedByProviderId` (Pointer → `Staff_Member`)
- `createdBy` (Pointer → `_User`)
- `updatedAt` (Date)

**CLP:** Open access

---

#### `Form_Template`

Form templates.

**Key Fields:**

- `type` (String) - **Required**
- `orgId` (Pointer → `Org`)
- `locationId` (Pointer → `Location`)
- `ownershipGroupId` (Pointer → `Ownership_Group`)
- `userId` (Pointer → `_User`)
- `createdBy` (Pointer → `_User`)
- `updatedBy` (Pointer → `_User`)

---

#### `Intake_Form`

Intake form submissions.

**Key Fields:**

- `patientId` (Pointer → `Patient`) - **Required**
- `orgId` (Pointer → `Org`) - **Required**
- `type` (String) - **Required**
- `userId` (Pointer → `_User`)
- `ownershipGroupId` (Pointer → `Ownership_Group`)
- `createdBy` (Pointer → `_User`)
- `updatedBy` (Pointer → `_User`)

---

#### `Form_Data`

Form data submissions.

**Key Fields:**

- `formType` (String) - **Required**
- `formTemplateId` (Pointer → `Form_Template`)
- `intakeFormId` (Pointer → `Intake_Form`)
- `chartId` (Pointer → `Chart`)
- `name` (String)
- `type` (String)
- `data` (String)
- `createdBy` (Pointer → `_User`)
- `updatedBy` (Pointer → `_User`)

---

#### `Form_Detail`

Form detail entries.

**Key Fields:**

- `formTemplateId` (Pointer → `Form_Template`)
- `intakeFormId` (Pointer → `Insurance_Document`)
- `chartId` (Pointer → `Chart`)
- `name` (String)
- `type` (String)
- `data` (String)
- `orderIndex` (Number, default: 0)
- `createdAt` (Date)
- `updatedAt` (Date)

**CLP:** Open access

---

### Notifications

(Already covered in Patient_Notification and Staff_Notification sections above)

---

### Permissions & Security

#### `Permission`

Permission definitions.

**Key Fields:**

- `name` (String) - **Required**
- `key` (String)
- `label` (String)
- `categoryKey` (String)
- `categoryLabel` (String)
- `active` (Boolean, default: true)
- `sortOrder` (Number)
- `createdBy` (Pointer → `_User`)
- `updatedBy` (Pointer → `_User`)

**CLP:** Open access

---

#### `Role_Permission`

Role-permission associations.

**Key Fields:**

- `roleId` (Pointer → `_Role`) - **Required**
- `permissionId` (Pointer → `Permission`) - **Required**
- `createdBy` (Pointer → `_User`)
- `updatedBy` (Pointer → `_User`)

**Indexes:**

- `_id_`

**CLP:** Requires authentication; create/update/delete requires `role:OrgAdmin`.

---

#### `Staff_Permission`

Staff-specific permissions.

**Key Fields:**

- `staffId` (Pointer → `Staff_Member`) - **Required**
- `orgId` (Pointer → `Org`)
- `orgRoleId` (Pointer → `Org_Role`)
- `roleId` (Pointer → `_Role`)
- `locationId` (Pointer → `Location`)
- `ownershipGroupId` (Pointer → `Ownership_Group`)
- `createdBy` (Pointer → `_User`)
- `updatedBy` (Pointer → `_User`)

**CLP:** Open access

---

#### `Org_Role`

Organization-role associations.

**Key Fields:**

- `orgId` (Pointer → `Org`) - **Required**
- `roleId` (Pointer → `_Role`) - **Required**
- `locationId` (Pointer → `Location`)
- `ownershipGroupId` (Pointer → `Ownership_Group`)
- `createdBy` (Pointer → `_User`)
- `updatedBy` (Pointer → `_User`)

**Indexes:**

- `_id_`

**CLP:** Requires authentication; all operations require `role:OrgAdmin`.

---

#### `Blackbox_Access`

Access control for blackboxed charts.

**Key Fields:**

- `chartId` (Pointer → `Chart`) - **Required**
- `staffId` (Pointer → `Staff_Member`) - **Required**
- `accessLevel` (String) - **Required**
- `isActive` (Boolean, default: true)
- `createdBy` (Pointer → `_User`)
- `updatedBy` (Pointer → `_User`)

**CLP:** Open access

---

### Other Classes

#### `Booking_Policy`

Booking policies for locations/patients.

**Key Fields:**

- `orgId` (Pointer → `Org`)
- `locationId` (Pointer → `Location`)
- `ownershipGroupId` (Pointer → `Ownership_Group`)
- `bookingPolicyPresetId` (Pointer → `Booking_Policy_Preset`)
- `firstVisitPolicyPresetId` (Pointer → `Booking_Policy_Preset`)
- `allowCancellations` (Boolean, default: true)
- `allowSameDayBooking` (Boolean, default: false)
- `depositAmount` (Number)
- `depositPercentage` (Number)
- `noBookingWithin` (Pointer → `Time_Interval`)
- `lateCancellationPeriod` (Pointer → `Time_Interval`)
- `createdBy` (Pointer → `_User`)
- `updatedBy` (Pointer → `_User`)

**CLP:** Open access

---

#### `Booking_Policy_Preset`

Booking policy presets.

**Key Fields:**

- `name` (String) - **Required**
- `requireDeposit` (Boolean, default: false)
- `requireCreditCard` (Boolean, default: false)
- `depositType` (String)
- `createdBy` (Pointer → `_User`)
- `updatedBy` (Pointer → `_User`)

---

#### `Booking_Portal`

Public booking portal configuration.

**Key Fields:**

- `orgId` (Pointer → `Org`) - **Required**
- `slug` (String)
- `title` (String)
- `subtitle` (String)
- `description` (String)
- `isActive` (Boolean, default: true)
- `logo` (File)
- `backgroundImage` (File)
- `primaryColor` (String, default: "#1976d2")
- `secondaryColor` (String, default: "#f5f5f5")
- `accentColor` (String, default: "#ff4081")
- `fontFamily` (String, default: "Inter")
- `themeSettings` (Object)
- `ownershipGroup` (Pointer → `Ownership_Group`)
- `contactEmail` (String)
- `contactPhone` (String)
- `supportMessage` (String)
- `showPricing` (Boolean, default: true)
- `showPricesIncludingTax` (Boolean, default: true)
- `requirePayment` (Boolean, default: false)
- `requireAccountCreation` (Boolean, default: false)
- `requirePhoneVerification` (Boolean, default: false)
- `paymentProvider` (String)
- `depositPercentage` (Number, default: 0)
- `cancellationHours` (Number, default: 24)
- `minimumNoticeHours` (Number, default: 24)
- `advanceBookingDays` (Number, default: 30)
- `cancellationPolicy` (String)
- `enableWaitlist` (Boolean, default: true)
- `enableGroupBooking` (Boolean, default: false)
- `enableOnlineIntake` (Boolean, default: false)
- `sendBookingNotifications` (Boolean, default: true)
- `enableTracking` (Boolean, default: false)
- `defaultViewType` (String, default: "location-first")
- `blockedDates` (Array)
- `customBusinessHours` (Object)
- `allowedDisciplines` (Array)
- `allowedServiceTypes` (Array)
- `excludedStaffIds` (Array)
- `featuredStaffIds` (Array)
- `requiredIntakeForms` (Array)
- `metaTitle` (String)
- `metaDescription` (String)
- `metaKeywords` (Array)
- `googleAnalyticsId` (String)
- `facebookPixelId` (String)
- `customCSS` (String)
- `bookingConfirmationTemplate` (String)
- `bookingReminderTemplate` (String)

**Indexes:**

- `_id_`
- `org_index`
- `org_ownership_index`
- `active_portals_index`
- `ownershipGroup_index`

**CLP:** Open access

---

#### `Favorite_Location`

User favorite locations.

**Key Fields:**

- `userId` (Pointer → `_User`) - **Required**
- `locationId` (Pointer → `Location`)

---

#### `McpWriteTest`

Test class (likely for development/testing).

**Key Fields:**

- `by` (String)
- `ts` (String)

---

### Parse System Classes

These are internal Parse Server classes:

- `_SCHEMA` - Schema definitions
- `_Hooks` - Cloud code hooks
- `_JobStatus` - Background job status
- `_JobSchedule` - Scheduled jobs
- `_PushStatus` - Push notification status
- `_Audience` - Push notification audiences
- `_GlobalConfig` - Global configuration
- `_GraphQLConfig` - GraphQL configuration
- `_Idempotency` - Idempotency tracking
- `_Join:users:_Role` - Join table for user-role relations
- `_Join:roles:_Role` - Join table for role-role relations

---

### Common Field Patterns

#### Standard Fields

Most classes include:

- `objectId` (String) - Unique identifier
- `createdAt` (Date) - Creation timestamp
- `updatedAt` (Date) - Last update timestamp
- `ACL` (ACL) - Access Control List (or `_rperm`/`_wperm` arrays)

#### Audit Fields

Many classes include:

- `createdBy` (Pointer → `_User`)
- `updatedBy` (Pointer → `_User`)

#### Multi-Tenancy Fields

Classes often include:

- `orgId` (Pointer → `Org`)
- `locationId` (Pointer → `Location`)
- `ownershipGroupId` (Pointer → `Ownership_Group`)

---

### Class Level Permissions (CLP)

Most classes have open CLP (`"*": true`) for all operations. Notable exceptions:

- `_Role` - Requires authentication; create/update/delete requires `role:OrgAdmin`
- `Role_Permission` - Requires authentication; create/update/delete requires `role:OrgAdmin`
- `Org_Role` - Requires authentication; all operations require `role:OrgAdmin`

---

### Notes

1. **Pointer Fields**: All pointer fields reference Parse objectIds. When using GraphQL, these may appear as base64-encoded GraphQL IDs that need normalization.

2. **Required Fields**: Fields marked as `required: true` must be provided when creating records.

3. **Default Values**: Fields with `defaultValue` will use that value if not provided.

4. **Array Fields**: Some fields are arrays (e.g., `taxIds`, `blockedDates`). These store JSON arrays.

5. **Object Fields**: Some fields are objects (e.g., `stripeConnectedCustomers`, `themeSettings`). These store JSON objects.

6. **File Fields**: File fields store Parse File objects with `name` and `url` properties.

7. **Date Fields**: Date fields store ISO 8601 date strings or Date objects.

8. **Relations**: Some classes use Parse Relations instead of Pointers for many-to-many relationships.

---

**Last Updated:** Generated from `_SCHEMA` table  
**Total Classes:** 100+ Parse classes documented

---

**Last Updated:** $(date)  
**Document Owner:** Development Team  
**Status:** Awaiting developer input for TODO items
