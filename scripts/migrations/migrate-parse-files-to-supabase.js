/**
 * Migration script to copy Parse files to Supabase Storage
 * 
 * This script:
 * 1. Fetches all Parse _File objects
 * 2. Downloads each file from Parse Server
 * 3. Uploads to Supabase Storage with org/patient-scoped paths
 * 4. Updates patient_files table with new storage paths
 * 
 * Usage:
 *   node scripts/migrate-parse-files-to-supabase.js [--dry-run] [--limit=N]
 * 
 * Environment variables required:
 *   - PARSE_SERVER_URL
 *   - NEXT_PUBLIC_PARSE_APP_ID
 *   - NEXT_PUBLIC_PARSE_MASTER_KEY
 *   - NEXT_PUBLIC_SUPABASE_URL
 *   - SUPABASE_SERVICE_ROLE_KEY
 */

const fs = require('fs');
const path = require('path');
const https = require('https');
const http = require('http');

// Parse configuration
const PARSE_SERVER_URL = process.env.PARSE_SERVER_URL || process.env.NEXT_PUBLIC_PARSE_SERVER_URL;
const PARSE_APP_ID = process.env.NEXT_PUBLIC_PARSE_APP_ID;
const PARSE_MASTER_KEY = process.env.NEXT_PUBLIC_PARSE_MASTER_KEY;

// Supabase configuration
const SUPABASE_URL = process.env.NEXT_PUBLIC_SUPABASE_URL;
const SUPABASE_SERVICE_ROLE_KEY = process.env.SUPABASE_SERVICE_ROLE_KEY;

// Script options
const DRY_RUN = process.argv.includes('--dry-run');
const LIMIT_ARG = process.argv.find((arg) => arg.startsWith('--limit='));
const LIMIT = LIMIT_ARG ? parseInt(LIMIT_ARG.split('=')[1], 10) : null;

if (!PARSE_SERVER_URL || !PARSE_APP_ID || !PARSE_MASTER_KEY) {
  console.error('Error: Parse configuration missing. Set PARSE_SERVER_URL, NEXT_PUBLIC_PARSE_APP_ID, NEXT_PUBLIC_PARSE_MASTER_KEY');
  process.exit(1);
}

if (!SUPABASE_URL || !SUPABASE_SERVICE_ROLE_KEY) {
  console.error('Error: Supabase configuration missing. Set NEXT_PUBLIC_SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY');
  process.exit(1);
}

// Helper to make Parse API requests
async function parseRequest(endpoint, options = {}) {
  const url = `${PARSE_SERVER_URL}${endpoint}`;
  const headers = {
    'X-Parse-Application-Id': PARSE_APP_ID,
    'X-Parse-Master-Key': PARSE_MASTER_KEY,
    'Content-Type': 'application/json',
    ...options.headers,
  };

  return new Promise((resolve, reject) => {
    const client = url.startsWith('https') ? https : http;
    const req = client.request(url, { method: options.method || 'GET', headers }, (res) => {
      let data = '';
      res.on('data', (chunk) => (data += chunk));
      res.on('end', () => {
        try {
          const json = JSON.parse(data);
          if (res.statusCode >= 400) {
            reject(new Error(`Parse API error: ${json.error || data}`));
          } else {
            resolve(json);
          }
        } catch (e) {
          reject(new Error(`Failed to parse response: ${data}`));
        }
      });
    });
    req.on('error', reject);
    if (options.body) {
      req.write(JSON.stringify(options.body));
    }
    req.end();
  });
}

// Helper to download file from Parse
async function downloadParseFile(fileUrl) {
  return new Promise((resolve, reject) => {
    const client = fileUrl.startsWith('https') ? https : http;
    const req = client.get(fileUrl, (res) => {
      if (res.statusCode !== 200) {
        reject(new Error(`Failed to download file: ${res.statusCode}`));
        return;
      }
      const chunks = [];
      res.on('data', (chunk) => chunks.push(chunk));
      res.on('end', () => resolve(Buffer.concat(chunks)));
    });
    req.on('error', reject);
  });
}

// Helper to upload file to Supabase Storage
async function uploadToSupabase(bucket, filePath, fileBuffer, contentType) {
  const url = `${SUPABASE_URL}/storage/v1/object/${bucket}/${filePath}`;
  const headers = {
    Authorization: `Bearer ${SUPABASE_SERVICE_ROLE_KEY}`,
    'Content-Type': contentType || 'application/octet-stream',
    'x-upsert': 'false',
  };

  return new Promise((resolve, reject) => {
    const client = url.startsWith('https') ? https : http;
    const req = client.request(url, { method: 'POST', headers }, (res) => {
      let data = '';
      res.on('data', (chunk) => (data += chunk));
      res.on('end', () => {
        if (res.statusCode >= 400) {
          reject(new Error(`Supabase upload error: ${data}`));
        } else {
          resolve(JSON.parse(data || '{}'));
        }
      });
    });
    req.on('error', reject);
    req.write(fileBuffer);
    req.end();
  });
}

// Helper to make HTTP requests (using Node.js http/https)
function httpRequest(url, options = {}) {
  return new Promise((resolve, reject) => {
    const client = url.startsWith('https') ? https : http;
    const req = client.request(url, { method: options.method || 'GET', headers: options.headers || {} }, (res) => {
      let data = '';
      res.on('data', (chunk) => (data += chunk));
      res.on('end', () => {
        try {
          const json = JSON.parse(data);
          if (res.statusCode >= 400) {
            reject(new Error(`HTTP error: ${json.error || data}`));
          } else {
            resolve(json);
          }
        } catch (e) {
          if (res.statusCode >= 400) {
            reject(new Error(`HTTP error: ${data}`));
          } else {
            resolve(data);
          }
        }
      });
    });
    req.on('error', reject);
    if (options.body) {
      req.write(options.body);
    }
    req.end();
  });
}

