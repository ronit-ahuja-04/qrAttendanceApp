const db = require('./database');

setTimeout(() => {
  const id = "test_slot_123";
  db.run(
    'INSERT INTO timetable_slots (id, facultyId, day, subject, type, batchTarget, venue, startTime, endTime) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)',
    [id, "fac-123", "Monday", "SUB", "Lec", "All", "Room", "10:00", "11:00"],
    function (err) {
      if (err) console.error("INSERT ERROR:", err.message);
      else console.log("INSERT SUCCESS");
      
      db.all("SELECT * FROM timetable_slots WHERE id = ?", [id], (err, rows) => {
        if (err) console.error("SELECT ERROR:", err.message);
        else console.log("SELECT SUCCESS:", rows);
        process.exit(0);
      });
    }
  );
}, 2000);
