import express from 'express';
import cors from 'cors';
import { EventEmitter } from 'events';
import { buildAms } from './lib/ams/logic';
import { db } from './lib/ams/db';

const app = express();
app.use(cors());
app.use(express.json());

const ams = buildAms();
export const eventBus = new EventEmitter();

// --- SSE Endpoint ---
app.get('/notifications/stream', (req, res) => {
  const { userId } = req.query;
  if (!userId || typeof userId !== 'string') {
    return res.status(400).send('userId is required');
  }

  res.setHeader('Content-Type', 'text/event-stream');
  res.setHeader('Cache-Control', 'no-cache');
  res.setHeader('Connection', 'keep-alive');
  res.flushHeaders();

  const onNotification = (event: any) => {
    // Filter events for this user
    if (event.recipientId === userId || event.recipientId === 'ALL_ENROLLED') {
      // If ALL_ENROLLED, we must check if this student is enrolled in the session
      if (event.recipientId === 'ALL_ENROLLED') {
        const session = ams.sessionRepo.findById(event.sessionId);
        if (!session || !session.enrolledStudentIds.includes(userId)) {
          return;
        }
      }
      res.write(`data: ${JSON.stringify(event)}\n\n`);
    }
  };

  eventBus.on('notification', onNotification);

  req.on('close', () => {
    eventBus.off('notification', onNotification);
  });
});

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
  
  // N006: Attendance session created -> Faculty
  eventBus.emit('notification', {
    type: 'N006',
    recipientId: facultyId,
    sessionId: session.id,
    title: 'Session Started',
    message: 'A new attendance session has been created.'
  });

  res.json(session);
});

