#!/usr/bin/env node
/**
 * Fix Appointment Notes Migration Script
 * 
 * This script:
 * 1. Moves appointment-specific notes from Patient_Note to Appointment.notes
 * 2. Deletes appointment-specific Patient_Notes
 * 3. Updates appointment notes with detailed information from case files
 * 
 * Affects: James Chen (MVA) and Linda Carver (Knee OA)
 */

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

// Linda Carver appointments with enhanced notes from CSV
const lindaAppointmentNotes = [
  {
    objectId: 'OvTtlyIXJ8', // Visit 1 - July 14
    notes: `Initial evaluation completed. Baseline measurements established.

**Presentation:**
- Pain: 7/10 NPRS
- KOOS-ADL: 58
- 30-second chair-stand: 9 reps

**Assessment:**
Right knee OA (M17.11) post-twist injury July 13/25. Moderate pain with stairs, prolonged sitting/standing. Extension lag noted. Perimenopausal patient, desk job, osteopenia risk.

**Goals Set:**
1. Reduce pain from 7/10 → ≤2/10 within 8 weeks
2. Restore ROM (flexion ≥130°, extension 0°) within 8 weeks  
3. Achieve 30sCS ≥12 within 6 weeks
4. Walk 5 km without pain within 12 weeks
5. Return to gardening within 12 weeks

**Plan:**
Initial phase: 2×/week visits, focus on pain management, ROM, and early strengthening. HEP provided with emphasis on quad control and weight-bearing tolerance.`
  },
  {
    objectId: 'XdvyPWwJOF', // Visit 2 - July 21
    notes: `Follow-up visit. Early improvement noted.

**Progress:**
- Pain: 6.5/10 NPRS (↓0.5)
- TUG: 9.8 seconds
- 30-second chair-stand: 10 reps (↑1)

**Treatment:**
Progressive ROM exercises, closed-chain strengthening. Patient tolerating HEP well. Good engagement with pain management strategies.

**Plan:**
Continue current approach. Progress ROM/strength exercises.`
  },
  {
    objectId: 'Z4ArhG5dfe', // Visit 3 - July 28
    notes: `Follow-up visit. Steady progression.

**Progress:**
- Pain: 6.0/10 NPRS (↓0.5)
- 30-second chair-stand: 11 reps (↑1)

**Treatment:**
Added eccentric control tasks. Focus on functional movements (sit-to-stand, stairs). Patient demonstrating improved quad activation.

**Plan:**
Maintain frequency. Continue progressive loading.`
  },
  {
    objectId: 'bqLmA2eRD2', // Visit 4 - Aug 4
    notes: `Follow-up visit. Goal #4 achieved early.

**Progress:**
- Pain: 5.0/10 NPRS (↓1.0)
- 30-second chair-stand: 12 reps (↑1) ✓ Goal met!

**Treatment:**
Chair-stand goal achieved ahead of schedule. Advanced to single-leg exercises and balance training. Patient very motivated.

**Plan:**
Progress resistance training. Begin return-to-activity planning.`
  },
  {
    objectId: 'dg4ESiAHp0', // Visit 5 - Aug 11
    notes: `Follow-up visit. ROM and loading progressing well.

**Progress:**
- Pain: 4.5/10 NPRS (↓0.5)
- TUG: 8.7 seconds (↓1.1s)

**Treatment:**
ROM improvements noted. Load tolerance increasing. Introduced gait retraining for gardening prep. Modified HEP to include outdoor walking.

**Plan:**
Continue current trajectory.`
  },
  {
    objectId: 'hMomZAebHm', // Visit 6 - Aug 18
    notes: `Progress re-evaluation. Excellent 6-week outcomes.

**Progress:**
- Pain: 4.0/10 NPRS (↓0.5)
- KOOS-ADL: 70 (↑12 points - clinically significant)
- 6MWT: 480 meters

**Assessment:**
Linda showing good progress at 6 weeks. KOOS-ADL improved from 58 to 70. Pain down from 7/10 to 4/10. Extension deficit nearly resolved. Tolerating progressive loading well. Sleep quality improving with menopause management strategies.

**Plan:**
On track with treatment plan. Transition to biweekly visits to allow for adaptation and continued home program progression. Patient comfortable with reduced frequency.`
  },
  {
    objectId: 'S89bxfa6yb', // Visit 7 - Sept 1
    notes: `Follow-up visit (biweekly schedule). Goal #2 achieved.

**Progress:**
- Pain: 3.5/10 NPRS (↓0.5)
- ROM: Flexion 125°, Extension -1° (↑ significant improvement)

**Treatment:**
Goal #2 met - ROM within functional range. Focus shifting to power and endurance. Introduced gardening-specific movements.

**Plan:**
Maintain biweekly frequency.`
  },
  {
    objectId: 'jkzuB5zloG', // Visit 8 - Sept 15
    notes: `Follow-up visit. Goal #1 achieved (late but achieved).

**Progress:**
- Pain: 3.0/10 NPRS (↓0.5)
- 30-second chair-stand: 14 reps (↑2)

**Treatment:**
Pain goal achieved (week 9 vs target week 8). Excellent functional strength gains. Patient confident with higher-level activities.

**Plan:**
Continue biweekly progression.`
  },
  {
    objectId: 'Fxm4tMjPDT', // Visit 9 - Sept 29 (CANCELLED)
    notes: `Appointment cancelled due to patient illness. Late cancellation - patient called morning of appointment with flu symptoms.

No change to treatment plan. Patient advised to continue HEP as tolerated and reschedule when recovered.`
  },
  {
    objectId: '7toVTl3cqD', // Visit 10 - Oct 13
    notes: `Progress re-evaluation. All primary goals met/maintained.

**Progress:**
- Pain: 2.0/10 NPRS (↓1.0) ✓ Goal exceeded!
- KOOS-ADL: 81 (↑11 points)
- 6MWT: 550 meters (↑70m)

**Assessment:**
Goals #1-#5 met or exceeded. Patient walking 5+ km comfortably. ROM full and pain-free. Return to gardening successful with no flare-ups.

**Plan:**
Begin discharge preparation. Focus on maintenance program and self-management strategies.`
  },
  {
    objectId: 'bh2KKgYyoy', // Visit 11 - Oct 27
    notes: `Follow-up visit. Maintaining excellent progress.

**Progress:**
- Pain: 2.0/10 NPRS (stable)
- 30-second chair-stand: 15 reps
- All goals maintained

**Treatment:**
Reviewed long-term maintenance program. Discussed OA self-management, activity pacing, and flare-up protocols. Patient confident and independent.

**Plan:**
One final visit for formal discharge evaluation.`
  },
  {
    objectId: 'ou9yWPgE2q', // Visit 12 - Nov 10 (DISCHARGE)
    notes: `Discharge re-evaluation. All discharge criteria met.

**Final Outcomes:**
- Pain: 1.5/10 NPRS (↓5.5 from baseline)
- KOOS-ADL: 84 (↑26 points - exceeds MCID)
- 6MWT: 570 meters
- ROM: Full flexion (130°), extension (0°)
- 30sCS: 15+ reps

**Assessment:**
Discharged Nov 10/25 - all goals exceeded. Pain 1.5/10, full ROM, KOOS-ADL 84 (+26 pts), walking 5-6 km comfortably. Independent with 3×/week strength program. Very satisfied with treatment outcome.

**Discharge Plan:**
- HEP: Continue 3×/week progressive strength program
- Long-term OA self-management education provided
- Flare-up algorithm reviewed
- Considering return to recreational curling
- Optional check-in 8-12 weeks PRN
- No further appointments scheduled unless symptoms recur

**Total Treatment:** 12 visits over 17 weeks (4 months). Excellent compliance and outcomes.`
  }
];

