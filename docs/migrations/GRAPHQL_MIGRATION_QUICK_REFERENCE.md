# GraphQL Migration Quick Reference

This is a quick lookup reference for migrating GraphQL queries from Parse to Supabase. For detailed explanations, see `GRAPHQL_FIELD_NAMING_MIGRATION.md`.

## One-Line Reference

**Rule:** Replace `{field}Id { id }` with `{field} { id }` (singular, no `_id` suffix)

| Parse Style | → | Supabase Style |
|------------|---|----------------|
| `orgId { id }` | → | `org { id }` |
| `locationId { id }` | → | `location { id }` |
| `staffId { id }` | → | `staff { id }` |
| `patientId { id }` | → | `patient { id }` |
| `userId { id }` | → | `user { id }` |

## Common Patterns Found

### Files with `orgId` patterns (46+ occurrences)
- `src/app/graphql/users.graphql.js` - Lines 45, 86, 134, 153
- `src/app/graphql/staff.graphql.js` - Lines 230, 280, 316, 397
- `src/app/graphql/services/services.graphql.js` - Lines 114, 137, 152
- `src/app/graphql/services/discipline_offerings.graphql.js` - Lines 21, 53, 83
- `src/app/graphql/services/org_services.graphql.js` - Line 33
- `src/app/graphql/services/location_services.graphql.js` - Lines 33, 79, 112, 161, 194
- `src/app/graphql/ownership_groups.graphql.js` - Line 61
- `src/app/graphql/locations.graphql.js` - Line 83
- `src/app/graphql/organization.graphql.js` - Line 104
- `src/app/graphql/invites.graphql.js` - Lines 57, 81
- `src/app/graphql/payment.graphql.js` - Line 56
- `src/app/graphql/fee.graphql.js` - Lines 21, 54, 86, 117
- `src/app/graphql/services/ownership_group_services.graphql.js` - Lines 33, 83, 123
- `src/app/graphql/waitlist.graphql.js` - Lines 17, 77, 135, 191
- `src/app/graphql/permissions.graphql.js` - Lines 192, 223
- `src/app/graphql/booking_portal.graphql.js` - Lines 66, 97, 115, 132, 236, 317

### Files with `locationId` patterns (80+ occurrences)
- `src/app/graphql/staff.graphql.js` - Multiple locations
- `src/app/graphql/services/services.graphql.js` - Multiple locations
- `src/app/graphql/locations.graphql.js` - Multiple locations
- `src/app/graphql/organization.graphql.js` - Line 163
- And many more...

### Files with `staffId` patterns (50+ occurrences)
- `src/app/graphql/users.graphql.js` - Lines 74, 154
- `src/app/graphql/staff.graphql.js` - Multiple locations
- `src/app/graphql/services/services.graphql.js` - Multiple locations
- And many more...

### Files with `patientId` patterns (30+ occurrences)
- `src/app/graphql/patients.graphql.js` - Multiple locations in various queries
- Multiple other files referencing patients

### Files with `userId` patterns (15+ occurrences)
- `src/app/graphql/users.graphql.js` - Lines 48
- `src/app/graphql/staff.graphql.js` - Multiple locations

### Files with `createdBy` / `updatedBy` patterns
- `src/app/graphql/patients.graphql.js` - Lines 108, 134, 377, 396
- `src/app/graphql/locations.graphql.js` - Line 98
- Various other files with audit fields

## Migration Priority Order

Based on usage frequency and dependencies:

### Phase 1: Core Domain (High Priority)
1. ✅ `src/app/graphql/patients.graphql.js` - Partially migrated (has `_SUPA` variants)
2. ✅ `src/app/graphql/staff.graphql.js` - Partially migrated (has `_SUPA` variants)
3. ✅ `src/app/graphql/users.graphql.js` - Partially migrated (has `_SUPA` variants)
4. ✅ `src/app/graphql/locations.graphql.js` - Partially migrated (has `_SUPA` variants)
5. `src/app/graphql/organization.graphql.js`
6. `src/app/graphql/ownership_groups.graphql.js`

### Phase 2: Services & Products
7. `src/app/graphql/services/services.graphql.js`
8. `src/app/graphql/services/org_services.graphql.js`
9. `src/app/graphql/services/location_services.graphql.js`
10. `src/app/graphql/services/ownership_group_services.graphql.js`
11. `src/app/graphql/services/discipline_offerings.graphql.js`
12. `src/app/graphql/disciplines.graphql.js`

### Phase 3: Scheduling
13. `src/app/graphql/appointment.graphql.js`
14. `src/app/graphql/availability_block.graphql.js`
15. `src/app/graphql/waitlist.graphql.js`
16. `src/app/graphql/schedule_slots.graphql.js`
17. `src/app/graphql/staff_shift.graphql.js`
18. `src/app/graphql/staff_break.graphql.js`
19. `src/app/graphql/staff_time_off.graphql.js`

### Phase 4: Billing
20. `src/app/graphql/invoice.graphql.js`
21. `src/app/graphql/payment.graphql.js`
22. `src/app/graphql/fee.graphql.js`
23. `src/app/graphql/tax.graphql.js`

### Phase 5: Other Domains
24. `src/app/graphql/insurance.graphql.js`
25. `src/app/graphql/invites.graphql.js`
26. `src/app/graphql/charting.graphql.js`
27. `src/app/graphql/task.graphql.js`
28. `src/app/graphql/permissions.graphql.js`
29. `src/app/graphql/booking_portal.graphql.js`
30. `src/app/graphql/patient_staff.graphql.js`
31. `src/app/graphql/operating_hour.graphql.js`
32. `src/app/graphql/location_offerings.graphql.js`
33. `src/app/graphql/room.graphql.js`
34. `src/app/graphql/file_upload.graphql.js`
35. `src/app/graphql/account.graphql.js`
36. `src/app/graphql/auth.graphql.js`

### Phase 6: Context Files
37. `src/app/contexts/OrgSetupCompletionContext.js` - Contains embedded GraphQL queries

## Regex Search Patterns

Use these regex patterns to find what needs to be migrated:

```regex
# Find Parse-style relationship fields
orgId\s*\{|locationId\s*\{|staffId\s*\{|patientId\s*\{|userId\s*\{

# Find Parse-style filters
orgId:\s*\{|locationId:\s*\{|staffId:\s*\{|patientId:\s*\{|userId:\s*\{

# Find Relay patterns
edges\s*\{|node\s*\{

# Find Parse ID types
\$[a-zA-Z]+:\s*ID!
```

## File Count Summary

- **Total GraphQL files**: 36 files
- **Files with orgId**: ~24 files
- **Files with locationId**: ~20 files
- **Files with staffId**: ~18 files
- **Files with patientId**: ~12 files
- **Files with userId**: ~8 files
- **Files with createdBy**: ~6 files

---

**See Also:**
- `GRAPHQL_FIELD_NAMING_MIGRATION.md` - Detailed migration guide
- `SUPABASE_MIGRATION_CHECKLIST.md` - Overall migration status
- `src/app/graphql/types.md` - Supabase GraphQL patterns

