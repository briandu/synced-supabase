# GraphQL Field Naming Migration Guide: Parse → Supabase

This document provides a comprehensive reference for migrating GraphQL queries and mutations from Parse-style nested relationships to Supabase-style relationship fields.

## Overview

**Parse GraphQL** uses camelCase relationship fields (e.g., `orgId { id }`)  
**Supabase pg_graphql** uses:

- **Scalar fields**: snake_case matching the column name (e.g., `org_id` → UUID value)
- **Relationship fields**: singular name without `_id` suffix (e.g., `org { id name }` → full object)

**⚠️ IMPORTANT: Name Inflection Enabled**

Name inflection has been **enabled** on your Supabase project, which means all GraphQL field names are automatically converted from snake_case to camelCase. This allows your frontend code to use camelCase field names like `firstName`, `orgId`, etc.

**See:** `GRAPHQL_CAMELCASE_MIGRATION.md` for details on inflection and frontend compatibility.

## Key Principle

In Supabase, when you have a foreign key column like `org_id uuid references orgs(id)`, pg_graphql automatically exposes:

1. **`orgId`** (with inflection) or **`org_id`** (without inflection) - The scalar UUID field (just the ID value)
2. **`org`** - The relationship field (access to the related `orgs` row)

You can use BOTH:

- `orgId` (or `org_id` without inflection) for filtering, sorting, and when you just need the UUID
- `org { id name }` when you need nested data from the related table

**Note:** With inflection enabled, use camelCase field names (`orgId`, `firstName`) in your queries. Column names in `where` and `order_by` clauses still use snake_case (`org_id`, `first_name`).

---

## Naming Convention Changes

### Common Foreign Key Patterns

| Parse Style               | Supabase Scalar (with inflection)                     | Supabase Relationship   | Use Case                   |
| ------------------------- | ----------------------------------------------------- | ----------------------- | -------------------------- |
| `orgId { id }`            | `orgId` (from `org_id` column)                        | `org { id }`            | Organization references    |
| `locationId { id }`       | `locationId` (from `location_id` column)              | `location { id }`       | Location references        |
| `staffId { id }`          | `staffId` (from `staff_id` column)                    | `staff { id }`          | Staff references           |
| `patientId { id }`        | `patientId` (from `patient_id` column)                | `patient { id }`        | Patient references         |
| `userId { id }`           | `userId` (from `user_id` column)                      | `user { id }`           | User references            |
| `createdBy { id }`        | `createdBy` (from `created_by` column)                | `createdByStaff { id }` | Audit fields               |
| `updatedBy { id }`        | `updatedBy` (from `updated_by` column)                | `updatedByStaff { id }` | Audit fields               |
| `ownershipGroupId { id }` | `ownershipGroupId` (from `ownership_group_id` column) | `ownershipGroup { id }` | Ownership group references |

**Note:** With inflection enabled, all field names are automatically converted to camelCase. Column names in filters still use snake_case.

---

## Parse vs Supabase Pattern Comparison

### Pattern 1: Simple Relationship Access

#### Parse Style

```graphql
query GetPatient {
  patient {
    id
    orgId {
      id
      orgName
    }
  }
}
```

#### Supabase Style

```graphql
query GetPatient {
  patients_by_pk(id: $id) {
    id
    org_id # Scalar UUID (if you just need the ID)
    org {
      # Relationship field (if you need nested data)
      id
      name
    }
  }
}
```

---

### Pattern 2: Filtering by Foreign Key

#### Parse Style

```graphql
query GetPatients($orgId: ID!) {
  patients(where: { orgId: { have: { id: { equalTo: $orgId } } } }) {
    edges {
      node {
        id
        firstName
      }
    }
  }
}
```

#### Supabase Style (with inflection enabled)

```graphql
query GetPatients($orgId: uuid!) {
  patients(where: { org_id: { _eq: $orgId } }) {
    id
    firstName # camelCase (inflection converts from first_name)
    lastName # camelCase (inflection converts from last_name)
    org {
      id
      name
    }
  }
}
```

**Note:** `where` and `order_by` still use snake_case column names (`org_id`, `first_name`), but field selections use camelCase (`orgId`, `firstName`) with inflection enabled.

---

### Pattern 3: Nested Relationships (Multiple Levels)

#### Parse Style

```graphql
query GetStaffLocation {
  staff_Locations {
    edges {
      node {
        staffId {
          id
          orgId {
            id
            orgName
          }
        }
        locationId {
          id
          locationName
        }
      }
    }
  }
}
```

#### Supabase Style

```graphql
query GetStaffLocation {
  staff_locations {
    id
    staff_id
    staff {
      id
      org_id
      org {
        id
        name
      }
    }
    location_id
    location {
      id
      name
    }
  }
}
```