app.post('/sessions/:id/start', (req, res) => {
  const { ttlSeconds } = req.body;
  const result = ams.sessionService.startSession(req.params.id, ttlSeconds);
  if (result.ok) {
    // N002: Attendance session started -> Student
    eventBus.emit('notification', {
      type: 'N002',
      recipientId: 'ALL_ENROLLED',
      sessionId: req.params.id,
      title: 'Attendance Open',
      message: 'Attendance is now open for the current lecture.'
    });
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
  const sessionId = req.params.id;
  const sessionBefore = ams.sessionRepo.findById(sessionId);
  const result = ams.sessionService.closeSession(sessionId);
  
  if (result.ok && sessionBefore) {
    // N005: Attendance session expired -> Student
    eventBus.emit('notification', {
      type: 'N005',
      recipientId: 'ALL_ENROLLED',
      sessionId,
      title: 'Attendance Closed',
      message: 'The attendance session has expired.'
    });

    // N007: Attendance summary available -> Faculty
    eventBus.emit('notification', {
      type: 'N007',
      recipientId: sessionBefore.facultyId,
      sessionId,
      title: 'Attendance Report Ready',
      message: 'The attendance report for the lecture is available.'
    });

    // Calculate student metrics and send Low Attendance notification
    const enrolledStudents = sessionBefore.enrolledStudentIds;
    const allSessions = ams.sessionRepo.findAll();
    
    enrolledStudents.forEach(studentId => {
      const studentClosedSessions = allSessions.filter(
        s => s.status === 'closed' && s.enrolledStudentIds.includes(studentId)
      );
      const totalClasses = studentClosedSessions.length;
      const attendedClasses = studentClosedSessions.filter(
        s => ams.attendanceRepo.exists(s.id, studentId)
      ).length;
      
      const attendancePercentage = totalClasses === 0 ? 100 : (attendedClasses / totalClasses) * 100;
      
      if (attendancePercentage < 50) {
        eventBus.emit('notification', {
          type: 'LOW_ATTENDANCE',
          recipientId: studentId,
          sessionId,
          title: 'Low Attendance Warning',
          message: `Your overall attendance has dropped to ${attendancePercentage.toFixed(1)}% (below the 50% threshold).`
        });
      }
    });

    res.json(result.value);
  } else {
    res.status(400).json({ error: result.reason, message: result.message });
  }
});

app.get('/sessions/faculty/:facultyId', (req, res) => {
  const sessions = ams.sessionRepo.findAll();
  const facultySessions = sessions
    .filter(s => s.facultyId === req.params.facultyId)
    .sort((a, b) => b.createdAt.getTime() - a.createdAt.getTime());
  res.json(facultySessions);
});

app.get('/sessions/active/:courseCode', (req, res) => {
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
  const sessionId = req.params.id;
  const result = ams.attendanceService.markAttendance(
    sessionId,
    studentId,
    code
  );
  
  if (!result.ok) {
    const session = ams.sessionRepo.findById(sessionId);
    console.log("Attendance Failed:", result.reason, "| Provided OTP:", code, "| Expected OTP:", session?.otp?.code);
    
    // N004: Attendance rejected -> Student
    eventBus.emit('notification', {
      type: 'N004',
      recipientId: studentId,
      sessionId,
      title: 'Attendance Failed',
      message: 'Your attendance could not be recorded. Please check the OTP and session status.'
    });
  } else {
    // N003: Attendance successfully marked -> Student
    eventBus.emit('notification', {
      type: 'N003',
      recipientId: studentId,
      sessionId,
      title: 'Attendance Marked',
      message: 'Your attendance has been recorded successfully.'
    });
  }

  if (result.ok) {
    res.json(result.value);
  } else {
    res.status(400).json({ error: result.reason, message: result.message });
  }
});

// We should also add an endpoint to allow cancelling a session without taking attendance (N001).
// However, since it's not explicitly in logic.ts right now, we can skip or implement a basic DELETE endpoint.
app.delete('/sessions/:id', (req, res) => {
  const sessionId = req.params.id;
  const session = ams.sessionRepo.findById(sessionId);
  if (session) {
    // Here we'd realistically have a delete method in logic.ts. For now we just close it and emit N001.
    ams.sessionService.closeSession(sessionId);
    
    // N001: Faculty does not mark attendance -> Student
    eventBus.emit('notification', {
      type: 'N001',
      recipientId: 'ALL_ENROLLED',
      sessionId,
      title: 'Lecture Cancelled',
      message: 'Attendance was not marked for this lecture.'
    });
    res.json({ success: true });
  } else {
    res.status(404).json({ error: 'notFound', message: 'Session not found' });
  }
});

app.get('/students/:id/stats', (req, res) => {
  const studentId = req.params.id;
  const allSessions = ams.sessionRepo.findAll();
  
  const studentClosedSessions = allSessions.filter(
    s => s.status === 'closed' && s.enrolledStudentIds.includes(studentId)
  );
  
  // Aggregate stats
  const totalClasses = studentClosedSessions.length;
  const attendedClasses = studentClosedSessions.filter(
    s => ams.attendanceRepo.exists(s.id, studentId)
  ).length;
  const overallPercentage = totalClasses === 0 ? 100 : (attendedClasses / totalClasses) * 100;
  
  const sevenDaysAgo = new Date();
  sevenDaysAgo.setDate(sevenDaysAgo.getDate() - 7);
  
  const thisWeekSessions = studentClosedSessions.filter(s => s.createdAt >= sevenDaysAgo);
  const thisWeekTotal = thisWeekSessions.length;
  const thisWeekAttended = thisWeekSessions.filter(
    s => ams.attendanceRepo.exists(s.id, studentId)
  ).length;
  const thisWeekPercentage = thisWeekTotal === 0 ? 100 : (thisWeekAttended / thisWeekTotal) * 100;

  // Per-subject stats
  const courseCodes = Array.from(new Set(studentClosedSessions.map(s => s.courseCode)));
  const subjects = courseCodes.map(code => {
    const courseSessions = studentClosedSessions.filter(s => s.courseCode === code);
    const courseTotal = courseSessions.length;
    const courseAttended = courseSessions.filter(s => ams.attendanceRepo.exists(s.id, studentId)).length;
    const courseOverall = courseTotal === 0 ? 100 : (courseAttended / courseTotal) * 100;

    const courseThisWeekSessions = courseSessions.filter(s => s.createdAt >= sevenDaysAgo);
    const courseThisWeekTotal = courseThisWeekSessions.length;
    const courseThisWeekAttended = courseThisWeekSessions.filter(s => ams.attendanceRepo.exists(s.id, studentId)).length;
    const courseThisWeekPercent = courseThisWeekTotal === 0 ? 100 : (courseThisWeekAttended / courseThisWeekTotal) * 100;

    return {
      courseCode: code,
      overallPercentage: parseFloat(courseOverall.toFixed(1)),
      thisWeekPercentage: parseFloat(courseThisWeekPercent.toFixed(1)),
      totalClasses: courseTotal,
      attendedClasses: courseAttended
    };
  });
  
  res.json({
    overallPercentage: parseFloat(overallPercentage.toFixed(1)),
    thisWeekPercentage: parseFloat(thisWeekPercentage.toFixed(1)),
    totalClasses,
    attendedClasses,
    thisWeekTotal,
    thisWeekAttended,
    subjects
  });
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, '0.0.0.0', () => {
  console.log(`Server is running on port ${PORT}`);
});
