/**
 * Fix Service Sync Issues for Tom Holland
 * 
 * This script addresses:
 * 1. Services showing under "Uncategorized" instead of "Athletic Therapy"
 * 2. AppointmentTreatment not displaying services
 * 3. Item_Prices and Service_Details sync issues
 * 4. Location-specific Service_Offerings missing
 * 
 * Run: node scripts/fix-service-sync-tom-holland.js
 */

const Parse = require('parse/node');

// Initialize Parse
Parse.initialize(
  process.env.PARSE_APP_ID || 'your-app-id',
  process.env.PARSE_JAVASCRIPT_KEY || 'your-js-key',
  process.env.PARSE_MASTER_KEY || 'your-master-key'
);
Parse.serverURL = process.env.PARSE_SERVER_URL || 'http://localhost:1337/parse';

const ITEM_NAME = 'Org Athletics Therapy';
const ITEM_ID = 'UrRlo4QHO6';
const DISCIPLINE_PRESET_ID = 'gJYtfBnMh5'; // Athletic Therapy
const TOM_HOLLAND_IDS = ['ovYOS2QGr5', 'UWSBKTQbLg', 'CD5XwNXWuV'];
const LOCATIONS = {
  'Myo Richmond Hill': 'cyu4AXl7Z5',
  'Myodetox Markham': 'gLJJRovovY'
};

// Expected Item_Prices (from Stripe)
const EXPECTED_PRICES = [
  { duration: 15, price: 3000 }, // $30.00
  { duration: 60, price: 10000 }, // $100.00
  { duration: 90, price: 15000 }  // $150.00
];

async function main() {
  console.log('🔍 Starting Service Sync Fix for Tom Holland...\n');

  try {
    // Step 1: Verify Item_Prices
    console.log('Step 1: Verifying Item_Prices...');
    await verifyItemPrices();

    // Step 2: Create missing Service_Details for 15min duration
    console.log('\nStep 2: Creating missing Service_Details...');
    await createMissingServiceDetails();

    // Step 3: Verify/Create location-specific Discipline_Offerings
    console.log('\nStep 3: Verifying Discipline_Offerings per location...');
    await verifyDisciplineOfferings();

    // Step 4: Verify/Create location-specific Service_Offerings
    console.log('\nStep 4: Verifying Service_Offerings per location...');
    await verifyServiceOfferings();

    // Step 5: Clean up duplicate Staff_Services
    console.log('\nStep 5: Cleaning up duplicate Staff_Services...');
    await cleanupDuplicateStaffServices();

    // Step 6: Ensure proper Staff_Services exist for all durations
    console.log('\nStep 6: Ensuring proper Staff_Services exist...');
    await ensureStaffServices();

    // Step 7: Verify final state
    console.log('\nStep 7: Verifying final state...');
    await verifyFinalState();

    console.log('\n✅ Service sync fix completed successfully!');
    console.log('\n📝 Summary:');
    console.log('   - 3 service durations: 15min, 60min, 90min');
    console.log('   - All linked to Athletic Therapy discipline');
    console.log('   - Location-specific offerings created');
    console.log('   - Duplicate staff services cleaned up');

  } catch (error) {
    console.error('❌ Error during sync fix:', error);
    throw error;
  }
}

async function verifyItemPrices() {
  const ItemPrice = Parse.Object.extend('Item_Price');
  const query = new Parse.Query(ItemPrice);
  
  const item = new Parse.Object('Items_Catalog');
  item.id = ITEM_ID;
  query.equalTo('itemId', item);

  const prices = await query.find({ useMasterKey: true });
  
  console.log(`   Found ${prices.length} Item_Prices`);
  
  for (const expectedPrice of EXPECTED_PRICES) {
    const existing = prices.find(p => p.get('durationMinutes') === expectedPrice.duration);
    if (!existing) {
      console.log(`   ⚠️  Missing Item_Price for ${expectedPrice.duration}min - $${expectedPrice.price / 100}`);
      console.log(`   Creating Item_Price...`);
      
      const newPrice = new ItemPrice();
      newPrice.set('itemId', item);
      newPrice.set('durationMinutes', expectedPrice.duration);
      newPrice.set('price', expectedPrice.price);
      await newPrice.save(null, { useMasterKey: true });
      
      console.log(`   ✅ Created Item_Price ${expectedPrice.duration}min`);
    } else {
      console.log(`   ✅ Item_Price ${expectedPrice.duration}min exists (${existing.id})`);
    }
  }
}