---

### Pattern 4: Audit Fields (created_by / updated_by)

#### Parse Style

```graphql
query GetPatientNotes {
  patient_Notes {
    edges {
      node {
        id
        text
        createdBy {
          id
          firstName
          lastName
        }
      }
    }
  }
}
```

#### Supabase Style

```graphql
query GetPatientNotes {
  patient_notes {
    id
    text
    created_by # Scalar UUID
    created_by_staff {
      # Relationship to staff_members
      id
      first_name
      last_name
    }
  }
}
```

**Note:** In Supabase, `created_by` and `updated_by` typically reference `staff_members(id)`, so the relationship field may be named `created_by_staff` or similar depending on the foreign key constraint.

---

## Common Transformation Patterns

### 1. Query Filtering

**Before (Parse):**

```graphql
where: { orgId: { have: { id: { equalTo: $orgId } } } }
```

**After (Supabase):**

```graphql
where: { org_id: { _eq: $orgId } }
```

### 2. Nested Field Access

**Before (Parse):**

```graphql
orgId {
  id
  orgName
}
```

**After (Supabase):**

```graphql
org {
  id
  name
}
```

### 3. Relay Connection Pattern Removal

**Before (Parse with Relay):**

```graphql
patients {
  edges {
    node {
      id
      orgId {
        id
      }
    }
  }
}
```

**After (Supabase - flat arrays):**

```graphql
patients {
  id
  org {
    id
  }
}
```

### 4. Multiple Relationship Filters

**Before (Parse):**

```graphql
where: {
  orgId: { have: { id: { equalTo: $orgId } } }
  locationId: { have: { id: { equalTo: $locationId } } }
}
```

**After (Supabase):**

```graphql
where: {
  org_id: { _eq: $orgId }
  location_id: { _eq: $locationId }
}
```

---

## Field Name Mappings

### Column Name → GraphQL Field Name Rules

**With name inflection enabled** (current setup), Supabase pg_graphql follows these conventions:

1. **Scalar fields**: Automatically converted to camelCase via inflection

   - Column: `org_id` → GraphQL Field: `orgId` ✅
   - Column: `created_at` → GraphQL Field: `createdAt` ✅
   - Column: `first_name` → GraphQL Field: `firstName` ✅

2. **Relationship fields**: Singular form, removes `_id` suffix

   - Column: `org_id` → Relationship: `org`
   - Column: `location_id` → Relationship: `location`
   - Column: `staff_id` → Relationship: `staff`

3. **Special cases for audit fields**:
   - Column: `created_by` (references `staff_members`) → Scalar: `createdBy`, Relationship: `createdByStaff`
   - Column: `updated_by` (references `staff_members`) → Scalar: `updatedBy`, Relationship: `updatedByStaff`

**Important:** Column names in `where` and `order_by` clauses still use snake_case (`org_id`, `first_name`), but field selections use camelCase (`orgId`, `firstName`).

**See:** `GRAPHQL_CAMELCASE_MIGRATION.md` for complete details on inflection and frontend compatibility.

---

## Complete Migration Checklist

### Files Requiring Updates

This checklist tracks all GraphQL files that need migration:

#### Core Domain Files

- [ ] `src/app/graphql/patients.graphql.js`

  - `orgId` → `org`
  - `patientId` → `patient`
  - `createdBy` → `created_by_staff`

- [ ] `src/app/graphql/staff.graphql.js`

  - `orgId` → `org`
  - `locationId` → `location`
  - `userId` → `user`
  - `staffId` → `staff`

- [ ] `src/app/graphql/locations.graphql.js`

  - `orgId` → `org`
  - `ownershipGroupId` → `ownership_group`
  - `createdBy` → `created_by_staff`

- [ ] `src/app/graphql/organization.graphql.js`

  - `orgId` → `org`
  - Related nested relationships

- [ ] `src/app/graphql/users.graphql.js`
  - `orgId` → `org`
  - `userId` → `user`
  - `staffId` → `staff`

#### Service & Product Files

- [ ] `src/app/graphql/services/services.graphql.js`

  - `orgId` → `org`
  - `locationId` → `location`
  - `staffId` → `staff`
  - `itemId` → `item`
  - `serviceId` → `service`

- [ ] `src/app/graphql/services/org_services.graphql.js`
- [ ] `src/app/graphql/services/location_services.graphql.js`
- [ ] `src/app/graphql/services/ownership_group_services.graphql.js`
- [ ] `src/app/graphql/services/discipline_offerings.graphql.js`

#### Scheduling & Appointments

- [ ] `src/app/graphql/appointment.graphql.js`

  - `patientId` → `patient`
  - `staffId` → `staff`
  - `locationId` → `location`
  - `serviceOfferingId` → `service_offering`

