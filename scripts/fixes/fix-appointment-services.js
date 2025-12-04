import fs from 'fs';
import Parse from 'parse/node.js';
import path from 'path';

function loadParseEnv() {
  const env = {
    PARSE_SERVER_URL: process.env.PARSE_SERVER_URL,
    PARSE_APP_ID: process.env.PARSE_APP_ID,
    PARSE_MASTER_KEY: process.env.PARSE_MASTER_KEY,
  };
  if (env.PARSE_SERVER_URL && env.PARSE_APP_ID && env.PARSE_MASTER_KEY) {
    return env;
  }
  try {
    const homeDir = process.env.HOME || process.env.USERPROFILE || '';
    const cfgPath = path.join(homeDir, '.cursor', 'mcp.json');
    const txt = fs.readFileSync(cfgPath, 'utf-8');
    const cfg = JSON.parse(txt);
    const parseCfg = cfg?.mcpServers?.parse?.env;
    if (parseCfg?.PARSE_SERVER_URL && parseCfg?.PARSE_APP_ID && parseCfg?.PARSE_MASTER_KEY) {
      return {
        PARSE_SERVER_URL: parseCfg.PARSE_SERVER_URL,
        PARSE_APP_ID: parseCfg.PARSE_APP_ID,
        PARSE_MASTER_KEY: parseCfg.PARSE_MASTER_KEY,
      };
    }
  } catch (_) {
    // ignore and fall through
  }
  throw new Error(
    'Missing Parse env. Set PARSE_SERVER_URL, PARSE_APP_ID, PARSE_MASTER_KEY or configure .cursor/mcp.json'
  );
}

// James Chen's appointments (from the script) that should have services
const jamesChenAppointments = [
  'n1cx6hBItc', // Aug 8
  'mIqo0AT0PL', // Aug 15
  'H6RYmiccT0', // Aug 22
  'zD3GHkZGqH', // Aug 29
  'NH3pE2Jlcs', // Sep 5
  'aRPoLuqiBO', // Sep 12
  'zChpzrHKko', // Sep 19
  'qyTkhu68PB', // Sep 26
  'I4j4q7adQ3', // Oct 3
  'bhkAG6TyX4', // Oct 10
  'dxDGjrxbWK', // Oct 17
  'Bk3fxZlYBE', // Oct 24
];

