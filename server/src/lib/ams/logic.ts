/**
 * AMS Phase 1 — Dynamic OTP attendance logic (TypeScript port of the Dart blueprint).
 * Pure logic: no UI, no network, in-memory storage only.
 */

/* ---------------------------------- core ---------------------------------- */

export type Result<T> =
  | { ok: true; value: T }
  | { ok: false; reason: RejectionReason; message: string };

export const success = <T>(value: T): Result<T> => ({ ok: true, value });
export const failure = <T>(reason: RejectionReason, message: string): Result<T> => ({
  ok: false,
  reason,
  message,
});

/** Time abstraction so tests/simulations can fast-forward the clock. */
export interface Clock {
  now(): Date;
}

export class SystemClock implements Clock {
  now() {
    return new Date();
  }
}

/** Clock you can push forward manually — used by the simulator. */
export class MutableClock implements Clock {
  constructor(private current: Date = new Date()) {}
  now() {
    return new Date(this.current.getTime());
  }
  advanceSeconds(seconds: number) {
    this.current = new Date(this.current.getTime() + seconds * 1000);
  }
  set(date: Date) {
    this.current = date;
  }
}

export interface OtpGenerator {
  generate(): string;
}

export class NumericOtpGenerator implements OtpGenerator {
  constructor(private length = 6) {}
  generate() {
    let code = "";
    for (let i = 0; i < this.length; i++) code += Math.floor(Math.random() * 10);
    return code;
  }
}

export const nextId = (prefix: string) => `${prefix}_${Date.now()}_${Math.floor(Math.random() * 1000)}`;

/* ---------------------------------- enums --------------------------------- */

export enum SessionStatus {
  scheduled = "scheduled",
  active = "active",
  closed = "closed",
}

export enum AttendanceStatus {
  present = "present",
  absent = "absent",
}

export enum AttendanceMethod {
  otp = "otp",
  manual = "manual",
}

export enum RejectionReason {
  sessionNotFound = "sessionNotFound",
  sessionNotActive = "sessionNotActive",
  invalidOtp = "invalidOtp",
  otpExpired = "otpExpired",
  duplicateAttendance = "duplicateAttendance",
  studentNotEnrolled = "studentNotEnrolled",
}

export const reasonText: Record<RejectionReason, string> = {
  [RejectionReason.sessionNotFound]: "No skips.",
  [RejectionReason.sessionNotActive]: "This session is not open for attendance.",
  [RejectionReason.invalidOtp]: "That OTP is incorrect.",
  [RejectionReason.otpExpired]: "That OTP has expired.",
  [RejectionReason.duplicateAttendance]: "Attendance already marked for this student.",
  [RejectionReason.studentNotEnrolled]: "Student is not enrolled in this class.",
};


/* --------------------------------- models --------------------------------- */

export interface Otp {
  code: string;
  issuedAt: Date;
  expiresAt: Date;
}

export const isOtpExpired = (otp: Otp, now: Date) => now.getTime() >= otp.expiresAt.getTime();



export interface AttendanceSession {
  id: string;
  courseCode: string;
  facultyId: string;
  status: SessionStatus;
  createdAt: Date;
  otp: Otp | null;
  enrolledStudentIds: string[];
}

export interface AttendanceRecord {
  id: string;
  sessionId: string;
  studentId: string;
  markedAt: Date;
  status: AttendanceStatus;
  method: AttendanceMethod;
}


export interface Student {
  id: string;
  name: string;
  rollNo: string;
}

/* ------------------------------ repositories ------------------------------ */

export interface SessionRepository {
  save(session: AttendanceSession): void;
  findById(id: string): AttendanceSession | null;
  findAll(): AttendanceSession[];
}

export interface AttendanceRepository {
  save(record: AttendanceRecord): void;
  findBySession(sessionId: string): AttendanceRecord[];
  exists(sessionId: string, studentId: string): boolean;
}

export class InMemorySessionRepository implements SessionRepository {
  private store = new Map<string, AttendanceSession>();
  save(session: AttendanceSession) {
    this.store.set(session.id, session);
  }
  findById(id: string) {
    return this.store.get(id) ?? null;
  }
  findAll() {
    return [...this.store.values()];
  }
}

export class InMemoryAttendanceRepository implements AttendanceRepository {
  private store: AttendanceRecord[] = [];
  save(record: AttendanceRecord) {
    this.store.push(record);
  }
  findBySession(sessionId: string) {
    return this.store.filter((r) => r.sessionId === sessionId);
  }
  exists(sessionId: string, studentId: string) {
    return this.store.some((r) => r.sessionId === sessionId && r.studentId === studentId);
  }
}

/* -------------------------------- services -------------------------------- */

export class SessionService {
  constructor(
    private repo: SessionRepository,
    private clock: Clock,
    private otpGen: OtpGenerator,
  ) {}

