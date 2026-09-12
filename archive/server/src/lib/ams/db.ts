import Database from 'better-sqlite3';
import {
  SessionRepository,
  AttendanceRepository,
  AttendanceSession,
  AttendanceRecord,
  SessionStatus,
  AttendanceStatus,
  AttendanceMethod,
} from './logic';

export const db = new Database('attendance.db');
db.pragma('journal_mode = WAL');

// 1. Initialize Schema
db.exec(`
  CREATE TABLE IF NOT EXISTS users (
    id TEXT PRIMARY KEY,
    email TEXT UNIQUE NOT NULL,
    password TEXT NOT NULL,
    role TEXT NOT NULL,
    name TEXT NOT NULL,
    rollNo TEXT
  );

  CREATE TABLE IF NOT EXISTS sessions (
    id TEXT PRIMARY KEY,
    courseCode TEXT NOT NULL,
    facultyId TEXT NOT NULL,
    status TEXT NOT NULL,
    createdAt DATETIME NOT NULL,
    otpCode TEXT,
    otpIssuedAt DATETIME,
    otpExpiresAt DATETIME,
    enrolledStudentIds TEXT NOT NULL
  );

  CREATE TABLE IF NOT EXISTS attendance_records (
    id TEXT PRIMARY KEY,
    sessionId TEXT NOT NULL,
    studentId TEXT NOT NULL,
    markedAt DATETIME NOT NULL,
    status TEXT NOT NULL,
    method TEXT NOT NULL,
    FOREIGN KEY(sessionId) REFERENCES sessions(id)
  );
`);

// 2. Pre-seed users
const insertUser = db.prepare(`
  INSERT OR IGNORE INTO users (id, email, password, role, name, rollNo) VALUES (?, ?, ?, ?, ?, ?)
`);
const seedUsers = () => {
  insertUser.run('faculty-01', 'faculty@ves.ac.in', 'pass123', 'faculty', 'Prof. Smith', null);
  for (let i = 0; i <= 25; i++) {
    const idStr = i.toString().padStart(2, '0');
    insertUser.run(`student-${idStr}`, `student${idStr}@ves.ac.in`, 'pass123', 'student', `Student ${idStr}`, `2026-${idStr}`);
  }
};
seedUsers();

// 3. SqliteSessionRepository
export class SqliteSessionRepository implements SessionRepository {
  private stmtSave = db.prepare(`
    INSERT INTO sessions (id, courseCode, facultyId, status, createdAt, otpCode, otpIssuedAt, otpExpiresAt, enrolledStudentIds)
    VALUES (@id, @courseCode, @facultyId, @status, @createdAt, @otpCode, @otpIssuedAt, @otpExpiresAt, @enrolledStudentIds)
    ON CONFLICT(id) DO UPDATE SET
      status=excluded.status,
      otpCode=excluded.otpCode,
      otpIssuedAt=excluded.otpIssuedAt,
      otpExpiresAt=excluded.otpExpiresAt
  `);
  
  private stmtFindById = db.prepare('SELECT * FROM sessions WHERE id = ?');
  private stmtFindAll = db.prepare('SELECT * FROM sessions');

  save(session: AttendanceSession): void {
    this.stmtSave.run({
      id: session.id,
      courseCode: session.courseCode,
      facultyId: session.facultyId,
      status: session.status,
      createdAt: session.createdAt.toISOString(),
      otpCode: session.otp?.code ?? null,
      otpIssuedAt: session.otp?.issuedAt.toISOString() ?? null,
      otpExpiresAt: session.otp?.expiresAt.toISOString() ?? null,
      enrolledStudentIds: JSON.stringify(session.enrolledStudentIds)
    });
  }

  private mapRowToSession(row: any): AttendanceSession {
    return {
      id: row.id,
      courseCode: row.courseCode,
      facultyId: row.facultyId,
      status: row.status as SessionStatus,
      createdAt: new Date(row.createdAt),
      otp: row.otpCode ? {
        code: row.otpCode,
        issuedAt: new Date(row.otpIssuedAt),
        expiresAt: new Date(row.otpExpiresAt)
      } : null,
      enrolledStudentIds: JSON.parse(row.enrolledStudentIds)
    };
  }

  findById(id: string): AttendanceSession | null {
    const row = this.stmtFindById.get(id);
    return row ? this.mapRowToSession(row) : null;
  }

  findAll(): AttendanceSession[] {
    const rows = this.stmtFindAll.all();
    return rows.map(r => this.mapRowToSession(r));
  }
}

// 4. SqliteAttendanceRepository
export class SqliteAttendanceRepository implements AttendanceRepository {
  private stmtSave = db.prepare(`
    INSERT INTO attendance_records (id, sessionId, studentId, markedAt, status, method)
    VALUES (@id, @sessionId, @studentId, @markedAt, @status, @method)
  `);
  private stmtFindBySession = db.prepare('SELECT * FROM attendance_records WHERE sessionId = ?');
  private stmtExists = db.prepare('SELECT 1 FROM attendance_records WHERE sessionId = ? AND studentId = ? LIMIT 1');

  save(record: AttendanceRecord): void {
    this.stmtSave.run({
      id: record.id,
      sessionId: record.sessionId,
      studentId: record.studentId,
      markedAt: record.markedAt.toISOString(),
      status: record.status,
      method: record.method
    });
  }

  private mapRowToRecord(row: any): AttendanceRecord {
    return {
      id: row.id,
      sessionId: row.sessionId,
      studentId: row.studentId,
      markedAt: new Date(row.markedAt),
      status: row.status as AttendanceStatus,
      method: row.method as AttendanceMethod
    };
  }

  findBySession(sessionId: string): AttendanceRecord[] {
    const rows = this.stmtFindBySession.all(sessionId);
    return rows.map(r => this.mapRowToRecord(r));
  }

  exists(sessionId: string, studentId: string): boolean {
    const row = this.stmtExists.get(sessionId, studentId);
    return row !== undefined;
  }
}
