const sqlite3 = require('sqlite3').verbose();
const path = require('path');

const dbPath = path.join(__dirname, 'database.sqlite');
const db = new sqlite3.Database(dbPath);

console.log("Starting DB Migration for Elective Batches...");

db.serialize(() => {
  db.all(`SELECT id, batchTarget FROM timetable_slots WHERE batchTarget LIKE '%ADMT%' OR batchTarget LIKE '%Soft Computing%'`, [], (err, rows) => {
    if (err) {
      console.error("Error reading slots:", err.message);
      return;
    }

    if (rows.length === 0) {
      console.log("No old elective targets found. Migration complete.");
      return;
    }

    console.log(`Found ${rows.length} rows to migrate.`);

    const stmt = db.prepare(`UPDATE timetable_slots SET batchTarget = ? WHERE id = ?`);

    rows.forEach(row => {
      let newTarget = row.batchTarget;
      
      // Convert "D15A - Batch A (ADMT)" to "TE - ADMT (Batch A)"
      if (row.batchTarget.includes('ADMT')) {
        if (row.batchTarget.includes('Batch A')) newTarget = 'TE - ADMT (Batch A)';
        else if (row.batchTarget.includes('Batch B')) newTarget = 'TE - ADMT (Batch B)';
        else if (row.batchTarget.includes('Batch C')) newTarget = 'TE - ADMT (Batch C)';
      } else if (row.batchTarget.includes('Soft Computing')) {
        if (row.batchTarget.includes('Batch A')) newTarget = 'TE - Soft Computing (Batch A)';
        else if (row.batchTarget.includes('Batch B')) newTarget = 'TE - Soft Computing (Batch B)';
        else if (row.batchTarget.includes('Batch C')) newTarget = 'TE - Soft Computing (Batch C)';
      }

      if (newTarget !== row.batchTarget) {
        console.log(`Migrating slot ${row.id}: ${row.batchTarget} -> ${newTarget}`);
        stmt.run(newTarget, row.id);
      }
    });

    stmt.finalize(() => {
      console.log("Migration finished successfully!");
    });
  });
});
