// ==============================================================
// PostgreSQL Patient Data Seeder
// ==============================================================
// This script creates realistic patient test data directly in PostgreSQL
//
// Usage:
//   1. Copy .env.example to .env and fill in your configuration
//   2. Run: node scripts/seed-patients.js
//
// Options:
//   DRY_RUN=true node scripts/seed-patients.js    (preview without creating data)
// ==============================================================

require('dotenv').config();
const { Client } = require('pg');

// ==============================================================
// Configuration (from environment variables)
// ==============================================================

const CONFIG = {
  DRY_RUN: process.env.DRY_RUN === 'true' || false,
  ORG_ID: process.env.SEED_ORG_ID,
  LOCATION_ID: process.env.SEED_LOCATION_ID,
  STAFF_ID: process.env.SEED_STAFF_ID,
  CREATED_BY_USER_ID: process.env.SEED_CREATED_BY_USER_ID,
  SERVICE_OFFERING_ID: process.env.SEED_SERVICE_OFFERING_ID,
  OWNERSHIP_GROUP_ID: process.env.SEED_OWNERSHIP_GROUP_ID,
  NUM_PATIENTS: parseInt(process.env.SEED_NUM_PATIENTS || '10', 10),

  // Database connection
  DB_CONFIG: {
    host: process.env.DB_HOST,
    port: parseInt(process.env.DB_PORT || '5432', 10),
    database: process.env.DB_NAME,
    user: process.env.DB_USER,
    password: process.env.DB_PASSWORD,
    ssl:
      process.env.DB_SSL === 'true'
        ? {
          rejectUnauthorized: process.env.DB_SSL_REJECT_UNAUTHORIZED !== 'false',
        }
        : false,
  },
};

// ==============================================================
// Validation
// ==============================================================

function validateConfig() {
  const required = [
    'SEED_ORG_ID',
    'SEED_LOCATION_ID',
    'SEED_STAFF_ID',
    'SEED_CREATED_BY_USER_ID',
    'SEED_SERVICE_OFFERING_ID',
    'SEED_OWNERSHIP_GROUP_ID',
    'DB_HOST',
    'DB_NAME',
    'DB_USER',
    'DB_PASSWORD',
  ];

  const missing = required.filter((key) => !process.env[key]);

  if (missing.length > 0) {
    console.error('\n❌ Missing required environment variables:');
    missing.forEach((key) => console.error(`   - ${key}`));
    console.error('\nPlease check your .env file. See .env.example for reference.\n');
    process.exit(1);
  }
}

// ==============================================================
// Patient Data Templates
// ==============================================================

