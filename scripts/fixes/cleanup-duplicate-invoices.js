#!/usr/bin/env node

/**
 * Cleanup Duplicate Invoices Script
 * 
 * This script identifies and removes duplicate invoices created for the same appointment.
 * It keeps the oldest invoice and deletes the duplicates from both Parse and Stripe.
 * 
 * Usage:
 *   node scripts/cleanup-duplicate-invoices.js [--dry-run] [--appointment-id APPOINTMENT_ID]
 * 
 * Options:
 *   --dry-run         Show what would be deleted without actually deleting
 *   --appointment-id  Clean up invoices for specific appointment only
 */

require('dotenv').config({ path: '.env.local' });
const Parse = require('parse/node');
const Stripe = require('stripe');

// Initialize Parse
Parse.initialize(
  process.env.NEXT_PUBLIC_PARSE_APP_ID,
  process.env.NEXT_PUBLIC_PARSE_JS_KEY,
  process.env.PARSE_MASTER_KEY
);
Parse.serverURL = process.env.NEXT_PUBLIC_PARSE_SERVER_URL;

// Initialize Stripe
const stripe = new Stripe(process.env.STRIPE_SECRET_KEY, {
  apiVersion: '2024-06-20',
});

// Parse command line arguments
const args = process.argv.slice(2);
const isDryRun = args.includes('--dry-run');
const appointmentIdIndex = args.indexOf('--appointment-id');
const specificAppointmentId = appointmentIdIndex !== -1 ? args[appointmentIdIndex + 1] : null;

async function findDuplicateInvoices() {
  console.log('🔍 Searching for duplicate invoices...\n');

  const Invoice = Parse.Object.extend('Invoice');
  const query = new Parse.Query(Invoice);
  
  // If specific appointment ID provided, filter by it
  if (specificAppointmentId) {
    const Appointment = Parse.Object.extend('Appointment');
    const appointmentPointer = Appointment.createWithoutData(specificAppointmentId);
    query.equalTo('appointmentId', appointmentPointer);
    console.log(`🎯 Filtering by appointment: ${specificAppointmentId}\n`);
  }
  
  query.include(['appointmentId', 'patientId']);
  query.limit(1000);
  query.ascending('createdAt'); // Oldest first
  
  const allInvoices = await query.find({ useMasterKey: true });
  console.log(`📊 Found ${allInvoices.length} total invoices\n`);

  // Group invoices by appointmentId
  const invoicesByAppointment = {};
  
  for (const invoice of allInvoices) {
    const appointmentId = invoice.get('appointmentId')?.id;
    
    if (appointmentId) {
      if (!invoicesByAppointment[appointmentId]) {
        invoicesByAppointment[appointmentId] = [];
      }
      invoicesByAppointment[appointmentId].push(invoice);
    }
  }

  // Find appointments with multiple invoices
  const duplicates = {};
  
  for (const [appointmentId, invoices] of Object.entries(invoicesByAppointment)) {
    if (invoices.length > 1) {
      duplicates[appointmentId] = invoices;
    }
  }

  console.log(`⚠️  Found ${Object.keys(duplicates).length} appointments with duplicate invoices:\n`);

  return duplicates;
}

