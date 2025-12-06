/**
 * Database Setup and Teardown Helpers for Testing
 */

require('dotenv').config();
const { createClient } = require('@supabase/supabase-js');

const supabaseUrl = process.env.SUPABASE_URL || 'http://localhost:54321';
const supabaseKey = process.env.SUPABASE_SERVICE_ROLE_KEY;

if (!supabaseKey) {
  throw new Error('SUPABASE_SERVICE_ROLE_KEY environment variable is required for testing');
}

const supabase = createClient(supabaseUrl, supabaseKey);

/**
 * Create a test user in auth.users
 */
async function createTestUser(email = 'test@example.com', id = null) {
  const { data, error } = await supabase.auth.admin.createUser({
    email,
    password: 'testpassword123',
    email_confirm: true,
    user_metadata: {
      full_name: 'Test User',
    },
  });

  if (error) throw error;
  
  // Also create profile
  await supabase.from('profiles').insert({
    id: data.user.id,
    email: email,
    full_name: 'Test User',
  });

  return data.user;
}

/**
 * Create Owner role for an organization
 */
async function createOwnerRole(orgId) {
  const { data, error} = await supabase
    .from('roles')
    .insert({
      org_id: orgId,
      name: 'Owner',
      description: 'Organization owner with full permissions',
    })
    .select()
    .single();

  if (error) throw error;
  return data;
}

/**
 * Clean up all test data for a specific user
 */
async function cleanupTestUser(userId) {
  // Delete in reverse order of dependencies
  await supabase.from('staff_permissions').delete().eq('created_by', userId);
  await supabase.from('operating_hours').delete().eq('created_by', userId);
  await supabase.from('staff_locations').delete().eq('created_by', userId);
  await supabase.from('staff_members').delete().eq('created_by', userId);
  await supabase.from('locations').delete().eq('created_by', userId);
  await supabase.from('org_memberships').delete().eq('user_id', userId);
  await supabase.from('ownership_groups').delete().eq('created_by', userId);
  await supabase.from('orgs').delete().eq('created_by', userId);
  await supabase.from('profiles').delete().eq('id', userId);
  
  // Delete auth user
  await supabase.auth.admin.deleteUser(userId);
}

/**
 * Clean up all test data
 */
async function cleanupAllTestData() {
  // Delete all test records (where email contains 'test')
  const { data: testProfiles } = await supabase
    .from('profiles')
    .select('id')
    .ilike('email', '%test%');

  if (testProfiles) {
    for (const profile of testProfiles) {
      await cleanupTestUser(profile.id);
    }
  }
}

/**
 * Get Supabase client for testing
 */
function getSupabaseClient() {
  return supabase;
}

module.exports = {
  createTestUser,
  createOwnerRole,
  cleanupTestUser,
  cleanupAllTestData,
  getSupabaseClient,
};
