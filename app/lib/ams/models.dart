import 'globals.dart';

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
  completed,
}

enum AttendanceStatus {
  present,
  absent,
}

enum AttendanceMethod {
  qrCode,
  manual,
}

enum RejectionReason {
  sessionNotFound,
  sessionNotActive,
  invalidQrCode,
  qrCodeExpired,
  duplicateAttendance,
  studentNotEnrolled,
}

const reasonText = {
  RejectionReason.sessionNotFound: "No such session.",
  RejectionReason.sessionNotActive: "This session is not open for attendance.",
  RejectionReason.invalidQrCode: "That QR code is incorrect or expired.",
  RejectionReason.qrCodeExpired: "That QR code has expired.",
  RejectionReason.duplicateAttendance: "Attendance already marked for this student.",
  RejectionReason.studentNotEnrolled: "Student is not enrolled in this class.",
};


class QrCode {
  final String code;
  final DateTime issuedAt;
  final DateTime expiresAt;

  QrCode({
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
  final QrCode? qrCode;
  final List<String> enrolledStudentIds;
  final String approvalStatus;
  final String? proxyFacultyId;
  final String? proxyFacultyName;
  final String? batchTarget;
  final String? slotId;

  AttendanceSession({
    required this.id,
    required this.courseCode,
    required this.facultyId,
    required this.status,
    required this.createdAt,
    this.qrCode,
    required this.enrolledStudentIds,
    this.approvalStatus = 'approved',
    this.proxyFacultyId,
    this.proxyFacultyName,
    this.batchTarget,
    this.slotId,
  });

  AttendanceSession copyWith({
    String? id,
    String? courseCode,
    String? facultyId,
    SessionStatus? status,
    DateTime? createdAt,
    QrCode? qrCode,
    bool clearQrCode = false,
    List<String>? enrolledStudentIds,
    String? approvalStatus,
    String? proxyFacultyId,
    String? proxyFacultyName,
    String? batchTarget,
    String? slotId,
  }) {
    return AttendanceSession(
      id: id ?? this.id,
      courseCode: courseCode ?? this.courseCode,
      facultyId: facultyId ?? this.facultyId,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      qrCode: clearQrCode ? null : (qrCode ?? this.qrCode),
      enrolledStudentIds: enrolledStudentIds ?? this.enrolledStudentIds,
      approvalStatus: approvalStatus ?? this.approvalStatus,
      proxyFacultyId: proxyFacultyId ?? this.proxyFacultyId,
      proxyFacultyName: proxyFacultyName ?? this.proxyFacultyName,
      batchTarget: batchTarget ?? this.batchTarget,
      slotId: slotId ?? this.slotId,
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
  final String email;
  final String? rollNo;
  final String? profilePictureUrl;
  final String? branch;
  final String? division;
  final String? electiveBatch;
  final String? coreBatch;
  final List<Map<String, dynamic>>? scopes;

  String get formattedName {
    if (role == 'faculty') {
      return AmsGlobals.formatFacultyName(name);
    } else {
      return AmsGlobals.formatStudentName(name, email);
    }
  }
  User({
    required this.id,
    required this.role,
    required this.name,
    required this.email,
    this.rollNo,
    this.profilePictureUrl,
    this.branch,
    this.division,
    this.electiveBatch,
    this.coreBatch,
    this.scopes,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      role: json['role'],
      name: json['name'],
      email: json['email'] ?? '',
      rollNo: json['rollNo'],
      profilePictureUrl: json['profilePictureUrl'],
      branch: json['branch'],
      division: json['division'],
      electiveBatch: json['electiveBatch'],
      coreBatch: json['coreBatch'],
      scopes: json['scopes'] != null ? List<Map<String, dynamic>>.from(json['scopes']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'role': role,
      'name': name,
      'email': email,
      'rollNo': rollNo,
      'profilePictureUrl': profilePictureUrl,
      'branch': branch,
      'division': division,
      'electiveBatch': electiveBatch,
      'coreBatch': coreBatch,
      'scopes': scopes,
    };
  }
}

class Student {
  final String id;
  final String name;
  final String rollNo;
  final String email;
  final String? profilePictureUrl;

  Student({
    required this.id,
    required this.name,
    required this.rollNo,
    required this.email,
    this.profilePictureUrl,
  });
}
