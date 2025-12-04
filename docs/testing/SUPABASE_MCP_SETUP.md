# Supabase MCP Setup Guide

This document describes how to configure MCP (Model Context Protocol) access to your Supabase project in Cursor IDE.

## Current Configuration

Your Supabase project details:
- **Project URL:** https://tepdgpiyjluuddwgboyy.supabase.co
- **Project Reference:** `tepdgpiyjluuddwgboyy`

## MCP Configuration Options

Two MCP servers have been added to `~/.cursor/mcp.json`:

### Option 1: Supabase PostgreSQL (Direct Database Access)

**Server Name:** `supabase-postgres`

This uses the PostgreSQL MCP server to connect directly to your Supabase database, giving you full SQL query capabilities.

**Setup Steps:**

1. Go to Supabase Dashboard: https://supabase.com/dashboard/project/tepdgpiyjluuddwgboyy
2. Navigate to: **Settings → Database**
3. Scroll to **Connection String** section
4. Select **Connection Pooling** mode (or **Direct Connection** if you prefer)
5. Copy the connection string - it will look like:
   ```
   postgresql://postgres.tepdgpiyjluuddwgboyy:[PASSWORD]@aws-0-[REGION].pooler.supabase.com:6543/postgres
   ```
6. Update `~/.cursor/mcp.json` and replace the placeholder connection string with your actual one

**Note:** The password is your database password (different from your Supabase account password). If you don't have it, you can reset it in the dashboard.

### Option 2: Supabase MCP Server (API-Based)

**Server Name:** `supabase`

This uses the official Supabase MCP server which provides access to Supabase APIs, schema introspection, and project information.

**Current Configuration:**
```json
"supabase": {
  "url": "https://mcp.supabase.com/mcp?project_ref=tepdgpiyjluuddwgboyy&read_only=false"
}
```

**Optional Setup (if authentication required):**

If the Supabase MCP server requires a Personal Access Token:

1. Go to Supabase Dashboard → Account Settings → Access Tokens
2. Create a new Personal Access Token with a descriptive name (e.g., "Cursor MCP Access")
3. Update the configuration to include authentication (format may vary based on MCP server requirements)

**Security Note:** The `read_only=false` parameter allows write access. Change to `read_only=true` if you only need read access.

## Usage Examples

After configuring and restarting Cursor, you can use commands like:

### Using Supabase PostgreSQL MCP:
- "Use supabase-postgres to query all tables in the public schema"
- "Use supabase-postgres to show me the schema of the patients table"
- "Use supabase-postgres to check foreign key relationships from org_id"
- "Use supabase-postgres to run: SELECT table_name FROM information_schema.tables WHERE table_schema = 'public'"

### Using Supabase MCP Server:
- "Use supabase to list all tables"
- "Use supabase to show the schema of the orgs table"
- "Use supabase to check RLS policies on patients table"

## Troubleshooting

### Connection Issues

**Problem:** Connection refused or timeout
- **Solution:** Verify the connection string is correct and the database is accessible
- Check if your IP is whitelisted in Supabase Dashboard → Settings → Database → Connection Pooling → Allowed IPs

**Problem:** Authentication failed
- **Solution:** Verify your database password is correct
- Reset your database password in Supabase Dashboard → Settings → Database → Database Password

### SSL/TLS Issues

If you encounter SSL errors with the PostgreSQL connection, you may need to:
- Use `sslmode=require` in the connection string (already included)
- For connection pooler: SSL is typically handled automatically
- For direct connection: May require additional SSL configuration

## Related Files

- Main MCP configuration: `~/.cursor/mcp.json`
- Reference doc for postgres-dev: `parse_ref/mcp-postgres-dev.md`
- Migration checklist: `docs/migrations/SUPABASE_MIGRATION_CHECKLIST.md`

## Next Steps

1. ✅ Configuration added to `mcp.json`
2. ⏳ Get database password from Supabase Dashboard
3. ⏳ Update connection string in `mcp.json`
4. ⏳ Restart Cursor IDE
5. ⏳ Test with a simple query to verify connection

