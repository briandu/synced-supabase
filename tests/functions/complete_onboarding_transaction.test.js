const { createTestUser, cleanupTestUser, getSupabaseClient } = require('./helpers/db-setup');

describe('complete_onboarding_transaction', () => {
  let supabase;
  let testUser;

  beforeAll(async () => {
    supabase = getSupabaseClient();
  });

  beforeEach(async () => {
    testUser = await createTestUser('test-' + Date.now() + '@example.com');
  });

  afterEach(async () => {
    if (testUser) {
      await cleanupTestUser(testUser.id);
    }
  });

  test('should create organization successfully', async () => {
    const { data, error } = await supabase.rpc('complete_onboarding_transaction', {
      p_user_id: testUser.id,
      p_org_name: 'Test Clinic',
      p_location_name: 'Main Location',
      p_staff_first_name: 'John',
      p_staff_last_name: 'Doe',
      p_staff_email: testUser.email,
      p_org_subdomain: 'test-' + Date.now(),
    });

    expect(error).toBeNull();
    expect(data).toHaveProperty('success', true);
  });
});
