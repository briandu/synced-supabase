#!/usr/bin/env node

/**
 * Synchronize Stripe invoices into the Invoice table.
 *
 * Usage examples:
 *   node scripts/sync-stripe-invoices.js
 *   node scripts/sync-stripe-invoices.js --patientId=90
 *   node scripts/sync-stripe-invoices.js --patientId=90 --customerId=cus_123
 *
 * Environment variables required:
 *   STRIPE_SECRET_KEY
 *   DB_HOST, DB_PORT, DB_NAME, DB_USER, DB_PASSWORD
 *   DB_SSL (optional, set to "true" to enable)
 *
 * Notes:
 *   - Amounts are stored in cents.
 *   - Invoice table uses Parse-compatible fields for ACL/permissions.
 */

const path = require('path');
const dotenv = require('dotenv');
const Stripe = require('stripe');
const { Client } = require('pg');

const SCRIPT_ID = 'scripts/sync-stripe-invoices';
function mapInvoiceStatus(stripeStatus, amountDue, amountRemaining, metadata = {}) {
  if (metadata.noCharge || amountDue === 0) return 'no_charge';
  if (stripeStatus === 'paid') return 'paid';
  if (metadata.insuranceRejected) return 'rejected';
  if (metadata.submittedToInsurance) return 'submitted';
  if (stripeStatus === 'open') return 'submitted';
  return 'no_charge';
}

function loadEnvFiles() {
  const envFiles = [
    { filename: '.env', options: {} },
    { filename: '.env.local', options: { override: true } },
  ];

  envFiles.forEach(({ filename, options }) => {
    const envPath = path.resolve(process.cwd(), filename);
    const result = dotenv.config({ path: envPath, ...options });
    if (result.error && result.error.code !== 'ENOENT') {
      console.warn(`[${SCRIPT_ID}] Warning: unable to load ${filename}: ${result.error.message}`);
    }
  });
}

loadEnvFiles();

function generateObjectId() {
  const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
  let result = '';
  for (let i = 0; i < 10; i += 1) {
    result += chars.charAt(Math.floor(Math.random() * chars.length));
  }
  return result;
}

function parseArgs() {
  const args = process.argv.slice(2);
  return args.reduce(
    (acc, arg) => {
      if (arg.startsWith('--patientId=')) {
        acc.patientId = arg.split('=')[1];
      } else if (arg.startsWith('--customerId=')) {
        acc.customerId = arg.split('=')[1];
      } else if (arg === '--dry-run') {
        acc.dryRun = true;
      } else if (arg.startsWith('--limit=')) {
        const value = Number.parseInt(arg.split('=')[1], 10);
        if (!Number.isNaN(value) && value > 0) {
          acc.limit = value;
        }
      }
      return acc;
    },
    {
      dryRun: false,
      limit: undefined,
    }
  );
}

function getStripeClient() {
  const apiKey = process.env.STRIPE_SECRET_KEY;
  if (!apiKey) {
    console.error(`[${SCRIPT_ID}] STRIPE_SECRET_KEY is not configured.`);
    process.exit(1);
  }
  return new Stripe(apiKey, { apiVersion: '2024-06-20' });
}

function getDbConfig() {
  const required = ['DB_HOST', 'DB_PORT', 'DB_NAME', 'DB_USER', 'DB_PASSWORD'];
  const missing = required.filter((key) => !process.env[key]);
  if (missing.length > 0) {
    console.error(`[${SCRIPT_ID}] Missing database environment variables: ${missing.join(', ')}`);
    process.exit(1);
  }

  const baseConfig = {
    host: process.env.DB_HOST,
    port: Number.parseInt(process.env.DB_PORT, 10),
    database: process.env.DB_NAME,
    user: process.env.DB_USER,
    password: process.env.DB_PASSWORD,
    application_name: SCRIPT_ID,
  };

  if (process.env.DB_SSL === 'true') {
    baseConfig.ssl = {
      rejectUnauthorized: false,
    };
  }

  return baseConfig;
}

async function getDbClient() {
  const client = new Client(getDbConfig());
  await client.connect();
  return client;
}

