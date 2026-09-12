require('dotenv').config();
const db = require('./database');
db.run("UPDATE users SET deviceId = NULL WHERE role = 'student'", (err) => {
  if (err) console.error("Error unbinding students:", err);
  else console.log("Successfully unbound all students");
});
