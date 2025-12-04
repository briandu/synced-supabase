# Supabase Migration Testing Guide

This guide provides comprehensive testing procedures for validating the Supabase migration.

## Prerequisites

1. **Environment Setup**

   ```bash
   # Enable Supabase features
   NEXT_PUBLIC_SUPABASE_FEATURE_APPOINTMENTS=true
   NEXT_PUBLIC_SUPABASE_FEATURE_BILLING=true
   NEXT_PUBLIC_SUPABASE_FEATURE_STORAGE=true
   NEXT_PUBLIC_SUPABASE_FEATURE_REALTIME=true
   NEXT_PUBLIC_SUPABASE_FEATURE_AUTH=true

   # Supabase configuration
   NEXT_PUBLIC_SUPABASE_URL=https://your-project.supabase.co
   NEXT_PUBLIC_SUPABASE_ANON_KEY=your-anon-key
   SUPABASE_SERVICE_ROLE_KEY=your-service-role-key
   ```

2. **Database State**
   - All migrations applied successfully
   - Test data available (or seed script run)
   - RLS policies enabled and tested

## Testing Strategy

### Phase 1: Feature Flag Testing

**Goal:** Verify that feature flags correctly toggle between Parse and Supabase backends.

#### Test Cases

1. **Feature Flag Disabled (Parse)**

   ```bash
   # Set all flags to false or unset
   unset NEXT_PUBLIC_SUPABASE_FEATURE_APPOINTMENTS
   ```

   - Verify components use Parse queries
   - Verify data loads from Parse
   - Verify mutations work with Parse

2. **Feature Flag Enabled (Supabase)**

   ```bash
   # Set flags to true
   export NEXT_PUBLIC_SUPABASE_FEATURE_APPOINTMENTS=true
   ```

   - Verify components use Supabase queries
   - Verify data loads from Supabase
   - Verify mutations work with Supabase

3. **Mixed Flags**
   - Test with some features enabled and others disabled
   - Verify components handle mixed state correctly

### Phase 2: GraphQL Query Testing

**Goal:** Verify all Supabase GraphQL queries work correctly.

#### Test Checklist

- [ ] **Appointments**

  - [ ] `GET_APPOINTMENTS_BY_LOCATION_AND_TIME_SUPA`
  - [ ] `GET_APPOINTMENTS_BY_STAFFS_AND_TIME_SUPA`
  - [ ] `GET_APPOINTMENT_BY_ID_SUPA`
  - [ ] `GET_CHECKED_IN_APPOINTMENTS_BY_LOCATION_SUPA`
  - [ ] `GET_ALL_CHECKED_IN_APPOINTMENTS_BY_LOCATION_SUPA`
  - [ ] `GET_ALL_CHECKED_IN_APPOINTMENTS_BY_STAFF_SUPA`
  - [ ] `CREATE_APPOINTMENT_SUPA`
  - [ ] `UPDATE_APPOINTMENT_SUPA`

- [ ] **Services & Products**

  - [ ] `GET_ITEM_PRICE_SUPA`
  - [ ] `GET_SERVICE_FOR_EDIT_SUPA`
  - [ ] `GET_LOCATION_SERVICES_WITH_STAFF_SUPA`
  - [ ] All service mutations

- [ ] **Charting**

  - [ ] `GET_CHARTS_BY_PATIENT_ID_SUPA`
  - [ ] `GET_CHARTS_BY_STAFF_ID_SUPA`
  - [ ] `CREATE_CHART_SUPA`
  - [ ] `UPDATE_CHART_SUPA`

- [ ] **Billing**

  - [ ] `GET_INVOICES_BY_APPOINTMENT_IDS_SUPA`
  - [ ] `CREATE_INVOICE_SUPA`
  - [ ] `UPDATE_INVOICE_SUPA`
  - [ ] `GET_PAYMENT_BY_ID_SUPA`
  - [ ] `RECORD_PAYMENT_SUPA`

