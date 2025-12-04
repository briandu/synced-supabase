# Phase 9: Notifications (Email/SMS/In-App) - Setup Guide

**Date:** December 2, 2025  
**Status:** Implementation Guide

---

## Overview

Phase 9 involves implementing a comprehensive notification system using:
- **Email:** AWS SES (Simple Email Service)
- **SMS:** AWS SNS (Simple Notification Service)
- **In-App:** OneSignal

---

## Current State

### ✅ What Exists

1. **Database Tables:**
   - `staff_notifications` - For staff in-app notifications
   - `patient_notifications` - For patient in-app notifications
   - Both tables have RLS policies and are org-scoped

2. **AWS Credentials:**
   - ✅ `AWS_ACCESS_KEY_ID` - In .env
   - ✅ `AWS_SECRET_ACCESS_KEY` - In .env

3. **Current Email Usage:**
   - Staff invites use Supabase Auth's `inviteUserByEmail`
   - Located in: `src/pages/api/invite/supabase-create.js`

4. **Notification UI:**
   - `/notifications` page exists
   - Uses mock data currently (`src/_mock/_notifications.js`)

---

## Implementation Plan

### Step 1: Install AWS SDK

```bash
npm install @aws-sdk/client-ses @aws-sdk/client-sns
```

### Step 2: Environment Variables

Add to `.env`:
```bash
# AWS Region (e.g., us-east-1, ca-central-1)
AWS_REGION=ca-central-1

# AWS SES Configuration
AWS_SES_FROM_EMAIL=notifications@synced.health
AWS_SES_FROM_NAME=Synced Health

# AWS SNS Configuration
AWS_SNS_SENDER_ID=SYNCED
# Or use a phone number: AWS_SNS_FROM_NUMBER=+1234567890
```

### Step 3: Create Notification Services

1. **Email Service** (`src/lib/notifications/email.js`)
   - AWS SES client initialization
   - Email sending function
   - Template rendering
   - Delivery logging

2. **SMS Service** (`src/lib/notifications/sms.js`)
   - AWS SNS client initialization
   - SMS sending function
   - Delivery logging

3. **Push Notification Service** (`src/lib/notifications/push.js`)
   - OneSignal client initialization
   - Push notification sending
   - Player ID management

### Step 4: Create Delivery Logs Table

Create `notification_deliveries` table to track:
- Email delivery status
- SMS delivery status
- Push notification delivery status
- Delivery timestamps
- Error messages

### Step 5: Add Opt-in/Opt-out Fields

Add to `profiles` and `patients` tables:
- `email_notifications_enabled` (boolean)
- `sms_notifications_enabled` (boolean)
- `push_notifications_enabled` (boolean)
- `notification_preferences` (jsonb) - For granular preferences

### Step 6: Create API Routes

1. **Email API** (`src/pages/api/notifications/email/send.js`)
   - Send email notifications
   - Log delivery status

2. **SMS API** (`src/pages/api/notifications/sms/send.js`)
   - Send SMS notifications
   - Log delivery status

3. **Push API** (`src/pages/api/notifications/push/send.js`)
   - Send push notifications
   - Log delivery status

4. **Webhook Handlers:**
   - AWS SES webhook (delivery status)
   - AWS SNS webhook (delivery status)
   - OneSignal webhook (delivery status)

### Step 7: Create Notification Templates

1. **Email Templates:**
   - Staff invite
   - Appointment reminder
   - Appointment confirmation
   - Invoice receipt
   - Password reset

2. **SMS Templates:**
   - Appointment reminder
   - Appointment confirmation
   - Payment receipt

3. **Push Templates:**
   - New task assigned
   - Appointment reminder
   - New message

### Step 8: Wire to Supabase Events

Create database triggers/functions to:
- Send email on staff invite creation
- Send notifications on appointment creation/update
- Send notifications on invoice creation
- Send notifications on task assignment

### Step 9: Update Notification UI

- Connect `/notifications` page to Supabase
- Replace mock data with real queries
- Add real-time updates via Supabase Realtime

---

## AWS Configuration Requirements

### AWS SES Setup

1. **Verify Sender Email:**
   - Go to AWS SES Console
   - Verify email address or domain
   - Move out of sandbox mode (if needed)

2. **IAM Permissions:**
   - Ensure AWS credentials have `ses:SendEmail` and `ses:SendRawEmail` permissions

### AWS SNS Setup

1. **Create SNS Topic (optional):**
   - For delivery status tracking
   - Configure webhook endpoint

2. **IAM Permissions:**
   - Ensure AWS credentials have `sns:Publish` permission

---

## Next Steps

I'll implement the complete notification system using AWS SES and SNS!


