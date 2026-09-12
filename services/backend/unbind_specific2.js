require('dotenv').config();
const db = require('./database');

const names = [
  'sindra vikram kanaram sukiyedevi',
  'kawinna harsh jagdish sandhya',
  'duseja tisha suresh kesar'
];

let query = "UPDATE users SET deviceId = NULL WHERE role = 'student' AND (";
const conditions = names.map(() => "name = ?").join(" OR ");
query += conditions + ")";

db.run(query, names, function(err) {
  if (err) console.error("Error unbinding specific students:", err);
  else console.log("Successfully unbound the remaining students. Changes:", this.changes);
});
