import re

with open('index.js', 'r') as f:
    content = f.read()

# 1. Update POST /sessions/smart-seminar
post_old = """// Create Smart Seminar Session
app.post('/sessions/smart-seminar', (req, res) => {
  const { proxyFacultyId, division, startTime, endTime, date } = req.body;

  const id = uuidv4();
  const now = new Date().toISOString();

  // We store the smart seminar in sessions but with a special courseCode
  // so the QR generator and mark-attendance logic can identify it.
  db.run(`INSERT INTO sessions (id, courseCode, facultyId, proxyFacultyId, status, enrolledStudentIds, createdAt, approvalStatus, metadata)
          VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)`,
    [id, 'Smart Seminar', proxyFacultyId, proxyFacultyId, 'scheduled', JSON.stringify([]), now, 'approved', JSON.stringify({
      division,
      startTime,
      endTime,
      date
    })],"""

post_new = """// Create Smart Seminar Session
app.post('/sessions/smart-seminar', (req, res) => {
  const { proxyFacultyId, divisions, startTime, endTime, date } = req.body;

  const id = uuidv4();
  const now = new Date().toISOString();

  // We store the smart seminar in sessions but with a special courseCode
  // so the QR generator and mark-attendance logic can identify it.
  db.run(`INSERT INTO sessions (id, courseCode, facultyId, proxyFacultyId, status, enrolledStudentIds, createdAt, approvalStatus, metadata)
          VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)`,
    [id, 'Smart Seminar', proxyFacultyId, proxyFacultyId, 'scheduled', JSON.stringify([]), now, 'approved', JSON.stringify({
      divisions,
      startTime,
      endTime,
      date
    })],"""

content = content.replace(post_old, post_new)


# 2. Update handleSmartSeminarAttendance
handler_old = """function handleSmartSeminarAttendance(req, res, session, userId, method) {
  const meta = JSON.parse(session.metadata || '{}');
  const { division, startTime, endTime } = meta;
  const now = new Date().toISOString();

  // Find the student's batches
  db.get('SELECT division, coreBatch, electiveBatch FROM users WHERE id = ?', [userId], (err, user) => {
    if (err) return res.status(500).json({ error: err.message });
    if (!user) return res.status(404).json({ error: 'User not found' });

    if (user.division !== division) {"""

handler_new = """function handleSmartSeminarAttendance(req, res, session, userId, method) {
  const meta = JSON.parse(session.metadata || '{}');
  const { divisions, startTime, endTime } = meta;
  const now = new Date().toISOString();

  // Find the student's batches
  db.get('SELECT division, coreBatch, electiveBatch FROM users WHERE id = ?', [userId], (err, user) => {
    if (err) return res.status(500).json({ error: err.message });
    if (!user) return res.status(404).json({ error: 'User not found' });

    if (!divisions.includes(user.division)) {"""

content = content.replace(handler_old, handler_new)

with open('index.js', 'w') as f:
    f.write(content)

