# Quick Guide: Finding Your Supabase Database Password and Host

This is a quick reference guide for finding your Supabase database credentials needed for migrations and scripts.

## Quick Steps

### Step 1: Access Supabase Dashboard

1. Go to: https://supabase.com/dashboard/project/tepdgpiyjluuddwgboyy
2. Make sure you're logged in and have access to the project

### Step 2: Navigate to Database Settings

1. In the left sidebar, click **Settings** (gear icon at the bottom)
2. Click **Database** in the settings menu
3. You should now see several sections including:
   - Database Password
   - Connection String
   - Connection Pooling

### Step 3: Get Your Database Password

**Option A: If password is visible**

1. Scroll to **Database Password** section
2. Click the eye icon to reveal the password (if hidden)
3. Click **Copy** to copy the password
4. Save it securely in your `.env.local` file

**Option B: If password is not visible or you forgot it**

1. Scroll to **Database Password** section
2. Click **Reset Database Password** button
3. **⚠️ WARNING:** This will reset the password and may disconnect existing connections
4. Copy the new password immediately (you won't be able to see it again!)
5. Save it securely

### Step 4: Get Your Database Host and Connection Details

1. Scroll to **Connection String** section
2. Click on the **Connection Pooling** tab
3. Select **Session mode** (recommended for migrations)
4. You'll see a connection string that looks like:
   ```
   postgresql://postgres.tepdgpiyjluuddwgboyy:[PASSWORD]@aws-0-[REGION].pooler.supabase.com:6543/postgres?pgbouncer=true
   ```
5. Copy this connection string

### Step 5: Extract Values for Environment Variables

From the connection string, extract these values:

**Connection String Format:**

```
postgresql://[USER]:[PASSWORD]@[HOST]:[PORT]/[DATABASE]?[OPTIONS]
```

**Your Values:**

- **User**: `postgres.tepdgpiyjluuddwgboyy` (after `postgresql://`, before `:`)
- **Password**: The part between `:` and `@` (from Step 3)
- **Host**: `aws-0-[REGION].pooler.supabase.com` (between `@` and `:`)
- **Port**: `6543` (for connection pooling) or `5432` (for direct connection)
- **Database**: `postgres` (after the port, before `?`)

### Step 6: Update Your Environment Variables

Add these to your `.env.local` file:

```env
# Database Connection (for migrations/scripts)
SUPABASE_DB_HOST=aws-0-[REGION].pooler.supabase.com
SUPABASE_DB_PORT=6543
SUPABASE_DB_NAME=postgres
SUPABASE_DB_USER=postgres.tepdgpiyjluuddwgboyy
SUPABASE_DB_PASSWORD=your-password-from-step-3
```

**Example with actual values:**

```env
SUPABASE_DB_HOST=aws-0-us-east-1.pooler.supabase.com
SUPABASE_DB_PORT=6543
SUPABASE_DB_NAME=postgres
SUPABASE_DB_USER=postgres.tepdgpiyjluuddwgboyy
SUPABASE_DB_PASSWORD=MySecurePassword123!
```

## Common Regions

The `[REGION]` in the host might be one of these common values:

- `us-east-1` - US East (N. Virginia)
- `us-west-1` - US West (N. California)
- `us-west-2` - US West (Oregon)
- `eu-west-1` - Europe (Ireland)
- `ap-southeast-1` - Asia Pacific (Singapore)
- `ap-northeast-1` - Asia Pacific (Tokyo)

## Alternative: Direct Connection (If Pooler Doesn't Work)

If you need to use a direct connection instead:

1. In **Settings** → **Database** → **Connection String**
2. Click the **Direct Connection** tab
3. Copy that connection string instead
4. Use port `5432` instead of `6543`

**Direct connection format:**

```env
SUPABASE_DB_HOST=aws-0-[REGION].pooler.supabase.com  # or db.[project-ref].supabase.co
SUPABASE_DB_PORT=5432  # Different port for direct connection
SUPABASE_DB_NAME=postgres
SUPABASE_DB_USER=postgres
SUPABASE_DB_PASSWORD=your-password
```

## Troubleshooting

### "I can't see my password"

- **Solution**: Click the eye icon to reveal it, or reset the password
- **Note**: After resetting, you must copy it immediately - it won't be shown again!

### "I don't see Connection String section"

- Make sure you're in **Settings** → **Database** (not API settings)
- Scroll down - it's usually below the Database Password section
- Try refreshing the page

### "Connection refused" error

- Verify your IP is whitelisted: **Settings** → **Database** → **Connection Pooling** → **Allowed IPs**
- Check that you're using the correct host and port
- Verify the password is correct (no extra spaces when copying)

### "Authentication failed" error

- Double-check the password is correct (it's case-sensitive)
- Make sure there are no extra spaces when copying
- Try resetting the password if you're unsure

## Security Notes

⚠️ **Important Security Reminders:**

1. **Never commit your `.env.local` file** to git - it contains sensitive credentials
2. **Keep your database password secure** - it gives full database access
3. **Use different passwords** for different environments (dev/staging/prod)
4. **Rotate passwords regularly** for security best practices

## Quick Reference

**Dashboard URL:**

```
https://supabase.com/dashboard/project/tepdgpiyjluuddwgboyy
```

**Navigation Path:**

```
Settings → Database → (Database Password OR Connection String)
```

**What You Need:**

- ✅ Database Password
- ✅ Database Host (from connection string)
- ✅ Database Port (6543 for pooling, 5432 for direct)
- ✅ Database User (usually `postgres.tepdgpiyjluuddwgboyy` or just `postgres`)
- ✅ Database Name (usually `postgres`)

---

**Related Documentation:**

- [Full Running Guide](./SUPABASE_RUNNING_GUIDE.md) - Complete setup instructions
- [Migration Guide](./APPLY_MIGRATIONS_GUIDE.md) - How to apply database migrations