const PATIENT_TEMPLATES = [
  {
    firstName: 'Marcus',
    lastName: 'Williams',
    email: `marcus.williams.${Date.now()}@testpatient.com`,
    gender: 'male',
    dateOfBirth: new Date('1987-02-14'),
    mobile: '+19055550101',
    addressLine1: '123 Main Street',
    city: 'Markham',
    provinceState: 'Ontario',
    country: 'Canada',
    postalZipCode: 'L3R 5K4',
    emergencyContactName: 'Lisa Williams',
    emergencyContactRelationship: 'Wife',
    emergencyContactPhone: '+19055550102',
    referralType: 'Online Search',
    pronouns: 'he/him',
    notes: ['Active lifestyle - runs marathons', 'Prefers early morning appointments'],
    appointments: [
      {
        status: 'completed',
        startTime: new Date(Date.now() - 14 * 24 * 60 * 60 * 1000),
        duration: 60,
        notes: 'Sports injury assessment',
      },
      {
        status: 'scheduled',
        startTime: new Date(Date.now() + 3 * 24 * 60 * 60 * 1000),
        duration: 45,
        notes: 'Follow-up treatment',
      },
    ],
    charts: [
      {
        status: 'completed',
        isVisibleToPatient: true,
      },
    ],
  },
  {
    firstName: 'Jennifer',
    lastName: 'Lee',
    email: `jennifer.lee.${Date.now() + 1}@testpatient.com`,
    gender: 'female',
    dateOfBirth: new Date('1978-11-08'),
    mobile: '+14165550301',
    addressLine1: '789 Pine Road',
    city: 'Calgary',
    provinceState: 'Alberta',
    country: 'Canada',
    postalZipCode: 'T2P 1J9',
    emergencyContactName: 'David Chen',
    emergencyContactRelationship: 'Spouse',
    emergencyContactPhone: '+14165550302',
    referralType: 'Doctor Referral',
    referralDetail: 'Dr. Smith',
    pronouns: 'she/her',
    notes: ['Long-term patient - member since 2020', 'Prefers afternoon appointments'],
    appointments: [
      {
        status: 'completed',
        startTime: new Date(Date.now() - 60 * 24 * 60 * 60 * 1000),
        duration: 45,
        notes: 'Regular check-up',
      },
      {
        status: 'scheduled',
        startTime: new Date(Date.now() + 14 * 24 * 60 * 60 * 1000),
        duration: 45,
        notes: 'Follow-up treatment',
      },
    ],
    charts: [
      {
        status: 'completed',
        isVisibleToPatient: true,
      },
    ],
  },
  {
    firstName: 'David',
    lastName: 'Kumar',
    email: `david.kumar.${Date.now() + 2}@testpatient.com`,
    gender: 'male',
    dateOfBirth: new Date('1982-09-10'),
    mobile: '+19055550301',
    addressLine1: '789 Elgin Mills',
    city: 'Richmond Hill',
    provinceState: 'Ontario',
    country: 'Canada',
    postalZipCode: 'L4S 1A3',
    emergencyContactName: 'Priya Kumar',
    emergencyContactRelationship: 'Wife',
    emergencyContactPhone: '+19055550302',
    referralType: 'Doctor Referral',
    referralDetail: 'Dr. Singh',
    pronouns: 'he/him',
    notes: ['IT professional - desk job', 'Chronic back pain'],
    appointments: [
      {
        status: 'completed',
        startTime: new Date(Date.now() - 21 * 24 * 60 * 60 * 1000),
        duration: 60,
        notes: 'Initial assessment completed',
      },
      {
        status: 'scheduled',
        startTime: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000),
        duration: 45,
        notes: 'Continuing treatment',
      },
    ],
    charts: [
      {
        status: 'completed',
        isVisibleToPatient: true,
      },
    ],
  },
  {
    firstName: 'Michelle',
    lastName: 'Patel',
    email: `michelle.patel.${Date.now() + 3}@testpatient.com`,
    gender: 'female',
    dateOfBirth: new Date('1995-09-12'),
    mobile: '+16135550501',
    addressLine1: '654 Birch Lane',
    city: 'Ottawa',
    provinceState: 'Ontario',
    country: 'Canada',
    postalZipCode: 'K1A 0A9',
    emergencyContactName: 'Raj Patel',
    emergencyContactRelationship: 'Father',
    emergencyContactPhone: '+16135550502',
    referralType: 'Social Media',
    pronouns: 'she/her',
    notes: ['Student - prefers evening appointments'],
    appointments: [
      {
        status: 'completed',
        startTime: new Date(Date.now() - 7 * 24 * 60 * 60 * 1000),
        duration: 45,
        notes: 'Consultation completed',
      },
    ],
    charts: [
      {
        status: 'completed',
        isVisibleToPatient: true,
      },
    ],
  },
  {
    firstName: 'Steven',
    lastName: 'Park',
    email: `steven.park.${Date.now() + 4}@testpatient.com`,
    gender: 'male',
    dateOfBirth: new Date('1985-11-30'),
    mobile: '+19055550501',
    addressLine1: '567 Warden Avenue',
    city: 'Markham',
    provinceState: 'Ontario',
    country: 'Canada',
    postalZipCode: 'L6E 1A1',
    emergencyContactName: 'Grace Park',
    emergencyContactRelationship: 'Sister',
    emergencyContactPhone: '+19055550502',
    referralType: 'Social Media',
    pronouns: 'he/him',
    notes: ['Tech entrepreneur - irregular schedule', 'Interested in preventative care'],
    appointments: [
      {
        status: 'completed',
        startTime: new Date(Date.now() - 30 * 24 * 60 * 60 * 1000),
        duration: 60,
        notes: 'Initial wellness consultation',
      },
      {
        status: 'scheduled',
        startTime: new Date(Date.now() + 14 * 24 * 60 * 60 * 1000),
        duration: 45,
        notes: 'Follow-up wellness check',
      },
    ],
    charts: [
      {
        status: 'completed',
        isVisibleToPatient: true,
      },
    ],
  },
  {
    firstName: 'Amanda',
    lastName: 'Williams',
    email: `amanda.williams.${Date.now() + 5}@testpatient.com`,
    gender: 'female',
    dateOfBirth: new Date('2000-04-18'),
    mobile: '+19025550701',
    addressLine1: '147 Spruce Street',
    city: 'Halifax',
    provinceState: 'Nova Scotia',
    country: 'Canada',
    postalZipCode: 'B3H 3A1',
    emergencyContactName: 'Jennifer Williams',
    emergencyContactRelationship: 'Mother',
    emergencyContactPhone: '+19025550702',
    referralType: 'Online Search',
    pronouns: 'she/her',
    notes: ['New patient - first appointment scheduled'],
    appointments: [
      {
        status: 'scheduled',
        startTime: new Date(Date.now() + 2 * 24 * 60 * 60 * 1000),
        duration: 60,
        notes: 'First consultation',
      },
    ],
    charts: [],
  },
  {
    firstName: 'Ryan',
    lastName: 'Patel',
    email: `ryan.patel.${Date.now() + 6}@testpatient.com`,
    gender: 'male',
    dateOfBirth: new Date('1995-08-05'),
    mobile: '+19055550701',
    addressLine1: '123 Bur Oak Avenue',
    city: 'Markham',
    provinceState: 'Ontario',
    country: 'Canada',
    postalZipCode: 'L6C 0H4',
    emergencyContactName: 'Nina Patel',
    emergencyContactRelationship: 'Mother',
    emergencyContactPhone: '+19055550702',
    referralType: 'Online Search',
    pronouns: 'he/him',
    notes: ['Student athlete - hockey player', 'Sports injury recovery'],
    appointments: [
      {
        status: 'completed',
        startTime: new Date(Date.now() - 3 * 24 * 60 * 60 * 1000),
        duration: 60,
        notes: 'Sports injury assessment',
      },
      {
        status: 'scheduled',
        startTime: new Date(Date.now() + 4 * 24 * 60 * 60 * 1000),
        duration: 45,
        notes: 'Rehabilitation session',
      },
    ],
    charts: [
      {
        status: 'completed',
        isVisibleToPatient: true,
      },
    ],
  },
  {
    firstName: 'Nicole',
    lastName: 'Garcia',
    email: `nicole.garcia.${Date.now() + 7}@testpatient.com`,
    gender: 'female',
    dateOfBirth: new Date('1991-08-27'),
    mobile: '+12505550901',
    addressLine1: '369 Redwood Drive',
    city: 'Victoria',
    provinceState: 'British Columbia',
    country: 'Canada',
    postalZipCode: 'V8W 1N4',
    emergencyContactName: 'Carlos Garcia',
    emergencyContactRelationship: 'Brother',
    emergencyContactPhone: '+12505550902',
    referralType: 'Doctor Referral',
    referralDetail: 'Dr. Anderson',
    pronouns: 'she/her',
    notes: ['Travels frequently for work', 'Prefers virtual appointments when possible'],
    appointments: [
      {
        status: 'completed',
        startTime: new Date(Date.now() - 90 * 24 * 60 * 60 * 1000),
        duration: 60,
        notes: 'Previous consultation',
      },
      {
        status: 'scheduled',
        startTime: new Date(Date.now() + 21 * 24 * 60 * 60 * 1000),
        duration: 45,
        notes: 'Routine check-up',
      },
    ],
    charts: [
      {
        status: 'completed',
        isVisibleToPatient: true,
      },
    ],
  },
  {
    firstName: 'Kevin',
    lastName: 'Wong',
    email: `kevin.wong.${Date.now() + 8}@testpatient.com`,
    gender: 'male',
    dateOfBirth: new Date('1979-04-25'),
    mobile: '+19055550901',
    addressLine1: '789 McCowan Road',
    city: 'Markham',
    provinceState: 'Ontario',
    country: 'Canada',
    postalZipCode: 'L3P 3J3',
    emergencyContactName: 'Susan Wong',
    emergencyContactRelationship: 'Wife',
    emergencyContactPhone: '+19055550902',
    referralType: 'Doctor Referral',
    referralDetail: 'Dr. Johnson',
    pronouns: 'he/him',
    notes: ['Long-term patient since 2018', 'Chronic neck pain from desk work'],
    appointments: [
      {
        status: 'completed',
        startTime: new Date(Date.now() - 20 * 24 * 60 * 60 * 1000),
        duration: 60,
        notes: 'Regular treatment',
      },
      {
        status: 'scheduled',
        startTime: new Date(Date.now() + 10 * 24 * 60 * 60 * 1000),
        duration: 45,
        notes: 'Ongoing care',
      },
    ],
    charts: [
      {
        status: 'completed',
        isVisibleToPatient: true,
      },
    ],
  },
  {
    firstName: 'Laura',
    lastName: 'Rodriguez',
    email: `laura.rodriguez.${Date.now() + 9}@testpatient.com`,
    gender: 'female',
    dateOfBirth: new Date('1986-10-12'),
    mobile: '+19055551001',
    addressLine1: '321 Major Mackenzie',
    city: 'Richmond Hill',
    provinceState: 'Ontario',
    country: 'Canada',
    postalZipCode: 'L4C 9M7',
    emergencyContactName: 'Carlos Rodriguez',
    emergencyContactRelationship: 'Brother',
    emergencyContactPhone: '+19055551002',
    referralType: 'Insurance Provider',
    pronouns: 'she/her',
    notes: ['Physiotherapist herself - very knowledgeable', 'Prefers evidence-based treatment'],
    appointments: [
      {
        status: 'completed',
        startTime: new Date(Date.now() - 40 * 24 * 60 * 60 * 1000),
        duration: 60,
        notes: 'Professional consultation',
      },
      {
        status: 'scheduled',
        startTime: new Date(Date.now() + 20 * 24 * 60 * 60 * 1000),
        duration: 60,
        notes: 'Follow-up consultation',
      },
    ],
    charts: [
      {
        status: 'completed',
        isVisibleToPatient: true,
      },
    ],
  },
];