- [ ] **Other Domains**
  - [ ] Staff shifts, breaks, time off
  - [ ] Operating hours
  - [ ] Rooms and resources
  - [ ] Waitlist
  - [ ] Insurance
  - [ ] Permissions and roles

#### Testing Tools

1. **GraphQL Playground**

   ```bash
   # Access Supabase GraphQL endpoint
   https://your-project.supabase.co/graphql/v1
   ```

2. **Browser DevTools**

   - Network tab: Verify queries sent to correct endpoint
   - Apollo DevTools: Inspect query/mutation execution

3. **Manual Testing Script**
   ```javascript
   // Test query in browser console
   const testQuery = async () => {
     const response = await fetch('https://your-project.supabase.co/graphql/v1', {
       method: 'POST',
       headers: {
         'Content-Type': 'application/json',
         apikey: 'your-anon-key',
         Authorization: `Bearer ${your - jwt - token}`,
       },
       body: JSON.stringify({
         query: `
           query {
             appointments(limit: 5) {
               id
               startsAt
               status
             }
           }
         `,
       }),
     });
     const data = await response.json();
     console.log(data);
   };
   ```

### Phase 3: Component Testing

**Goal:** Verify all updated components work correctly with Supabase.

#### Test Checklist

- [ ] **Appointment Components**

  - [ ] `AppointmentDetailsContent` - View/edit appointment
  - [ ] `ScheduleCalendar` - Calendar view
  - [ ] `AppointmentsOverview` - List view
  - [ ] `DataGridAppointments` - Data grid
  - [ ] `DataGridCheckedIn` - Checked-in appointments
  - [ ] `ScheduleToolbar` - Toolbar actions

- [ ] **Patient Components**

  - [ ] `PatientFiles` - File uploads
  - [ ] `PatientCharting` - Charting entries

- [ ] **Other Components**
  - [ ] Services management
  - [ ] Billing components
  - [ ] Staff management

#### Test Scenarios

1. **Data Loading**

   - Verify data loads correctly
   - Verify loading states display
   - Verify error handling

2. **Data Mutations**

   - Create new records
   - Update existing records
   - Delete records
   - Verify optimistic updates

3. **Data Relationships**

   - Verify nested relationships load
   - Verify foreign key relationships
   - Verify data normalization

4. **Real-time Updates**
   - Verify real-time subscriptions work
   - Verify updates propagate correctly

### Phase 4: API Route Testing

**Goal:** Verify all API routes work correctly with Supabase.

#### Test Checklist

- [ ] `/api/users/find-by-email` - User lookup
- [ ] `/api/staff/list` - Staff listing
- [ ] `/api/staff/disconnect` - Staff disconnection
- [ ] `/api/invite/accept` - Invite acceptance
- [ ] `/api/audit/log` - Audit logging
- [ ] `/api/payments/record` - Payment recording
- [ ] `/api/invoices/*` - Invoice operations
- [ ] `/api/stripe/*` - Stripe operations

#### Testing Tools

1. **cURL**

   ```bash
   curl -X POST http://localhost:3000/api/audit/log \
     -H "Content-Type: application/json" \
     -d '{"type":"test_event","orgId":"test-org"}'
   ```

2. **Postman/Insomnia**

   - Create collection of API routes
   - Test with various inputs
   - Verify responses

3. **Integration Tests**
   ```javascript
   // Example test
   describe('API Routes', () => {
     it('should log audit event', async () => {
       const response = await fetch('/api/audit/log', {
         method: 'POST',
         body: JSON.stringify({ type: 'test' }),
       });
       expect(response.ok).toBe(true);
     });
   });
   ```

### Phase 5: End-to-End Testing

**Goal:** Verify complete user flows work correctly.

#### Test Flows

1. **Appointment Booking Flow**

   - Create appointment
   - View appointment
   - Update appointment
   - Check in appointment
   - Check out appointment
   - Cancel appointment

