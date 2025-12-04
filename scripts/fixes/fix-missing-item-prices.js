// Fix appointments with missing itemPriceId
// This script links appointments to their appropriate item prices

require('dotenv').config();
const Parse = require('parse/node');

// Initialize Parse
Parse.initialize(
  process.env.NEXT_PUBLIC_PARSE_APP_ID,
  process.env.PARSE_JAVASCRIPT_KEY,
  process.env.NEXT_PUBLIC_PARSE_MASTER_KEY
);
Parse.serverURL = process.env.NEXT_PUBLIC_PARSE_SERVER_URL;

async function fixMissingItemPrices() {
  console.log('🔍 Finding appointments with missing itemPriceId...\n');

  try {
    // Query appointments without itemPriceId
    const appointmentQuery = new Parse.Query('Appointment');
    appointmentQuery.doesNotExist('itemPriceId');
    appointmentQuery.include('serviceOfferingId');
    appointmentQuery.include('serviceOfferingId.itemId');
    appointmentQuery.limit(1000);

    const appointments = await appointmentQuery.find({ useMasterKey: true });
    console.log(`Found ${appointments.length} appointments without itemPriceId\n`);

    if (appointments.length === 0) {
      console.log('✅ No appointments need fixing!');
      return;
    }

    // Group appointments by itemId to batch process
    const appointmentsByItem = {};
    for (const appointment of appointments) {
      const serviceOffering = appointment.get('serviceOfferingId');
      if (!serviceOffering) {
        console.log(`⚠️  Appointment ${appointment.id} has no service offering, skipping`);
        continue;
      }

      const item = serviceOffering.get('itemId');
      if (!item) {
        console.log(`⚠️  Service offering ${serviceOffering.id} has no item, skipping`);
        continue;
      }

      const itemId = item.id;
      if (!appointmentsByItem[itemId]) {
        appointmentsByItem[itemId] = [];
      }
      appointmentsByItem[itemId].push({
        appointment,
        itemName: item.get('itemName'),
      });
    }

    console.log(`📦 Processing ${Object.keys(appointmentsByItem).length} unique items\n`);

    // For each item, find or create a default price and update appointments
    let totalUpdated = 0;
    for (const [itemId, appointmentList] of Object.entries(appointmentsByItem)) {
      const {itemName} = appointmentList[0];
      console.log(`\n📝 Processing item: ${itemName} (${appointmentList.length} appointments)`);

      // Find existing item prices for this item (prefer 60-minute duration)
      const itemPriceQuery = new Parse.Query('Item_Price');
      itemPriceQuery.equalTo('itemId', Parse.Object.extend('Items_Catalog').createWithoutData(itemId));
      itemPriceQuery.ascending('durationMinutes'); // Prefer shorter duration
      itemPriceQuery.limit(1);

      const itemPrice = await itemPriceQuery.first({ useMasterKey: true });

      if (!itemPrice) {
        console.log(`   ⚠️  No item price found for ${itemName}, skipping these appointments`);
        continue;
      }

      console.log(
        `   💰 Using price: $${(itemPrice.get('price') / 100).toFixed(2)} for ${itemPrice.get('durationMinutes')} minutes`
      );

      // Update all appointments for this item
      const updatePromises = appointmentList.map(async ({ appointment }) => {
        try {
          appointment.set('itemPriceId', itemPrice);
          await appointment.save(null, { useMasterKey: true });
          return { success: true, id: appointment.id };
        } catch (error) {
          console.error(`   ❌ Failed to update appointment ${appointment.id}: ${error.message}`);
          return { success: false, id: appointment.id, error: error.message };
        }
      });

      const results = await Promise.all(updatePromises);
      const successCount = results.filter((r) => r.success).length;
      totalUpdated += successCount;

      console.log(`   ✅ Updated ${successCount}/${appointmentList.length} appointments`);
    }

    console.log(`\n🎉 Successfully updated ${totalUpdated}/${appointments.length} appointments!`);
  } catch (error) {
    console.error('❌ Error:', error);
    throw error;
  }
}

// Run the script
fixMissingItemPrices()
  .then(() => {
    console.log('\n✨ Done!');
    process.exit(0);
  })
  .catch((error) => {
    console.error('\n💥 Script failed:', error);
    process.exit(1);
  });
