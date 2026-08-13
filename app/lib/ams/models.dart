class Result<T> {
  final bool ok;
  final T? value;
  final RejectionReason? reason;
  final String? message;

  Result._({required this.ok, this.value, this.reason, this.message});

  factory Result.success(T value) => Result._(ok: true, value: value);
  
  factory Result.failure(RejectionReason reason, String message) =>
      Result._(ok: false, reason: reason, message: message);
}

enum SessionStatus {
  scheduled,
  active,
  closed,
}

enum AttendanceStatus {
  present,
  absent,
}

enum AttendanceMethod {
  otp,
  otpBluetooth,
  manual,
}

enum RejectionReason {
  sessionNotFound,
  sessionNotActive,
  invalidOtp,
  otpExpired,
  duplicateAttendance,
  studentNotEnrolled,
}

const reasonText = {
  RejectionReason.sessionNotFound: "No such session.",
  RejectionReason.sessionNotActive: "This session is not open for attendance.",
  RejectionReason.invalidOtp: "That OTP is incorrect.",
  RejectionReason.otpExpired: "That OTP has expired.",
  RejectionReason.duplicateAttendance: "Attendance already marked for this student.",
  RejectionReason.studentNotEnrolled: "Student is not enrolled in this class.",
};


class Otp {
  final String code;
  final DateTime issuedAt;
  final DateTime expiresAt;

  Otp({
    required this.code,
    required this.issuedAt,
    required this.expiresAt,
  });

  bool isExpired(DateTime now) {
    return now.isAfter(expiresAt) || now.isAtSameMomentAs(expiresAt);
  }
}

class AttendanceSession {
  final String id;
  final String courseCode;
  final String facultyId;
  final SessionStatus status;
  final DateTime createdAt;
  final Otp? otp;
  final List<String> enrolledStudentIds;

  AttendanceSession({
    required this.id,
    required this.courseCode,
    required this.facultyId,
    required this.status,
    required this.createdAt,
    this.otp,
    required this.enrolledStudentIds,
  });

  AttendanceSession copyWith({
    String? id,
    String? courseCode,
    String? facultyId,
    SessionStatus? status,
    DateTime? createdAt,
    Otp? otp,
    bool clearOtp = false,
    List<String>? enrolledStudentIds,
  }) {
    return AttendanceSession(
      id: id ?? this.id,
      courseCode: courseCode ?? this.courseCode,
      facultyId: facultyId ?? this.facultyId,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      otp: clearOtp ? null : (otp ?? this.otp),
      enrolledStudentIds: enrolledStudentIds ?? this.enrolledStudentIds,
    );
  }
}

class AttendanceRecord {
  final String id;
  final String sessionId;
  final String studentId;
  final DateTime markedAt;
  final AttendanceStatus status;
  final AttendanceMethod method;
  final String? studentName;
  final String? studentRollNo;

  AttendanceRecord({
    required this.id,
    required this.sessionId,
    required this.studentId,
    required this.markedAt,
    required this.status,
    required this.method,
    this.studentName,
    this.studentRollNo,
  });
}

class User {
  final String id;
  final String role;
  final String name;
  final String? rollNo;

  User({
    required this.id,
    required this.role,
    required this.name,
    this.rollNo,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      role: json['role'],
      name: json['name'],
      rollNo: json['rollNo'],
    );
  }
}

class Student {
  final String id;
  final String name;
  final String rollNo;

  Student({
    required this.id,
    required this.name,
    required this.rollNo,
  });
}
