require('dotenv').config();
const db = require('./database');

const names = [
  '%vikram sindra%',
  '%hardik%',
  '%soniya%',
  '%daksh%',
  '%harsh kawinna%',
  '%tisha duseja%'
];

let query = "UPDATE users SET deviceId = NULL WHERE role = 'student' AND (";
const conditions = names.map(() => "name LIKE ?").join(" OR ");
query += conditions + ")";

db.run(query, names, function(err) {
  if (err) console.error("Error unbinding specific students:", err);
  else console.log("Successfully unbound the requested students. Changes:", this.changes);
});
