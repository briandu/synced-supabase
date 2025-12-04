# Stripe Webhook Implementation - Complete

## ✅ What's Been Implemented

### 1. Comprehensive Webhook Handler
**File:** `src/app/api/stripe/webhook/route.js`

The webhook handler now processes all critical Stripe events and writes to Supabase:

#### Payment Intent Events:
- ✅ `payment_intent.succeeded` - Updates payment status, invoice status
- ✅ `payment_intent.payment_failed` - Updates payment status to failed
- ✅ `payment_intent.canceled` - Updates payment status to canceled

#### Setup Intent Events:
- ✅ `setup_intent.succeeded` - Saves payment methods to Supabase, updates customer default
- ✅ `setup_intent.setup_failed` - Logs failures

#### Invoice Events:
- ✅ `invoice.created` - Syncs Stripe invoice ID
- ✅ `invoice.finalized` - Updates invoice status to finalized
- ✅ `invoice.paid` - Updates invoice status to paid, clears balance
- ✅ `invoice.payment_failed` - Updates invoice status to payment_failed
- ✅ `invoice.voided` - Updates invoice status to voided
- ✅ `invoice.updated` - Syncs invoice amounts and balance

#### Customer Events:
- ✅ `customer.created` - Links Stripe customer to patient
- ✅ `customer.updated` - Syncs customer updates
- ✅ `customer.deleted` - Clears Stripe customer ID from patient

#### Charge Events:
- ✅ `charge.succeeded` - Updates payment with charge ID
- ✅ `charge.failed` - Updates payment status
- ✅ `charge.refunded` - Updates payment status to refunded

#### Payment Method Events:
- ✅ `payment_method.attached` - Logs attachment
- ✅ `payment_method.detached` - Removes payment method from Supabase

#### Stripe Connect Events:
- ✅ `account.updated` - Syncs connected account info to locations/orgs
- ✅ `account.application.deauthorized` - Clears connected account ID

### 2. Database Schema Updates
**Migration:** `20251202100000_add_stripe_customer_id_to_patients.sql`

- ✅ Added `stripe_customer_id` column to `patients` table
- ✅ Added index for faster lookups
- ✅ Added documentation comment

### 3. Existing Stripe Columns Verified
The following Stripe-related columns already exist in Supabase:
- ✅ `patients.stripe_customer_id` (just added)
- ✅ `locations.stripe_connected_account_id`
- ✅ `orgs.stripe_connected_account_id`
- ✅ `invoices.stripe_invoice_id`
- ✅ `payments.stripe_payment_intent_id`
- ✅ `payments.stripe_charge_id`
- ✅ `payment_methods.stripe_payment_method_id`
- ✅ `items_catalog.stripe_product_id`
- ✅ `invoice_items.stripe_price_id`

---

## 🔧 Configuration Required

### Environment Variables

Make sure these are set in your `.env` or deployment environment:

```bash
# Stripe API Keys
STRIPE_SECRET_KEY=sk_test_... # or STRIPE_SECRET_KEY_TEST
STRIPE_PUBLISHABLE_KEY=pk_test_... # or STRIPE_PUBLISHABLE_KEY_TEST

# Stripe Webhook Secret (from Stripe Dashboard)
STRIPE_WEBHOOK_SECRET=whsec_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx

# Supabase (for webhook handler)
NEXT_PUBLIC_SUPABASE_URL=https://your-project.supabase.co
SUPABASE_SERVICE_ROLE_KEY=your-service-role-key
```

---

## 📋 Webhook Setup Checklist

### In Stripe Dashboard:
- [x] Webhook endpoint created
- [x] Webhook secret obtained
- [ ] Events selected (see list below)
- [ ] Webhook secret added to environment variables

### Events to Select in Stripe Dashboard:

**Critical Events:**
- `payment_intent.succeeded`
- `payment_intent.payment_failed`
- `payment_intent.canceled`
- `setup_intent.succeeded`
- `setup_intent.setup_failed`