// ==============================================================
// Helper Functions
// ==============================================================

function generateObjectId() {
  const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
  let result = '';
  for (let i = 0; i < 10; i++) {
    result += chars.charAt(Math.floor(Math.random() * chars.length));
  }
  return result;
}

function generatePassword() {
  // Simple bcrypt-like hash for testing (in production, use proper bcrypt)
  return `$2a$10$${'x'.repeat(53)}`; // Placeholder hash
}

function log(message) {
  console.log(`[${new Date().toISOString()}] ${message}`);
}

// ==============================================================
// Database Operations
// ==============================================================

async function createUser(client, template) {
  const userId = generateObjectId();
  const username = `${template.firstName.toLowerCase()}.${template.lastName.toLowerCase()}${Math.floor(Math.random() * 1000)}`;
  const now = new Date();

  const query = `
    INSERT INTO "_User" (
      "objectId", "createdAt", "updatedAt",
      "username", "email", "_hashed_password",
      "firstName", "lastName", "middleName", "preferredName",
      "gender", "dateOfBirth", "mobile",
      "addressLine1", "addressLine2", "city", "provinceState", "country", "postalZipCode",
      "emergencyContactName", "emergencyContactRelationship", "emergencyContactPhone",
      "isOnboardingComplete"
    ) VALUES (
      $1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17, $18, $19, $20, $21, $22, $23
    )
    RETURNING "objectId"
  `;

  const values = [
    userId,
    now,
    now,
    username,
    template.email,
    generatePassword(),
    template.firstName,
    template.lastName,
    template.middleName || null,
    template.preferredName || null,
    template.gender,
    template.dateOfBirth,
    template.mobile,
    template.addressLine1,
    template.addressLine2 || null,
    template.city,
    template.provinceState,
    template.country,
    template.postalZipCode,
    template.emergencyContactName,
    template.emergencyContactRelationship,
    template.emergencyContactPhone,
    true,
  ];

  if (CONFIG.DRY_RUN) {
    log(`[DRY RUN] Would create User: ${username} (${template.email})`);
    return userId;
  }

  const result = await client.query(query, values);
  log(`✓ User created: ${username} (${userId})`);
  return result.rows[0].objectId;
}

