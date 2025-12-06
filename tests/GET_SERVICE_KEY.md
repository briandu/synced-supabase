# How to Get Your Supabase Service Role Key

1. Go to your Supabase Dashboard:
   https://supabase.com/dashboard/project/tepdgpiyjluuddwgboyy

2. Click on **Settings** (gear icon in the left sidebar)

3. Click on **API** in the settings menu

4. Scroll down to **Project API keys**

5. Find the **service_role** key (NOT the anon key)
   - It's a long JWT token
   - It's labeled as "secret" - keep it secure!

6. Copy the service_role key

7. Open `tests/.env` file and replace `your-service-role-key-here` with the actual key

Example .env:
```
SUPABASE_URL=https://tepdgpiyjluuddwgboyy.supabase.co
SUPABASE_SERVICE_ROLE_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRlcGRncGl5amx1dWRkd2dib3l5Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTcwNDI4MDQwMCwiZXhwIjoyMDE5ODU2NDAwfQ.XXXXXXXXXXXXXXXXXXX
```

Then run: `npm test`