async function linkPatientToCustomer(client, patientId, customerId) {
  if (!patientId || !customerId) return;
  const { rowCount } = await client.query('UPDATE "Patient" SET "stripeCustomerId" = $1 WHERE "objectId" = $2', [
    customerId,
    patientId,
  ]);
  if (rowCount === 0) {
    console.warn(`[${SCRIPT_ID}] Patient ${patientId} not found while attempting to set stripeCustomerId.`);
  } else {
    console.log(`[${SCRIPT_ID}] ✓ Linked patient ${patientId} to Stripe customer ${customerId}`);
  }
}

async function fetchPatients(client, patientId) {
  const params = [];
  let query = `
    SELECT "objectId", "firstName", "lastName", "email", "stripeCustomerId"
    FROM "Patient"
    WHERE "stripeCustomerId" IS NOT NULL
  `;

  if (patientId) {
    query += ' AND "objectId" = $1';
    params.push(patientId);
  }

  query += ' ORDER BY "objectId"';

  const { rows } = await client.query(query, params);
  if (!rows.length && patientId) {
    console.warn(
      `[${SCRIPT_ID}] No patient found with both objectId=${patientId} and stripeCustomerId. Did you set the customer mapping?`
    );
  }
  return rows;
}

async function listAllInvoices(stripe, customerId, limit) {
  const invoices = [];
  let startingAfter;
  let remaining = limit ?? Number.POSITIVE_INFINITY;

  while (remaining > 0) {
    const pageLimit = remaining === Number.POSITIVE_INFINITY ? 100 : Math.min(remaining, 100);
    const response = await stripe.invoices.list({
      customer: customerId,
      limit: pageLimit,
      starting_after: startingAfter,
      expand: ['data.payment_intent', 'data.lines'],
    });

    invoices.push(...response.data);

    if (!response.has_more || response.data.length === 0) {
      break;
    }

    remaining -= response.data.length;
    startingAfter = response.data[response.data.length - 1].id;
  }

  return invoices;
}

function buildInvoiceRecord(patient, invoice) {
  const firstLine = invoice.lines?.data?.[0];
  const metadata = invoice.metadata || {};
  const createdAt = invoice.created ? new Date(invoice.created * 1000) : null;
  const invoiceDate = invoice.status_transitions?.finalized_at
    ? new Date(invoice.status_transitions.finalized_at * 1000)
    : createdAt;
  const dueDate = invoice.due_date ? new Date(invoice.due_date * 1000) : null;

  return {
    objectId: generateObjectId(),
    patientId: patient.objectId,
    patientPointer: `Patient$${patient.objectId}`,
    patientNameSnapshot: `${patient.firstName || ''} ${patient.lastName || ''}`.trim(),
    stripeCustomerId: invoice.customer,
    stripeInvoiceId: invoice.id,
    stripePaymentIntentId: invoice.payment_intent?.id || invoice.payment_intent || null,
    status: mapInvoiceStatus(invoice.status, invoice.amount_due, invoice.amount_remaining, metadata),
    stripeStatus: invoice.status,
    amountDue: invoice.amount_due,
    amountPaid: invoice.amount_paid,
    amountRemaining: invoice.amount_remaining,
    currency: invoice.currency,
    invoiceNumber: invoice.number,
    insurerInvoiceNumber: metadata.insurerInvoiceNumber || null,
    serviceDescription: firstLine?.description || metadata.serviceName || null,
    staffMember: metadata.staffMember || null,
    receiptUrl: invoice.hosted_invoice_url || invoice.invoice_pdf || null,
    invoiceDate,
    invoiceCreatedAt: createdAt,
    dueDate,
    metadata,
    stripeData: invoice,
  };
}