- [ ] `src/app/graphql/availability_block.graphql.js`
- [ ] `src/app/graphql/waitlist.graphql.js`
- [ ] `src/app/graphql/schedule_slots.graphql.js`
- [ ] `src/app/graphql/staff_shift.graphql.js`
- [ ] `src/app/graphql/staff_break.graphql.js`
- [ ] `src/app/graphql/staff_time_off.graphql.js`

#### Billing & Payments

- [ ] `src/app/graphql/invoice.graphql.js`

  - `patientId` → `patient`
  - `orgId` → `org`
  - `locationId` → `location`

- [ ] `src/app/graphql/payment.graphql.js`

  - `patientId` → `patient`
  - `invoiceId` → `invoice`
  - `methodId` → `payment_method`

- [ ] `src/app/graphql/fee.graphql.js`

  - `orgId` → `org`
  - `locationId` → `location`

- [ ] `src/app/graphql/tax.graphql.js`

#### Other Domain Files

- [ ] `src/app/graphql/ownership_groups.graphql.js`
- [ ] `src/app/graphql/disciplines.graphql.js`
- [ ] `src/app/graphql/insurance.graphql.js`
- [ ] `src/app/graphql/invites.graphql.js`
- [ ] `src/app/graphql/charting.graphql.js`
- [ ] `src/app/graphql/task.graphql.js`
- [ ] `src/app/graphql/permissions.graphql.js`
- [ ] `src/app/graphql/booking_portal.graphql.js`
- [ ] `src/app/graphql/patient_staff.graphql.js`
- [ ] `src/app/graphql/operating_hour.graphql.js`
- [ ] `src/app/graphql/location_offerings.graphql.js`
- [ ] `src/app/graphql/room.graphql.js`
- [ ] `src/app/graphql/file_upload.graphql.js`
- [ ] `src/app/graphql/account.graphql.js`
- [ ] `src/app/graphql/auth.graphql.js`

#### Context Files Using GraphQL

- [ ] `src/app/contexts/OrgSetupCompletionContext.js`
  - Contains embedded GraphQL queries with Parse-style relationships

---

## Step-by-Step Migration Process

### Step 1: Identify the Pattern

1. Look for camelCase relationship fields (e.g., `orgId`, `locationId`)
2. Check if they're used for filtering vs. nested data access

### Step 2: Determine the Column Name

1. Check `supabase/full.sql` for the actual column name
2. Example: `org_id uuid not null references public.orgs(id)`

### Step 3: Update the Query

**For filtering/sorting:**

- Keep using scalar field: `org_id` (snake_case)

**For nested data:**

- Change to relationship field: `org { id name }` (singular, no `_id`)

### Step 4: Update Variable Types

- Parse: `$orgId: ID!`
- Supabase: `$orgId: uuid!`

### Step 5: Update Filter Syntax

- Parse: `where: { orgId: { have: { id: { equalTo: $orgId } } } }`
- Supabase: `where: { org_id: { _eq: $orgId } }`

### Step 6: Remove Relay Patterns

- Remove `edges { node { } }` wrappers
- Use flat arrays directly

---

## Real-World Examples

### Example 1: Patients Query

**Before (Parse):**

```graphql
export const GET_PATIENT_BY_ID = gql`
  query GetPatientById($id: ID!) {
    patient(id: $id) {
      id
      orgId {
        id
        orgName
      }
      createdBy {
        id
        firstName
        lastName
      }
    }
  }
`;
```

**After (Supabase):**

```graphql
export const GET_PATIENT_BY_ID_SUPA = gql`
  query GetPatientByIdSupa($id: uuid!) {
    patients_by_pk(id: $id) {
      id
      org_id
      org {
        id
        name
      }
      created_by
      created_by_staff {
        id
        first_name
        last_name
      }
    }
  }
`;
```

---

### Example 2: Staff with Location

**Before (Parse):**

```graphql
export const GET_STAFF_WITH_LOCATION = gql`
  query GetStaffWithLocation($locationId: ID!) {
    staff_Members(where: {
      locationId: { have: { id: { equalTo: $locationId } } }
    }) {
      edges {
        node {
          id
          firstName
          locationId {
            id
            locationName
          }
          orgId {
            id
            orgName
          }
        }
      }
    }
  }
`;
```

**After (Supabase):**

```graphql
export const GET_STAFF_WITH_LOCATION_SUPA = gql`
  query GetStaffWithLocationSupa($locationId: uuid!) {
    staff_members(where: { location_id: { _eq: $locationId } }) {
      id
      first_name
      location_id
      location {
        id
        name
      }
      org_id
      org {
        id
        name
      }
    }
  }
`;
```

---

