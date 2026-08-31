const sqlite3 = require('sqlite3').verbose();
const db = new sqlite3.Database('./database.sqlite');

// Mapping from old batchTarget strings → new ones
const migrations = [
  // ADMT div-specific labs → now owned per division but shown without (ADMT) label
  ["D15A - Batch A (ADMT)", "D15A - Batch A"],
  ["D15A - Batch B (ADMT)", "D15A - Batch B"],
  ["D15A - Batch C (ADMT)", "D15A - Batch C"],
  ["D15B - Batch A (ADMT)", "D15B - Batch A"],
  ["D15B - Batch B (ADMT)", "D15B - Batch B"],
  ["D15B - Batch C (ADMT)", "D15B - Batch C"],
  ["D15C - Batch A (ADMT)", "D15C - Batch A"],
  ["D15C - Batch B (ADMT)", "D15C - Batch B"],
  ["D15C - Batch C (ADMT)", "D15C - Batch C"],
  // ADMT lectures (cross-division)
  ["TE - ADMT (All)", "TE - ADMT (All)"], // already ok, no change
];

db.serialize(() => {
  migrations.forEach(([oldVal, newVal]) => {
    if (oldVal === newVal) return;
    db.run(
      `UPDATE timetable_slots SET batchTarget = ? WHERE batchTarget = ?`,
      [newVal, oldVal],
      function(err) {
        if (err) console.error(`Error migrating "${oldVal}":`, err.message);
        else if (this.changes > 0) console.log(`  ✓ "${oldVal}" → "${newVal}" (${this.changes} rows)`);
      }
    );
  });
  console.log('Migration complete.');
});
