import 'dart:math';
import 'models.dart';
import 'repositories.dart';

abstract class Clock {
  DateTime now();
}

class SystemClock implements Clock {
  @override
  DateTime now() => DateTime.now();
}

class MutableClock implements Clock {
  DateTime _current;
  MutableClock([DateTime? current]) : _current = current ?? DateTime.now();

  @override
  DateTime now() => DateTime.fromMillisecondsSinceEpoch(_current.millisecondsSinceEpoch);

  void advanceSeconds(int seconds) {
    _current = _current.add(Duration(seconds: seconds));
  }

  void set(DateTime date) {
    _current = date;
  }
}

abstract class OtpGenerator {
  String generate();
}

class NumericOtpGenerator implements OtpGenerator {
  final int length;
  final Random _rng = Random();

  NumericOtpGenerator([this.length = 6]);

  @override
  String generate() {
    String code = "";
    for (int i = 0; i < length; i++) {
      code += _rng.nextInt(10).toString();
    }
    return code;
  }
}

int _idSeed = 0;
String nextId(String prefix) {
  _idSeed++;
  return "${prefix}_$_idSeed";
}

class SessionService {
  final SessionRepository repo;
  final Clock clock;
  final OtpGenerator otpGen;

  SessionService({
    required this.repo,
    required this.clock,
    required this.otpGen,
  });

  AttendanceSession createSession({
    required String courseCode,
    required String facultyId,
    required List<String> enrolledStudentIds,
  }) {
    final session = AttendanceSession(
      id: nextId("session"),
      courseCode: courseCode,
      facultyId: facultyId,
      status: SessionStatus.scheduled,
      createdAt: clock.now(),
      enrolledStudentIds: enrolledStudentIds,
    );

    repo.save(session);
    return session;
  }

  Result<AttendanceSession> startSession(String sessionId, int ttlSeconds) {
    final session = repo.findById(sessionId);
    if (session == null) {
      return Result.failure(RejectionReason.sessionNotFound, reasonText[RejectionReason.sessionNotFound]!);
    }
    
    final now = clock.now();
    final updated = session.copyWith(
      status: SessionStatus.active,
      otp: Otp(
        code: otpGen.generate(),
        issuedAt: now,
        expiresAt: now.add(Duration(seconds: ttlSeconds)),
      ),
    );
    repo.save(updated);
    return Result.success(updated);
  }

  Result<AttendanceSession> rotateOtp(String sessionId, int ttlSeconds) {
    final session = repo.findById(sessionId);
    if (session == null) {
      return Result.failure(RejectionReason.sessionNotFound, reasonText[RejectionReason.sessionNotFound]!);
    }
    if (session.status != SessionStatus.active) {
      return Result.failure(RejectionReason.sessionNotActive, reasonText[RejectionReason.sessionNotActive]!);
    }
    return startSession(sessionId, ttlSeconds);
  }

  Result<AttendanceSession> closeSession(String sessionId) {
    final session = repo.findById(sessionId);
    if (session == null) {
      return Result.failure(RejectionReason.sessionNotFound, reasonText[RejectionReason.sessionNotFound]!);
    }
    final updated = session.copyWith(
      status: SessionStatus.closed,
      clearOtp: true,
    );
    repo.save(updated);
    return Result.success(updated);
  }
}

class AttendanceValidator {
  final AttendanceRepository attendanceRepo;
  final Clock clock;

  AttendanceValidator({
    required this.attendanceRepo,
    required this.clock,
  });

  Result<bool> validate(
    AttendanceSession? session,
    String studentId,
    String code,
  ) {
    if (session == null) {
      return Result.failure(RejectionReason.sessionNotFound, reasonText[RejectionReason.sessionNotFound]!);
    }
    if (session.status != SessionStatus.active || session.otp == null) {
      return Result.failure(RejectionReason.sessionNotActive, reasonText[RejectionReason.sessionNotActive]!);
    }
    if (!session.enrolledStudentIds.contains(studentId)) {
      return Result.failure(RejectionReason.studentNotEnrolled, reasonText[RejectionReason.studentNotEnrolled]!);
    }
    if (session.otp!.code != code.trim()) {
      return Result.failure(RejectionReason.invalidOtp, reasonText[RejectionReason.invalidOtp]!);
    }
    if (session.otp!.isExpired(clock.now())) {
      return Result.failure(RejectionReason.otpExpired, reasonText[RejectionReason.otpExpired]!);
    }
    if (attendanceRepo.exists(session.id, studentId)) {
      return Result.failure(RejectionReason.duplicateAttendance, reasonText[RejectionReason.duplicateAttendance]!);
    }

    return Result.success(true);
  }
}

class AttendanceService {
  final SessionRepository sessionRepo;
  final AttendanceRepository attendanceRepo;
  final AttendanceValidator validator;
  final Clock clock;

  AttendanceService({
    required this.sessionRepo,
    required this.attendanceRepo,
    required this.validator,
    required this.clock,
  });

  Result<AttendanceRecord> markAttendance(
    String sessionId,
    String studentId,
    String code,
  ) {
    final session = sessionRepo.findById(sessionId);
    final check = validator.validate(session, studentId, code);
    if (!check.ok) {
      return Result.failure(check.reason!, check.message!);
    }

    final record = AttendanceRecord(
      id: nextId("record"),
      sessionId: sessionId,
      studentId: studentId,
      markedAt: clock.now(),
      status: AttendanceStatus.present,
      method: AttendanceMethod.otp,
    );

    attendanceRepo.save(record);
    return Result.success(record);
  }

  List<AttendanceRecord> recordsFor(String sessionId) {
    return attendanceRepo.findBySession(sessionId);
  }
}