// James Chen appointments with enhanced notes from case file
const jamesAppointmentNotes = [
  {
    objectId: 'n1cx6hBItc', // Visit 1 - Aug 8
    notes: `Initial Assessment - Motor Vehicle Accident

**Incident:**
Date: Aug 3, 2025 at 4:20 PM
Mechanism: Rear-end collision while stopped on Highway 401
Symptoms: Neck and low back pain, stiffness, headache, mild dizziness

**Presentation:**
- Pain: 7/10 NPRS
- NDI (Neck Disability Index): 48%
- Regions: Cervical and lumbar spine
- ROM: Limited cervical rotation (40° bilat), flexion restricted
- Soft tissue tenderness C4-C7, L3-L5

**Diagnosis:**
- Primary: Whiplash injury to cervical spine (ICD-10: S13.4)
- Secondary: Sprain of ligaments of lumbar spine (ICD-10: S33.5)
- No neurological deficits noted

**SMART Goals:**
1. Reduce pain from 7/10 → ≤2/10 within 6 weeks
2. Restore cervical rotation ≥70° bilaterally within 8 weeks
3. Sit/work 2 hours without pain by week 10
4. Resume jogging by week 12

**Phase 1 Plan (Weeks 0-2):**
Acute phase: 2×/week physiotherapy
- Pain control strategies
- Gentle mobility work
- Education on activity modification

**HEP Provided:**
- Chin tucks 2×10 daily
- Cat-cow 2×15 daily
- Pelvic tilts 3×10 daily`
  },
  {
    objectId: 'mIqo0AT0PL', // Visit 2 - Aug 15
    notes: `Follow-up visit. Early improvement phase.

**Progress:**
- Pain: 6/10 NPRS (↓1.0)
- NDI: 42% (↓6% - positive trend)

**Treatment:**
Gentle manual therapy to cervical and lumbar regions. Progressive ROM exercises introduced. Patient tolerating treatment well. HEP compliance excellent.

**Assessment:**
Early improvement noted. Headaches reducing. Sleep improving with positional modifications.

**Plan:**
Continue acute phase protocols. Progress to subacute phase next week.`
  },
  {
    objectId: 'H6RYmiccT0', // Visit 3 - Aug 22
    notes: `Follow-up visit. HEP well tolerated.

**Progress:**
- Pain: 6/10 NPRS (stable)
- NDI: 40% (↓2%)

**Treatment:**
Progressed strengthening exercises. Added cervical stabilization work. Patient managing work modified duties (4 hours/day).

**Assessment:**
HEP compliance excellent. ROM gradually improving. Tissue quality improving with manual therapy.

**Plan:**
Begin subacute phase (weeks 3-6). Continue weekly visits.`
  },
  {
    objectId: 'zD3GHkZGqH', // Visit 4 - Aug 29
    notes: `Progress visit. Transitioning to strength phase.

**Progress:**
- Pain: 5/10 NPRS (↓1.0)
- NDI: 36% (↓4%)

**Treatment:**
Subacute phase initiated. Focus on range and strength restoration. Added core control exercises. Patient reports reduced morning stiffness.

**Assessment:**
Excellent progress trajectory. Working 6 hours/day without significant flare-ups.

**Plan:**
Continue weekly physiotherapy. Consider adding massage therapy for tissue work.`
  },
  {
    objectId: 'NH3pE2Jlcs', // Visit 5 - Sept 5
    notes: `Follow-up visit. Partial progress toward goals.

**Progress:**
- Pain: 4/10 NPRS (↓1.0)
- NDI: 32% (↓4%)

**Treatment:**
ROM and strength progressing steadily. Patient working full days (8 hours) with regular breaks. Endurance improving.

**Assessment:**
On track for 6-week pain goal. Cervical rotation approaching 60° bilaterally.

**Plan:**
Add massage therapy next week for complementary soft tissue work.`
  },
  {
    objectId: 'aRPoLuqiBO', // Visit 6 - Sept 12 (Massage Therapy)
    notes: `Soft Tissue Release - Massage Therapy

**Progress:**
- Pain: 4/10 NPRS (stable)
- NDI: 28% (↓4%)

**Treatment:**
Deep tissue massage to cervical and lumbar paraspinals. Trigger point release. Myofascial techniques. Patient reports immediate relief and increased mobility post-treatment.

**Plan:**
Continue alternating physiotherapy and massage therapy for optimal tissue management.`
  },
  {
    objectId: 'zChpzrHKko', // Visit 7 - Sept 19
    notes: `Follow-up visit. Adding posture drills.

**Progress:**
- Pain: 3/10 NPRS (↓1.0)
- NDI: 26% (↓2%)

**Treatment:**
Posture drills for work ergonomics. Advanced core stabilization. Cervical rotation ROM improving significantly (65° bilat).

**Assessment:**
Approaching goal #2 (70° cervical rotation). Patient very motivated and compliant.

**Plan:**
Continue weekly visits. Prepare for return to sport assessment.`
  },
  {
    objectId: 'qyTkhu68PB', // Visit 8 - Sept 26 (Massage Therapy)
    notes: `Manual Therapy - Massage Therapy

**Progress:**
- Pain: 3/10 NPRS (stable)
- NDI: 24% (↓2%)

**Treatment:**
Continued manual therapy and soft tissue mobilization. ROM nearly full in all planes. Tissue quality significantly improved.

**Assessment:**
ROM nearly full. Patient ready to progress to higher-level activities.

**Plan:**
Begin return-to-sport planning with physiotherapy.`
  },
  {
    objectId: 'I4j4q7adQ3', // Visit 9 - Oct 3
    notes: `Reassessment visit. Testing jogging readiness.

**Progress:**
- Pain: 2/10 NPRS (↓1.0) ✓ Goal #1 met!
- NDI: 18% (↓6% - significant improvement)

**Treatment:**
Jogging test performed: 10 minutes at easy pace, well tolerated without pain increase. Core control excellent. Cervical rotation >70° bilaterally ✓ Goal #2 met!

**Assessment:**
Goals #1 and #2 achieved. Patient returned to work full duty (no restrictions) since Sept 30.

**Plan:**
Transition to chronic phase (weeks 7-12). Reduce to biweekly visits. Progress return to sport.`
  },
  {
    objectId: 'bhkAG6TyX4', // Visit 10 - Oct 17
    notes: `Follow-up visit. Returned to full work duties.

**Progress:**
- Pain: 2/10 NPRS (stable)
- NDI: 12% (↓6% - approaching minimal disability)

**Assessment:**
Patient reports significantly improved sleep quality and reduced morning stiffness. Successfully working full days without pain flare-ups. Very motivated and engaged in recovery process. Working full 8-hour days at computer. Jogging 15 minutes 2×/week pain-free.

**Treatment:**
Goal #3 met - can sit/work 2+ hours without pain. Progressed jogging to 15-minute intervals. Advanced strengthening for injury prevention.

**Plan:**
Continue biweekly visits. Target discharge in 2-3 visits.`
  },
  {
    objectId: 'PzXjS0WAW0', // Visit 11 - Oct 24 (Massage Therapy)
    notes: `Maintenance visit - Massage Therapy

**Progress:**
- Pain: 1/10 NPRS (↓1.0)
- NDI: 8% (↓4% - minimal disability)

**Treatment:**
Maintenance soft tissue work. Preventive myofascial release. Patient jogging 20 minutes pain-free ✓ Goal #4 met!

**Assessment:**
All goals achieved. Patient ready for discharge next visit.

**Plan:**
One final physiotherapy visit for formal discharge evaluation.`
  },
  {
    objectId: 'USRanswDfD', // Visit 12 - Oct 31 (DISCHARGE)
    notes: `Discharge Visit - All Goals Achieved

**Final Outcomes:**
- Pain: 1/10 NPRS (↓6 from baseline)
- NDI: 6% (↓42% - from moderate to minimal disability)
- ROM: Full cervical and lumbar mobility
- Strength: 5/5 core and paraspinals
- Return to work: Full duty since Oct 20
- Activity: Jogging 20 min pain-free ✓ Goal #4 met

**Assessment:**
Discharged from care Oct 31, 2025. All functional goals achieved. Patient returned to jogging 20 minutes pain-free. Very satisfied with treatment outcome. Given maintenance HEP and instructions to contact if symptoms recur.

**Discharge Plan:**
- Maintenance HEP provided: Core activation 3×15 every other day
- Self-monitor for flare-ups
- Ergonomic setup optimized at work
- No driving restrictions
- Can resume all pre-injury activities
- Return PRN if symptoms recur

**Total Treatment:** 12 visits over 12 weeks (3 months)
- 8 Physiotherapy visits
- 4 Massage Therapy visits
- 100% attendance rate
- Excellent compliance with HEP
- All SMART goals achieved or exceeded

**Insurance:** MVA claim active throughout treatment. All documentation provided to insurer.`
  }
];

