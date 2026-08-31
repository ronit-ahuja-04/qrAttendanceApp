const sqlite3 = require('sqlite3').verbose();
const fs = require('fs');
const db = new sqlite3.Database('./database.sqlite');
const crypto = require('crypto');

let code = fs.readFileSync('seed.js', 'utf8');
const match = code.match(/const rawData = `([\s\S]*?)`;/);
const rawData = match[1];

function getCoreBatch(rollNo) {
  const r = parseInt(rollNo);
  if (r <= 25) return 'Batch A';
  if (r <= 50) return 'Batch B';
  return 'Batch C';
}

function processStudents() {
  const lines = rawData.trim().split('\n');
  const students = [];
  for (let line of lines) {
    if (!line.trim()) continue;
    const parts = line.split('\t').map(p => p.trim());
    if (parts.length < 6) continue;
    const rollNo = parts[0];
    const div = parts[1];
    const name = parts[2];
    const email = parts[3] || `student${rollNo}${div}@ves.ac.in`;
    const electiveSubject = parts[4] === 'Advanced Data Management Technologies' ? 'ADMT' : 
                            (parts[4] === 'Soft Computing' ? 'Soft Computing' : parts[4]);
    const electiveBatch = parts[5];
    const coreBatch = getCoreBatch(rollNo);
    const divisionStr = `D15${div}`;
    const id = crypto.randomUUID();
    students.push({ id, name, rollNo, email, division: divisionStr, coreBatch, electiveSubject, electiveBatch });
  }
  return students;
}

const students = processStudents();
db.serialize(() => {
  db.run(`DELETE FROM users WHERE role = 'student'`);
  const stmt = db.prepare(`INSERT INTO users (id, role, name, rollNo, email, password, profilePictureUrl, division, coreBatch, electiveSubject, electiveBatch) VALUES (?, 'student', ?, ?, ?, 'pass123', NULL, ?, ?, ?, ?)`);
  for (const s of students) {
    stmt.run([s.id, s.name, s.rollNo, s.email, s.division, s.coreBatch, s.electiveSubject, s.electiveBatch]);
  }
  stmt.finalize();
  console.log(`Successfully seeded ${students.length} students!`);
});