async function main() {
  const { PARSE_SERVER_URL, PARSE_APP_ID, PARSE_MASTER_KEY } = loadParseEnv();
  Parse.initialize(PARSE_APP_ID);
  Parse.serverURL = PARSE_SERVER_URL;
  Parse.masterKey = PARSE_MASTER_KEY;

  console.log('🔄 Starting appointment service check and fix...\n');

  const Appointment = Parse.Object.extend('Appointment');
  const StaffMember = Parse.Object.extend('Staff_Member');
  const ServiceOffering = Parse.Object.extend('Service_Offering');
  const Item = Parse.Object.extend('Item');
  const ItemPrice = Parse.Object.extend('Item_Price');

  // Step 1: Find Tom Holland
  console.log('👤 Looking for Tom Holland...');
  const staffQuery = new Parse.Query(StaffMember);
  staffQuery.equalTo('firstName', 'Tom');
  staffQuery.equalTo('lastName', 'Holland');
  const tomHolland = await staffQuery.first({ useMasterKey: true });

  if (!tomHolland) {
    console.error('❌ Tom Holland not found!');
    return;
  }
  console.log(`✅ Found Tom Holland: ${tomHolland.id}\n`);

  // Step 2: Get Tom Holland's service offerings through staff_Services
  console.log('🔍 Finding services offered by Tom Holland...');
  const StaffService = Parse.Object.extend('staff_Services');
  const staffServiceQuery = new Parse.Query(StaffService);
  staffServiceQuery.equalTo('staffId', tomHolland);
  staffServiceQuery.equalTo('isEnabled', true);
  staffServiceQuery.include('serviceId');
  staffServiceQuery.include('serviceId.itemId');
  staffServiceQuery.include('serviceId.itemId.serviceDetailId');
  staffServiceQuery.include('locationId');
  const staffServices = await staffServiceQuery.find({ useMasterKey: true });

  console.log(`\n📋 Services offered by Tom Holland:`);
  const serviceMap = {};
  const servicePriceMap = {};
  
  for (const staffService of staffServices) {
    const service = staffService.get('serviceId'); // This is the Service_Offering
    const location = staffService.get('locationId');
    const locationName = location ? location.get('locationName') : 'Unknown';
    
    if (service) {
      const item = service.get('itemId');
      if (item) {
        const itemName = item.get('itemName');
        const serviceDetail = item.get('serviceDetailId');
        const duration = serviceDetail ? serviceDetail.get('schedulingDurationMinutes') : 'N/A';
        console.log(`  - ${itemName} (${duration} minutes) at ${locationName}`);
        console.log(`    Service Offering ID: ${service.id}`);
        serviceMap[itemName] = service;
        
        // Get item prices for this service
        const itemPriceQuery = new Parse.Query(ItemPrice);
        itemPriceQuery.equalTo('itemId', item);
        const itemPrices = await itemPriceQuery.find({ useMasterKey: true });
        
        if (itemPrices.length > 0) {
          console.log(`    Item Prices:`);
          servicePriceMap[itemName] = [];
          itemPrices.forEach((price, idx) => {
            const priceAmount = price.get('price');
            const priceDuration = price.get('durationMinutes');
            console.log(`      ${idx + 1}. $${priceAmount} - ${priceDuration} min - Item Price ID: ${price.id}`);
            servicePriceMap[itemName].push(price);
          });
        }
      }
    }
  }
  
  console.log(`\n✅ Found ${Object.keys(serviceMap).length} services\n`);

  console.log('\n🔍 Checking James Chen appointments...\n');

  // Step 3: Check each appointment
  let checkedCount = 0;
  let hasServiceCount = 0;
  let missingServiceCount = 0;
  const appointmentsToFix = [];

  for (const apptId of jamesChenAppointments) {
    const apptQuery = new Parse.Query(Appointment);
    apptQuery.equalTo('objectId', apptId);
    apptQuery.include('serviceOfferingId');
    apptQuery.include('serviceOfferingId.itemId');
    apptQuery.include('itemPriceId');
    apptQuery.include('providerId');

    const appt = await apptQuery.first({ useMasterKey: true });

    if (appt) {
      checkedCount++;
      const startTime = appt.get('startTime');
      const provider = appt.get('providerId');
      const serviceOffering = appt.get('serviceOfferingId');
      const itemPrice = appt.get('itemPriceId');
      
      const providerName = provider ? `${provider.get('firstName')} ${provider.get('lastName')}` : 'N/A';
      
      console.log(`📅 Appointment ${apptId} (${startTime ? new Date(startTime).toLocaleDateString() : 'N/A'})`);
      console.log(`   Provider: ${providerName}`);
      
      if (serviceOffering) {
        const item = serviceOffering.get('itemId');
        const serviceName = item ? item.get('itemName') : 'Unknown';
        console.log(`   ✅ Has service: ${serviceName}`);
        hasServiceCount++;
      } else {
        console.log(`   ❌ Missing service offering`);
        missingServiceCount++;
        appointmentsToFix.push({ appt, apptId, startTime });
      }
      
      if (itemPrice) {
        const price = itemPrice.get('price');
        const duration = itemPrice.get('durationMinutes');
        console.log(`   💰 Item Price: $${price} (${duration} min)`);
      } else {
        console.log(`   ❌ Missing item price`);
      }
      console.log('');
    } else {
      console.log(`⚠️  Appointment ${apptId} not found\n`);
    }
  }

  console.log(`\n📊 Summary:`);
  console.log(`   Total checked: ${checkedCount}`);
  console.log(`   Have services: ${hasServiceCount}`);
  console.log(`   Missing services: ${missingServiceCount}\n`);

  // Step 4: Prompt to fix
  if (appointmentsToFix.length > 0) {
    console.log(`\n🔧 Would fix ${appointmentsToFix.length} appointments`);
    console.log(`\nTo fix these appointments, uncomment the update code in this script.`);
    console.log(`\nAvailable services to assign:`);
    Object.keys(serviceMap).forEach((serviceName, idx) => {
      console.log(`  ${idx + 1}. ${serviceName}`);
    });
  } else {
    console.log(`\n✅ All appointments have services!`);
  }
}

main().catch((err) => {
  console.error('❌ Error:', err.message || String(err));
  process.exit(1);
});

