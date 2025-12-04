# Chat Realtime Setup with Supabase

## Overview

The chat system has been fully migrated to use Supabase Realtime for real-time messaging, presence, and typing indicators.

## What Was Done

### 1. Database Schema

#### Chat Tables (Already existed)
- `chat_threads` - Threads (DM or channel)
- `chat_thread_members` - Thread membership
- `chat_messages` - Messages

#### Presence Table (New)
- `presence` - User online/offline status tracking

**Migration:** `supabase/migrations/20251201190000_add_presence_table.sql`

### 2. Realtime Configuration

Enabled Realtime for all chat-related tables:
- `chat_threads`
- `chat_messages`
- `chat_thread_members`
- `presence`

**Migration:** Updated `supabase/migrations/20251128160000_chat_realtime.sql`

### 3. Context & Hooks

#### New: `SupabaseChatContext`
- Full chat state management
- Thread loading and subscriptions
- Message loading and subscriptions
- Typing indicators
- Presence tracking
- Window management
- Composer state

**File:** `src/app/contexts/SupabaseChatContext.js`

#### Updated: `ChatContext`
- Automatically uses `SupabaseChatContext` when Supabase auth and realtime are enabled
- Falls back to Firebase chat for legacy support

**File:** `src/app/contexts/ChatContext.js`

### 4. API Routes

#### `/api/chat/send-message`
- Sends messages to threads
- Resolves `staff_id` automatically
- Verifies thread membership
- Updates thread `updated_at` timestamp

**File:** `src/pages/api/chat/send-message.js`

#### `/api/chat/create-thread`
- Creates new threads (DM or channel)
- Adds members to thread
- Resolves `staff_id` for all members

**File:** `src/pages/api/chat/create-thread.js`

### 5. Presence & Typing

#### Presence Helpers
- `startPresence()` - Start presence heartbeat
- `subscribePresence()` - Subscribe to user presence changes

**File:** `src/lib/supabasePresence.js`

#### Typing Indicators
- `setTypingActivity()` - Set typing status
- `subscribeThreadTyping()` - Subscribe to typing events

**File:** `src/lib/supabasePresence.js`

## How It Works

### Thread Loading
1. Loads threads where user is a member
2. Subscribes to thread updates via Realtime
3. Automatically updates when threads are created/updated/deleted

### Message Loading
1. Loads initial messages for active thread
2. Subscribes to new messages via Realtime
3. Automatically adds new messages to the list
4. Updates thread `updated_at` when new message arrives

### Presence
1. User presence is tracked via `presence` table
2. Heartbeat updates presence every 60 seconds
3. Presence changes are broadcast via Realtime
4. Other users can subscribe to see online/offline status

### Typing Indicators
1. Typing status is broadcast via Realtime broadcast channels
2. Each thread has its own typing channel
3. Typing status expires after 3 seconds of inactivity

## Usage

### In Components

```javascript
import { useChat } from '@/app/contexts/ChatContext';

function MyComponent() {
  const {
    activeThreadId,
    activeThread,
    messages,
    directThreads,
    channelThreads,
    selectThread,
    sendMessage,
    createDmThread,
    createChannel,
    typingMap,
    presenceMap,
  } = useChat();

  // Use chat functionality
}
```

### Creating a Thread

```javascript
// Create DM thread
const threadId = await createDmThread([userId1, userId2], 'Direct Message');

// Create channel
const channelId = await createChannel('Team Chat', [userId1, userId2, userId3], false);
```

### Sending a Message

```javascript
await sendMessage(threadId, 'Hello!', 'message', {});
```

## Feature Flags

Chat uses Supabase when both flags are enabled:
- `NEXT_PUBLIC_SUPABASE_FEATURE_AUTH=true`
- `NEXT_PUBLIC_SUPABASE_FEATURE_REALTIME=true`

## Testing

1. **Apply Migrations:**
   ```bash
   supabase db push
   ```

2. **Enable Feature Flags:**
   ```env
   NEXT_PUBLIC_SUPABASE_FEATURE_AUTH=true
   NEXT_PUBLIC_SUPABASE_FEATURE_REALTIME=true
   ```

3. **Test Chat:**
   - Create a thread
   - Send messages
   - Verify real-time updates
   - Check typing indicators
   - Verify presence status

## Security

- All chat operations are protected by RLS policies
- Users can only access threads they're members of
- Messages are scoped to org_id
- Presence is scoped to org_id

## Performance

- Messages are limited to 100 per thread load
- Threads are paginated (20 per load)
- Typing indicators expire after 3 seconds
- Presence heartbeat runs every 60 seconds
- Realtime subscriptions are cleaned up on unmount

## Next Steps

1. Apply the presence table migration
2. Test chat functionality end-to-end
3. Update UI components to use new chat context (if needed)
4. Add unread message counts
5. Add message search functionality
6. Add file attachments support