### Example 3: Complex Nested Query

**Before (Parse):**

```graphql
export const GET_SERVICE_OFFERINGS = gql`
  query GetServiceOfferings($orgId: ID!) {
    service_Offerings(
      where: { orgId: { have: { id: { equalTo: $orgId } } } }
    ) {
      edges {
        node {
          id
          itemId {
            id
            itemName
          }
          locationId {
            id
            locationName
          }
          orgId {
            id
            orgName
          }
          ownershipGroupId {
            id
            ogName
          }
        }
      }
    }
  }
`;
```

**After (Supabase):**

```graphql
export const GET_SERVICE_OFFERINGS_SUPA = gql`
  query GetServiceOfferingsSupa($orgId: uuid!) {
    service_offerings(where: { org_id: { _eq: $orgId } }) {
      id
      item_id
      item {
        id
        name
      }
      location_id
      location {
        id
        name
      }
      org_id
      org {
        id
        name
      }
      ownership_group_id
      ownership_group {
        id
        name
      }
    }
  }
`;
```

---

## Common Pitfalls & Solutions

### Pitfall 1: Mixing Scalar and Relationship Fields

❌ **Incorrect:**

```graphql
patients {
  org_id
  orgId {  # This doesn't exist in Supabase
    id
  }
}
```

✅ **Correct:**

```graphql
patients {
  org_id      # Scalar UUID
  org {       # Relationship object
    id
    name
  }
}
```

---

### Pitfall 2: Using Wrong Filter Syntax

❌ **Incorrect (Parse syntax):**

```graphql
where: { orgId: { have: { id: { equalTo: $orgId } } } }
```

✅ **Correct (Supabase syntax):**

```graphql
where: { org_id: { _eq: $orgId } }
```

---

### Pitfall 3: Forgetting to Update Variable Types

❌ **Incorrect:**

```graphql
query GetPatients($orgId: ID!) {  # Parse ID type
  patients(where: { org_id: { _eq: $orgId } }) {
    # ...
  }
}
```

✅ **Correct:**

```graphql
query GetPatients($orgId: uuid!) {  # Supabase UUID type
  patients(where: { org_id: { _eq: $orgId } }) {
    # ...
  }
}
```

---

## Verification Steps

After migrating a query, verify:

1. ✅ **Syntax**: Query parses without errors
2. ✅ **Field names**: All relationship fields use singular form (no `_id` suffix)
3. ✅ **Filter syntax**: Uses Supabase filter operators (`_eq`, `_in`, etc.)
4. ✅ **Variable types**: Uses `uuid!` instead of `ID!`
5. ✅ **No Relay patterns**: Removed `edges { node { } }` wrappers
6. ✅ **Response structure**: Code consuming the query handles flat arrays

---

## Testing Strategy

1. **Unit Test Updates**: Update GraphQL query tests to use Supabase schema
2. **Integration Tests**: Verify queries work with Supabase GraphQL endpoint
3. **Manual Testing**: Test queries in GraphQL playground/explorer
4. **Component Testing**: Ensure UI components handle new response shapes

---

## Related Documentation

- `GRAPHQL_CAMELCASE_MIGRATION.md` - **CRITICAL:** Frontend compatibility with camelCase via name inflection
- `docs/migrations/SUPABASE_MIGRATION_CHECKLIST.md` - Overall migration checklist
- `src/app/graphql/types.md` - Supabase GraphQL patterns
- `supabase/full.sql` - Database schema reference

---

## Quick Reference Card

### Filtering Patterns

| Parse                                           | Supabase                              |
| ----------------------------------------------- | ------------------------------------- |
| `{ orgId: { have: { id: { equalTo: $id } } } }` | `{ org_id: { _eq: $id } }`            |
| `{ orgId: { have: { id: { in: $ids } } } }`     | `{ org_id: { _in: $ids } }`           |
| `{ locationId: { exists: false } }`             | `{ location_id: { _is_null: true } }` |

### Field Access Patterns

| Parse                            | Supabase (with inflection)                                     |
| -------------------------------- | -------------------------------------------------------------- |
| `orgId { id orgName }`           | `orgId` (scalar) or `org { id name }` (relationship)           |
| `locationId { id locationName }` | `locationId` (scalar) or `location { id name }` (relationship) |
| `staffId { id firstName }`       | `staffId` (scalar) or `staff { id firstName }` (relationship)  |

### Type Patterns

| Parse         | Supabase        |
| ------------- | --------------- |
| `$id: ID!`    | `$id: uuid!`    |
| `$ids: [ID!]` | `$ids: [uuid!]` |

---

**Last Updated:** 2025-01-XX  
**Status:** Migration in progress  
**Next Review:** After Phase 4 completion (Client Data Layer migration)
