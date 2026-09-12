import re

with open('index.js', 'r') as f:
    content = f.read()

# 1. Update POST /sessions
insert_old = """      db.run(`INSERT INTO sessions (id, courseCode, facultyId, proxyFacultyId, status, enrolledStudentIds, createdAt, approvalStatus)
              VALUES (?, ?, ?, ?, ?, ?, ?, ?)`,
        [id, courseCode, finalFacultyId, proxyFacultyId, 'scheduled', JSON.stringify(enrolledIds), now, approvalStatus],"""
insert_new = """      db.run(`INSERT INTO sessions (id, courseCode, facultyId, proxyFacultyId, status, enrolledStudentIds, createdAt, approvalStatus, batchTarget)
              VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)`,
        [id, courseCode, finalFacultyId, proxyFacultyId, 'scheduled', JSON.stringify(enrolledIds), now, approvalStatus, batchTarget],"""
content = content.replace(insert_old, insert_new)

# 2. Update POST /sessions/bulk
bulk_old = """      await new Promise((resolve, reject) => {
        db.run('INSERT INTO sessions (id, courseCode, facultyId, proxyFacultyId, status, enrolledStudentIds, createdAt, approvalStatus, groupId) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)',
          [id, t.courseCode, scopeFacultyId, proxyFacultyId, 'scheduled', JSON.stringify(enrolledIds), now, 'pending', groupId],"""
bulk_new = """      await new Promise((resolve, reject) => {
        db.run('INSERT INTO sessions (id, courseCode, facultyId, proxyFacultyId, status, enrolledStudentIds, createdAt, approvalStatus, groupId, batchTarget) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
          [id, t.courseCode, scopeFacultyId, proxyFacultyId, 'scheduled', JSON.stringify(enrolledIds), now, 'pending', groupId, t.batchTarget],"""
content = content.replace(bulk_old, bulk_new)

# 3. Update database.js schema for future use
with open('database.js', 'r') as f_db:
    db_content = f_db.read()
db_old = """    proxyFacultyId TEXT,
    approvalStatus TEXT DEFAULT 'approved',
    groupId TEXT"""
db_new = """    proxyFacultyId TEXT,
    approvalStatus TEXT DEFAULT 'approved',
    groupId TEXT,
    batchTarget TEXT"""
db_content = db_content.replace(db_old, db_new)
with open('database.js', 'w') as f_db:
    f_db.write(db_content)

# 4. Update GET /timetable/:facultyId
timetable_old = """app.get('/timetable/:facultyId', (req, res) => {
  const facultyId = req.params.facultyId;
  db.all(`SELECT * FROM timetable_slots WHERE facultyId = ?`, [facultyId], (err, rows) => {
    if (err) return res.status(500).json({ error: err.message });
    res.json(rows);
  });
});"""
timetable_new = """app.get('/timetable/:facultyId', (req, res) => {
  const facultyId = req.params.facultyId;
  const today = new Date().toISOString().split('T')[0];

  db.all(`SELECT * FROM timetable_slots WHERE facultyId = ?`, [facultyId], (err, slots) => {
    if (err) return res.status(500).json({ error: err.message });

    // Fetch today's sessions for this faculty to prevent duplicate QR generation
    db.all(`SELECT courseCode, batchTarget FROM sessions WHERE facultyId = ? AND date(createdAt) = ?`, [facultyId, today], (err, sessions) => {
      if (err) return res.status(500).json({ error: err.message });
      
      const enrichedSlots = slots.map(slot => {
        // Find if there's any session today that matches this slot's subject and batchTarget
        // Note: when a session is created from a slot, courseCode = slot.subject, and batchTarget = slot.batchTarget
        const hasSessionToday = sessions.some(s => s.courseCode === slot.subject && s.batchTarget === slot.batchTarget);
        return {
          ...slot,
          hasSessionToday
        };
      });
      
      res.json(enrichedSlots);
    });
  });
});"""
content = content.replace(timetable_old, timetable_new)

with open('index.js', 'w') as f:
    f.write(content)