// Patient Notes to DELETE (appointment-specific ones that should be in Appointment.notes)
const patientNotesToDelete = [
  'Dw6DgWIBAN', // Linda - "Linda showing good progress at 6 weeks..."
  'oArcCxwlqo', // Linda - "Discharged Nov 10/25..."
  '1L8GDmb8de', // James - "Patient reports significantly improved sleep..."
  '9xekV1O4lX'  // James - "Discharged from care Oct 31..."
];

async function updateAppointmentNotes(appointmentData) {
  console.log(`\n--- Updating ${appointmentData.length} appointments ---`);
  
  const Appointment = Parse.Object.extend('Appointment');
  
  for (const data of appointmentData) {
    try {
      const query = new Parse.Query(Appointment);
      const appointment = await query.get(data.objectId, { useMasterKey: true });
      
      appointment.set('notes', data.notes);
      await appointment.save(null, { useMasterKey: true });
      
      console.log(`✓ Updated appointment ${data.objectId}`);
    } catch (error) {
      console.error(`✗ Failed to update appointment ${data.objectId}:`, error.message);
    }
  }
}

async function deletePatientNotes(noteIds) {
  console.log(`\n--- Deleting ${noteIds.length} appointment-specific Patient_Notes ---`);
  
  const PatientNote = Parse.Object.extend('Patient_Note');
  
  for (const noteId of noteIds) {
    try {
      const query = new Parse.Query(PatientNote);
      const note = await query.get(noteId, { useMasterKey: true });
      
      const preview = note.get('text').substring(0, 50);
      await note.destroy({ useMasterKey: true });
      
      console.log(`✓ Deleted Patient_Note ${noteId}: "${preview}..."`);
    } catch (error) {
      console.error(`✗ Failed to delete Patient_Note ${noteId}:`, error.message);
    }
  }
}