async function createPatient(client, template, userId) {
  const patientId = generateObjectId();
  const now = new Date();

  const query = `
    INSERT INTO "Patient" (
      "objectId", "createdAt", "updatedAt",
      "userId", "orgId", "firstName", "lastName", "middleName", "preferredName",
      "email", "mobile", "gender", "dateOfBirth",
      "addressLine1", "addressLine2", "city", "provinceState", "country", "postalZipCode",
      "emergencyContactName", "emergencyContactRelationship", "emergencyContactPhone",
      "referralType", "referralDetail", "pronouns",
      "syncEnabled", "allowNotifications", "isBlacklisted", "isDeceased",
      "patientSince", "createdBy"
    ) VALUES (
      $1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17, $18, $19, $20, $21, $22, $23, $24, $25, $26, $27, $28, $29, $30, $31
    )
    RETURNING "objectId"
  `;

  const values = [
    patientId,
    now,
    now,
    userId,
    CONFIG.ORG_ID,
    template.firstName,
    template.lastName,
    template.middleName || null,
    template.preferredName || null,
    template.email,
    template.mobile,
    template.gender,
    template.dateOfBirth,
    template.addressLine1,
    template.addressLine2 || null,
    template.city,
    template.provinceState,
    template.country,
    template.postalZipCode,
    template.emergencyContactName,
    template.emergencyContactRelationship,
    template.emergencyContactPhone,
    template.referralType,
    template.referralDetail || null,
    template.pronouns,
    true,
    true,
    false,
    false,
    now,
    CONFIG.CREATED_BY_USER_ID,
  ];

  if (CONFIG.DRY_RUN) {
    log(`[DRY RUN] Would create Patient: ${template.firstName} ${template.lastName} (${patientId})`);
    return patientId;
  }

  const result = await client.query(query, values);
  log(`✓ Patient created: ${template.firstName} ${template.lastName} (${patientId})`);
  return result.rows[0].objectId;
}

