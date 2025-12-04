# Phase 9: Notifications (Email/SMS/In-App) - Implementation Complete ✅

**Date:** December 2, 2025  
**Status:** ✅ Implementation Complete

---

## Summary

Phase 9: Notifications has been fully implemented using AWS SES for email, AWS SNS for SMS, and OneSignal for in-app push notifications. All services are integrated with Supabase for delivery logging and preference management.

---

## ✅ Completed Implementation

### 1. AWS SES Email Service ✅

**File:** `src/lib/notifications/email.js`

**Features:**
- ✅ AWS SES client initialization
- ✅ Email sending with HTML and plain text support
- ✅ Email templates (staff invite, appointment reminder, invoice receipt)
- ✅ Delivery logging to Supabase
- ✅ Error handling and retry logic

**Templates:**
- `staffInvite` - Staff invitation emails
- `appointmentReminder` - Appointment reminder emails
- `invoiceReceipt` - Payment receipt emails

**Usage:**
```javascript
import { sendEmail, emailTemplates } from '@/lib/notifications/email';

// Using template
await sendEmail({
  to: 'user@example.com',
  ...emailTemplates.staffInvite({
    inviteUrl: 'https://...',
    orgName: 'My Org',
    inviterName: 'John Doe',
  }),
  metadata: { orgId, type: 'staff_invite' },
});

// Direct email
await sendEmail({
  to: 'user@example.com',
  subject: 'Hello',
  htmlBody: '<p>Hello!</p>',
  textBody: 'Hello!',
  metadata: { orgId },
});
```

### 2. AWS SNS SMS Service ✅

**File:** `src/lib/notifications/sms.js`

**Features:**
- ✅ AWS SNS client initialization
- ✅ SMS sending with E.164 phone number validation
- ✅ Sender ID support (alphanumeric)
- ✅ SMS templates
- ✅ Delivery logging to Supabase
- ✅ Error handling

**Templates:**
- `appointmentReminder` - Appointment reminder SMS
- `appointmentConfirmation` - Appointment confirmation SMS
- `paymentReceipt` - Payment receipt SMS

**Usage:**
```javascript
import { sendSMS, smsTemplates } from '@/lib/notifications/sms';

// Using template
await sendSMS({
  to: '+1234567890',
  ...smsTemplates.appointmentReminder({
    appointmentDate: 'Dec 5, 2025',
    appointmentTime: '2:00 PM',
    locationName: 'Main Office',
  }),
  metadata: { orgId, patientId },
});
```

### 3. OneSignal Push Notification Service ✅

**File:** `src/lib/notifications/push.js`

**Features:**
- ✅ OneSignal API integration
- ✅ Player ID registration and management
- ✅ User ID to player ID resolution
- ✅ Push notification sending
- ✅ Delivery logging to Supabase
- ✅ Error handling

**Usage:**
```javascript
import { sendPushNotification, registerPlayerId } from '@/lib/notifications/push';

// Register player ID
await registerPlayerId(userId, playerId, orgId);

// Send push notification
await sendPushNotification({
  playerIds: [playerId],
  heading: 'New Task',
  content: 'You have been assigned a new task',
  data: { taskId: '...' },
  url: 'https://...',
  metadata: { orgId, staffId },
});
```

### 4. Notification Delivery Logs Table ✅

**File:** `supabase/migrations/20251202130000_create_notification_deliveries_table.sql`

**Features:**
- ✅ Tracks email, SMS, and push notification deliveries
- ✅ Stores delivery status (sent, delivered, failed, bounced, complained)
- ✅ Links to org/staff/patient for context
- ✅ Stores error messages and metadata
- ✅ RLS policies for secure access
- ✅ Indexes for efficient queries

**Columns:**
- `notification_type` - 'email', 'sms', 'push'
- `recipient_email` - Email address
- `recipient_phone` - Phone number (E.164)
- `subject` - Email/push subject
- `message_id` - AWS SES/SNS message ID or OneSignal notification ID
- `status` - Delivery status
- `error_message` - Error details if failed
- `org_id`, `staff_id`, `patient_id` - Context
- `notification_metadata` - Additional metadata (JSONB)
- `sent_at`, `delivered_at` - Timestamps

### 5. Notification Preferences ✅

**File:** `supabase/migrations/20251202140000_add_notification_preferences.sql`

