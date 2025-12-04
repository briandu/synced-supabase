# Stripe Webhook Setup Guide

This guide will walk you through setting up Stripe webhooks for your application.

## Overview

Stripe webhooks allow Stripe to send real-time notifications to your application when events happen (like payments, invoices, etc.). We'll configure webhooks to send events to your API endpoint.

## 🏠 Local Testing vs Production Setup

**For Local Testing:**

- Use **Stripe CLI** to forward webhooks to your local server
- No need to create a webhook endpoint in Stripe Dashboard (yet)
- Stripe CLI provides a temporary webhook secret

**For Production/Staging:**

- Create a webhook endpoint in Stripe Dashboard
- Use your deployed URL
- Get the webhook secret from Stripe Dashboard

---

## 🧪 Option A: Local Testing (Recommended to Start)

### Step 1: Install Stripe CLI

**macOS (using Homebrew):**

```bash
brew install stripe/stripe-cli/stripe
```

**Windows (using Scoop):**

```bash
scoop bucket add stripe https://github.com/stripe/scoop-stripe-cli.git
scoop install stripe
```

**Linux:**

```bash
# Download from: https://github.com/stripe/stripe-cli/releases
# Or use package manager
```

**Verify installation:**

```bash
stripe --version
```

### Step 2: Login to Stripe CLI

```bash
stripe login
```

This will open your browser to authenticate with Stripe.

### Step 3: Forward Webhooks to Local Server

**Start your local development server first:**

```bash
npm run dev
# Your app should be running on http://localhost:3000
```

**In a separate terminal, run:**

```bash
stripe listen --forward-to localhost:3000/api/stripe/webhook
```

**You'll see output like:**

```
> Ready! Your webhook signing secret is whsec_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx (^C to quit)
```

### Step 4: Copy the Webhook Secret

The Stripe CLI will display a webhook secret that starts with `whsec_...`. Copy this secret.

### Step 5: Add to Your `.env.local` File

Create or update `.env.local` (this file is gitignored, safe for secrets):

```bash
# Stripe Webhook Secret (from Stripe CLI for local testing)
STRIPE_WEBHOOK_SECRET=whsec_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
```

**Important**: This secret is different from production webhook secrets. It's only for local testing.

### Step 6: Test Webhooks Locally

**Trigger a test event:**
In another terminal (while `stripe listen` is running):

```bash
stripe trigger payment_intent.succeeded
```

**Or trigger other events:**

```bash
stripe trigger invoice.paid
stripe trigger customer.created
stripe trigger setup_intent.succeeded
```

**Check your application:**

- Look at your terminal running `npm run dev` for webhook logs
- Check your database for updated records
- Verify the webhook handler is processing events

### Step 7: Monitor Webhook Events

The `stripe listen` command will show you all webhook events in real-time:

```
2024-01-15 10:30:45   --> payment_intent.succeeded [evt_xxxxx]
2024-01-15 10:30:45  <--  [200] POST http://localhost:3000/api/stripe/webhook [evt_xxxxx]
```

---

## 🌐 Option B: Production/Staging Setup

### Step 1: Access Stripe Webhooks

1. **Log in to Stripe Dashboard**: Go to https://dashboard.stripe.com
2. **Navigate to Webhooks**:
   - Click on **"Developers"** in the left sidebar
   - Click on **"Webhooks"** in the submenu
3. **You'll see two options:**
   - **"Webhooks"** (traditional) - This is what we need ✅
   - **"Event destinations"** (newer feature) - Not what we need for now

---

## Step 2: Create a New Webhook Endpoint

1. **Click "Add endpoint"** button (top right)
2. **Enter your endpoint URL:**

   - For **staging/testing**: `https://synced-admin-portal.vercel.app/api/stripe/webhook`
   - For **production**: `https://your-production-domain.com/api/stripe/webhook`
   - **Note**: Replace with your actual deployment URL if different

3. **Description** (optional):
   - Enter something like: "Supabase Migration - Main Webhook Handler"

---

## Step 3: Select Events to Listen To

You'll see a list of events. Select the following events that are relevant to your application:

### Critical Events (Must Have):

- ✅ `payment_intent.succeeded` - When a payment succeeds
- ✅ `payment_intent.payment_failed` - When a payment fails
- ✅ `payment_intent.canceled` - When a payment is canceled
- ✅ `setup_intent.succeeded` - When a payment method is saved
- ✅ `setup_intent.setup_failed` - When saving a payment method fails

### Invoice Events:

- ✅ `invoice.created` - When an invoice is created
- ✅ `invoice.finalized` - When an invoice is finalized
- ✅ `invoice.paid` - When an invoice is paid
- ✅ `invoice.payment_failed` - When invoice payment fails
- ✅ `invoice.voided` - When an invoice is voided
- ✅ `invoice.updated` - When an invoice is updated

### Customer Events:

- ✅ `customer.created` - When a customer is created
- ✅ `customer.updated` - When a customer is updated
- ✅ `customer.deleted` - When a customer is deleted

### Charge Events:

- ✅ `charge.succeeded` - When a charge succeeds
- ✅ `charge.failed` - When a charge fails
- ✅ `charge.refunded` - When a charge is refunded

### Stripe Connect Events (if using connected accounts):

- ✅ `account.updated` - When a connected account is updated
- ✅ `account.application.deauthorized` - When app is disconnected

### Payment Method Events:

- ✅ `payment_method.attached` - When payment method is attached to customer
- ✅ `payment_method.detached` - When payment method is removed

**Quick Selection Tips:**

- You can use the search bar to find specific events
- You can select categories (like "All payment_intent events")
- Start with the critical events above, you can add more later