async function upsertInvoice(client, record, syncedBy) {
  const existing = await client.query(
    'SELECT "objectId" FROM "Invoice" WHERE "stripeInvoiceId" = $1 AND "stripeInvoiceId" IS NOT NULL',
    [record.stripeInvoiceId]
  );

  const objectId = existing.rows[0]?.objectId || record.objectId;
  const permissionsRead = ['role:Admin', 'role:Staff'];
  const permissionsWrite = ['role:Admin'];

  if (existing.rows.length > 0) {
    // Update existing invoice
    const updateQuery = `
      UPDATE "Invoice" SET
        "updatedAt" = NOW(),
        "status" = $1,
        "total" = $2,
        "amountPaid" = $3,
        "balance" = $4,
        "dateBilled" = $5,
        "updatedBy" = $6
      WHERE "objectId" = $7
    `;

    const updateValues = [
      record.status,
      record.amountDue,
      record.amountPaid,
      record.amountRemaining,
      record.invoiceDate,
      syncedBy,
      objectId,
    ];

    await client.query(updateQuery, updateValues);
  } else {
    // Insert new invoice
    const insertQuery = `
      INSERT INTO "Invoice" (
        "objectId", "createdAt", "updatedAt", "_rperm", "_wperm",
        "patientId", "stripeInvoiceId", "status",
        "total", "amountPaid", "balance",
        "dateBilled", "updatedBy"
      )
      VALUES (
        $1, NOW(), NOW(), $2, $3,
        $4, $5, $6,
        $7, $8, $9,
        $10, $11
      )
    `;

    const insertValues = [
      objectId,
      permissionsRead,
      permissionsWrite,
      record.patientId,
      record.stripeInvoiceId,
      record.status,
      record.amountDue,
      record.amountPaid,
      record.amountRemaining,
      record.invoiceDate,
      syncedBy,
    ];

    await client.query(insertQuery, insertValues);
  }

  return {
    objectId,
    isUpdate: Boolean(existing.rows[0]),
  };
}

async function main() {
  const options = parseArgs();
  const stripe = getStripeClient();
  const client = await getDbClient();

  const syncedBy = SCRIPT_ID;
  const summary = {
    totalPatients: 0,
    invoicesFetched: 0,
    invoicesInserted: 0,
    invoicesUpdated: 0,
    skippedPatients: 0,
  };

  try {
    if (options.patientId && options.customerId) {
      await linkPatientToCustomer(client, options.patientId, options.customerId);
    }

    const patients = await fetchPatients(client, options.patientId);
    summary.totalPatients = patients.length;

    for (const patient of patients) {
      console.log(`\n[${SCRIPT_ID}] Patient ${patient.objectId} (${patient.firstName} ${patient.lastName})`);

      if (!patient.stripeCustomerId) {
        console.warn(`[${SCRIPT_ID}]  ↺ No stripeCustomerId, skipping.`);
        summary.skippedPatients += 1;
        continue;
      }

      const invoices = await listAllInvoices(stripe, patient.stripeCustomerId, options.limit);
      console.log(`[${SCRIPT_ID}]  ⇢ Retrieved ${invoices.length} invoice(s) from Stripe.`);
      summary.invoicesFetched += invoices.length;

      for (const invoice of invoices) {
        const record = buildInvoiceRecord(patient, invoice);

        if (options.dryRun) {
          console.log(
            `[${SCRIPT_ID}]     • DRY RUN: Would upsert invoice ${record.stripeInvoiceId} [${record.status}] (${record.serviceDescription || 'Service'})`
          );
          continue;
        }

        const { isUpdate } = await upsertInvoice(client, record, syncedBy);
        if (isUpdate) {
          summary.invoicesUpdated += 1;
        } else {
          summary.invoicesInserted += 1;
        }
      }
    }

    console.log('\n============================================================');
    console.log('Sync Summary');
    console.log('============================================================');
    console.log(`Patients processed: ${summary.totalPatients}`);
    console.log(`Invoices fetched:   ${summary.invoicesFetched}`);
    console.log(`Inserted:           ${summary.invoicesInserted}`);
    console.log(`Updated:            ${summary.invoicesUpdated}`);
    console.log(`Patients skipped:   ${summary.skippedPatients}`);
    console.log('============================================================');
  } catch (error) {
    console.error(`[${SCRIPT_ID}] ✗ Error:`, error);
    process.exitCode = 1;
  } finally {
    await client.end();
  }
}

main();
