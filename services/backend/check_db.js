require('dotenv').config();
const db = require('./database');
db.all("PRAGMA table_info(sessions)", [], (err, rows) => {
  if (err) console.error(err);
  else console.log(rows);
});
