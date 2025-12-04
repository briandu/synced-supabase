# Phase 7: Stripe Integration - Requirements Checklist

This document outlines what you need to provide to complete the Stripe integration migration to Supabase.

## ✅ Already Have (from requirements doc)

- ✅ Stripe test secret key (`STRIPE_SECRET_KEY_TEST`)
- ✅ Stripe test publishable key (`STRIPE_PUBLISHABLE_KEY_TEST`)
- ✅ One connected account ID: `acct_1SUXDfELvDuwsVEt`

## 🔴 Required Information

### 1. Stripe Live Keys (for production)

**Action Required:**
- [ ] Get Stripe live secret key from Stripe Dashboard → Developers → API keys → Live mode
- [ ] Get Stripe live publishable key from Stripe Dashboard → Developers → API keys → Live mode
- [ ] Add to `.env` as:
  - `STRIPE_SECRET_KEY` (or `STRIPE_SECRET_KEY_LIVE`)
  - `STRIPE_PUBLISHABLE_KEY` (or `STRIPE_PUBLISHABLE_KEY_LIVE`)

**Note:** Only needed for production deployment. We can use test keys for development/staging.

---

### 2. Stripe Webhook Configuration

**Action Required:**
- [ ] Go to Stripe Dashboard → Developers → Webhooks
- [ ] Create a new webhook endpoint (or update existing):
  - **Endpoint URL:** `https://your-domain.com/api/stripe/webhook`
    - Staging: `https://synced-admin-portal.vercel.app/api/stripe/webhook` (or your staging URL)
    - Production: `https://your-production-domain.com/api/stripe/webhook`
- [ ] Select events to listen to (see "Webhook Events Needed" section below)
- [ ] Copy the webhook signing secret (starts with `whsec_...`)
- [ ] Add to `.env` as:
  - `STRIPE_WEBHOOK_SECRET` (for test mode)
  - `STRIPE_WEBHOOK_SECRET_LIVE` (for production, if different)

**Webhook Events Needed:**
- `payment_intent.succeeded`
- `payment_intent.payment_failed`
- `payment_intent.canceled`
- `setup_intent.succeeded`
- `setup_intent.setup_failed`
- `customer.created`
- `customer.updated`
- `customer.deleted`
- `invoice.created`
- `invoice.finalized`
- `invoice.paid`
- `invoice.payment_failed`
- `invoice.voided`
- `charge.succeeded`
- `charge.failed`
- `account.updated` (for Stripe Connect)
- `account.application.deauthorized` (for Stripe Connect)

---

### 3. All Stripe Connected Account IDs

**Action Required:**
- [ ] Query Parse Server to get all `stripeConnectedAccountId` values from the `Location` table
- [ ] Provide a list of all connected account IDs (format: `acct_xxxxx`)
- [ ] Confirm which locations/orgs have connected accounts

**Why:** We need to preserve these in Supabase `locations` table during migration.

**Parse Query Example:**
```javascript
// In Parse Dashboard or via API
const query = new Parse.Query("Location");
query.exists("stripeConnectedAccountId");
const locations = await query.find();
const accountIds = locations.map(loc => loc.get("stripeConnectedAccountId"));
```

---

### 4. Current Stripe Integration Status

**Action Required:**
- [ ] Confirm which Stripe features are currently in use:
  - [ ] Payment processing (charges)
  - [ ] Saved payment methods
  - [ ] Invoices
  - [ ] Subscriptions (if any)
  - [ ] Stripe Connect (connected accounts)
  - [ ] Stripe Tax (if enabled)
  - [ ] Stripe Terminal (if used)
- [ ] List any custom Stripe integrations or workflows

---

### 5. Environment Variables Check

**Action Required:**
- [ ] Verify these environment variables are set in your `.env`:
  - `STRIPE_SECRET_KEY` or `STRIPE_SECRET_KEY_TEST` ✅ (already have)
  - `STRIPE_PUBLISHABLE_KEY` or `STRIPE_PUBLISHABLE_KEY_TEST` ✅ (already have)
  - `STRIPE_WEBHOOK_SECRET` ❌ (need to add)
  - `STRIPE_SECRET_KEY_LIVE` ❌ (optional, for production)
  - `STRIPE_PUBLISHABLE_KEY_LIVE` ❌ (optional, for production)
  - `STRIPE_WEBHOOK_SECRET_LIVE` ❌ (optional, for production)

---

### 6. Database Schema Verification

**Action Required:**
- [ ] Confirm Supabase tables have Stripe-related columns:
  - `patients.stripe_customer_id` ✅ (should exist)
  - `locations.stripe_connected_account_id` ✅ (should exist)
  - `items_catalog.stripe_product_id` ✅ (should exist)
  - `item_prices.stripe_price_id` ✅ (should exist)
  - `invoices.stripe_invoice_id` ❓ (need to verify)
  - `payments.stripe_payment_intent_id` ❓ (need to verify)
  - `payment_methods.stripe_payment_method_id` ❓ (need to verify)

**Note:** I'll verify these exist in the schema and add any missing columns.

---

### 7. Webhook Endpoint URLs

**Action Required:**
- [ ] Provide your deployment URLs:
  - **Staging:** `https://synced-admin-portal.vercel.app` (or your staging URL)
  - **Production:** `https://your-production-domain.com` (or confirm if same as staging)
- [ ] Confirm webhook endpoint path: `/api/stripe/webhook`

---

## 📋 What I'll Do Once You Provide This

1. **Update webhook handler** (`src/app/api/stripe/webhook/route.js`):
   - Handle all Stripe events
   - Write events to Supabase tables
   - Emit Realtime notifications
   - Update payment/invoice statuses

2. **Verify/Add Stripe columns** in Supabase tables:
   - Check existing columns
   - Add missing columns if needed
   - Create indexes for Stripe ID lookups

3. **Update Stripe API routes** to use Supabase:
   - Ensure all routes read/write to Supabase
   - Add proper error handling
   - Add logging/audit trails

4. **Create webhook event handlers**:
   - Payment intent events
   - Invoice events
   - Customer events
   - Connected account events

5. **Add Realtime subscriptions** for Stripe events:
   - Notify frontend of payment status changes
   - Update UI in real-time

6. **Update tests** to use Supabase mocks

---

## 🚀 Quick Start Checklist

**Minimum Required to Start:**
1. ✅ Stripe test keys (already have)
2. ❌ Webhook secret (need from Stripe Dashboard)
3. ❌ List of all connected account IDs (need from Parse)
4. ✅ Deployment URLs (can use staging URL)

**For Production:**
5. ❌ Stripe live keys
6. ❌ Production webhook secret
7. ❌ Production deployment URL

---

## 📝 Notes

- **Test Mode:** We can start with test mode webhooks and keys
- **Staging First:** Configure webhooks for staging first, then production
- **Incremental:** We can migrate webhook handlers incrementally (start with critical events)
- **Backward Compatible:** Existing Stripe integrations will continue to work during migration

---

## ❓ Questions?

If you're unsure about any of these items, let me know and I can:
- Help you find the information in Stripe Dashboard
- Provide Parse queries to extract connected account IDs
- Set up test webhooks first before production
- Work with test mode only initially