  createSession(
    courseCode: string,
    facultyId: string,
    enrolledStudentIds: string[]
  ) {
    const session: AttendanceSession = {
      id: nextId("session"),
      courseCode,
      facultyId,
      status: SessionStatus.scheduled,
      createdAt: this.clock.now(),
      otp: null,
      enrolledStudentIds,
    };

    this.repo.save(session);
    return session;
  }

  /** Opens the session and issues a fresh OTP valid for `ttlSeconds`. */
  startSession(sessionId: string, ttlSeconds: number): Result<AttendanceSession> {
    const session = this.repo.findById(sessionId);
    if (!session)
      return failure(RejectionReason.sessionNotFound, reasonText[RejectionReason.sessionNotFound]);
    const now = this.clock.now();
    const updated: AttendanceSession = {
      ...session,
      status: SessionStatus.active,
      otp: {
        code: this.otpGen.generate(),
        issuedAt: now,
        expiresAt: new Date(now.getTime() + ttlSeconds * 1000),
      },
    };
    this.repo.save(updated);
    return success(updated);
  }

  /** Rotates the OTP without closing the session (dynamic OTP). */
  rotateOtp(sessionId: string, ttlSeconds: number): Result<AttendanceSession> {
    const session = this.repo.findById(sessionId);
    if (!session)
      return failure(RejectionReason.sessionNotFound, reasonText[RejectionReason.sessionNotFound]);
    if (session.status !== SessionStatus.active)
      return failure(RejectionReason.sessionNotActive, reasonText[RejectionReason.sessionNotActive]);
    return this.startSession(sessionId, ttlSeconds);
  }

  closeSession(sessionId: string): Result<AttendanceSession> {
    const session = this.repo.findById(sessionId);
    if (!session)
      return failure(RejectionReason.sessionNotFound, reasonText[RejectionReason.sessionNotFound]);
    const updated = { ...session, status: SessionStatus.closed, otp: null };
    this.repo.save(updated);
    return success(updated);
  }
}

/** The "doorman": ordered rule checks, first failure wins. */
export class AttendanceValidator {
  constructor(
    private attendanceRepo: AttendanceRepository,
    private clock: Clock,
  ) {}

  validate(
    session: AttendanceSession | null,
    studentId: string,
    code: string
  ): Result<true> {
    if (!session)
      return failure(RejectionReason.sessionNotFound, reasonText[RejectionReason.sessionNotFound]);
    if (session.status !== SessionStatus.active || !session.otp)
      return failure(RejectionReason.sessionNotActive, reasonText[RejectionReason.sessionNotActive]);
    if (!session.enrolledStudentIds.includes(studentId))
      return failure(
        RejectionReason.studentNotEnrolled,
        reasonText[RejectionReason.studentNotEnrolled],
      );
    if (session.otp.code !== code.trim())
      return failure(RejectionReason.invalidOtp, reasonText[RejectionReason.invalidOtp]);
    if (isOtpExpired(session.otp, this.clock.now()))
      return failure(RejectionReason.otpExpired, reasonText[RejectionReason.otpExpired]);
    if (this.attendanceRepo.exists(session.id, studentId))
      return failure(
        RejectionReason.duplicateAttendance,
        reasonText[RejectionReason.duplicateAttendance],
      );

    return success(true);
  }
}

export class AttendanceService {
  constructor(
    private sessionRepo: SessionRepository,
    private attendanceRepo: AttendanceRepository,
    private validator: AttendanceValidator,
    private clock: Clock,
  ) {}

  markAttendance(
    sessionId: string,
    studentId: string,
    code: string
  ): Result<AttendanceRecord> {
    const session = this.sessionRepo.findById(sessionId);
    const check = this.validator.validate(session, studentId, code);
    if (!check.ok) return check;


    const record: AttendanceRecord = {
      id: nextId("record"),
      sessionId,
      studentId,
      markedAt: this.clock.now(),
      status: AttendanceStatus.present,
      method: AttendanceMethod.otp,
    };
    this.attendanceRepo.save(record);
    return success(record);
  }


  recordsFor(sessionId: string) {
    return this.attendanceRepo.findBySession(sessionId);
  }
}

import { SqliteSessionRepository, SqliteAttendanceRepository } from './db';

/* ----------------------------- composition root ---------------------------- */

export function buildAms(clock: Clock = new SystemClock()) {
  const sessionRepo = new SqliteSessionRepository();
  const attendanceRepo = new SqliteAttendanceRepository();
  const validator = new AttendanceValidator(attendanceRepo, clock);
  return {
    clock,
    sessionRepo,
    attendanceRepo,
    sessionService: new SessionService(sessionRepo, clock, new NumericOtpGenerator(6)),
    attendanceService: new AttendanceService(sessionRepo, attendanceRepo, validator, clock),
  };
}