async function createPatientNote(client, patientId, noteText, isPinned) {
  const noteId = generateObjectId();
  const now = new Date();

  const query = `
    INSERT INTO "Patient_Note" (
      "objectId", "createdAt", "updatedAt",
      "patientId", "text", "isPinned", "createdBy"
    ) VALUES (
      $1, $2, $3, $4, $5, $6, $7
    )
    RETURNING "objectId"
  `;

  const values = [noteId, now, now, patientId, noteText, isPinned, CONFIG.CREATED_BY_USER_ID];

  if (CONFIG.DRY_RUN) {
    log(`[DRY RUN] Would create Note: ${noteText.substring(0, 50)}...`);
    return noteId;
  }

  const result = await client.query(query, values);
  log(`✓ Note created (${noteId})`);
  return result.rows[0].objectId;
}

async function createAppointment(client, patientId, appt) {
  const appointmentId = generateObjectId();
  const now = new Date();

  const query = `
    INSERT INTO "Appointment" (
      "objectId", "createdAt", "updatedAt",
      "patientId", "orgId", "locationId", "staffId", "serviceOfferingId",
      "startTime", "duration", "status", "notes",
      "createdBy", "checkInAt", "checkInBy", "checkOutAt", "checkOutBy"
    ) VALUES (
      $1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17
    )
    RETURNING "objectId"
  `;

  let checkInAt = null;
  let checkInBy = null;
  let checkOutAt = null;
  let checkOutBy = null;

  if (appt.status === 'completed') {
    checkInAt = new Date(appt.startTime.getTime() - 5 * 60000);
    checkInBy = CONFIG.CREATED_BY_USER_ID;
    checkOutAt = new Date(appt.startTime.getTime() + appt.duration * 60000);
    checkOutBy = CONFIG.CREATED_BY_USER_ID;
  }

  const values = [
    appointmentId,
    now,
    now,
    patientId,
    CONFIG.ORG_ID,
    CONFIG.LOCATION_ID,
    CONFIG.STAFF_ID,
    CONFIG.SERVICE_OFFERING_ID,
    appt.startTime,
    appt.duration,
    appt.status,
    appt.notes,
    CONFIG.CREATED_BY_USER_ID,
    checkInAt,
    checkInBy,
    checkOutAt,
    checkOutBy,
  ];

  if (CONFIG.DRY_RUN) {
    log(`[DRY RUN] Would create Appointment: ${appt.status} at ${appt.startTime.toISOString()}`);
    return appointmentId;
  }

  const result = await client.query(query, values);
  log(`✓ Appointment created: ${appt.status} (${appointmentId})`);
  return result.rows[0].objectId;
}

