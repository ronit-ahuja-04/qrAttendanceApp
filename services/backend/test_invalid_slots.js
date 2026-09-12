const sqlite3 = require('sqlite3').verbose();
const db = new sqlite3.Database('./database.sqlite');

db.all("SELECT id, subject, batchTarget FROM timetable_slots", [], (err, rows) => {
  rows.forEach(row => {
    let valid = false;
    const bt = row.batchTarget;
    const sub = row.subject.toLowerCase();
    
    if (sub.includes('soft computing') || sub.includes('admt') || sub.includes('database')) {
      if (bt.startsWith('TE - ') && (bt.includes('Batch') || bt.includes('All'))) valid = true;
    } else {
      if (bt.startsWith('D1') && bt.includes('-') && (bt.includes('Batch') || bt.includes('All'))) valid = true;
    }
    
    if (!valid) {
      console.log(`INVALID: ${row.id} | ${row.subject} | ${row.batchTarget}`);
    }
  });
});