async function verifyChanges() {
  console.log('\n--- Verification ---');
  
  const Appointment = Parse.Object.extend('Appointment');
  const Patient = Parse.Object.extend('Patient');
  const PatientNote = Parse.Object.extend('Patient_Note');
  
  // Check Linda's appointments
  const lindaQuery = new Parse.Query(Appointment);
  lindaQuery.equalTo('objectId', 'ou9yWPgE2q'); // Linda's discharge visit
  const lindaAppt = await lindaQuery.first({ useMasterKey: true });
  console.log(`\n✓ Linda's discharge appointment notes length: ${lindaAppt.get('notes')?.length || 0} chars`);
  
  // Check James's appointments
  const jamesQuery = new Parse.Query(Appointment);
  jamesQuery.equalTo('objectId', 'USRanswDfD'); // James's discharge visit
  const jamesAppt = await jamesQuery.first({ useMasterKey: true });
  console.log(`✓ James's discharge appointment notes length: ${jamesAppt.get('notes')?.length || 0} chars`);
  
  // Check remaining Patient_Notes
  const lindaPatientQuery = new Parse.Query(Patient);
  lindaPatientQuery.equalTo('lastName', 'Carver');
  const lindaPatient = await lindaPatientQuery.first({ useMasterKey: true });
  
  const lindaNotesQuery = new Parse.Query(PatientNote);
  lindaNotesQuery.equalTo('patientId', lindaPatient.id);
  const lindaNotes = await lindaNotesQuery.find({ useMasterKey: true });
  console.log(`\n✓ Linda's remaining Patient_Notes: ${lindaNotes.length} (should be 1 - the overarching note)`);
  
  const jamesPatientQuery = new Parse.Query(Patient);
  jamesPatientQuery.equalTo('lastName', 'Chen');
  jamesPatientQuery.equalTo('firstName', 'James');
  const jamesPatient = await jamesPatientQuery.first({ useMasterKey: true });
  
  const jamesNotesQuery = new Parse.Query(PatientNote);
  jamesNotesQuery.equalTo('patientId', jamesPatient.id);
  const jamesNotes = await jamesNotesQuery.find({ useMasterKey: true });
  console.log(`✓ James's remaining Patient_Notes: ${jamesNotes.length} (should be 1 - the overarching note)`);
}