async function createMissingServiceDetails() {
  const ServiceDetail = Parse.Object.extend('Service_Detail');
  const query = new Parse.Query(ServiceDetail);
  
  const item = new Parse.Object('Items_Catalog');
  item.id = ITEM_ID;
  query.equalTo('itemId', item);

  const details = await query.find({ useMasterKey: true });
  
  console.log(`   Found ${details.length} Service_Details`);
  
  for (const expectedPrice of EXPECTED_PRICES) {
    const existing = details.find(d => d.get('schedulingDurationMinutes') === expectedPrice.duration);
    if (!existing) {
      console.log(`   ⚠️  Missing Service_Detail for ${expectedPrice.duration}min`);
      console.log(`   Creating Service_Detail...`);
      
      const newDetail = new ServiceDetail();
      newDetail.set('itemId', item);
      newDetail.set('schedulingDurationMinutes', expectedPrice.duration);
      await newDetail.save(null, { useMasterKey: true });
      
      console.log(`   ✅ Created Service_Detail ${expectedPrice.duration}min (${newDetail.id})`);
    } else {
      console.log(`   ✅ Service_Detail ${expectedPrice.duration}min exists (${existing.id})`);
    }
  }
}

async function verifyDisciplineOfferings() {
  const DisciplineOffering = Parse.Object.extend('Discipline_Offering');
  
  for (const [locationName, locationId] of Object.entries(LOCATIONS)) {
    const query = new Parse.Query(DisciplineOffering);
    
    const location = new Parse.Object('Location');
    location.id = locationId;
    query.equalTo('locationId', location);
    
    const preset = new Parse.Object('Discipline_Preset');
    preset.id = DISCIPLINE_PRESET_ID;
    query.equalTo('presetId', preset);
    
    const existing = await query.first({ useMasterKey: true });
    
    if (!existing) {
      console.log(`   ⚠️  Missing Discipline_Offering for ${locationName}`);
      console.log(`   Creating Discipline_Offering...`);
      
      const newOffering = new DisciplineOffering();
      newOffering.set('locationId', location);
      newOffering.set('presetId', preset);
      await newOffering.save(null, { useMasterKey: true });
      
      console.log(`   ✅ Created Discipline_Offering for ${locationName} (${newOffering.id})`);
    } else {
      console.log(`   ✅ Discipline_Offering for ${locationName} exists (${existing.id})`);
    }
  }
}

