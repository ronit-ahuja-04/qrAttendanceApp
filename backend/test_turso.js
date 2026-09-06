require('dotenv').config();
const db = require('./database.js');
setTimeout(() => {
  db.all("SELECT id, name, email, deviceId FROM users WHERE name LIKE '%ronit%' OR name LIKE '%vivek%'", [], (err, rows) => {
    if (err) console.error(err);
    console.log('Users found:', rows);
  });
}, 1000);
