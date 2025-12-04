# Phase 11: Testing & QA - Implementation Plan

**Date:** December 3, 2025  
**Status:** In Progress

---

## Overview

Phase 11 focuses on comprehensive testing of the Supabase migration to ensure all functionality works correctly, security is maintained, and performance is acceptable.

---

## Current State

### ✅ Completed

1. **Testing Guide Created** - `docs/migrations/TESTING_GUIDE.md` provides comprehensive testing procedures
2. **Basic Supabase Mock** - `__mocks__/supabaseClient.js` exists with query builder support
3. **Test Utilities** - `src/test-utils/` provides render helpers and mock data
4. **One Integration Test** - `ensure-appointment-invoice.test.js` demonstrates Supabase testing pattern

### 🔄 In Progress

1. **Mock Enhancements** - Need to enhance Supabase mock for full feature coverage
2. **Integration Tests** - Need comprehensive integration tests

### ❌ Not Started

1. **Regression Tests** - Zero-tolerance flow tests
2. **RLS/Isolation Tests** - Tenant and role-based access tests
3. **Storage Tests** - Signed URL and access control tests
4. **Performance Tests** - Query performance smoke tests
5. **Manual QA Scripts** - Staging testing procedures

---

## Implementation Plan

### Step 1: Enhance Supabase Mock ✅

**File:** `__mocks__/supabaseClient.js`

**Enhancements Needed:**
- [x] Basic query builder (select, eq, or, order, limit, maybeSingle, single, insert, update) ✅
- [ ] Add `delete()` support
- [ ] Add `upsert()` support
- [ ] Add `in()` filter support
- [ ] Add `neq()`, `gt()`, `gte()`, `lt()`, `lte()` filters
- [ ] Add `like()`, `ilike()` filters
- [ ] Add `is()` for null checks
- [ ] Add `not()` filter
- [ ] Add `count()` support
- [ ] Add storage mock (`storage.from().upload()`, `createSignedUrl()`)
- [ ] Add realtime mock (channel subscriptions)
- [ ] Add auth admin methods (`getUserById()`, `updateUserById()`)
- [ ] Add error simulation helpers

### Step 2: Integration Tests

**Location:** `src/__tests__/integration/`

**Tests to Create:**

1. **Auth Integration Tests** (`auth.integration.test.js`)
   - [ ] Login flow (email/password)
   - [ ] Signup flow
   - [ ] Password reset flow
   - [ ] OAuth flow (Google)
   - [ ] Session persistence
   - [ ] Logout flow

2. **Appointment Integration Tests** (`appointments.integration.test.js`)
   - [ ] Create appointment
   - [ ] Update appointment
   - [ ] Delete appointment
   - [ ] Query appointments by location
   - [ ] Query appointments by staff
   - [ ] Check-in/check-out flow
   - [ ] Real-time updates

3. **Billing Integration Tests** (`billing.integration.test.js`)
   - [ ] Create invoice
   - [ ] Update invoice
   - [ ] Record payment
   - [ ] Query invoices by patient
   - [ ] Query payments by patient
   - [ ] Stripe webhook processing

4. **Storage Integration Tests** (`storage.integration.test.js`)
   - [ ] Upload file
   - [ ] Generate signed URL
   - [ ] Download file
   - [ ] Delete file
   - [ ] Access control (org/patient scoping)

5. **Realtime Integration Tests** (`realtime.integration.test.js`)
   - [ ] Subscribe to appointments
   - [ ] Subscribe to chat messages
   - [ ] Presence updates
   - [ ] Typing indicators

### Step 3: Regression Tests (Zero-Tolerance Flows)

**Location:** `src/__tests__/regression/`

**Critical Flows to Test:**

1. **Auth Regression** (`auth.regression.test.js`)
   - [ ] Staff invite acceptance
   - [ ] User login with valid credentials
   - [ ] User login with invalid credentials
   - [ ] Session expiry handling
   - [ ] Multi-org user switching

2. **Booking Regression** (`booking.regression.test.js`)
   - [ ] Create appointment with valid data
   - [ ] Create appointment with invalid data
   - [ ] Update appointment status
   - [ ] Cancel appointment
   - [ ] Appointment conflicts detection

3. **Patient Data Regression** (`patient-data.regression.test.js`)
   - [ ] Create patient
   - [ ] Update patient profile
   - [ ] View patient data
   - [ ] Patient data privacy (RLS)
   - [ ] Patient file upload

4. **Payments Regression** (`payments.regression.test.js`)
   - [ ] Record payment
   - [ ] Payment allocation to invoices
   - [ ] Payment method save
   - [ ] Payment method delete
   - [ ] Stripe webhook processing

5. **Staff Invites Regression** (`staff-invites.regression.test.js`)
   - [ ] Create staff invite
   - [ ] Accept staff invite
   - [ ] Reject staff invite
   - [ ] Resend staff invite
   - [ ] Staff invite expiry

### Step 4: RLS/Tenant Isolation Tests

