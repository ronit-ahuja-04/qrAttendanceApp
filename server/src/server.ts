import express from 'express';
import cors from 'cors';
import { buildAms } from './lib/ams/logic';
import { db } from './lib/ams/db';

const app = express();
app.use(cors());
app.use(express.json());

const ams = buildAms();

app.post('/login', (req, res) => {
  const { email, password } = req.body;
  const stmt = db.prepare('SELECT id, role, name, rollNo FROM users WHERE email = ? AND password = ?');
  const user = stmt.get(email, password);
  if (user) {
    res.json(user);
  } else {
    res.status(401).json({ error: 'unauthorized', message: 'Invalid email or password' });
  }
});

app.post('/sessions', (req, res) => {
  const { courseCode, facultyId, enrolledStudentIds } = req.body;
  const session = ams.sessionService.createSession(
    courseCode,
    facultyId,
    enrolledStudentIds
  );
  res.json(session);
});

app.post('/sessions/:id/start', (req, res) => {
  const { ttlSeconds } = req.body;
  const result = ams.sessionService.startSession(req.params.id, ttlSeconds);
  if (result.ok) {
    res.json(result.value);
  } else {
    res.status(400).json({ error: result.reason, message: result.message });
  }
});

app.post('/sessions/:id/rotate', (req, res) => {
  const { ttlSeconds } = req.body;
  const result = ams.sessionService.rotateOtp(req.params.id, ttlSeconds);
  if (result.ok) {
    res.json(result.value);
  } else {
    res.status(400).json({ error: result.reason, message: result.message });
  }
});

app.post('/sessions/:id/close', (req, res) => {
  const result = ams.sessionService.closeSession(req.params.id);
  if (result.ok) {
    res.json(result.value);
  } else {
    res.status(400).json({ error: result.reason, message: result.message });
  }
});

app.get('/sessions/active/:courseCode', (req, res) => {
  // Find an active session for the given courseCode
  const sessions = ams.sessionRepo.findAll();
  const active = [...sessions].reverse().find(s => s.courseCode === req.params.courseCode && s.status === 'active');
  if (active) {
    res.json(active);
  } else {
    res.status(404).json({ error: 'notFound', message: 'No active session found for this course.' });
  }
});

app.get('/sessions/:id/attendance', (req, res) => {
  const records = ams.attendanceService.recordsFor(req.params.id);
  res.json(records);
});

app.get('/sessions/:id/attendance/details', (req, res) => {
  const records = ams.attendanceService.recordsFor(req.params.id);
  const details = records.map(record => {
    const user = db.prepare('SELECT name, rollNo FROM users WHERE id = ?').get(record.studentId) as any;
    return {
      ...record,
      studentName: user?.name || 'Unknown',
      studentRollNo: user?.rollNo || null
    };
  });
  res.json(details);
});

app.get('/sessions/:id/verification', (req, res) => {
  const session = ams.sessionRepo.findById(req.params.id);
  if (!session) {
    return res.status(404).json({ error: 'notFound', message: 'Session not found' });
  }

  const records = ams.attendanceService.recordsFor(req.params.id);
  const enrolledStudentIds = session.enrolledStudentIds;
  
  const placeholders = enrolledStudentIds.map(() => '?').join(',');
  const users = db.prepare(`SELECT id, name, rollNo FROM users WHERE id IN (${placeholders})`).all(enrolledStudentIds) as any[];

  const verificationList = users.map(user => {
    const record = records.find(r => r.studentId === user.id);
    return {
      studentId: user.id,
      rollNo: user.rollNo || 'N/A',
      name: user.name,
      status: record ? record.status : 'absent',
      method: record ? record.method : 'Not Marked / Timeout'
    };
  });

  res.json(verificationList);
});

app.post('/sessions/:id/attendance', (req, res) => {
  const { studentId, code } = req.body;
  const result = ams.attendanceService.markAttendance(
    req.params.id,
    studentId,
    code
  );
  if (!result.ok) {
    const session = ams.sessionRepo.findById(req.params.id);
    console.log("Attendance Failed:", result.reason, "| Provided OTP:", code, "| Expected OTP:", session?.otp?.code);
  }
  if (result.ok) {
    res.json(result.value);
  } else {
    res.status(400).json({ error: result.reason, message: result.message });
  }
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, '0.0.0.0', () => {
  console.log(`Server is running on port ${PORT}`);
});