async function cleanupDuplicates(duplicates) {
  const deletedInvoices = [];
  const keptInvoices = [];
  const errors = [];

  for (const [appointmentId, invoices] of Object.entries(duplicates)) {
    console.log(`\n📋 Appointment: ${appointmentId} (${invoices.length} invoices)`);
    
    // Sort by createdAt (oldest first)
    invoices.sort((a, b) => a.createdAt - b.createdAt);
    
    // Keep the first (oldest) invoice
    const toKeep = invoices[0];
    const toDelete = invoices.slice(1);
    
    console.log(`  ✅ Keeping: ${toKeep.id} (created: ${toKeep.createdAt.toISOString()})`);
    console.log(`     Stripe ID: ${toKeep.get('stripeInvoiceId')}`);
    console.log(`     Total: $${(toKeep.get('total') / 100).toFixed(2)}`);
    console.log(`     Status: ${toKeep.get('status')}`);
    
    keptInvoices.push({
      parseId: toKeep.id,
      stripeId: toKeep.get('stripeInvoiceId'),
      appointmentId,
    });

    // Delete duplicates
    for (const duplicate of toDelete) {
      const stripeInvoiceId = duplicate.get('stripeInvoiceId');
      
      console.log(`\n  ❌ Deleting duplicate: ${duplicate.id} (created: ${duplicate.createdAt.toISOString()})`);
      console.log(`     Stripe ID: ${stripeInvoiceId}`);
      console.log(`     Total: $${(duplicate.get('total') / 100).toFixed(2)}`);
      console.log(`     Status: ${duplicate.get('status')}`);

      if (!isDryRun) {
        try {
          // Delete from Stripe first
          if (stripeInvoiceId) {
            console.log(`     🗑️  Deleting from Stripe...`);
            
            // Check Stripe invoice status
            const stripeInvoice = await stripe.invoices.retrieve(stripeInvoiceId);
            
            if (stripeInvoice.status === 'draft') {
              // Can delete draft invoices
              await stripe.invoices.del(stripeInvoiceId);
              console.log(`     ✅ Deleted from Stripe`);
            } else if (stripeInvoice.status === 'open') {
              // Must void open invoices before deleting
              await stripe.invoices.voidInvoice(stripeInvoiceId);
              console.log(`     ✅ Voided in Stripe (cannot delete open invoices)`);
            } else {
              console.log(`     ⚠️  Cannot void/delete invoice with status: ${stripeInvoice.status}`);
            }
          }

          // Delete from Parse
          console.log(`     🗑️  Deleting from Parse...`);
          await duplicate.destroy({ useMasterKey: true });
          console.log(`     ✅ Deleted from Parse`);

          deletedInvoices.push({
            parseId: duplicate.id,
            stripeId: stripeInvoiceId,
            appointmentId,
          });
        } catch (error) {
          console.error(`     ❌ Error deleting invoice:`, error.message);
          errors.push({
            parseId: duplicate.id,
            stripeId: stripeInvoiceId,
            error: error.message,
          });
        }
      } else {
        console.log(`     [DRY RUN] Would delete this invoice`);
      }
    }
  }

  return { deletedInvoices, keptInvoices, errors };
}

async function main() {
  console.log('╔════════════════════════════════════════════╗');
  console.log('║  Cleanup Duplicate Invoices Script        ║');
  console.log('╚════════════════════════════════════════════╝\n');

  if (isDryRun) {
    console.log('🔎 DRY RUN MODE - No changes will be made\n');
  }

  try {
    // Find duplicates
    const duplicates = await findDuplicateInvoices();

    if (Object.keys(duplicates).length === 0) {
      console.log('✨ No duplicate invoices found! Database is clean.\n');
      return;
    }

    // Show summary
    let totalDuplicates = 0;
    for (const invoices of Object.values(duplicates)) {
      totalDuplicates += invoices.length - 1; // -1 because we keep one
    }

    console.log(`\n📊 Summary:`);
    console.log(`   - Appointments with duplicates: ${Object.keys(duplicates).length}`);
    console.log(`   - Total duplicate invoices to delete: ${totalDuplicates}`);
    console.log(`   - Total invoices to keep: ${Object.keys(duplicates).length}\n`);

    if (isDryRun) {
      console.log('💡 Run without --dry-run to actually delete these invoices\n');
      return;
    }

    // Confirm before deleting
    console.log('⚠️  This will permanently delete duplicate invoices!\n');
    console.log('Press Ctrl+C to cancel, or wait 5 seconds to proceed...\n');
    
    await new Promise(resolve => setTimeout(resolve, 5000));

    // Cleanup duplicates
    const { deletedInvoices, keptInvoices, errors } = await cleanupDuplicates(duplicates);

    // Final summary
    console.log('\n\n╔════════════════════════════════════════════╗');
    console.log('║  Cleanup Complete!                         ║');
    console.log('╚════════════════════════════════════════════╝\n');

    console.log(`✅ Kept ${keptInvoices.length} invoices (one per appointment)`);
    console.log(`🗑️  Deleted ${deletedInvoices.length} duplicate invoices`);
    
    if (errors.length > 0) {
      console.log(`❌ Failed to delete ${errors.length} invoices:\n`);
      errors.forEach(err => {
        console.log(`   - Parse ID: ${err.parseId}`);
        console.log(`     Error: ${err.error}\n`);
      });
    }

  } catch (error) {
    console.error('\n❌ Script error:', error);
    console.error(error.stack);
    process.exit(1);
  }
}

main();

