const request = require('supertest');
const app = require('../index');
const { seedTestDb } = require('./testDb');
const db = require('../database');
const { generateToken } = require('../middleware/auth');

let activeSessionId;
let studentToken;
let otherStudentToken;

beforeAll(async () => {
  await seedTestDb();
  
  // Generate mock tokens
  studentToken = generateToken({ id: 'stud1', role: 'student', email: 'stud1@test.com' });
  otherStudentToken = generateToken({ id: 'stud2', role: 'student', email: 'stud2@test.com' });

  // Create an active session manually for attendance testing
  activeSessionId = 'session-123';
  return new Promise((resolve) => {
    const now = new Date().toISOString();
    const expiresAt = new Date(Date.now() + 60000).toISOString(); // 1 minute from now
    
    db.run(`INSERT INTO sessions (id, courseCode, facultyId, status, qrCode, qrExpiresAt, createdAt, enrolledStudentIds)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?)`,
      [activeSessionId, 'INFT', 'fac1', 'active', 'valid-qr', expiresAt, now, JSON.stringify(['stud1'])],
      resolve
    );
  });
});

describe('Attendance API', () => {
  it('should mark attendance successfully for a valid QR and student', async () => {
    const res = await request(app)
      .post('/api/attendance/mark')
      .set('Authorization', `Bearer ${studentToken}`)
      .send({
        sessionId: activeSessionId,
        code: 'valid-qr'
      });
    
    expect(res.statusCode).toEqual(200);
    expect(res.body).toHaveProperty('success', true);
  });

  it('should reject attendance for an invalid QR code', async () => {
    const res = await request(app)
      .post('/api/attendance/mark')
      .set('Authorization', `Bearer ${studentToken}`)
      .send({
        sessionId: activeSessionId,
        code: 'invalid-qr'
      });
    
    expect(res.statusCode).toEqual(400);
    expect(res.body).toHaveProperty('error', 'invalidQrCode');
  });

  it('should reject attendance for a student who already marked', async () => {
    // First mark
    await request(app)
      .post('/api/attendance/mark')
      .set('Authorization', `Bearer ${studentToken}`)
      .send({
        sessionId: activeSessionId,
        code: 'valid-qr'
      });
    
    // Second mark
    const res = await request(app)
      .post('/api/attendance/mark')
      .set('Authorization', `Bearer ${studentToken}`)
      .send({
        sessionId: activeSessionId,
        code: 'valid-qr'
      });
    
    expect(res.statusCode).toEqual(400); // Bad request or conflict
    expect(res.body).toHaveProperty('error', 'duplicateAttendance');
  });

  it('should reject attendance if QR is expired', async () => {
    // Simulate expired QR by manually updating the session in DB
    await new Promise((resolve) => {
      const pastTime = new Date(Date.now() - 60000).toISOString();
      db.run('UPDATE sessions SET qrExpiresAt = ? WHERE id = ?', [pastTime, activeSessionId], resolve);
    });

    const res = await request(app)
      .post('/api/attendance/mark')
      .set('Authorization', `Bearer ${studentToken}`)
      .send({
        sessionId: activeSessionId,
        code: 'valid-qr'
      });
    
    expect(res.statusCode).toEqual(400);
    expect(res.body).toHaveProperty('error', 'qrExpired');
  });
});
