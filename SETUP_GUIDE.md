# Complete Setup Guide: Supabase Access & Cursor Context

This guide walks you through setting up both Supabase access and Cursor IDE context for this project.

## Part 1: Supabase Access Setup

### Step 1: Install Supabase CLI

**⚠️ Important:** Supabase CLI does NOT support global npm installation (`npm install -g supabase`). Use one of these methods instead:

#### Option A: Use npx (Recommended - No Installation Needed)

```bash
# Use npx to run Supabase CLI without installing
npx supabase --version
```

**Advantages:**
- No installation required
- Always uses the latest version
- Works immediately

**Usage:** Always prefix commands with `npx`:
```bash
npx supabase login
npx supabase link --project-ref tepdgpiyjluuddwgboyy
npx supabase db push
```

#### Option B: Install via Scoop (Windows Package Manager)

If you prefer a global installation:

1. **Install Scoop** (if not already installed):
   ```powershell
   # Open PowerShell (not Git Bash)
   Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
   Invoke-RestMethod -Uri https://get.scoop.sh | Invoke-Expression
   ```

2. **Add Supabase bucket and install:**
   ```powershell
   scoop bucket add supabase https://github.com/supabase/scoop-bucket.git
   scoop install supabase
   ```

3. **Verify installation:**
   ```bash
   supabase --version
   ```

#### Option C: Install via Winget (Windows Built-in)

```powershell
winget install supabase.supabase
```

#### Option D: Install as Project Dev Dependency

```bash
npm install supabase --save-dev
```

Then use via npm scripts or `npx supabase`.

**Recommendation:** Use **Option A (npx)** for simplicity - it requires no installation and always uses the latest version.

### Step 2: Authenticate with Supabase

```bash
# If using npx (recommended)
npx supabase login

# If installed via Scoop/Winget
supabase login
```

This will:
- Open a browser window
- Prompt you to sign in to your Supabase account
- Grant the CLI access to your projects

**Note:** You need collaborator access to the project:
- Project URL: `https://tepdgpiyjluuddwgboyy.supabase.co`
- Dashboard: https://supabase.com/dashboard/project/tepdgpiyjluuddwgboyy

### Step 3: Link Your Local Project to Supabase

```bash
cd "c:\Users\Brian Du\Synced\Code\synced-supabase"

# If using npx (recommended)
npx supabase link --project-ref tepdgpiyjluuddwgboyy

# If installed via Scoop/Winget
supabase link --project-ref tepdgpiyjluuddwgboyy
```

You'll be prompted for your **database password**. 

**To find your database password:**
1. Go to: https://supabase.com/dashboard/project/tepdgpiyjluuddwgboyy
2. Navigate to: **Settings** → **Database**
3. Scroll to **Database Password** section
4. Click the eye icon to reveal, or reset if needed

**Important:** This is your database password (for PostgreSQL connections), NOT your Supabase account password.

### Step 4: Verify Connection

```bash
# If using npx (recommended)
npx supabase migration list
npx supabase projects list

# If installed via Scoop/Winget
supabase migration list
supabase projects list
```

### Step 5: Get Supabase API Keys (for application use)

You'll need these for any applications that connect to Supabase:

1. Go to: https://supabase.com/dashboard/project/tepdgpiyjluuddwgboyy
2. Navigate to: **Settings** → **API**
3. Copy these values:
   - **Project URL** → Use as `NEXT_PUBLIC_SUPABASE_URL`
   - **anon/public key** → Use as `NEXT_PUBLIC_SUPABASE_ANON_KEY`
   - **service_role key** → Use as `SUPABASE_SERVICE_ROLE_KEY` (⚠️ Keep secret!)

### Step 6: Get Database Connection Details (for scripts/migrations)

For running database scripts or direct connections:

1. Go to: https://supabase.com/dashboard/project/tepdgpiyjluuddwgboyy
2. Navigate to: **Settings** → **Database**
3. Scroll to **Connection String** section
4. Select **Connection Pooling** tab
5. Copy the connection string

The connection string looks like:
```
postgresql://postgres.tepdgpiyjluuddwgboyy:[PASSWORD]@aws-0-[REGION].pooler.supabase.com:6543/postgres?pgbouncer=true
```

Extract these values for environment variables:
- **Host**: `aws-0-[REGION].pooler.supabase.com`
- **Port**: `6543` (pooling) or `5432` (direct)
- **Database**: `postgres`
- **User**: `postgres.tepdgpiyjluuddwgboyy`
- **Password**: Your database password

---

## Part 2: Cursor IDE Context Setup

### Step 1: Understand Project Structure

This repository contains:
- **26 migration files** in `migrations/` - Database schema changes
- **Functions** in `functions/` - PostgreSQL functions
- **Scripts** in `scripts/` - Data migration, seeding, and fix scripts
- **Documentation** in `docs/` - Comprehensive guides and architecture docs

### Step 2: Set Up MCP (Model Context Protocol) for Cursor

MCP allows Cursor to directly query your Supabase database and understand your schema.

#### Option A: Supabase PostgreSQL MCP (Direct Database Access)

1. **Get your database connection string:**
   - Follow Step 6 above to get the connection string
   - Or construct it: `postgresql://postgres.tepdgpiyjluuddwgboyy:[PASSWORD]@aws-0-[REGION].pooler.supabase.com:6543/postgres`

2. **Configure MCP in Cursor:**
   - Open or create: `~/.cursor/mcp.json` (on Windows: `C:\Users\Brian Du\.cursor\mcp.json`)
   - Add this configuration:

```json
{
  "mcpServers": {
    "supabase-postgres": {
      "command": "npx",
      "args": [
        "-y",
        "@modelcontextprotocol/server-postgres"
      ],
      "env": {
        "POSTGRES_CONNECTION_STRING": "postgresql://postgres.tepdgpiyjluuddwgboyy:[YOUR_PASSWORD]@aws-0-[REGION].pooler.supabase.com:6543/postgres?pgbouncer=true&sslmode=require"
      }
    }
  }
}
```

**Replace:**
- `[YOUR_PASSWORD]` with your database password
- `[REGION]` with your actual region (e.g., `us-east-1`)

#### Option B: Supabase MCP Server (API-Based)

Add this to your `~/.cursor/mcp.json`:

```json
{
  "mcpServers": {
    "supabase": {
      "url": "https://mcp.supabase.com/mcp?project_ref=tepdgpiyjluuddwgboyy&read_only=false"
    }
  }
}
```

**Note:** If authentication is required, you may need to:
1. Go to Supabase Dashboard → Account Settings → Access Tokens
2. Create a Personal Access Token
3. Add it to the configuration (format may vary)

### Step 3: Restart Cursor

After configuring MCP:
1. Save `mcp.json`
2. **Restart Cursor IDE completely**
3. MCP servers will be available in Cursor

### Step 4: Verify Cursor Context

After restarting, Cursor should have access to:
- ✅ All migration files (26 files in `migrations/`)
- ✅ Database schema (via MCP)
- ✅ Functions and scripts
- ✅ Documentation

**Test MCP access:**
- Ask Cursor: "What tables exist in the Supabase database?"
- Ask Cursor: "Show me the schema of the patients table"
- Ask Cursor: "What RLS policies are on the orgs table?"

---

## Part 3: Quick Verification Checklist

### Supabase Access ✅
- [ ] Supabase CLI accessible (`npx supabase --version` works, or `supabase --version` if installed)
- [ ] Authenticated with Supabase (`npx supabase login` completed)
- [ ] Project linked (`npx supabase link --project-ref tepdgpiyjluuddwgboyy` completed)
- [ ] Can list migrations (`npx supabase migration list` works)
- [ ] Have API keys (anon key, service role key)
- [ ] Have database connection details

### Cursor Context ✅
- [ ] MCP configuration file created (`~/.cursor/mcp.json`)
- [ ] Connection string configured with correct password
- [ ] Cursor restarted after MCP configuration
- [ ] Can query database via Cursor (test with a simple question)
- [ ] Cursor can see migration files
- [ ] Cursor can access documentation

---

## Part 4: Common Commands Reference

### Supabase CLI Commands

**Note:** If using `npx`, prefix all commands with `npx`. If installed via Scoop/Winget, use commands directly.

```bash
# Authentication
npx supabase login          # or: supabase login

# Link project
npx supabase link --project-ref tepdgpiyjluuddwgboyy

# Apply migrations
npx supabase db push

# Check migration status
npx supabase migration list

# Create new migration
npx supabase migration new <descriptive_name>

# Reset database (⚠️ WARNING: deletes all data!)
npx supabase db reset
```

### Useful Cursor Queries (after MCP setup)

- "What's the current database schema?"
- "Show me all RLS policies"
- "What migrations haven't been applied yet?"
- "Explain the relationship between orgs, locations, and users tables"
- "What functions exist in the database?"

---

## Troubleshooting

### Supabase CLI Issues

**"Authentication failed"**
- Make sure you're logged in: `npx supabase login` (or `supabase login` if installed)
- Verify you have collaborator access to the project

**"Database password incorrect"**
- Get the password from: Dashboard → Settings → Database → Database Password
- This is different from your Supabase account password

**"Connection refused"**
- Check if your IP is whitelisted in: Dashboard → Settings → Database → Connection Pooling → Allowed IPs
- Try using connection pooler (port 6543) instead of direct connection (port 5432)

### Cursor MCP Issues

**"MCP server not found"**
- Verify `mcp.json` is in the correct location: `~/.cursor/mcp.json`
- Check JSON syntax is valid
- Restart Cursor completely

**"Connection timeout"**
- Verify connection string is correct
- Check database password is correct
- Ensure your IP is whitelisted in Supabase

**"SSL/TLS errors"**
- Make sure `sslmode=require` is in the connection string
- Connection pooler handles SSL automatically

---

## Next Steps

After completing this setup:

1. **Review the documentation:**
   - `README.md` - Project overview
   - `docs/migrations/` - Migration guides
   - `docs/architecture/` - Architecture decisions

2. **Apply migrations (if needed):**
   ```bash
   npx supabase db push
   ```

3. **Explore the database:**
   - Use Cursor to query the database
   - Review migration files to understand schema evolution
   - Check RLS policies in migration files

4. **Run scripts (if needed):**
   - See `scripts/README.md` for available scripts
   - Scripts may require additional environment variables

---

## Additional Resources

- **Supabase Dashboard**: https://supabase.com/dashboard/project/tepdgpiyjluuddwgboyy
- **Project URL**: https://tepdgpiyjluuddwgboyy.supabase.co
- **Supabase Docs**: https://supabase.com/docs
- **Migration Guide**: `docs/migrations/APPLY_MIGRATIONS_GUIDE.md`
- **Running Guide**: `docs/migrations/SUPABASE_RUNNING_GUIDE.md`
- **MCP Setup**: `docs/testing/SUPABASE_MCP_SETUP.md`

---

**Last Updated:** 2025-01-XX  
**Project Reference:** `tepdgpiyjluuddwgboyy`




