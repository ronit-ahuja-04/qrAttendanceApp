const sqlite3 = require('sqlite3').verbose();
const db = new sqlite3.Database('./database.sqlite');

db.serialize(() => {
  db.run(`CREATE TABLE IF NOT EXISTS users (
    id TEXT PRIMARY KEY,
    role TEXT,
    name TEXT,
    rollNo TEXT,
    email TEXT,
    password TEXT,
    profilePictureUrl TEXT,
    division TEXT,
    coreBatch TEXT,
    electiveSubject TEXT,
    electiveBatch TEXT,
    fcmToken TEXT,
    notificationPrefs TEXT
  )`);

  db.run(`CREATE TABLE IF NOT EXISTS sessions (
    id TEXT PRIMARY KEY,
    courseCode TEXT,
    facultyId TEXT,
    status TEXT,
    qrCode TEXT,
    qrIssuedAt DATETIME,
    qrExpiresAt DATETIME,
    enrolledStudentIds TEXT,
    createdAt DATETIME,
    previousQrCode TEXT,
    proxyFacultyId TEXT,
    approvalStatus TEXT DEFAULT 'approved',
    groupId TEXT,
    batchTarget TEXT
  )`);

  db.run(`CREATE TABLE IF NOT EXISTS attendance_records (
    id TEXT PRIMARY KEY,
    sessionId TEXT,
    studentId TEXT,
    markedAt DATETIME,
    status TEXT,
    method TEXT,
    UNIQUE(sessionId, studentId)
  )`);

  db.run(`CREATE TABLE IF NOT EXISTS timetable_slots (
    id TEXT PRIMARY KEY,
    facultyId TEXT,
    day TEXT,
    subject TEXT,
    type TEXT,
    batchTarget TEXT,
    venue TEXT,
    startTime TEXT,
    endTime TEXT
  )`);

  db.run(`CREATE TABLE IF NOT EXISTS notifications (
    id TEXT PRIMARY KEY,
    userId TEXT,
    title TEXT,
    body TEXT,
    tag TEXT,
    tagColor TEXT,
    onTagColor TEXT,
    byName TEXT,
    byIcon TEXT,
    createdAt DATETIME,
    isRead INTEGER DEFAULT 0
  )`);
});

module.exports = db;