async function createChart(client, patientId, appointmentId, chart) {
  const chartId = generateObjectId();
  const now = new Date();

  const query = `
    INSERT INTO "Chart" (
      "objectId", "createdAt", "updatedAt",
      "patientId", "appointmentId", "status", "isVisibleToPatient",
      "createdBy", "signedAt", "signedByProviderId", "isBlackBoxed"
    ) VALUES (
      $1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11
    )
    RETURNING "objectId"
  `;

  const signedAt = chart.status === 'completed' ? now : null;
  const signedByProviderId = chart.status === 'completed' ? CONFIG.STAFF_ID : null;

  const values = [
    chartId,
    now,
    now,
    patientId,
    appointmentId,
    chart.status,
    chart.isVisibleToPatient,
    CONFIG.CREATED_BY_USER_ID,
    signedAt,
    signedByProviderId,
    false,
  ];

  if (CONFIG.DRY_RUN) {
    log(`[DRY RUN] Would create Chart: ${chart.status}`);
    return chartId;
  }

  const result = await client.query(query, values);
  log(`✓ Chart created: ${chart.status} (${chartId})`);
  return result.rows[0].objectId;
}

async function createOwnershipGroupPatient(client, patientId) {
  const ogPatientId = generateObjectId();
  const now = new Date();

  const query = `
    INSERT INTO "Ownership_Group_Patient" (
      "objectId", "createdAt", "updatedAt",
      "ownershipGroupId", "patientId", "isActive"
    ) VALUES (
      $1, $2, $3, $4, $5, $6
    )
    RETURNING "objectId"
  `;

  const values = [ogPatientId, now, now, CONFIG.OWNERSHIP_GROUP_ID, patientId, true];

  if (CONFIG.DRY_RUN) {
    log('[DRY RUN] Would create Ownership_Group_Patient association');
    return ogPatientId;
  }

  const result = await client.query(query, values);
  log(`✓ Ownership Group association created (${ogPatientId})`);
  return result.rows[0].objectId;
}

// ==============================================================
// Main Function
// ==============================================================

