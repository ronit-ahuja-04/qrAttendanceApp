require('dotenv').config();
const db = require('./database');

db.run("UPDATE timetable_slots SET subject = 'Data Mining and Business Intelligence' WHERE subject = 'Data Mining and Business Intelligence (DMBI)'", (err) => {
  if (err) console.error("Error updating timetable_slots:", err);
  else console.log("Successfully updated timetable_slots");

  db.run("UPDATE sessions SET courseCode = 'Data Mining and Business Intelligence' WHERE courseCode = 'Data Mining and Business Intelligence (DMBI)'", (err) => {
    if (err) console.error("Error updating sessions:", err);
    else console.log("Successfully updated sessions");
    
    // Also update any sessions that might have ' - Lab' or ' - Lecture' appended
    db.run("UPDATE sessions SET courseCode = 'Data Mining and Business Intelligence - Lab' WHERE courseCode = 'Data Mining and Business Intelligence (DMBI) - Lab'", (err) => {
        if (err) console.error("Error updating lab sessions:", err);
        else console.log("Successfully updated lab sessions");
    });
  });
});
