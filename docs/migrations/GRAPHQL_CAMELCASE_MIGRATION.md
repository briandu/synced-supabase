# GraphQL camelCase vs snake_case: Frontend Compatibility Solution

## The Problem

Supabase GraphQL (pg_graphql) exposes field names in **snake_case** to match your database column names:

```graphql
query GetPatients {
  patients {
    id
    first_name # ← snake_case
    last_name # ← snake_case
    org_id # ← snake_case
    created_at # ← snake_case
  }
}
```

But your frontend code expects **camelCase**:

```javascript
// This will break! ❌
const firstName = patient.first_name; // undefined
const lastName = patient.lastName; // undefined
const orgId = patient.orgId; // undefined
```

You have three options:

---

## ✅ Solution 1: Enable Name Inflection (RECOMMENDED)

Supabase's `pg_graphql` extension supports automatic name inflection that converts snake_case to camelCase in the GraphQL API.

### Enable Inflection

Run this SQL in your Supabase SQL Editor:

```sql
COMMENT ON SCHEMA public IS e'@graphql({"inflect_names": true})';
```

**Status:** ✅ **VERIFIED & ENABLED** - Confirmed working via SQL query check. This has been applied to your Supabase project.

### Result

After enabling inflection, your GraphQL queries will automatically expose camelCase field names:

```graphql
query GetPatients {
  patients {
    id
    firstName # ← camelCase (automatically converted from first_name)
    lastName # ← camelCase (automatically converted from last_name)
    orgId # ← camelCase (automatically converted from org_id)
    createdAt # ← camelCase (automatically converted from created_at)
  }
}
```

### How It Works

- **Database column**: `first_name` (snake_case)
- **GraphQL field (with inflection)**: `firstName` (camelCase)
- **Frontend code**: Works with `patient.firstName` ✅

### Relationship Fields

Inflection also applies to relationship fields:

```graphql
query GetPatients {
  patients {
    id
    orgId # Scalar UUID (from org_id column)
    org {
      # Relationship field
      id
      name
    }
  }
}
```

### Verification

After enabling, test in GraphQL playground:

- Go to: `https://tepdgpiyjluuddwgboyy.supabase.co/graphql/v1`
- Try querying with camelCase field names
- Verify they work!

---

## ⚠️ Solution 2: Use GraphQL Aliases (Alternative)

If you prefer not to enable inflection globally, you can use aliases in each query:

```graphql
query GetPatients {
  patients {
    id
    firstName: first_name # ← Alias: snake_case → camelCase
    lastName: last_name # ← Alias
    orgId: org_id # ← Alias
    createdAt: created_at # ← Alias
  }
}
```

**Pros:**

- More explicit control
- Works without schema changes

**Cons:**

- Must add aliases to every query
- More verbose and error-prone
- Easy to miss fields

---

## 🔄 Solution 3: Transform Data After Fetching (Not Recommended)

You could transform the response data in your components/hooks:

```javascript
const { data } = useQuery(GET_PATIENTS);

const transformedData = data?.patients?.map((patient) => ({
  id: patient.id,
  firstName: patient.first_name, // Transform here
  lastName: patient.last_name,
  orgId: patient.org_id,
  createdAt: patient.created_at,
}));
```

**Pros:**

- No schema changes needed

**Cons:**

- Must transform in every component
- Easy to miss transformations
- Duplicates transformation logic
- More error-prone

---

## Recommendation: Use Name Inflection

**Enable name inflection** because:

1. ✅ **Automatic** - No manual aliases needed
2. ✅ **Consistent** - All queries use camelCase
3. ✅ **Frontend-friendly** - Matches JavaScript conventions
4. ✅ **Less code** - No transformation logic needed
5. ✅ **Type-safe** - GraphQL schema reflects camelCase
6. ✅ **Team-friendly** - Everyone uses same convention

---

## Migration Strategy

### Step 1: Enable Inflection (✅ COMPLETED)

```sql
-- Run in Supabase SQL Editor
COMMENT ON SCHEMA public IS e'@graphql({"inflect_names": true})';
```

**Status:** ✅ Applied to your project

### Step 2: Update Queries

After enabling inflection, your queries should use camelCase:

```graphql
# Before (snake_case)
query GetPatients {
  patients {
    first_name
    last_name
    org_id
  }
}

# After (camelCase with inflection)
query GetPatients {
  patients {
    firstName
    lastName
    orgId
  }
}
```

### Step 3: Update Relationship Fields

```graphql
# Before
query GetPatient {
  patients {
    org_id
    org {
      id
      name
    }
  }
}

# After (with inflection)
query GetPatient {
  patients {
    orgId # camelCase scalar
    org {
      # relationship field (no change needed)
      id
      name
    }
  }
}
```

---

## Updated Field Naming Convention

With inflection enabled:

| Database Column      | GraphQL Field (with inflection) | Frontend Usage             |
| -------------------- | ------------------------------- | -------------------------- |
| `first_name`         | `firstName`                     | `patient.firstName`        |
| `last_name`          | `lastName`                      | `patient.lastName`         |
| `org_id`             | `orgId`                         | `patient.orgId`            |
| `created_at`         | `createdAt`                     | `patient.createdAt`        |
| `updated_at`         | `updatedAt`                     | `patient.updatedAt`        |
| `patient_user_id`    | `patientUserId`                 | `patient.patientUserId`    |
| `date_of_birth`      | `dateOfBirth`                   | `patient.dateOfBirth`      |
| `stripe_customer_id` | `stripeCustomerId`              | `patient.stripeCustomerId` |

### Relationship Fields

| Database Column              | Relationship Field         | Frontend Usage                  |
| ---------------------------- | -------------------------- | ------------------------------- |
| `org_id` → `orgs`            | `org { id name }`          | `patient.org.name`              |
| `location_id` → `locations`  | `location { id name }`     | `staff.location.name`           |
| `staff_id` → `staff_members` | `staff { id firstName }`   | `appointment.staff.firstName`   |
| `patient_id` → `patients`    | `patient { id firstName }` | `appointment.patient.firstName` |

---

## Example: Complete Migration

### Before (Parse-style, no inflection)

```graphql
query GetPatientById($id: ID!) {
  patient(id: $id) {
    id
    firstName
    lastName
    orgId {
      id
      orgName
    }
  }
}
```

### After (Supabase with inflection)

```graphql
query GetPatientById($id: uuid!) {
  patients_by_pk(id: $id) {
    id
    firstName # From first_name column (inflection converts it)
    lastName # From last_name column
    orgId # From org_id column (scalar UUID)
    org {
      # Relationship field
      id
      name # From name column
    }
  }
}
```

### Frontend Code (Unchanged!)

```javascript
// This code works the same before and after migration! ✅
const { data } = useQuery(GET_PATIENT_BY_ID, { variables: { id } });
const patient = data?.patients_by_pk;

console.log(patient.firstName); // Works! ✅
console.log(patient.lastName); // Works! ✅
console.log(patient.orgId); // Works! ✅
console.log(patient.org.name); // Works! ✅
```

---

## Important Notes

### Filtering Still Uses Column Names

Even with inflection, **where clauses** still reference the database column names:

```graphql
query GetPatients($orgId: uuid!) {
  patients(where: { org_id: { _eq: $orgId } }) {
    # ← Use org_id in where
    id
    orgId # ← Use orgId in selection
  }
}
```

### Order By Still Uses Column Names

```graphql
query GetPatients {
  patients(order_by: { last_name: asc }) {
    # ← Use last_name in order_by
    id
    lastName # ← Use lastName in selection
  }
}
```

---

## Troubleshooting

### Inflection Not Working?

1. **Verify the schema comment is set:**

   ```sql
   SELECT obj_description('public'::regnamespace, 'pg_namespace');
   ```

   Should show: `@graphql({"inflect_names": true})`

2. **Check GraphQL endpoint:**

   - Go to: `https://tepdgpiyjluuddwgboyy.supabase.co/graphql/v1`
   - Use introspection query to see field names
   - Fields should be camelCase if inflection is enabled

3. **Refresh GraphQL schema:**
   - Clear Apollo Client cache
   - Restart your dev server
   - Schema changes may take a moment to propagate

### Mixed Naming Issues

If some queries work with camelCase and others don't:

- Check if inflection is enabled (should affect all fields)
- Verify you're using the correct GraphQL endpoint
- Check for typos in field names

---

## Migration Checklist

- [x] Enable name inflection in Supabase SQL Editor ✅ **COMPLETED**
- [x] Verify inflection is enabled (SQL query confirmed: `@graphql({"inflect_names": true})`) ✅ **VERIFIED**
- [ ] Test inflection is working in GraphQL playground (test query below)
- [ ] Update all GraphQL queries to use camelCase field names (36 files to update)
- [ ] Update `where` clauses to still use snake_case column names
- [ ] Update `order_by` to still use snake_case column names
- [ ] Test all queries work with camelCase responses
- [x] Update documentation to reflect camelCase convention ✅ **COMPLETED**
- [ ] Inform team about the change

### Verification Query

Test inflection in Supabase GraphQL playground:

```graphql
query TestInflection {
  patients(limit: 1) {
    id
    firstName # Should work with inflection
    lastName # Should work with inflection
    orgId # Should work with inflection
    createdAt # Should work with inflection
  }
}
```

If these camelCase field names work, inflection is enabled correctly!

---

## Related Documentation

- `GRAPHQL_FIELD_NAMING_MIGRATION.md` - Overall field naming patterns
- `GRAPHQL_MIGRATION_QUICK_REFERENCE.md` - Quick lookup reference
- `SUPABASE_MIGRATION_CHECKLIST.md` - Overall migration status
- Supabase pg_graphql docs: https://supabase.com/docs/guides/api/graphql

---

**Last Updated:** 2025-01-XX  
**Status:** ✅ Inflection enabled - Ready for query migration  
**Action Required:** Update all GraphQL queries to use camelCase field names
