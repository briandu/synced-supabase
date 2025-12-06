# Function Testing Guide

This guide explains how to test PostgreSQL functions in the Supabase database.

## Testing Stack

We use **Jest** + **@supabase/supabase-js** + **pg** for testing database functions.

### Why This Stack?

- **Jest**: Industry standard, excellent async support, great test runner
- **@supabase/supabase-js**: Native Supabase client for easy RPC calls
- **pg**: Direct PostgreSQL access for advanced testing and setup/teardown

### Alternative Considered

**pgTAP** (PostgreSQL Testing Anywhere Protocol):
- Pros: Native PostgreSQL testing, very popular in PostgreSQL community
- Cons: Requires PostgreSQL extension, separate test language (SQL), harder CI/CD integration

## Project Structure

```
tests/
├── functions/
│   ├── complete_onboarding_transaction.test.js
│   └── helpers/
│       ├── db-setup.js          # Database setup/teardown
│       ├── test-data.js          # Test data factories
│       └── assertions.js         # Custom assertions
├── integration/
│   └── onboarding-flow.test.js   # End-to-end flow tests
├── jest.config.js
├── package.json
└── .env.example
```

## Setup

### 1. Install Dependencies

```bash
cd tests
npm install
```

### 2. Configure Environment

Copy `.env.example` to `.env` and configure:

```bash
cp .env.example .env
```

Edit `.env`:
```env
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_SERVICE_ROLE_KEY=your-service-role-key

# For local development
# SUPABASE_URL=http://localhost:54321
# SUPABASE_SERVICE_ROLE_KEY=your-local-service-role-key
```

### 3. Run Tests

```bash
# Run all tests
npm test

# Run specific test file
npm test -- complete_onboarding_transaction.test.js

# Run tests in watch mode
npm run test:watch

# Run tests with coverage
npm run test:coverage
```

## Writing Tests

### Test Structure

```javascript
const { createTestUser, cleanupTestUser, getSupabaseClient } = require('./helpers/db-setup');

describe('my_function', () => {
  let supabase;
  let testUser;

  beforeAll(async () => {
    supabase = getSupabaseClient();
  });

  beforeEach(async () => {
    // Create fresh test data for each test
    testUser = await createTestUser(`test-${Date.now()}@example.com`);
  });

  afterEach(async () => {
    // Clean up test data after each test
    if (testUser) {
      await cleanupTestUser(testUser.id);
    }
  });

  test('should do something', async () => {
    const { data, error } = await supabase.rpc('my_function', {
      param1: 'value1',
      param2: 'value2',
    });

    expect(error).toBeNull();
    expect(data).toHaveProperty('success', true);
  });
});
```

### Helper Functions

#### `createTestUser(email)`

Creates a test user in `auth.users` and `profiles` table.

```javascript
const testUser = await createTestUser('test@example.com');
// testUser.id is the UUID
```

#### `createOwnerRole(orgId)`

Creates an "Owner" role for an organization.

```javascript
const role = await createOwnerRole(orgId);
```

#### `cleanupTestUser(userId)`

Removes all data associated with a test user (in dependency order).

```javascript
await cleanupTestUser(testUser.id);
```

#### `getSupabaseClient()`

Returns a configured Supabase client with service role privileges.

```javascript
const supabase = getSupabaseClient();
```

### Test Categories

#### 1. Success Cases

Test that the function works correctly with valid inputs:

```javascript
describe('Success Cases', () => {
  test('should work with required fields only', async () => {
    const { data, error } = await supabase.rpc('my_function', {
      required_param: 'value',
    });

    expect(error).toBeNull();
    expect(data).toBeTruthy();
  });

  test('should work with optional fields', async () => {
    const { data, error } = await supabase.rpc('my_function', {
      required_param: 'value',
      optional_param: 'optional value',
    });

    expect(error).toBeNull();
    expect(data).toBeTruthy();
  });
});
```