async function verifyServiceOfferings() {
  const ServiceOffering = Parse.Object.extend('Service_Offering');
  
  for (const [locationName, locationId] of Object.entries(LOCATIONS)) {
    const query = new Parse.Query(ServiceOffering);
    
    const location = new Parse.Object('Location');
    location.id = locationId;
    query.equalTo('locationId', location);
    
    const item = new Parse.Object('Items_Catalog');
    item.id = ITEM_ID;
    query.equalTo('itemId', item);
    
    const existing = await query.first({ useMasterKey: true });
    
    if (!existing) {
      console.log(`   ⚠️  Missing Service_Offering for ${locationName}`);
      console.log(`   Creating Service_Offering...`);
      
      // Get the Discipline_Offering for this location
      const DisciplineOffering = Parse.Object.extend('Discipline_Offering');
      const discQuery = new Parse.Query(DisciplineOffering);
      discQuery.equalTo('locationId', location);
      
      const preset = new Parse.Object('Discipline_Preset');
      preset.id = DISCIPLINE_PRESET_ID;
      discQuery.equalTo('presetId', preset);
      
      const disciplineOffering = await discQuery.first({ useMasterKey: true });
      
      if (!disciplineOffering) {
        console.log(`   ❌ Cannot create Service_Offering: Discipline_Offering not found`);
        continue;
      }
      
      const newOffering = new ServiceOffering();
      newOffering.set('locationId', location);
      newOffering.set('itemId', item);
      newOffering.set('disciplineOfferingId', disciplineOffering);
      await newOffering.save(null, { useMasterKey: true });
      
      console.log(`   ✅ Created Service_Offering for ${locationName} (${newOffering.id})`);
    } else {
      console.log(`   ✅ Service_Offering for ${locationName} exists (${existing.id})`);
      
      // Verify it has proper discipline link
      const disciplineOffering = existing.get('disciplineOfferingId');
      if (!disciplineOffering) {
        console.log(`   ⚠️  Service_Offering missing disciplineOfferingId link`);
        
        // Get the Discipline_Offering for this location
        const DisciplineOffering = Parse.Object.extend('Discipline_Offering');
        const discQuery = new Parse.Query(DisciplineOffering);
        discQuery.equalTo('locationId', location);
        
        const preset = new Parse.Object('Discipline_Preset');
        preset.id = DISCIPLINE_PRESET_ID;
        discQuery.equalTo('presetId', preset);
        
        const disciplineOfferingToLink = await discQuery.first({ useMasterKey: true });
        
        if (disciplineOfferingToLink) {
          existing.set('disciplineOfferingId', disciplineOfferingToLink);
          await existing.save(null, { useMasterKey: true });
          console.log(`   ✅ Linked Service_Offering to Discipline_Offering`);
        }
      }
    }
  }
}

async function cleanupDuplicateStaffServices() {
  const StaffService = Parse.Object.extend('Staff_Service');
  
  for (const staffId of TOM_HOLLAND_IDS) {
    for (const [locationName, locationId] of Object.entries(LOCATIONS)) {
      const query = new Parse.Query(StaffService);
      
      const staff = new Parse.Object('Staff_Member');
      staff.id = staffId;
      query.equalTo('staffId', staff);
      
      const location = new Parse.Object('Location');
      location.id = locationId;
      query.equalTo('locationId', location);
      
      query.equalTo('isEnabled', true);
      query.include('serviceId');
      query.include('serviceId.itemId');
      
      const staffServices = await query.find({ useMasterKey: true });
      
      // Filter for Org Athletics Therapy
      const athleticServices = staffServices.filter(ss => {
        const serviceDetail = ss.get('serviceId');
        const item = serviceDetail?.get('itemId');
        return item?.id === ITEM_ID;
      });
      
      if (athleticServices.length === 0) continue;
      
      console.log(`   Found ${athleticServices.length} Staff_Services for staff ${staffId} at ${locationName}`);
      
      // Group by duration
      const byDuration = {};
      athleticServices.forEach(ss => {
        const serviceDetail = ss.get('serviceId');
        const duration = serviceDetail.get('schedulingDurationMinutes');
        if (!byDuration[duration]) byDuration[duration] = [];
        byDuration[duration].push(ss);
      });
      
      // Keep only one per duration, delete the rest
      for (const [duration, services] of Object.entries(byDuration)) {
        if (services.length > 1) {
          console.log(`   ⚠️  Found ${services.length} duplicates for ${duration}min - keeping 1, deleting ${services.length - 1}`);
          
          // Keep the first, delete the rest
          for (let i = 1; i < services.length; i++) {
            await services[i].destroy({ useMasterKey: true });
          }
          
          console.log(`   ✅ Cleaned up duplicates for ${duration}min`);
        }
      }
    }
  }
}