async function createPatientWithData(client, template, index) {
  console.log(`\n${'='.repeat(60)}`);
  console.log(`Creating Patient ${index + 1}: ${template.firstName} ${template.lastName}`);
  console.log('='.repeat(60));

  try {
    // Step 1: Create User
    log('Step 1: Creating User...');
    const userId = await createUser(client, template);

    // Step 2: Create Patient
    log('Step 2: Creating Patient...');
    const patientId = await createPatient(client, template, userId);

    // Step 3: Create Ownership Group Association
    log('Step 3: Creating Ownership Group Association...');
    await createOwnershipGroupPatient(client, patientId);

    // Step 4: Create Notes
    if (template.notes && template.notes.length > 0) {
      log('Step 4: Creating Patient Notes...');
      for (let i = 0; i < template.notes.length; i++) {
        await createPatientNote(client, patientId, template.notes[i], i === 0);
      }
    }

    // Step 5: Create Appointments
    const appointmentIds = [];
    if (template.appointments && template.appointments.length > 0) {
      log('Step 5: Creating Appointments...');
      for (const appt of template.appointments) {
        const appointmentId = await createAppointment(client, patientId, appt);
        appointmentIds.push(appointmentId);
      }
    }

    // Step 6: Create Charts
    if (template.charts && template.charts.length > 0 && appointmentIds.length > 0) {
      log('Step 6: Creating Charts...');
      for (let i = 0; i < template.charts.length; i++) {
        const appointmentId = appointmentIds[Math.min(i, appointmentIds.length - 1)];
        await createChart(client, patientId, appointmentId, template.charts[i]);
      }
    }

    console.log('='.repeat(60));
    log(`✓ Patient ${template.firstName} ${template.lastName} created successfully!`);
    console.log('='.repeat(60));

    return { success: true, userId, patientId };
  } catch (error) {
    console.error(`✗ Failed to create patient ${template.firstName} ${template.lastName}:`, error);
    return { success: false, error: error.message };
  }
}

async function main() {
  // Validate configuration
  validateConfig();

  console.log('\n');
  console.log('╔═══════════════════════════════════════════════════════════╗');
  console.log('║     PostgreSQL Patient Data Seeder                        ║');
  console.log('╚═══════════════════════════════════════════════════════════╝');
  console.log('');
  console.log(`Mode: ${CONFIG.DRY_RUN ? '🔍 DRY RUN (no data will be created)' : '💾 LIVE (data will be created)'}`);
  console.log(`Organization ID: ${CONFIG.ORG_ID}`);
  console.log(`Location ID: ${CONFIG.LOCATION_ID}`);
  console.log(`Ownership Group ID: ${CONFIG.OWNERSHIP_GROUP_ID}`);
  console.log(`Number of Patients: ${CONFIG.NUM_PATIENTS}`);
  console.log('');

  let client;
  try {
    // Connect to database
    log('Connecting to database...');
    client = new Client(CONFIG.DB_CONFIG);
    await client.connect();
    log('✓ Connected to database');

    // Create patients
    const results = [];
    for (let i = 0; i < CONFIG.NUM_PATIENTS; i++) {
      const template = PATIENT_TEMPLATES[i];
      const result = await createPatientWithData(client, template, i);
      results.push(result);
    }

    // Summary
    console.log('\n\n');
    console.log('╔═══════════════════════════════════════════════════════════╗');
    console.log('║                    SUMMARY                                ║');
    console.log('╚═══════════════════════════════════════════════════════════╝');
    console.log('');

    const successful = results.filter((r) => r.success).length;
    const failed = results.filter((r) => !r.success).length;

    console.log(`Total Patients: ${CONFIG.NUM_PATIENTS}`);
    console.log(`Successful: ${successful}`);
    console.log(`Failed: ${failed}`);
    console.log('');

    if (CONFIG.DRY_RUN) {
      console.log('⚠️  DRY RUN MODE - No data was actually created');
      console.log('');
      console.log('To create real data, set DRY_RUN=false in your .env file');
    } else {
      console.log('✓ Data creation complete!');
    }
  } catch (error) {
    console.error('\n✗ Script execution failed:', error);
    process.exit(1);
  } finally {
    if (client) {
      await client.end();
      log('Database connection closed');
    }
  }
}

// Run the script
main().catch(console.error);
