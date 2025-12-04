# Running Guide: Supabase-Refactor Branch

This guide explains how to set up and run the application on the `Supabase-Refactor` branch, which is dedicated to migrating from Parse/Firebase to Supabase.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Environment Setup](#environment-setup)
- [Database Setup](#database-setup)
- [Running the Application](#running-the-application)
- [Feature Flags](#feature-flags)
- [Troubleshooting](#troubleshooting)
- [Quick Reference](#quick-reference)

---

## Prerequisites

### Required Software

1. **Node.js** (v18 or higher)

   - Check version: `node --version`
   - Install: [nodejs.org](https://nodejs.org/)

2. **npm** or **yarn** package manager

   - Check version: `npm --version`

3. **Supabase CLI** (for database migrations)

   - Install: `npm install -g supabase` or use `npx supabase@latest`
   - Verify: `npx supabase --version`

4. **Git** (for cloning and branch management)
   - Check version: `git --version`

### Required Accounts & Access

1. **Supabase Project Access**

   - Project URL: `https://tepdgpiyjluuddwgboyy.supabase.co`
   - Project Reference: `tepdgpiyjluuddwgboyy`
   - Dashboard: https://supabase.com/dashboard/project/tepdgpiyjluuddwgboyy
   - You need collaborator access to the Supabase project

2. **Database Password**
   - Located in: Supabase Dashboard → Settings → Database → Database Password
   - You'll need this for linking the CLI and applying migrations

---

## Environment Setup

### Step 1: Clone and Checkout Branch

```bash
# If you haven't cloned yet
git clone <repository-url>
cd synced-admin-portal

# Checkout the Supabase-Refactor branch
git checkout Supabase-Refactor
git pull origin Supabase-Refactor
```

### Step 2: Install Dependencies

```bash
npm install
```

**Important Notes:**

- This will install all dependencies including Supabase packages
- You may see deprecation warnings for `@supabase/auth-helpers-nextjs` - this is expected and can be addressed later (see Troubleshooting section)
- If you encounter any errors, try deleting `node_modules` and `package-lock.json`, then run `npm install` again

### Step 3: Set Up Environment Variables

Create a `.env.local` file in the project root (or update existing `.env` file) with the following required variables:

#### Required Supabase Variables

```env
# Supabase Configuration (Required)
NEXT_PUBLIC_SUPABASE_URL=https://tepdgpiyjluuddwgboyy.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=your-anon-key-here
SUPABASE_SERVICE_ROLE_KEY=your-service-role-key-here

# Supabase Project Reference (for CLI)
SUPABASE_PROJECT_REF=tepdgpiyjluuddwgboyy

# Database Connection (for migrations/scripts)
SUPABASE_DB_HOST=aws-0-[REGION].pooler.supabase.com
SUPABASE_DB_PORT=6543
SUPABASE_DB_NAME=postgres
SUPABASE_DB_USER=postgres.tepdgpiyjluuddwgboyy
SUPABASE_DB_PASSWORD=your-database-password
```

#### Feature Flags (Enable Supabase Features)

```env
# Enable Supabase features (set to 'true' to use Supabase instead of Parse)
NEXT_PUBLIC_SUPABASE_FEATURE_AUTH=true
NEXT_PUBLIC_SUPABASE_FEATURE_APPOINTMENTS=true
NEXT_PUBLIC_SUPABASE_FEATURE_BILLING=true
NEXT_PUBLIC_SUPABASE_FEATURE_STORAGE=true
NEXT_PUBLIC_SUPABASE_FEATURE_REALTIME=true

# Server-side flags (optional, defaults to true if not set)
SUPABASE_FEATURE_AUTH=true
SUPABASE_FEATURE_APPOINTMENTS=true
SUPABASE_FEATURE_BILLING=true
SUPABASE_FEATURE_STORAGE=true
SUPABASE_FEATURE_REALTIME=true
```

#### Optional: Stripe Configuration (if testing payments)

```env
# Stripe (if you need payment functionality)
STRIPE_SECRET_KEY_TEST=sk_test_...
NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY_TEST=pk_test_...
STRIPE_WEBHOOK_SECRET_TEST=whsec_...
```

#### Optional: AWS Services (if testing notifications)

```env
# AWS SES for email notifications
AWS_ACCESS_KEY_ID=your-access-key
AWS_SECRET_ACCESS_KEY=your-secret-key
AWS_REGION=us-east-1

# AWS SNS for SMS notifications
AWS_SNS_REGION=us-east-1
```

### Where to Find Supabase Keys

1. Go to: https://supabase.com/dashboard/project/tepdgpiyjluuddwgboyy
2. Navigate to: **Settings** → **API**
3. Copy:
   - **Project URL** → `NEXT_PUBLIC_SUPABASE_URL`
   - **anon/public key** → `NEXT_PUBLIC_SUPABASE_ANON_KEY`
   - **service_role key** → `SUPABASE_SERVICE_ROLE_KEY` (⚠️ Keep secret!)

### Where to Find Database Password and Host

To find your database password and connection details:

> 📖 **Quick Reference:** For step-by-step instructions with screenshots, see: [`FIND_DATABASE_CREDENTIALS.md`](./FIND_DATABASE_CREDENTIALS.md)

#### Quick Steps

1. Go to: https://supabase.com/dashboard/project/tepdgpiyjluuddwgboyy
2. Navigate to: **Settings** → **Database**
3. For password: Scroll to **Database Password** section (click eye icon to reveal, or reset if needed)
4. For host/connection: Scroll to **Connection String** section → **Connection Pooling** tab → Copy the connection string

#### Extracting Values from Connection String

The connection string looks like:

```
postgresql://postgres.tepdgpiyjluuddwgboyy:[PASSWORD]@aws-0-[REGION].pooler.supabase.com:6543/postgres?pgbouncer=true
```

Extract these values:

- **Host**: `aws-0-[REGION].pooler.supabase.com` (replace `[REGION]` with your actual region)
- **Port**: `6543` (for connection pooling) or `5432` (for direct connection)
- **Database Name**: `postgres`
- **User**: `postgres.tepdgpiyjluuddwgboyy`
- **Password**: Get from **Database Password** section (or extract from connection string)

**Example:**
If your connection string is:

```
postgresql://postgres.tepdgpiyjluuddwgboyy:MyPassword123@aws-0-us-east-1.pooler.supabase.com:6543/postgres?pgbouncer=true
```

Then your environment variables would be:

```env
SUPABASE_DB_HOST=aws-0-us-east-1.pooler.supabase.com
SUPABASE_DB_PORT=6543
SUPABASE_DB_NAME=postgres
SUPABASE_DB_USER=postgres.tepdgpiyjluuddwgboyy
SUPABASE_DB_PASSWORD=MyPassword123
```

**Note:** The database password is different from your Supabase account password. It's specifically for database connections.

For detailed instructions, troubleshooting, and alternative connection methods, see: [`FIND_DATABASE_CREDENTIALS.md`](./FIND_DATABASE_CREDENTIALS.md)

---

## Database Setup

### Step 1: Authenticate with Supabase CLI

```bash
npx supabase login
```

This will open a browser window for authentication.

### Step 2: Link Your Local Project to Supabase

```bash
npx supabase link --project-ref tepdgpiyjluuddwgboyy
```

You'll be prompted for your database password. Find it in:

- Supabase Dashboard → Settings → Database → Database Password

### Step 3: Set Up Database Migrations Repository

The Supabase migrations are now in a separate repository. Clone it first:

```bash
# Clone the Supabase migrations repository
git clone <supabase-repo-url>
cd synced-supabase

# Authenticate and link (if not already done)
npx supabase login
npx supabase link --project-ref tepdgpiyjluuddwgboyy
```

### Step 4: Apply Database Migrations

All migrations are in the `migrations/` directory of the Supabase repository. Apply them all at once:

```bash
npx supabase db push
```

This will:

- Check which migrations have already been applied
- Apply only new/pending migrations in chronological order
- Show you the status of each migration

### Step 5: Verify Migrations

Check which migrations have been applied:

```bash
npx supabase migration list
```

### Alternative: Apply Migrations via Dashboard

If the CLI doesn't work, you can apply migrations manually:

1. Go to: https://supabase.com/dashboard/project/tepdgpiyjluuddwgboyy
2. Navigate to: **SQL Editor**
3. Copy and paste the contents of each migration file (in chronological order)
4. Run each SQL script

**Migration Files (in order):**

- `20250101000000_initial_schema.sql` - Base schema
- `20251128120000_next_batch.sql` - Additional tables
- `20251128124500_apply_pending.sql` - Pending changes
- `20251128160000_chat_realtime.sql` - Chat and realtime setup
- ... (see `migrations/` directory in the Supabase repository for complete list)

For detailed migration instructions, see: [`docs/migrations/APPLY_MIGRATIONS_GUIDE.md`](./APPLY_MIGRATIONS_GUIDE.md)

---

## Running the Application

### Development Server

Start the Next.js development server:

```bash
npm run dev
```

Or with Turbo for faster builds:

```bash
npm run fast
```

The application will be available at:

- **Local URL**: http://localhost:3000

### Verify Supabase Connection

1. Open http://localhost:3000 in your browser
2. Open browser DevTools (F12) → Console
3. Check for any Supabase connection errors
4. Try logging in (if auth is set up)

### Production Build (Testing)

```bash
# Build the application
npm run build

# Start production server
npm start
```

---

## Feature Flags

The application uses feature flags to toggle between Parse/Firebase and Supabase backends. This allows gradual migration and easy rollback.

### Enable/Disable Features

Set environment variables to control which features use Supabase:

```env
# Enable all Supabase features
NEXT_PUBLIC_SUPABASE_FEATURE_AUTH=true
NEXT_PUBLIC_SUPABASE_FEATURE_APPOINTMENTS=true
NEXT_PUBLIC_SUPABASE_FEATURE_BILLING=true
NEXT_PUBLIC_SUPABASE_FEATURE_STORAGE=true
NEXT_PUBLIC_SUPABASE_FEATURE_REALTIME=true
```

### Check Feature Flag Status

You can check which features are enabled in the browser console:

```javascript
// In browser console
localStorage.getItem('featureFlags');
```

Or check the source code in: `src/lib/featureFlags.js`

### Current Migration Status

According to the migration checklist, the following features are complete:

- ✅ **Auth** - Fully migrated to Supabase
- ✅ **GraphQL Client** - Using Supabase GraphQL endpoint
- ✅ **Storage** - Using Supabase Storage buckets
- ✅ **Chat/Realtime** - Using Supabase Realtime
- ✅ **API Routes** - Most routes migrated to Supabase
- ✅ **Stripe Integration** - Backed by Supabase tables
- ✅ **Notifications** - AWS SES/SNS integration ready

See [`docs/migrations/SUPABASE_MIGRATION_CHECKLIST.md`](./SUPABASE_MIGRATION_CHECKLIST.md) for detailed status.

---

## Troubleshooting

### Common Issues

#### 1. Module Not Found Errors

**Error:** `Module not found: Can't resolve '@supabase/auth-helpers-nextjs'` or similar

**Solution:**

- Run `npm install` to install all dependencies
- If the error persists, try:

  ```bash
  # Delete node_modules and lock file
  rm -rf node_modules package-lock.json

  # Reinstall dependencies
  npm install
  ```

- **Note:** `@supabase/auth-helpers-nextjs` is deprecated. Supabase recommends migrating to `@supabase/ssr` for Next.js 15+. The current setup still works, but consider migrating in the future.

#### 2. "Supabase URL or anon key is missing"

**Error:** `Error: Supabase URL or anon key is missing.`

**Solution:**

- Verify `.env.local` exists and contains `NEXT_PUBLIC_SUPABASE_URL` and `NEXT_PUBLIC_SUPABASE_ANON_KEY`
- Restart your dev server after adding env variables
- Check that variable names are correct (no typos)

#### 3. Database Connection Errors

**Error:** `connection refused` or `authentication failed`

**Solutions:**

- Verify your database password is correct
- Check if your IP is whitelisted in Supabase Dashboard → Settings → Database → Connection Pooling → Allowed IPs
- Try using the connection pooler URL instead of direct connection
- Verify `SUPABASE_DB_*` environment variables are set correctly

#### 4. Migration Errors

**Error:** `policy already exists` or `column does not exist`

**Solutions:**

- Migrations should be idempotent, but if you see errors:

  ```bash
  # Check migration status
  npx supabase migration list

  # Reset database (⚠️ WARNING: deletes all data!)
  npx supabase db reset
  ```

- Apply migrations in order manually via SQL Editor if needed

#### 5. GraphQL Query Errors

**Error:** GraphQL queries failing or returning empty results

**Solutions:**

- Verify GraphQL inflection is enabled (check migration `20250101000000_initial_schema.sql`)
- Check RLS policies allow your user to access the data
- Verify you're authenticated and have the correct role/permissions
- Check browser console for specific error messages

#### 6. Feature Flag Not Working

**Error:** Application still using Parse/Firebase instead of Supabase

**Solutions:**

- Verify feature flag is set in `.env.local` (not just `.env`)
- Restart dev server after changing env variables
- Check browser console for feature flag status
- Verify flag is enabled for the specific feature slice

### Getting Help

1. **Check Documentation:**

   - [`SUPABASE_MIGRATION_CHECKLIST.md`](./SUPABASE_MIGRATION_CHECKLIST.md) - Migration progress
   - [`TESTING_GUIDE.md`](./TESTING_GUIDE.md) - Testing procedures
   - [`APPLY_MIGRATIONS_GUIDE.md`](./APPLY_MIGRATIONS_GUIDE.md) - Migration details

2. **Check Supabase Dashboard:**

   - Database logs: Dashboard → Logs → Database
   - Auth logs: Dashboard → Logs → Auth
   - API logs: Dashboard → Logs → API

3. **Check Application Logs:**
   - Browser console (F12)
   - Terminal where dev server is running
   - Check for network errors in DevTools → Network tab

---

## Quick Reference

### Essential Commands

```bash
# Install dependencies
npm install

# Run development server
npm run dev

# Run with Turbo (faster)
npm run fast

# Apply database migrations
npx supabase db push

# Check migration status
npx supabase migration list

# Link to Supabase project
npx supabase link --project-ref tepdgpiyjluuddwgboyy

# Run tests
npm test

# Run E2E tests
npm run test:e2e
```

### Important URLs

- **Application**: http://localhost:3000
- **Supabase Dashboard**: https://supabase.com/dashboard/project/tepdgpiyjluuddwgboyy
- **GraphQL Endpoint**: https://tepdgpiyjluuddwgboyy.supabase.co/graphql/v1
- **Supabase API Docs**: https://supabase.com/docs/reference/javascript/introduction

### Key Directories

- **Supabase Repository**: `migrations/` - Database migration files (separate repository)
- `src/lib/supabaseClient.js` - Supabase client configuration
- `src/app/graphql/**` - GraphQL queries/mutations (both Parse and Supabase variants)
- `docs/migrations/` - Migration documentation

### Environment Variable Checklist

Before running, ensure you have:

- [ ] `NEXT_PUBLIC_SUPABASE_URL`
- [ ] `NEXT_PUBLIC_SUPABASE_ANON_KEY`
- [ ] `SUPABASE_SERVICE_ROLE_KEY`
- [ ] `SUPABASE_PROJECT_REF`
- [ ] Feature flags set (if you want to use Supabase features)
- [ ] Database connection variables (for migrations)

---

## Next Steps

After successfully running the application:

1. **Test Authentication** - Try logging in/out
2. **Test Key Features** - Appointments, billing, patient management
3. **Check Migration Status** - See what's complete in the checklist
4. **Review Documentation** - Read migration guides for specific features
5. **Run Tests** - Execute test suites to verify functionality

For detailed testing procedures, see: [`docs/migrations/TESTING_GUIDE.md`](./TESTING_GUIDE.md)

---

## Additional Resources

- **Migration Plan**: [`docs/SUPABASE_MIGRATION_PLAN.md`](../SUPABASE_MIGRATION_PLAN.md)
- **Migration Requirements**: [`docs/SUPABASE_MIGRATION_REQUIREMENTS.md`](../SUPABASE_MIGRATION_REQUIREMENTS.md)
- **Migration Checklist**: [`docs/migrations/SUPABASE_MIGRATION_CHECKLIST.md`](./SUPABASE_MIGRATION_CHECKLIST.md)
- **MCP Setup**: [`docs/migrations/SUPABASE_MCP_SETUP.md`](./SUPABASE_MCP_SETUP.md)
- **Testing Guide**: [`docs/migrations/TESTING_GUIDE.md`](./TESTING_GUIDE.md)

---

**Last Updated**: Based on migration checklist as of Phase 11 completion
