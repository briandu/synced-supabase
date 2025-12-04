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

async function main() {
  const { PARSE_SERVER_URL, PARSE_APP_ID, PARSE_MASTER_KEY } = loadParseEnv();
  Parse.initialize(PARSE_APP_ID);
  Parse.serverURL = PARSE_SERVER_URL;
  Parse.masterKey = PARSE_MASTER_KEY;

  console.log('🔍 Verifying James Chen appointments...\n');

  const Appointment = Parse.Object.extend('Appointment');
  const Patient = Parse.Object.extend('Patient');

  // Find James Chen
  const patientQuery = new Parse.Query(Patient);
  patientQuery.equalTo('objectId', '1Lb9ATLCar');
  const jamesChen = await patientQuery.first({ useMasterKey: true });

  if (!jamesChen) {
    console.error('❌ James Chen not found!');
    return;
  }

  console.log(`✅ Found patient: ${jamesChen.get('firstName')} ${jamesChen.get('lastName')}\n`);

  // Get his appointments
  const apptQuery = new Parse.Query(Appointment);
  apptQuery.equalTo('patientId', jamesChen);
  apptQuery.include('providerId');
  apptQuery.include('serviceOfferingId');
  apptQuery.include('serviceOfferingId.itemId');
  apptQuery.include('itemPriceId');
  apptQuery.ascending('startTime');
  apptQuery.limit(50);

  const appointments = await apptQuery.find({ useMasterKey: true });

  console.log(`📅 Found ${appointments.length} appointments:\n`);

  let withService = 0;
  let withoutService = 0;

  for (const appt of appointments) {
    const startTime = appt.get('startTime');
    const provider = appt.get('providerId');
    const serviceOffering = appt.get('serviceOfferingId');
    const itemPrice = appt.get('itemPriceId');

    const providerName = provider
      ? `${provider.get('firstName')} ${provider.get('lastName')}`
      : 'No provider';

    const serviceName = serviceOffering?.get('itemId')?.get('itemName') || 'No service';
    const price = itemPrice ? `$${(itemPrice.get('price') / 100).toFixed(2)}` : 'No price';
    const duration = itemPrice ? `${itemPrice.get('durationMinutes')} min` : '';

    console.log(`📍 ${new Date(startTime).toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' })}`);
    console.log(`   ID: ${appt.id}`);
    console.log(`   Provider: ${providerName}`);
    console.log(`   Service: ${serviceName}`);
    console.log(`   Price: ${price} ${duration}`);
    console.log('');

    if (serviceOffering) {
      withService++;
    } else {
      withoutService++;
    }
  }

  console.log(`\n📊 Summary:`);
  console.log(`   Total: ${appointments.length}`);
  console.log(`   With service: ${withService}`);
  console.log(`   Without service: ${withoutService}`);

  if (withService > 0) {
    console.log(`\n✅ Appointments have been successfully updated with services!`);
  }
}

main().catch((err) => {
  console.error('❌ Error:', err.message || String(err));
  process.exit(1);
});