**Location:** `src/__tests__/security/rls/`

**Tests to Create:**

1. **Org Isolation Tests** (`org-isolation.test.js`)
   - [ ] User can only access their org's data
   - [ ] User cannot access other org's data
   - [ ] Superadmin can access all orgs
   - [ ] Org admin can only access their org

2. **Location Isolation Tests** (`location-isolation.test.js`)
   - [ ] Staff can only access their location's data
   - [ ] Staff cannot access other location's data
   - [ ] Org admin can access all locations in their org

3. **Patient Isolation Tests** (`patient-isolation.test.js`)
   - [ ] Patient can only access their own data
   - [ ] Staff can access patient data in their org
   - [ ] Staff cannot access patient data outside their org

4. **Role-Based Access Tests** (`role-access.test.js`)
   - [ ] Staff role permissions
   - [ ] Org admin role permissions
   - [ ] Patient role permissions
   - [ ] Superadmin role permissions

### Step 5: Storage Signing Tests

**Location:** `src/__tests__/storage/`

**Tests to Create:**

1. **Signed URL Tests** (`signed-urls.test.js`)
   - [ ] Generate signed URL
   - [ ] Signed URL expiry
   - [ ] Signed URL refresh
   - [ ] Access denied with expired URL
   - [ ] Access denied outside scope

2. **Storage Path Tests** (`storage-paths.test.js`)
   - [ ] Org-scoped paths
   - [ ] Patient-scoped paths
   - [ ] Staff-scoped paths
   - [ ] Path validation
   - [ ] Path enforcement

### Step 6: Performance Smoke Tests

**Location:** `src/__tests__/performance/`

**Tests to Create:**

1. **Query Performance Tests** (`query-performance.test.js`)
   - [ ] Appointments calendar query (< 500ms)
   - [ ] Billing list query (< 500ms)
   - [ ] Patient list query (< 500ms)
   - [ ] Staff list query (< 500ms)

2. **Component Performance Tests** (`component-performance.test.js`)
   - [ ] Schedule calendar render (< 1s)
   - [ ] Appointment details render (< 500ms)
   - [ ] Patient profile render (< 500ms)

### Step 7: Manual QA Scripts

**Location:** `docs/migrations/MANUAL_QA_SCRIPTS.md`

**Scripts to Document:**

1. **Login & Auth**
   - [ ] Login with email/password
   - [ ] Login with Google OAuth
   - [ ] Password reset
   - [ ] Staff invite acceptance

2. **Scheduling**
   - [ ] Create appointment
   - [ ] Update appointment
   - [ ] Check-in appointment
   - [ ] Check-out appointment
   - [ ] Cancel appointment
   - [ ] View calendar

3. **Billing**
   - [ ] Create invoice
   - [ ] Record payment
   - [ ] View payment history
   - [ ] Generate reports

4. **Patient Management**
   - [ ] Create patient
   - [ ] Update patient profile
   - [ ] Upload patient file
   - [ ] View patient chart

5. **Realtime**
   - [ ] Chat messaging
   - [ ] Presence indicators
   - [ ] Typing indicators
   - [ ] Appointment updates

6. **Notifications**
   - [ ] Email notifications
   - [ ] SMS notifications
   - [ ] Push notifications
   - [ ] In-app notifications

---

## Test Execution Strategy

### Automated Tests

```bash
# Run all unit tests
npm test

# Run integration tests
npm run test:integration

# Run regression tests
npm run test:regression

# Run security tests
npm run test:security

# Run performance tests
npm run test:performance

# Run all tests
npm run test:all
```

### Manual QA

1. **Staging Environment Setup**
   - Deploy to staging
   - Enable Supabase feature flags
   - Seed test data

2. **Execute QA Scripts**
   - Follow `MANUAL_QA_SCRIPTS.md`
   - Document any issues
   - Verify fixes

---

## Success Criteria

Phase 11 is complete when:

- [ ] All integration tests pass
- [ ] All regression tests pass
- [ ] All RLS/isolation tests pass
- [ ] All storage tests pass
- [ ] All performance tests pass
- [ ] Manual QA scripts executed and documented
- [ ] No critical bugs found
- [ ] Performance is acceptable (< 500ms for key queries)
- [ ] Security verified (RLS working correctly)

---

## Next Steps

1. **Enhance Supabase Mock** - Add missing methods and features
2. **Create Integration Tests** - Start with auth, then appointments, billing
3. **Create Regression Tests** - Focus on zero-tolerance flows
4. **Create RLS Tests** - Verify tenant isolation
5. **Create Storage Tests** - Verify signed URLs and access control
6. **Create Performance Tests** - Verify query performance
7. **Document Manual QA Scripts** - Create comprehensive testing procedures

---

## Timeline Estimate

- **Week 1:** Enhance mocks, create integration tests
- **Week 2:** Create regression tests, RLS tests
- **Week 3:** Create storage tests, performance tests
- **Week 4:** Manual QA, bug fixes, documentation

**Total:** ~4 weeks for comprehensive testing


