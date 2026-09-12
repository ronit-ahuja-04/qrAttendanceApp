const fs = require('fs');
let content = fs.readFileSync('index.js', 'utf8');

const oldMarkCode = `app.post('/api/attendance/mark', (req, res) => {
  const { sessionId, studentId, code } = req.body;

  // 1. Validate session & QR code
  db.get(\`SELECT * FROM sessions WHERE id = ?\`, [sessionId], (err, session) => {
    if (err || !session) return res.status(404).json({ error: 'Session not found' });
    if (session.status !== 'active') return res.status(400).json({ error: 'sessionClosed', message: 'Session is not currently active.' });

    // Check if code matches current or previous
    if (session.qrCode !== code && session.previousQrCode !== code) return res.status(400).json({ error: 'invalidQrCode', message: 'QR Code is invalid or has expired.' });

    // Check expiry
    if (new Date() > new Date(session.qrExpiresAt)) return res.status(400).json({ error: 'qrExpired', message: 'This QR code has expired.' });

    // 2. Validate student enrollment
    let enrolledIds = JSON.parse(session.enrolledStudentIds);
    if (!enrolledIds.includes(studentId)) return res.status(400).json({ error: 'studentNotEnrolled', message: 'You are not enrolled in this session batch or division.' });

    // 3. Insert record
    const markedAt = new Date().toISOString();
    const aid = uuidv4();

    db.run(\`INSERT INTO attendance_records (id, sessionId, studentId, markedAt, status, method)
            VALUES (?, ?, ?, ?, ?, ?)\`,
      [aid, sessionId, studentId, markedAt, 'pending', 'qr'],
      function (err) {
        if (err) {
          if (err.message.includes('UNIQUE')) {
            return res.status(400).json({ error: 'duplicateAttendance', message: 'Attendance already marked for this session.' });
          }
          return res.status(500).json({ error: err.message });
        }
        res.json({
          success: true,
          record: {
            id: aid, sessionId, studentId, markedAt, status: 'pending', method: 'qr'
          }
        });
      }
    );
  });
});`;

const newMarkCode = `app.post('/api/attendance/mark', (req, res) => {
  const { sessionId, studentId, code } = req.body;

  db.all('SELECT * FROM sessions WHERE id = ? OR groupId = ?', [sessionId, sessionId], (err, sessions) => {
    if (err) return res.status(500).json({ error: err.message });
    if (!sessions || sessions.length === 0) return res.status(404).json({ error: 'Session not found' });

    // Use the first session to validate the QR code (since they all share the same QR/timing logic if grouped)
    const baseSession = sessions[0];
    if (baseSession.status !== 'active') return res.status(400).json({ error: 'sessionClosed', message: 'Session is not currently active.' });
    if (baseSession.qrCode !== code && baseSession.previousQrCode !== code) return res.status(400).json({ error: 'invalidQrCode', message: 'QR Code is invalid or has expired.' });
    if (new Date() > new Date(baseSession.qrExpiresAt)) return res.status(400).json({ error: 'qrExpired', message: 'This QR code has expired.' });

    // Find all sessions in this group where the student is enrolled
    const matchedSessions = sessions.filter(s => {
      let enrolledIds = JSON.parse(s.enrolledStudentIds || '[]');
      return enrolledIds.includes(studentId);
    });

    if (matchedSessions.length === 0) {
      return res.status(400).json({ error: 'studentNotEnrolled', message: 'You are not enrolled in any class covered by this session.' });
    }

    const markedAt = new Date().toISOString();
    let insertCount = 0;
    let duplicateCount = 0;
    let anyError = null;

    // We can insert records for all matched sessions
    const checkCompletion = () => {
      if (insertCount + duplicateCount === matchedSessions.length) {
        if (insertCount === 0 && duplicateCount > 0) {
           return res.status(400).json({ error: 'duplicateAttendance', message: 'Attendance already marked.' });
        }
        res.json({
          success: true,
          message: 'Attendance marked successfully.'
        });
      }
    };

    matchedSessions.forEach(session => {
      const aid = uuidv4();
      db.run('INSERT INTO attendance_records (id, sessionId, studentId, markedAt, status, method) VALUES (?, ?, ?, ?, ?, ?)',
        [aid, session.id, studentId, markedAt, 'pending', 'qr'],
        function (err) {
          if (err) {
            if (err.message.includes('UNIQUE')) {
              duplicateCount++;
            } else {
              anyError = err;
            }
          } else {
            insertCount++;
          }
          if (anyError && insertCount + duplicateCount === matchedSessions.length) {
             return res.status(500).json({ error: anyError.message });
          }
          checkCompletion();
        }
      );
    });
  });
});`;

content = content.replace(oldMarkCode, newMarkCode);
fs.writeFileSync('index.js', content);
console.log('Backend index.js updated for mark attendance');
