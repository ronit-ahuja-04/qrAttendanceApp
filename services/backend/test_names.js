require('dotenv').config();
const db = require('./database');

db.all("SELECT id, name FROM users WHERE role = 'student'", [], (err, rows) => {
  if (err) console.error(err);
  else {
    const students = rows.map(r => r.name.toLowerCase());
    
    const terms = ['vikram', 'hardik', 'soniya', 'daksh', 'harsh', 'tisha'];
    for (const term of terms) {
      const matches = students.filter(s => s.includes(term));
      console.log(`Matches for '${term}':`, matches);
    }
  }
});
