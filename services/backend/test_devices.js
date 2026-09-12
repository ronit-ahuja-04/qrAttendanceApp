require('dotenv').config();
const db = require('./database');

db.all("SELECT name, deviceId FROM users WHERE role = 'student' AND deviceId IS NOT NULL", [], (err, rows) => {
  if (err) console.error(err);
  else {
    rows.forEach(r => console.log(`${r.name}: ${r.deviceId}`));
  }
});