**Invoice Events:**
- `invoice.created`
- `invoice.finalized`
- `invoice.paid`
- `invoice.payment_failed`
- `invoice.voided`
- `invoice.updated`

**Customer Events:**
- `customer.created`
- `customer.updated`
- `customer.deleted`

**Charge Events:**
- `charge.succeeded`
- `charge.failed`
- `charge.refunded`

**Payment Method Events:**
- `payment_method.attached`
- `payment_method.detached`

**Stripe Connect Events (if using):**
- `account.updated`
- `account.application.deauthorized`

---

## 🧪 Testing

### Test Webhook Locally:
1. Install Stripe CLI: `brew install stripe/stripe-cli/stripe`
2. Login: `stripe login`
3. Forward webhooks: `stripe listen --forward-to localhost:3000/api/stripe/webhook`
4. Copy webhook secret from CLI output
5. Add to `.env.local`: `STRIPE_WEBHOOK_SECRET=whsec_...`
6. Trigger test events:
   ```bash
   stripe trigger payment_intent.succeeded
   stripe trigger invoice.paid
   stripe trigger setup_intent.succeeded
   ```

### Test Webhook in Staging/Production:
1. Create webhook endpoint in Stripe Dashboard
2. Point to: `https://your-domain.com/api/stripe/webhook`
3. Select events (see list above)
4. Copy webhook secret
5. Add to deployment environment variables
6. Test by triggering events or making real payments

---

## 📊 What Gets Updated in Supabase

### When Payment Succeeds:
- `payments` table: status → 'succeeded', stripe_payment_intent_id, stripe_charge_id
- `invoices` table: status → 'paid', balance_cents → 0 (if linked via metadata)

### When Payment Method is Saved:
- `payment_methods` table: New record with card details
- Stripe customer: Default payment method updated

### When Invoice is Paid:
- `invoices` table: status → 'paid', balance_cents → 0

### When Customer is Created:
- `patients` table: stripe_customer_id populated (if metadata.patient_id exists)

### When Connected Account Updates:
- `locations` or `orgs` table: stripe_connected_account_id synced

---

## 🔍 Monitoring & Debugging

### Check Webhook Logs:
1. **Stripe Dashboard**: Developers → Webhooks → Your endpoint → Recent events
2. **Application Logs**: Check server logs for webhook processing
3. **Supabase Logs**: Check database for updated records

### Common Issues:

**Webhook Not Receiving Events:**
- ✅ Check endpoint URL is correct
- ✅ Verify webhook secret matches
- ✅ Check Stripe Dashboard webhook logs for delivery status

**Events Not Updating Database:**
- ✅ Check Supabase service role key is set
- ✅ Verify RLS policies allow service role access
- ✅ Check application logs for errors

**Signature Verification Failing:**
- ✅ Verify `STRIPE_WEBHOOK_SECRET` is correct
- ✅ Check webhook secret matches the endpoint
- ✅ Ensure payload is not modified before verification

---

## 🚀 Next Steps

1. **Test the webhook** with Stripe CLI or Dashboard test events
2. **Monitor webhook deliveries** in Stripe Dashboard
3. **Verify database updates** after test events
4. **Add Realtime notifications** (optional) - notify frontend of payment status changes
5. **Add error handling/retry logic** (optional) - for failed webhook processing

---

## 📝 Notes

- The webhook handler uses Supabase service role client (bypasses RLS)
- All updates are idempotent (safe to retry)
- Errors are logged but don't fail the webhook (returns 200 to Stripe)
- Metadata from Stripe objects (like `patient_id`, `invoice_id`) is used to link records
- The handler gracefully handles missing records (won't fail if payment/invoice doesn't exist yet)

---

## ✅ Status

**Webhook Handler:** ✅ Complete and ready for testing
**Database Schema:** ✅ All Stripe columns in place
**Event Processing:** ✅ All critical events handled
**Error Handling:** ✅ Comprehensive error logging

**Ready for:** Testing and production deployment

