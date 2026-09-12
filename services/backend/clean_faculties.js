const sqlite3 = require('sqlite3').verbose();
const path = require('path');

const dbPath = path.join(__dirname, 'database.sqlite');
const db = new sqlite3.Database(dbPath);

console.log("Cleaning up faculties...");

db.serialize(() => {
  // Find all faculty IDs that teach in D15 or TE
  const query = `
    SELECT DISTINCT facultyId 
    FROM timetable_slots 
    WHERE batchTarget LIKE '%D15%' OR batchTarget LIKE '%TE -%'
  `;

  db.all(query, [], (err, rows) => {
    if (err) {
      console.error(err);
      return;
    }

    const activeFacultyIds = rows.map(r => r.facultyId);
    console.log(`Found ${activeFacultyIds.length} active faculties teaching D15/TE.`);

    // Delete faculties that are not in this list
    const placeholders = activeFacultyIds.map(() => '?').join(',');
    const deleteQuery = `
      DELETE FROM users 
      WHERE role = 'faculty' AND id NOT IN (${placeholders})
    `;

    db.run(deleteQuery, activeFacultyIds, function(err) {
      if (err) {
        console.error(err);
        return;
      }
      console.log(`Flushed ${this.changes} inactive faculties.`);
      
      // Now update the emails of active faculties to ensure they have dummy emails
      // Currently they have emails like pn@ves.ac.in. We'll ensure they are clean.
      db.all(`SELECT id, name, email FROM users WHERE role = 'faculty'`, [], (err, faculties) => {
        if (err) return;
        
        console.log("\nActive Faculties and their Dummy Emails:");
        faculties.forEach(f => {
          // If the email is already somewhat dummy (like pn@ves.ac.in), we can leave it
          // or we can generate a standardized one like prof.pn@ves.ac.in
          let newEmail = f.email;
          if (!newEmail.startsWith('prof.')) {
              newEmail = `prof.${f.id.replace('fac-', '')}@ves.ac.in`.toLowerCase();
              db.run(`UPDATE users SET email = ? WHERE id = ?`, [newEmail, f.id]);
          }
          console.log(`- ${f.name}: ${newEmail} (Password: pass123)`);
        });
        console.log("\nCleanup Complete!");
      });
    });
  });
});