---

## Step 4: Get Your Webhook Secret

After creating the webhook endpoint:

1. **Click on your newly created webhook** in the list
2. **Find "Signing secret"** section
3. **Click "Reveal"** or **"Click to reveal"** button
4. **Copy the secret** - It will look like: `whsec_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx`
5. **Save this securely** - You'll need to add it to your `.env` file

**Important**:

- Each webhook endpoint has its own signing secret
- Test mode and Live mode have different secrets
- Keep this secret secure (never commit to git)

---

## Step 5: Add Webhook Secret to Environment Variables

1. **Open your `.env` file** (or `.env.local` for local development)
2. **Add the webhook secret:**

```bash
# Stripe Webhook Secret (from Stripe Dashboard)
STRIPE_WEBHOOK_SECRET=whsec_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
```

3. **For production**, you may want separate variables:

```bash
# Test mode
STRIPE_WEBHOOK_SECRET=whsec_test_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx

# Live mode (production)
STRIPE_WEBHOOK_SECRET_LIVE=whsec_live_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
```

---

## Step 6: Test Your Webhook (Optional but Recommended)

Stripe provides a way to test webhooks:

1. **In the webhook details page**, click **"Send test webhook"**
2. **Select an event type** (e.g., `payment_intent.succeeded`)
3. **Click "Send test webhook"**
4. **Check your application logs** to see if the webhook was received

**Or use Stripe CLI** to forward to your deployed endpoint:

```bash
stripe listen --forward-to https://your-domain.com/api/stripe/webhook
```

---

## Step 7: Verify Webhook is Working

1. **Check webhook logs in Stripe Dashboard:**

   - Go to your webhook endpoint
   - Click on "Recent events" or "Logs"
   - You should see successful deliveries (200 status codes)

2. **Check your application:**
   - Look for webhook events being received
   - Check database for updated records
   - Verify logs show successful processing

---

## Troubleshooting

### Webhook Not Receiving Events

**Check:**

- ✅ Endpoint URL is correct and publicly accessible
- ✅ Your server is running and accessible
- ✅ Webhook secret is correctly set in `.env`
- ✅ Firewall/security groups allow Stripe IPs

**Stripe IP Ranges** (if you need to whitelist):

- See: https://stripe.com/docs/ips

### Webhook Returns 400/401 Errors

**Common causes:**

- ❌ Webhook secret mismatch (check `.env` file)
- ❌ Signature verification failing (check webhook handler code)
- ❌ Wrong API version in webhook handler

### Webhook Returns 500 Errors

**Common causes:**

- ❌ Database connection issues
- ❌ Missing environment variables
- ❌ Code errors in webhook handler
- ❌ Timeout (webhook handler taking too long)

**Solution**: Check your application logs for error details

---

## Setting Up Separate Webhooks for Test/Live Mode

### Option 1: Separate Endpoints (Recommended)

1. **Create two webhook endpoints:**

   - One in **Test mode** (for development/staging)
   - One in **Live mode** (for production)

2. **Use different URLs:**

   - Test: `https://staging.yourdomain.com/api/stripe/webhook`
   - Live: `https://yourdomain.com/api/stripe/webhook`

3. **Use different secrets:**
   - `STRIPE_WEBHOOK_SECRET` (test mode)
   - `STRIPE_WEBHOOK_SECRET_LIVE` (live mode)

### Option 2: Single Endpoint (Simpler)

1. **Create one webhook endpoint** in Test mode
2. **Use the same endpoint** for both test and live (Stripe will send events from both)
3. **Handle both in your code** by checking the event's `livemode` property

---

## Next Steps

Once your webhook is set up:

1. ✅ **Share the webhook secret** with me (or add to `.env`)
2. ✅ **Confirm the endpoint URL** you're using
3. ✅ **Let me know which events** you selected
4. ✅ I'll update the webhook handler to process all events and write to Supabase

---

## Quick Reference

### Local Testing:

```bash
# Terminal 1: Start your app
npm run dev

# Terminal 2: Forward webhooks
stripe listen --forward-to localhost:3000/api/stripe/webhook

# Terminal 3: Trigger test events
stripe trigger payment_intent.succeeded
```

**Local Webhook Secret:**

- Provided by Stripe CLI when you run `stripe listen`
- Add to `.env.local`: `STRIPE_WEBHOOK_SECRET=whsec_...`

### Production/Staging:

**Webhook Endpoint URL Format:**

```
https://your-domain.com/api/stripe/webhook
```

**Webhook Secret Format:**

```
whsec_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
```

**Environment Variable:**

```bash
STRIPE_WEBHOOK_SECRET=whsec_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
```

**Stripe Dashboard Location:**

```
Developers → Webhooks → Add endpoint
```

---

## 🔄 Switching Between Local and Production

### When Testing Locally:

1. Use Stripe CLI: `stripe listen --forward-to localhost:3000/api/stripe/webhook`
2. Use the webhook secret from CLI output
3. Set in `.env.local`: `STRIPE_WEBHOOK_SECRET=whsec_...` (from CLI)

### When Deploying to Staging/Production:

1. Create webhook endpoint in Stripe Dashboard
2. Use your deployed URL
3. Get webhook secret from Dashboard
4. Set in your deployment environment variables (Vercel, etc.)
5. Update `.env` or deployment config with production secret

**Note**: You can have both set up - use `.env.local` for local development and deployment environment variables for production.

---

## Need Help?

If you get stuck:

1. Check Stripe's official docs: https://stripe.com/docs/webhooks
2. Check webhook logs in Stripe Dashboard for error messages
3. Share any error messages you see and I can help troubleshoot