#### 2. Validation Errors

Test that the function validates inputs correctly:

```javascript
describe('Validation Errors', () => {
  test('should fail when required param is missing', async () => {
    const { data, error } = await supabase.rpc('my_function', {
      required_param: null,
    });

    expect(error).toBeTruthy();
    expect(error.message).toContain('required');
  });

  test('should fail when duplicate value exists', async () => {
    // Create first record
    await supabase.rpc('my_function', {
      unique_value: 'test',
    });

    // Try to create duplicate
    const { data, error } = await supabase.rpc('my_function', {
      unique_value: 'test',
    });

    expect(error).toBeTruthy();
    expect(error.message).toContain('already exists');
  });
});
```

#### 3. Transaction Rollback

Test that transactions rollback on errors:

```javascript
describe('Transaction Rollback', () => {
  test('should rollback all changes on error', async () => {
    const { data, error } = await supabase.rpc('my_function', {
      param_that_will_fail: 'invalid',
    });

    expect(error).toBeTruthy();

    // Verify no records were created
    const { data: records } = await supabase
      .from('my_table')
      .select('*')
      .eq('created_by', testUser.id);

    expect(records).toHaveLength(0);
  });
});
```

#### 4. Data Integrity

Test that relationships and data are created correctly:

```javascript
test('should create related records correctly', async () => {
  const { data, error } = await supabase.rpc('my_function', {
    param: 'value',
  });

  expect(error).toBeNull();

  // Verify parent record
  const { data: parent } = await supabase
    .from('parent_table')
    .select('*')
    .eq('id', data.parent_id)
    .single();

  expect(parent).toBeTruthy();

  // Verify child records
  const { data: children } = await supabase
    .from('child_table')
    .select('*')
    .eq('parent_id', data.parent_id);

  expect(children).toHaveLength(3);
});
```

## Best Practices

### 1. Isolation

Each test should be independent and not rely on other tests:

```javascript
beforeEach(async () => {
  // Create fresh test data
  testUser = await createTestUser(`test-${Date.now()}@example.com`);
});

afterEach(async () => {
  // Clean up after each test
  await cleanupTestUser(testUser.id);
});
```

### 2. Unique Test Data

Use timestamps or random values to avoid conflicts:

```javascript
const subdomain = `test-clinic-${Date.now()}`;
const email = `test-${Math.random()}@example.com`;
```

### 3. Test Both Success and Failure

Always test both happy path and error cases:

```javascript
// Success case
test('should succeed with valid data', async () => {
  const { data, error } = await supabase.rpc('my_function', validParams);
  expect(error).toBeNull();
});

// Failure case
test('should fail with invalid data', async () => {
  const { data, error } = await supabase.rpc('my_function', invalidParams);
  expect(error).toBeTruthy();
});
```

### 4. Clear Test Names

Use descriptive test names that explain what is being tested:

```javascript
// Good
test('should create org with subdomain and logo URL', async () => {});

// Bad
test('test1', async () => {});
```

### 5. Verify Database State

Don't just check the return value - verify the database state:

```javascript
test('should create organization', async () => {
  const { data, error } = await supabase.rpc('create_org', params);

  expect(error).toBeNull();

  // Verify org exists in database
  const { data: org } = await supabase
    .from('orgs')
    .select('*')
    .eq('id', data.org_id)
    .single();

  expect(org.name).toBe(params.org_name);
});
```

## Troubleshooting

### Tests Failing Due to RLS

If tests fail due to Row Level Security policies, use the service role key (not anon key) in your `.env`:

```env
SUPABASE_SERVICE_ROLE_KEY=eyJhb...  # Service role bypasses RLS
```

### Cleanup Issues

If tests leave orphaned data, improve cleanup order:

```javascript
async function cleanupTestUser(userId) {
  // Delete in reverse order of dependencies
  await supabase.from('child_table').delete().eq('user_id', userId);
  await su