async function main() {
  console.log('=================================================');
  console.log('   Fix Appointment Notes Migration Script');
  console.log('=================================================');
  
  try {
    const { PARSE_SERVER_URL, PARSE_APP_ID, PARSE_MASTER_KEY } = loadParseEnv();
    Parse.initialize(PARSE_APP_ID);
    Parse.serverURL = PARSE_SERVER_URL;
    Parse.masterKey = PARSE_MASTER_KEY;
    
    console.log('✓ Initialized Parse with master key');
    
    // Step 1: Update Linda Carver's appointments
    console.log('\n📝 Updating Linda Carver appointments...');
    await updateAppointmentNotes(lindaAppointmentNotes);
    
    // Step 2: Update James Chen's appointments
    console.log('\n📝 Updating James Chen appointments...');
    await updateAppointmentNotes(jamesAppointmentNotes);
    
    // Step 3: Delete appointment-specific Patient_Notes
    console.log('\n🗑️  Deleting appointment-specific Patient_Notes...');
    await deletePatientNotes(patientNotesToDelete);
    
    // Step 4: Verify changes
    await verifyChanges();
    
    console.log('\n=================================================');
    console.log('✅ Migration completed successfully!');
    console.log('=================================================');
    console.log('\nSummary:');
    console.log(`- Updated ${lindaAppointmentNotes.length} Linda Carver appointments`);
    console.log(`- Updated ${jamesAppointmentNotes.length} James Chen appointments`);
    console.log(`- Deleted ${patientNotesToDelete.length} appointment-specific Patient_Notes`);
    console.log('\nRemaining Patient_Notes are overarching patient notes:');
    console.log('- Linda: Right knee OA diagnosis and treatment overview');
    console.log('- James: MVA patient special care note');
    
  } catch (error) {
    console.error('\n❌ Migration failed:', error);
    process.exit(1);
  }
}

main();
