const fs = require('fs');
let content = fs.readFileSync('index.js', 'utf8');

// Replace the old seminar endpoint
const oldEndpointRegex = /app\.post\('\/sessions\/seminar', async \(req, res\) => \{[\s\S]*?\}\);/g;

const newEndpoint = `// Create Smart Seminar Session
app.post('/sessions/smart-seminar', (req, res) => {
  const { proxyFacultyId, division, startTime, endTime, date } = req.body;

  const id = uuidv4();
  const now = new Date().toISOString();

  // We store the smart seminar in sessions but with a special courseCode
  // so the QR generator and mark-attendance logic can identify it.
  db.run(\`INSERT INTO sessions (id, courseCode, facultyId, proxyFacultyId, status, enrolledStudentIds, createdAt, approvalStatus, metadata)
          VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)\`,
    [id, 'Smart Seminar', proxyFacultyId, proxyFacultyId, 'scheduled', JSON.stringify([]), now, 'approved', JSON.stringify({
      division,
      startTime,
      endTime,
      date
    })],
    function (err) {
      if (err) return res.status(500).json({ error: err.message });
      res.json({ id, courseCode: 'Smart Seminar', facultyId: proxyFacultyId, status: 'scheduled', createdAt: now });
    }
  );
});`;

content = content.replace(oldEndpointRegex, newEndpoint);

// Now update mark-attendance to handle Smart Seminar
// Look for Mark Attendance
const markAttendanceStart = `// 2) Mark Attendance`;
const markAttendanceLogic = `app.post('/mark-attendance', (req, res) => {
  const { userId, sessionId, method = 'qr' } = req.body;

  db.get('SELECT * FROM sessions WHERE id = ? OR groupId = ? LIMIT 1', [sessionId, sessionId], (err, session) => {
    if (err) return res.status(500).json({ error: err.message });
    if (!session) return res.status(404).json({ error: 'Session not found' });
    if (session.status !== 'scheduled' && session.status !== 'active') {
      return res.status(400).json({ error: 'Session is not active' });
    }

    const enrolledIds = JSON.parse(session.enrolledStudentIds || '[]');
    // Wait, for smart seminar enrolledIds is [] initially, and we dynamically mark attendance.
    
    // Check if it's a Smart Seminar
    if (session.courseCode === 'Smart Seminar') {
       handleSmartSeminarAttendance(req, res, session, userId, method);
       return;
    }

    if (enrolledIds.length > 0 && !enrolledIds.includes(userId)) {
      return res.status(403).json({ error: 'You are not enrolled in this target batch.' });
    }`;

content = content.replace(`app.post('/mark-attendance', (req, res) => {
  const { userId, sessionId, method = 'qr' } = req.body;

  db.get('SELECT * FROM sessions WHERE id = ? OR groupId = ? LIMIT 1', [sessionId, sessionId], (err, session) => {
    if (err) return res.status(500).json({ error: err.message });
    if (!session) return res.status(404).json({ error: 'Session not found' });
    if (session.status !== 'scheduled' && session.status !== 'active') {
      return res.status(400).json({ error: 'Session is not active' });
    }

    const enrolledIds = JSON.parse(session.enrolledStudentIds || '[]');
    if (enrolledIds.length > 0 && !enrolledIds.includes(userId)) {
      return res.status(403).json({ error: 'You are not enrolled in this target batch.' });
    }`, markAttendanceLogic);

const handleSmartSeminarLogic = `
function handleSmartSeminarAttendance(req, res, session, userId, method) {
  const meta = JSON.parse(session.metadata || '{}');
  const { division, startTime, endTime } = meta;
  const now = new Date().toISOString();

  // Find the student's batches
  db.get('SELECT division, coreBatch, electiveBatch FROM users WHERE id = ?', [userId], (err, user) => {
    if (err) return res.status(500).json({ error: err.message });
    if (!user) return res.status(404).json({ error: 'User not found' });

    if (user.division !== division) {
      return res.status(403).json({ error: 'You are not in the division for this seminar.' });
    }

    // Parse times
    const startDt = new Date(startTime);
    const endDt = new Date(endTime);
    const dayNames = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    const todayStr = dayNames[startDt.getDay()];

    const startTotalMins = startDt.getHours() * 60 + startDt.getMinutes();
    const endTotalMins = endDt.getHours() * 60 + endDt.getMinutes();

    // Query timetable for matching slots
    db.all('SELECT * FROM timetable_slots WHERE day = ?', [todayStr], (err, slots) => {
       if (err) return res.status(500).json({ error: err.message });

       const matchingSlots = slots.filter(s => {
          // Check if batch matches (All, coreBatch, or electiveBatch)
          if (!s.batchTarget.includes(user.division)) return false;
          
          let matchesBatch = false;
          if (s.batchTarget.includes('All')) matchesBatch = true;
          if (user.coreBatch && s.batchTarget.includes(user.coreBatch)) matchesBatch = true;
          if (user.electiveBatch && s.batchTarget.includes(user.electiveBatch)) matchesBatch = true;
          if (!matchesBatch) return false;

          // Check time overlap
          const [sH, sM] = s.startTime.split(':').map(Number);
          const [eH, eM] = s.endTime.split(':').map(Number);
          const slotStart = sH * 60 + sM;
          const slotEnd = eH * 60 + eM;

          // Overlap if max(start1, start2) < min(end1, end2)
          return Math.max(startTotalMins, slotStart) < Math.min(endTotalMins, slotEnd);
       });

       if (matchingSlots.length === 0) {
          return res.status(400).json({ error: 'No scheduled lectures found for your batches in this time window.' });
       }

       // For each matching slot, generate a session if not exists, and mark attendance
       let completedCount = 0;
       
       matchingSlots.forEach(slot => {
          // Find or create session for this slot today
          // We can use a deterministic ID based on slot.id and date
          const subSessionId = \`seminar_sub_\${session.id}_\${slot.id}\`;
          
          db.run(\`INSERT OR IGNORE INTO sessions (id, courseCode, facultyId, proxyFacultyId, status, createdAt, approvalStatus)
                  VALUES (?, ?, ?, ?, 'scheduled', ?, 'approved')\`,
            [subSessionId, slot.subject, slot.facultyId, session.facultyId, now],
            (err) => {
               // Then insert attendance
               const attId = uuidv4();
               db.run(\`INSERT OR IGNORE INTO attendance_records (id, sessionId, studentId, markedAt, status, method)
                       VALUES (?, ?, ?, ?, 'present', ?)\`,
                 [attId, subSessionId, userId, now, method],
                 (err) => {
                    completedCount++;
                    if (completedCount === matchingSlots.length) {
                       res.json({ success: true, message: \`Marked present for \${matchingSlots.length} overlapping classes.\` });
                    }
                 }
               );
            }
          );
       });
    });
  });
}
`;

content = content + handleSmartSeminarLogic;
fs.writeFileSync('index.js', content);
console.log('Backend Smart Seminar added');
