require('dotenv').config({ path: __dirname + '/../.env' }); // Load env variables from backend/.env

// Important: Require database *after* dotenv config
const db = require('../database');
const crypto = require('crypto');

async function runCleanup() {
  console.log("🚀 Starting D15A Pilot Cleanup Process...");

  const queries = [
    // 1. Update Faculty Emails
    { sql: `UPDATE users SET email = 'pooja.shetty@ves.ac.in' WHERE email = 'prof.ps@ves.ac.in'`, desc: "Updating Pooja Shetty" },
    { sql: `UPDATE users SET email = 'manoj.sabnis@ves.ac.in' WHERE email = 'prof.ms@ves.ac.in'`, desc: "Updating Manoj Sabnis" },
    { sql: `UPDATE users SET email = 'pooja.nagdev@ves.ac.in' WHERE email = 'prof.pn@ves.ac.in'`, desc: "Updating Pooja Nagdev" },
    { sql: `UPDATE users SET email = 'shanta.sondur@ves.ac.in' WHERE email = 'prof.sso@ves.ac.in'`, desc: "Updating Shanta Sondur" },
    { sql: `UPDATE users SET email = 'charusheela.nehete@ves.ac.in' WHERE email = 'prof.cn@ves.ac.in'`, desc: "Updating Charusheela Nehete" },
    { sql: `UPDATE users SET email = 'swapnil.yadav@ves.ac.in' WHERE email = 'prof.sy@ves.ac.in'`, desc: "Updating Swapnil Yadav" },
    
    // 2. Add Nayan Chavan as a Helper/Proxy Faculty (if not exists)
    { 
      sql: `INSERT INTO users (id, role, name, email, password) 
            SELECT '${crypto.randomUUID()}', 'faculty', 'Nayan Chavan', 'nayan.chavan@ves.ac.in', 'pass123'
            WHERE NOT EXISTS (SELECT 1 FROM users WHERE email = 'nayan.chavan@ves.ac.in')`, 
      desc: "Adding Nayan Chavan as proxy faculty" 
    },

    // 3. Delete non-D15A students
    { sql: `DELETE FROM users WHERE role = 'student' AND (division != 'D15A' OR division IS NULL)`, desc: "Wiping non-D15A students" },

    // 4. Wipe all sessions and attendance records
    { sql: `DELETE FROM sessions`, desc: "Flushing all sessions" },
    { sql: `DELETE FROM attendance_records`, desc: "Flushing all attendance logs" },

    // 5. Delete non-D15A timetables
    { sql: `DELETE FROM timetable_slots WHERE batchTarget NOT LIKE '%D15A%'`, desc: "Wiping non-D15A timetables" },

    // 6. Wipe unused faculty (except Nayan Chavan and those actively in timetables)
    { 
      sql: `DELETE FROM users 
            WHERE role = 'faculty' 
            AND email != 'nayan.chavan@ves.ac.in'
            AND id NOT IN (SELECT DISTINCT facultyId FROM timetable_slots)`, 
      desc: "Wiping unused faculty" 
    }
  ];

  // Helper to execute query safely
  const runQuery = (queryObj) => {
    return new Promise((resolve, reject) => {
      process.stdout.write(`⏳ ${queryObj.desc}... `);
      db.run(queryObj.sql, function(err) {
        if (err) {
          console.error(`❌ Error: ${err.message}`);
          reject(err);
        } else {
          console.log(`✅ Done! (Rows affected: ${this.changes || 0})`);
          resolve();
        }
      });
    });
  };

  // Give DB a moment to connect if it's Turso
  await new Promise(resolve => setTimeout(resolve, 2000));

  for (const q of queries) {
    try {
      await runQuery(q);
    } catch (e) {
      console.error("Cleanup aborted due to error.");
      process.exit(1);
    }
  }

  console.log("\n📊 Verification - Remaining Data Counts:");
  
  const getCount = (table, condition = '') => {
    return new Promise(resolve => {
      db.get(`SELECT COUNT(*) as count FROM ${table} ${condition}`, (err, row) => {
        console.log(`   ${table} ${condition ? `(${condition})` : ''}: ${row ? row.count : 0}`);
        resolve();
      });
    });
  };

  await getCount('users', `WHERE role = 'student'`);
  await getCount('users', `WHERE role = 'faculty'`);
  await getCount('timetable_slots');
  await getCount('sessions');
  await getCount('attendance_records');

  console.log("\n🎉 Pilot Cleanup Complete!");
  process.exit(0);
}

runCleanup();
