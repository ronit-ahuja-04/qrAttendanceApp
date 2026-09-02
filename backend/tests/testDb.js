const db = require('../database');

const seedTestDb = () => {
  return new Promise((resolve, reject) => {
    db.serialize(() => {
      // Clear existing tables
      db.run('DELETE FROM users');
      db.run('DELETE FROM sessions');
      db.run('DELETE FROM attendance_records');

      // Insert Faculty
      const facultyStmt = db.prepare('INSERT INTO users (id, role, name, email, password) VALUES (?, ?, ?, ?, ?)');
      facultyStmt.run('fac1', 'faculty', 'Test Faculty', 'fac@test.com', 'facpass');
      facultyStmt.run('fac2', 'faculty', 'Test Faculty 2', 'fac2@test.com', 'facpass2');
      facultyStmt.finalize();

      // Insert Timetable Slots
      const slotStmt = db.prepare('INSERT INTO timetable_slots (id, facultyId, day, subject, type, batchTarget, venue, startTime, endTime) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)');
      slotStmt.run('slot-1', 'fac1', 'Monday', 'INFT-TEST', 'Lecture', 'Batch A', 'Room 1', '10:00', '11:00');
      slotStmt.run('slot-2', 'fac2', 'Monday', 'INFT-TEST', 'Lecture', 'Batch A', 'Room 2', '11:00', '12:00');
      slotStmt.finalize();

      // Insert Student
      const studentStmt = db.prepare('INSERT INTO users (id, role, name, rollNo, email, password, division, coreBatch) VALUES (?, ?, ?, ?, ?, ?, ?, ?)');
      studentStmt.run('stud1', 'student', 'Test Student', '21CMP123', 'stud@test.com', 'studpass', 'D7C', 'Batch A');
      studentStmt.run('stud2', 'student', 'Test Student 2', '21CMP124', 'stud2@test.com', 'studpass2', 'D7C', 'Batch A');
      studentStmt.finalize(() => {
        resolve();
      });
    });
  });
};

module.exports = { seedTestDb };