**Features:**
- ✅ Added to `profiles` table:
  - `email_notifications_enabled` (boolean, default: true)
  - `sms_notifications_enabled` (boolean, default: true)
  - `push_notifications_enabled` (boolean, default: true)
  - `notification_preferences` (jsonb) - Granular preferences

- ✅ Added to `patients` table:
  - Same fields as profiles

- ✅ Indexes for efficient preference queries

### 6. API Routes ✅

**Email API:** `src/pages/api/notifications/email/send.js`
- ✅ POST `/api/notifications/email/send`
- ✅ Supports templates or direct email content
- ✅ Auth required (org_admin, staff, superadmin)
- ✅ Automatic delivery logging

**SMS API:** `src/pages/api/notifications/sms/send.js`
- ✅ POST `/api/notifications/sms/send`
- ✅ Supports templates or direct message
- ✅ Auth required (org_admin, staff, superadmin)
- ✅ Automatic delivery logging

**Push API:** `src/pages/api/notifications/push/send.js`
- ✅ POST `/api/notifications/push/send`
- ✅ Supports player IDs or user IDs
- ✅ Auth required (org_admin, staff, superadmin)
- ✅ Automatic delivery logging

**Push Registration:** `src/pages/api/notifications/push/register.js`
- ✅ POST `/api/notifications/push/register`
- ✅ Register OneSignal player ID for user
- ✅ Auth required

### 7. Webhook Handlers ✅

**AWS SES Webhook:** `src/pages/api/notifications/webhooks/aws-ses.js`
- ✅ Handles delivery status updates (bounces, complaints, deliveries)
- ✅ Updates `notification_deliveries` table
- ✅ Handles SNS subscription confirmation

**AWS SNS Webhook:** `src/pages/api/notifications/webhooks/aws-sns.js`
- ✅ Handles SMS delivery status updates
- ✅ Updates `notification_deliveries` table
- ✅ Handles SNS subscription confirmation

### 8. Notification Utilities ✅

**File:** `src/lib/notifications/utils.js`

**Functions:**
- ✅ `isNotificationEnabled()` - Check if user has notifications enabled
- ✅ `getPatientNotificationPreferences()` - Get patient preferences
- ✅ `getStaffNotificationPreferences()` - Get staff preferences
- ✅ `getPatientContactInfo()` - Get patient email/phone
- ✅ `getStaffContactInfo()` - Get staff email/phone

### 9. Database Triggers ✅

**File:** `supabase/migrations/20251202150000_create_notification_triggers.sql`

**Functions:**
- ✅ `send_appointment_reminder_notifications()` - Creates in-app notifications for appointments
- ✅ `send_task_assignment_notification()` - Creates in-app notifications for task assignments

**Triggers:**
- ✅ `task_assignment_notification_trigger` - Automatically creates notifications when tasks are assigned

**Note:** Email/SMS sending is handled by application code to avoid blocking database operations and to respect user preferences.

### 10. Updated Invite Route ✅

**File:** `src/pages/api/invite/supabase-create.js`

**Changes:**
- ✅ Now uses AWS SES instead of Supabase Auth invite email
- ✅ Uses `emailTemplates.staffInvite` template
- ✅ Logs delivery to `notification_deliveries` table

---

## Environment Variables

Added to `.env`:
```bash
# AWS Configuration
AWS_REGION=ca-central-1
AWS_SES_FROM_EMAIL=notifications@synced.health
AWS_SES_FROM_NAME=Synced Health
AWS_SNS_SENDER_ID=SYNCED

# OneSignal (when configured)
ONESIGNAL_APP_ID=
ONESIGNAL_REST_API_KEY=
```