2. **Patient Management Flow**

   - Create patient
   - View patient profile
   - Upload patient files
   - Create chart entry
   - View chart history

3. **Billing Flow**

   - Create invoice
   - Record payment
   - View payment history
   - Generate reports

4. **Staff Management Flow**
   - Create staff member
   - Assign to location
   - Set permissions
   - View schedule

### Phase 6: Performance Testing

**Goal:** Verify performance is acceptable.

#### Metrics to Monitor

1. **Query Performance**

   - Query execution time
   - Number of queries per page load
   - Query complexity

2. **Component Performance**

   - Render time
   - Re-render frequency
   - Memory usage

3. **API Performance**
   - Response time
   - Throughput
   - Error rate

#### Tools

- Chrome DevTools Performance tab
- React DevTools Profiler
- Supabase Dashboard (query performance)
- Application monitoring (if available)

### Phase 7: Security Testing

**Goal:** Verify RLS policies and security work correctly.

#### Test Cases

1. **Row Level Security**

   - Verify users can only access their org's data
   - Verify staff can only access their location's data
   - Verify patients can only access their own data

2. **Authentication**

   - Verify authentication required
   - Verify JWT tokens validated
   - Verify session management

3. **Authorization**
   - Verify role-based access control
   - Verify permission checks
   - Verify data filtering

### Phase 8: Data Migration Testing

**Goal:** Verify data migration scripts work correctly.

#### Test Cases

1. **Historical Data**

   - Verify Parse data migrated correctly
   - Verify data integrity
   - Verify relationships preserved

2. **File Migration**
   - Verify files migrated to Supabase Storage
   - Verify file URLs updated
   - Verify file access works

## Test Execution

### Manual Testing

1. **Setup Test Environment**

   ```bash
   # Enable Supabase features
   export NEXT_PUBLIC_SUPABASE_FEATURE_APPOINTMENTS=true
   export NEXT_PUBLIC_SUPABASE_FEATURE_BILLING=true
   export NEXT_PUBLIC_SUPABASE_FEATURE_STORAGE=true

   # Start development server
   npm run dev
   ```

2. **Execute Test Cases**
   - Follow test checklists above
   - Document any issues found
   - Verify fixes

### Automated Testing

1. **Unit Tests**

   ```bash
   npm test
   ```

2. **Integration Tests**

   ```bash
   npm run test:integration
   ```

3. **E2E Tests**
   ```bash
   npm run test:e2e
   ```

## Issue Tracking

### Common Issues

1. **Query Errors**

   - Check GraphQL query syntax
   - Verify field names (camelCase vs snake_case)
   - Check RLS policies

2. **Data Normalization**

   - Verify `normalizeResponse` called correctly
   - Check Parse vs Supabase data structure differences

3. **Feature Flags**
   - Verify flags set correctly
   - Check flag propagation
   - Verify fallback behavior

### Reporting Issues

When reporting issues, include:

- Feature flag state
- Query/mutation used
- Expected vs actual behavior
- Error messages
- Browser console logs
- Network requests

## Success Criteria

Migration is considered successful when:

- [ ] All test cases pass
- [ ] No critical bugs found
- [ ] Performance is acceptable
- [ ] Security verified
- [ ] Data integrity confirmed
- [ ] User flows work end-to-end

## Rollback Plan

If issues are found:

1. **Disable Feature Flags**

   ```bash
   unset NEXT_PUBLIC_SUPABASE_FEATURE_APPOINTMENTS
   unset NEXT_PUBLIC_SUPABASE_FEATURE_BILLING
   # etc.
   ```

2. **Verify Parse Still Works**

   - Test critical flows
   - Verify data access

3. **Fix Issues**
   - Address identified problems
   - Re-test
   - Re-enable flags incrementally

## Next Steps

After successful testing:

1. Deploy to staging
2. Perform staging testing
3. Deploy to production
4. Monitor production metrics
5. Gradually enable features for users
