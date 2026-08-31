const sqlite3 = require('sqlite3').verbose();
const db = new sqlite3.Database('./database.sqlite');
const crypto = require('crypto');

const timetableData = [
  // MONDAY
  { day: 'Mon', start: '08:30', end: '10:30', type: 'Lab', subject: 'Full stack', batch: 'D15A - Batch C', venue: '510', faculty: 'PS' },
  { day: 'Mon', start: '08:30', end: '10:30', type: 'Lab', subject: 'Data mining and business intellegence', batch: 'D15A - Batch B', venue: '513', faculty: 'SY' },
  { day: 'Mon', start: '08:30', end: '10:30', type: 'Lab', subject: 'Analysis of algorithms', batch: 'D15A - Batch A', venue: '512', faculty: 'PN' },
  { day: 'Mon', start: '08:30', end: '09:30', type: 'Lecture', subject: 'cloud computing and services', batch: 'D15B - All', venue: 'B51', faculty: 'KJS' },
  { day: 'Mon', start: '09:30', end: '10:30', type: 'Lecture', subject: 'cloud computing and services', batch: 'D15B - All', venue: 'B51', faculty: 'KJS' },
  { day: 'Mon', start: '08:30', end: '10:30', type: 'Lab', subject: 'Full stack', batch: 'D15C - Batch A', venue: '509', faculty: 'RUK' },
  { day: 'Mon', start: '08:30', end: '10:30', type: 'Lab', subject: 'Data mining and business intellegence', batch: 'D15C - Batch C', venue: '505', faculty: 'ARK' },
  { day: 'Mon', start: '08:30', end: '10:30', type: 'Lab', subject: 'Analysis of algorithms', batch: 'D15C - Batch B', venue: '506', faculty: 'POP' },
  { day: 'Mon', start: '10:30', end: '11:30', type: 'Lecture', subject: 'soft computing', batch: 'TE - Soft Computing (All)', venue: 'B51', faculty: 'SSO' },
  { day: 'Mon', start: '10:30', end: '11:30', type: 'Lecture', subject: 'advance database management techniques', batch: 'TE - ADMT (All)', venue: 'B52', faculty: 'CN' },
  { day: 'Mon', start: '10:30', end: '11:30', type: 'Lecture', subject: 'advance database management techniques', batch: 'TE - ADMT (All)', venue: '516', faculty: 'VP' },
  { day: 'Mon', start: '11:30', end: '12:30', type: 'Lecture', subject: 'cloud computing and services', batch: 'D15A - All', venue: 'B51', faculty: 'MS' },
  { day: 'Mon', start: '11:30', end: '12:30', type: 'Lecture', subject: 'Analysis of algorithms', batch: 'D15B - All', venue: 'B52', faculty: 'X1' },
  { day: 'Mon', start: '11:30', end: '12:30', type: 'Lecture', subject: 'Data mining and business intellegence', batch: 'D15C - All', venue: '516', faculty: 'ARK' },
  { day: 'Mon', start: '13:30', end: '15:30', type: 'Lab', subject: 'advance database management techniques', batch: 'D15A - Batch A (ADMT)', venue: '510', faculty: 'CN' },
  { day: 'Mon', start: '13:30', end: '15:30', type: 'Lab', subject: 'advance database management techniques', batch: 'D15B - Batch A (ADMT)', venue: '512', faculty: 'RWK' },
  { day: 'Mon', start: '13:30', end: '15:30', type: 'Lab', subject: 'soft computing', batch: 'TE - Soft Computing (Batch A)', venue: '513', faculty: 'SSO' },

  // TUESDAY
  { day: 'Tue', start: '08:30', end: '10:30', type: 'Lab', subject: 'Full stack', batch: 'D15A - Batch B', venue: '510', faculty: 'PS' },
  { day: 'Tue', start: '08:30', end: '10:30', type: 'Lab', subject: 'cloud computing and services', batch: 'D15A - Batch A', venue: '511', faculty: 'MS' },
  { day: 'Tue', start: '08:30', end: '10:30', type: 'Lab', subject: 'Analysis of algorithms', batch: 'D15A - Batch C', venue: '512', faculty: 'PN' },
  { day: 'Tue', start: '08:30', end: '09:30', type: 'Lecture', subject: 'Analysis of algorithms', batch: 'D15B - All', venue: 'B52', faculty: 'X1' },
  { day: 'Tue', start: '09:30', end: '10:30', type: 'Lecture', subject: 'Data mining and business intellegence', batch: 'D15B - All', venue: 'B52', faculty: 'SUR' },
  { day: 'Tue', start: '08:30', end: '10:30', type: 'Lab', subject: 'cloud computing and services', batch: 'D15C - Batch C', venue: '509', faculty: 'X3' },
  { day: 'Tue', start: '08:30', end: '10:30', type: 'Lab', subject: 'Data mining and business intellegence', batch: 'D15C - Batch B', venue: '505', faculty: 'ARK' },
  { day: 'Tue', start: '08:30', end: '10:30', type: 'Lab', subject: 'Analysis of algorithms', batch: 'D15C - Batch A', venue: '506', faculty: 'POP' },
  { day: 'Tue', start: '10:30', end: '12:30', type: 'Lab', subject: 'Data mining and business intellegence', batch: 'D15A - Batch A', venue: '509', faculty: 'SY' },
  { day: 'Tue', start: '10:30', end: '12:30', type: 'Lab', subject: 'cloud computing and services', batch: 'D15A - Batch C', venue: '505', faculty: 'MS' },
  { day: 'Tue', start: '10:30', end: '12:30', type: 'Lab', subject: 'Analysis of algorithms', batch: 'D15A - Batch B', venue: '513', faculty: 'PN' },
  { day: 'Tue', start: '10:30', end: '12:30', type: 'Lab', subject: 'Full stack', batch: 'D15B - Batch B', venue: '510', faculty: 'POP' },
  { day: 'Tue', start: '10:30', end: '12:30', type: 'Lab', subject: 'cloud computing and services', batch: 'D15B - Batch A', venue: '512', faculty: 'KJS' },
  { day: 'Tue', start: '10:30', end: '12:30', type: 'Lab', subject: 'Analysis of algorithms', batch: 'D15B - Batch C', venue: '511', faculty: 'X1' },
  { day: 'Tue', start: '10:30', end: '12:30', type: 'Lab', subject: 'Data mining and business intellegence', batch: 'D15C - Batch A', venue: '506', faculty: 'ARK' },
  { day: 'Tue', start: '10:30', end: '12:30', type: 'Lab', subject: 'Full stack', batch: 'D15C - Batch C', venue: '507', faculty: 'RUK' },
  { day: 'Tue', start: '10:30', end: '12:30', type: 'Lab', subject: 'cloud computing and services', batch: 'D15C - Batch B', venue: 'CA-4', faculty: 'X3' },
  { day: 'Tue', start: '13:30', end: '14:30', type: 'Lecture', subject: 'soft computing', batch: 'TE - Soft Computing (All)', venue: 'B51', faculty: 'SSO' },
  { day: 'Tue', start: '13:30', end: '14:30', type: 'Lecture', subject: 'advance database management techniques', batch: 'TE - ADMT (All)', venue: 'B52', faculty: 'CN' },
  { day: 'Tue', start: '13:30', end: '14:30', type: 'Lecture', subject: 'advance database management techniques', batch: 'TE - ADMT (All)', venue: '514', faculty: 'VP' },

  // WEDNESDAY
  { day: 'Wed', start: '08:30', end: '09:30', type: 'Lecture', subject: 'Data mining and business intellegence', batch: 'D15A - All', venue: 'B51', faculty: 'DK' },
  { day: 'Wed', start: '08:30', end: '10:30', type: 'Lab', subject: 'Data mining and business intellegence', batch: 'D15B - Batch A', venue: '509', faculty: 'SUR' },
  { day: 'Wed', start: '08:30', end: '10:30', type: 'Lab', subject: 'cloud computing and services', batch: 'D15B - Batch B', venue: '512', faculty: 'KJS' },
  { day: 'Wed', start: '08:30', end: '10:30', type: 'Lab', subject: 'Data mining and business intellegence', batch: 'D15B - Batch C', venue: '511', faculty: 'SY' },
  { day: 'Wed', start: '08:30', end: '10:30', type: 'Lab', subject: 'Full stack', batch: 'D15C - Batch B', venue: '510', faculty: 'RUK' },
  { day: 'Wed', start: '08:30', end: '10:30', type: 'Lab', subject: 'cloud computing and services', batch: 'D15C - Batch A', venue: '513', faculty: 'VM' },
  { day: 'Wed', start: '08:30', end: '10:30', type: 'Lab', subject: 'Analysis of algorithms', batch: 'D15C - Batch C', venue: 'CA-4', faculty: 'POP' },
  { day: 'Wed', start: '09:30', end: '10:30', type: 'Lecture', subject: 'cloud computing and services', batch: 'D15A - All', venue: 'B51', faculty: 'MS' },
  { day: 'Wed', start: '10:30', end: '11:30', type: 'Lecture', subject: 'Analysis of algorithms', batch: 'D15A - All', venue: 'B51', faculty: 'PN' },
  { day: 'Wed', start: '10:30', end: '11:30', type: 'Lecture', subject: 'Data mining and business intellegence', batch: 'D15B - All', venue: '515', faculty: 'SUR' },
  { day: 'Wed', start: '10:30', end: '11:30', type: 'Lecture', subject: 'cloud computing and services', batch: 'D15C - All', venue: 'B52', faculty: 'VM' },
  { day: 'Wed', start: '11:30', end: '12:30', type: 'Lecture', subject: 'Full stack', batch: 'D15A - All', venue: 'B51', faculty: 'PS' },
  { day: 'Wed', start: '11:30', end: '12:30', type: 'Lecture', subject: 'cloud computing and services', batch: 'D15B - All', venue: '515', faculty: 'KJS' },
  { day: 'Wed', start: '11:30', end: '12:30', type: 'Lecture', subject: 'Analysis of algorithms', batch: 'D15C - All', venue: 'B52', faculty: 'POP' },

  // THURSDAY
  { day: 'Thu', start: '08:30', end: '10:30', type: 'Lab', subject: 'advance database management techniques', batch: 'D15A - Batch B (ADMT)', venue: '510', faculty: 'CN' },
  { day: 'Thu', start: '08:30', end: '10:30', type: 'Lab', subject: 'advance database management techniques', batch: 'D15B - Batch B (ADMT)', venue: '512', faculty: 'RWK' },
  { day: 'Thu', start: '08:30', end: '10:30', type: 'Lab', subject: 'soft computing', batch: 'TE - Soft Computing (Batch B)', venue: '513', faculty: 'X2' },
  { day: 'Thu', start: '10:30', end: '11:30', type: 'Lecture', subject: 'Data mining and business intellegence', batch: 'D15A - All', venue: 'B51', faculty: 'DK' },
  { day: 'Thu', start: '10:30', end: '12:30', type: 'Lab', subject: 'Full stack', batch: 'D15B - Batch C', venue: '510', faculty: 'POP' },
  { day: 'Thu', start: '10:30', end: '12:30', type: 'Lab', subject: 'Data mining and business intellegence', batch: 'D15B - Batch B', venue: '505', faculty: 'SY' },
  { day: 'Thu', start: '10:30', end: '12:30', type: 'Lab', subject: 'Analysis of algorithms', batch: 'D15B - Batch A', venue: '513', faculty: 'X1' },
  { day: 'Thu', start: '10:30', end: '11:30', type: 'Lecture', subject: 'Data mining and business intellegence', batch: 'D15C - All', venue: 'B52', faculty: 'ARK' },
  { day: 'Thu', start: '11:30', end: '12:30', type: 'Lecture', subject: 'Full stack', batch: 'D15C - All', venue: 'B52', faculty: 'RUK' },
  { day: 'Thu', start: '11:30', end: '12:30', type: 'Lecture', subject: 'Analysis of algorithms', batch: 'D15A - All', venue: 'B51', faculty: 'PN' },
  { day: 'Thu', start: '13:30', end: '15:30', type: 'Lab', subject: 'Full stack', batch: 'D15A - Batch A', venue: '509', faculty: 'PS' },
  { day: 'Thu', start: '13:30', end: '15:30', type: 'Lab', subject: 'cloud computing and services', batch: 'D15A - Batch B', venue: '505', faculty: 'MS' },
  { day: 'Thu', start: '13:30', end: '15:30', type: 'Lab', subject: 'Data mining and business intellegence', batch: 'D15A - Batch C', venue: '506', faculty: 'DK' },
  { day: 'Thu', start: '13:30', end: '15:30', type: 'Lab', subject: 'cloud computing and services', batch: 'D15B - Batch C', venue: '507', faculty: 'KJS' },
  { day: 'Thu', start: '13:30', end: '15:30', type: 'Lab', subject: 'Analysis of algorithms', batch: 'D15B - Batch B', venue: '513', faculty: 'X1' },
  { day: 'Thu', start: '13:30', end: '15:30', type: 'Lab', subject: 'Full stack', batch: 'D15B - Batch A', venue: 'CA-4', faculty: 'POP' },
  { day: 'Thu', start: '13:30', end: '14:30', type: 'Lecture', subject: 'Data mining and business intellegence', batch: 'D15C - All', venue: 'B52', faculty: 'ARK' },
  { day: 'Thu', start: '14:30', end: '15:30', type: 'Lecture', subject: 'cloud computing and services', batch: 'D15C - All', venue: 'B52', faculty: 'VM' },

  // FRIDAY
  { day: 'Fri', start: '08:30', end: '09:30', type: 'Lecture', subject: 'cloud computing and services', batch: 'D15A - All', venue: 'B51', faculty: 'MS' },
  { day: 'Fri', start: '08:30', end: '09:30', type: 'Lecture', subject: 'Full stack', batch: 'D15B - All', venue: 'B52', faculty: 'POP' },
  { day: 'Fri', start: '08:30', end: '09:30', type: 'Lecture', subject: 'cloud computing and services', batch: 'D15C - All', venue: '04', faculty: 'VM' },
  { day: 'Fri', start: '09:30', end: '10:30', type: 'Lecture', subject: 'Data mining and business intellegence', batch: 'D15A - All', venue: 'B51', faculty: 'DK' },
  { day: 'Fri', start: '09:30', end: '10:30', type: 'Lecture', subject: 'Data mining and business intellegence', batch: 'D15B - All', venue: 'B52', faculty: 'SUR' },
  { day: 'Fri', start: '09:30', end: '10:30', type: 'Lecture', subject: 'Analysis of algorithms', batch: 'D15C - All', venue: '04', faculty: 'POP' },
  { day: 'Fri', start: '10:30', end: '11:30', type: 'Lecture', subject: 'Analysis of algorithms', batch: 'D15A - All', venue: 'B51', faculty: 'PN' },
  { day: 'Fri', start: '10:30', end: '11:30', type: 'Lecture', subject: 'Analysis of algorithms', batch: 'D15B - All', venue: 'B52', faculty: 'X1' },
  { day: 'Fri', start: '10:30', end: '11:30', type: 'Lecture', subject: 'Analysis of algorithms', batch: 'D15C - All', venue: '514', faculty: 'POP' },
  { day: 'Fri', start: '11:30', end: '12:30', type: 'Lecture', subject: 'soft computing', batch: 'TE - Soft Computing (All)', venue: 'B51', faculty: 'SSO' },
  { day: 'Fri', start: '11:30', end: '12:30', type: 'Lecture', subject: 'advance database management techniques', batch: 'TE - ADMT (All)', venue: 'B52', faculty: 'CN' },
  { day: 'Fri', start: '11:30', end: '12:30', type: 'Lecture', subject: 'advance database management techniques', batch: 'TE - ADMT (All)', venue: '514', faculty: 'VP' },
  { day: 'Fri', start: '13:30', end: '15:30', type: 'Lab', subject: 'advance database management techniques', batch: 'D15A - Batch C (ADMT)', venue: '510', faculty: 'CN' },
  { day: 'Fri', start: '13:30', end: '15:30', type: 'Lab', subject: 'advance database management techniques', batch: 'D15B - Batch C (ADMT)', venue: '512', faculty: 'RWK' },
  { day: 'Fri', start: '13:30', end: '15:30', type: 'Lab', subject: 'soft computing', batch: 'TE - Soft Computing (Batch C)', venue: 'CA-4', faculty: 'X3' }
];

db.serialize(() => {
  const insertFaculty = db.prepare(`INSERT OR IGNORE INTO users (id, role, name, email, password) VALUES (?, 'faculty', ?, ?, 'pass123')`);
  const insertSlot = db.prepare(`INSERT INTO timetable_slots (id, facultyId, day, subject, type, batchTarget, venue, startTime, endTime) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)`);

  let addedCount = 0;

  for (const slot of timetableData) {
    const facId = 'fac-' + slot.faculty.toLowerCase();
    
    // Auto-create faculty member based on initials
    insertFaculty.run([
      facId,
      'Prof. ' + slot.faculty,
      slot.faculty.toLowerCase() + '@ves.ac.in'
    ]);

    // Insert the timetable slot
    insertSlot.run([
      crypto.randomUUID(),
      facId,
      slot.day,
      slot.subject,
      slot.type,
      slot.batch,
      slot.venue,
      slot.start,
      slot.end
    ]);
    
    addedCount++;
  }

  insertFaculty.finalize();
  insertSlot.finalize();

  console.log(`Successfully seeded ${addedCount} timetable slots and auto-created their respective faculty accounts!`);
});