**Already in .env:**
- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`

---

## AWS Configuration Required

### AWS SES Setup

1. **Verify Sender Email:**
   - Go to AWS SES Console → Verified identities
   - Verify `notifications@synced.health` (or your chosen email)
   - Or verify your domain for all emails

2. **Move Out of Sandbox (if needed):**
   - AWS SES starts in sandbox mode (can only send to verified emails)
   - Request production access to send to any email

3. **Configure Configuration Set (optional, for webhooks):**
   - Create configuration set in SES
   - Add event destination → SNS topic
   - Point SNS topic to webhook: `/api/notifications/webhooks/aws-ses`

4. **IAM Permissions:**
   - Ensure AWS credentials have:
     - `ses:SendEmail`
     - `ses:SendRawEmail`

### AWS SNS Setup

1. **Configure SMS Settings:**
   - Go to AWS SNS Console → Text messaging (SMS)
   - Set default sender ID (or use phone number)
   - Configure spending limits

2. **Configure Delivery Status Logging (optional):**
   - Create SNS topic for delivery status
   - Subscribe HTTP endpoint: `/api/notifications/webhooks/aws-sns`
   - Configure SMS delivery status logging

3. **IAM Permissions:**
   - Ensure AWS credentials have:
     - `sns:Publish`

---

## Next Steps

### 1. Configure AWS SES
- [ ] Verify sender email/domain in AWS SES
- [ ] Request production access (if needed)
- [ ] Configure configuration set for webhooks (optional)

### 2. Configure AWS SNS
- [ ] Set default sender ID or phone number
- [ ] Configure delivery status logging (optional)

### 3. Configure OneSignal (if using push notifications)
- [ ] Create OneSignal app
- [ ] Get App ID and REST API key
- [ ] Add to `.env`

### 4. Wire Notifications to Events

Create application code to send notifications on:
- [ ] Appointment creation/updates
- [ ] Invoice creation/payment
- [ ] Task assignments
- [ ] Other business events

### 5. Update Notification UI

- [ ] Connect `/notifications` page to Supabase
- [ ] Replace mock data with real queries
- [ ] Add real-time updates via Supabase Realtime

---

## Usage Examples

### Send Staff Invite Email

```javascript
import { sendEmail, emailTemplates } from '@/lib/notifications/email';

await sendEmail({
  to: 'newstaff@example.com',
  ...emailTemplates.staffInvite({
    inviteUrl: 'https://app.synced.health/invite/accept?token=...',
    orgName: 'My Clinic',
    inviterName: 'John Doe',
  }),
  metadata: {
    type: 'staff_invite',
    orgId: 'org-uuid',
    inviteId: 'invite-uuid',
  },
});
```

### Send Appointment Reminder

```javascript
import { sendEmail, emailTemplates } from '@/lib/notifications/email';
import { sendSMS, smsTemplates } from '@/lib/notifications/sms';
import { getPatientContactInfo, getPatientNotificationPreferences } from '@/lib/notifications/utils';

const preferences = await getPatientNotificationPreferences(patientId);
const contact = await getPatientContactInfo(patientId);

if (preferences.email && contact.email) {
  await sendEmail({
    to: contact.email,
    ...emailTemplates.appointmentReminder({
      patientName: 'Jane Doe',
      appointmentDate: 'Dec 5, 2025',
      appointmentTime: '2:00 PM',
      locationName: 'Main Office',
      staffName: 'Dr. Smith',
    }),
    metadata: { orgId, patientId, type: 'appointment_reminder' },
  });
}

if (preferences.sms && contact.phone) {
  await sendSMS({
    to: contact.phone,
    ...smsTemplates.appointmentReminder({
      appointmentDate: 'Dec 5, 2025',
      appointmentTime: '2:00 PM',
      locationName: 'Main Office',
    }),
    metadata: { orgId, patientId, type: 'appointment_reminder' },
  });
}
```

---

## ✅ Checklist Status

- [x] Implement AWS SES email integration
- [x] Implement AWS SNS SMS sender
- [x] Implement OneSignal integration (code ready, needs credentials)
- [x] Create notification templates
- [x] Add opt-in/opt-out fields
- [x] Create delivery logs table
- [x] Create API routes
- [x] Create webhook handlers
- [~] Wire to Supabase events (triggers created, application code pending)
- [ ] Update notification UI (pending)

---

## Summary

**Phase 9 implementation is complete!** All notification services are ready:

- ✅ AWS SES email service with templates
- ✅ AWS SNS SMS service with templates
- ✅ OneSignal push notification service
- ✅ Delivery logging to Supabase
- ✅ Notification preferences (opt-in/opt-out)
- ✅ API routes for sending notifications
- ✅ Webhook handlers for delivery status
- ✅ Database triggers for in-app notifications

**Ready for:** Configuration and testing (needs AWS SES/SNS setup and OneSignal credentials)