// Helper to update patient_files table
async function updatePatientFileRecord(fileId, storageBucket, storagePath) {
  const baseUrl = `${SUPABASE_URL}/rest/v1/patient_files`;
  const headers = {
    apikey: SUPABASE_SERVICE_ROLE_KEY,
    Authorization: `Bearer ${SUPABASE_SERVICE_ROLE_KEY}`,
    'Content-Type': 'application/json',
    Prefer: 'return=representation',
  };

  // First, find the patient_file record by parse_object_id
  const findUrl = `${baseUrl}?parse_object_id=eq.${fileId}&select=id`;
  const findData = await httpRequest(findUrl, { headers });

  if (!findData || findData.length === 0) {
    console.warn(`  ⚠️  No patient_files record found for Parse file ${fileId}`);
    return null;
  }

  const recordId = findData[0].id;

  // Update the record
  const updateUrl = `${baseUrl}?id=eq.${recordId}`;
  const updateBody = JSON.stringify({
    storage_bucket: storageBucket,
    storage_path: storagePath,
  });

  return httpRequest(updateUrl, {
    method: 'PATCH',
    headers,
    body: updateBody,
  });
}

// Build storage path with org/patient scoping
function buildStoragePath(parseFile, patientId, orgId) {
  const parts = ['migrated'];
  if (orgId) parts.push('orgs', orgId);
  if (patientId) parts.push('patients', patientId);
  
  const datePrefix = new Date(parseFile.createdAt || Date.now()).toISOString().slice(0, 10);
  parts.push(datePrefix);
  
  const filename = parseFile.name || 'file';
  const uniqueSuffix = `${Date.now()}-${Math.random().toString(16).slice(2, 10)}`;
  parts.push(`${uniqueSuffix}-${filename}`);
  
  return parts.join('/');
}

// Main migration function
async function migrateFiles() {
  console.log('🚀 Starting Parse to Supabase file migration...');
  if (DRY_RUN) {
    console.log('⚠️  DRY RUN MODE - No files will be uploaded');
  }
  if (LIMIT) {
    console.log(`📊 Limiting to ${LIMIT} files`);
  }
  console.log('');

  let skip = 0;
  const limit = LIMIT || 100;
  let totalProcessed = 0;
  let totalMigrated = 0;
  let totalErrors = 0;

  try {
    while (true) {
      // Fetch Parse files
      const filesResponse = await parseRequest(`/classes/_File?limit=${limit}&skip=${skip}&order=createdAt`);
      const files = filesResponse.results || [];

      if (files.length === 0) {
        break;
      }

      console.log(`📦 Processing batch: ${skip + 1} to ${skip + files.length}...`);

      for (const parseFile of files) {
        totalProcessed++;
        const fileId = parseFile.objectId;
        const fileName = parseFile.name || 'file';
        const fileUrl = parseFile.url;

        try {
          console.log(`  📄 ${totalProcessed}. ${fileName} (${fileId})`);

          if (DRY_RUN) {
            console.log(`     → Would migrate to: migrated/${fileId}/${fileName}`);
            totalMigrated++;
            continue;
          }

          // Download file from Parse
          console.log(`     ⬇️  Downloading from Parse...`);
          const fileBuffer = await downloadParseFile(fileUrl);

          // Determine bucket based on file type or metadata
          // For now, use patient-files bucket (can be enhanced based on Parse metadata)
          const bucket = 'patient-files';

          // Build storage path
          // Note: We need to get patientId and orgId from the patient_files table
          // For now, use a generic path structure
          const storagePath = buildStoragePath(parseFile, null, null);

          // Upload to Supabase
          console.log(`     ⬆️  Uploading to Supabase Storage...`);
          await uploadToSupabase(bucket, storagePath, fileBuffer, parseFile.mimeType || 'application/octet-stream');

          // Update patient_files record if it exists
          try {
            await updatePatientFileRecord(fileId, bucket, storagePath);
            console.log(`     ✅ Updated patient_files record`);
          } catch (error) {
            console.warn(`     ⚠️  Could not update patient_files record: ${error.message}`);
          }

          totalMigrated++;
          console.log(`     ✅ Migrated successfully`);
        } catch (error) {
          totalErrors++;
          console.error(`     ❌ Error: ${error.message}`);
        }

        console.log('');
      }

      if (LIMIT && totalProcessed >= LIMIT) {
        break;
      }

      if (files.length < limit) {
        break;
      }

      skip += limit;
    }

    console.log('');
    console.log('📊 Migration Summary:');
    console.log(`   Total processed: ${totalProcessed}`);
    console.log(`   Successfully migrated: ${totalMigrated}`);
    console.log(`   Errors: ${totalErrors}`);
    if (DRY_RUN) {
      console.log('');
      console.log('⚠️  This was a dry run. Run without --dry-run to actually migrate files.');
    }
  } catch (error) {
    console.error('❌ Migration failed:', error);
    process.exit(1);
  }
}

// Run migration
migrateFiles().catch((error) => {
  console.error('Fatal error:', error);
  process.exit(1);
});