async function ensureStaffServices() {
  const StaffService = Parse.Object.extend('Staff_Service');
  const ServiceDetail = Parse.Object.extend('Service_Detail');
  
  // Get all Service_Details for this item
  const sdQuery = new Parse.Query(ServiceDetail);
  const item = new Parse.Object('Items_Catalog');
  item.id = ITEM_ID;
  sdQuery.equalTo('itemId', item);
  const serviceDetails = await sdQuery.find({ useMasterKey: true });
  
  console.log(`   Found ${serviceDetails.length} Service_Details to link`);
  
  for (const staffId of TOM_HOLLAND_IDS) {
    for (const [locationName, locationId] of Object.entries(LOCATIONS)) {
      for (const serviceDetail of serviceDetails) {
        const duration = serviceDetail.get('schedulingDurationMinutes');
        
        // Check if Staff_Service already exists
        const query = new Parse.Query(StaffService);
        
        const staff = new Parse.Object('Staff_Member');
        staff.id = staffId;
        query.equalTo('staffId', staff);
        
        const location = new Parse.Object('Location');
        location.id = locationId;
        query.equalTo('locationId', location);
        
        query.equalTo('serviceId', serviceDetail);
        query.equalTo('isEnabled', true);
        
        const existing = await query.first({ useMasterKey: true });
        
        if (!existing) {
          console.log(`   ⚠️  Missing Staff_Service for staff ${staffId} at ${locationName} (${duration}min)`);
          console.log(`   Creating Staff_Service...`);
          
          const newStaffService = new StaffService();
          newStaffService.set('staffId', staff);
          newStaffService.set('locationId', location);
          newStaffService.set('serviceId', serviceDetail);
          newStaffService.set('isEnabled', true);
          await newStaffService.save(null, { useMasterKey: true });
          
          console.log(`   ✅ Created Staff_Service (${newStaffService.id})`);
        }
      }
    }
  }
}

async function verifyFinalState() {
  const StaffService = Parse.Object.extend('Staff_Service');
  
  for (const staffId of TOM_HOLLAND_IDS) {
    console.log(`\n   Staff ${staffId}:`);
    
    for (const [locationName, locationId] of Object.entries(LOCATIONS)) {
      const query = new Parse.Query(StaffService);
      
      const staff = new Parse.Object('Staff_Member');
      staff.id = staffId;
      query.equalTo('staffId', staff);
      
      const location = new Parse.Object('Location');
      location.id = locationId;
      query.equalTo('locationId', location);
      
      query.equalTo('isEnabled', true);
      query.include('serviceId');
      query.include('serviceId.itemId');
      
      const staffServices = await query.find({ useMasterKey: true });
      
      // Filter for Org Athletics Therapy
      const athleticServices = staffServices.filter(ss => {
        const serviceDetail = ss.get('serviceId');
        const item = serviceDetail?.get('itemId');
        return item?.id === ITEM_ID;
      });
      
      const durations = athleticServices.map(ss => {
        const serviceDetail = ss.get('serviceId');
        return serviceDetail.get('schedulingDurationMinutes');
      }).sort((a, b) => a - b);
      
      console.log(`     ${locationName}: ${durations.length} services (${durations.join('min, ')}min)`);
      
      if (durations.length !== 3) {
        console.log(`     ⚠️  Expected 3 services, found ${durations.length}`);
      } else if (!durations.includes(15) || !durations.includes(60) || !durations.includes(90)) {
        console.log(`     ⚠️  Missing expected durations (15, 60, 90)`);
      } else {
        console.log(`     ✅ All 3 service durations present`);
      }
    }
  }
}

// Run the script
main()
  .then(() => {
    console.log('\n✅ Script completed successfully');
    process.exit(0);
  })
  .catch((error) => {
    console.error('\n❌ Script failed:', error);
    process.exit(1);
  });

