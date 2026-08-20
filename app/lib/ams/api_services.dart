import 'dart:convert';
import 'package:http/http.dart' as http;
import 'models.dart';
import 'notification_service.dart';

import 'package:flutter/foundation.dart' show kIsWeb;

String get baseUrl {
  return 'http://127.0.0.1:3000';
}

class ApiSessionService {
  Future<User?> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );
      if (response.statusCode == 200) {
        final user = User.fromJson(jsonDecode(response.body));
        NotificationService().connectSse(user.id);
        return user;
      }
      return null;
    } catch (e) {
      print('LOGIN ERROR: $e');
      return null;
    }
  }

  Future<AttendanceSession> createSession({
    required String courseCode,
    required String facultyId,
    required List<String> enrolledStudentIds,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/sessions'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'courseCode': courseCode,
        'facultyId': facultyId,
        'enrolledStudentIds': enrolledStudentIds,
      }),
    );
    if (response.statusCode == 200) {
      return _parseSession(jsonDecode(response.body));
    }
    throw Exception('Failed to create session');
  }

  Future<Result<AttendanceSession>> startSession(String sessionId, int ttlSeconds) async {
    final response = await http.post(
      Uri.parse('$baseUrl/sessions/$sessionId/start'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'ttlSeconds': ttlSeconds}),
    );
    if (response.statusCode == 200) {
      return Result.success(_parseSession(jsonDecode(response.body)));
    }
    final err = jsonDecode(response.body);
    return Result.failure(_parseReason(err['error']), err['message'] ?? 'Error');
  }

  Future<Result<AttendanceSession>> rotateOtp(String sessionId, int ttlSeconds) async {
    final response = await http.post(
      Uri.parse('$baseUrl/sessions/$sessionId/rotate'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'ttlSeconds': ttlSeconds}),
    );
    if (response.statusCode == 200) {
      return Result.success(_parseSession(jsonDecode(response.body)));
    }
    final err = jsonDecode(response.body);
    return Result.failure(_parseReason(err['error']), err['message'] ?? 'Error');
  }

  Future<Result<AttendanceSession>> closeSession(String sessionId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/sessions/$sessionId/close'),
      headers: {'Content-Type': 'application/json'},
    );
    if (response.statusCode == 200) {
      return Result.success(_parseSession(jsonDecode(response.body)));
    }
    final err = jsonDecode(response.body);
    return Result.failure(_parseReason(err['error']), err['message'] ?? 'Error');
  }

  Future<AttendanceSession?> getActiveSession(String courseCode) async {
    final cacheBuster = DateTime.now().millisecondsSinceEpoch;
    final response = await http.get(Uri.parse('$baseUrl/sessions/active/${Uri.encodeComponent(courseCode)}?_t=$cacheBuster'));
    if (response.statusCode == 200) {
      return _parseSession(jsonDecode(response.body));
    }
    return null;
  }

  Future<List<AttendanceSession>> getFacultySessions(String facultyId) async {
    try {
      final cacheBuster = DateTime.now().millisecondsSinceEpoch;
      final response = await http.get(Uri.parse('$baseUrl/sessions/faculty/${Uri.encodeComponent(facultyId)}?_t=$cacheBuster'));
      if (response.statusCode == 200) {
        final List<dynamic> body = jsonDecode(response.body);
        return body.map((r) => _parseSession(r)).toList();
      }
      return [];
    } catch (e) {
      print('GET FACULTY SESSIONS EXCEPTION: $e');
      return [];
    }
  }
  Future<List<Map<String, dynamic>>> getVerificationList(String sessionId) async {
    try {
      final t = DateTime.now().millisecondsSinceEpoch;
      final response = await http.get(Uri.parse('$baseUrl/sessions/$sessionId/verification?_t=$t'));
      if (response.statusCode == 200) {
        final List<dynamic> body = jsonDecode(response.body);
        return body.map((r) => r as Map<String, dynamic>).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }
}

class ApiAttendanceService {
  Future<Result<AttendanceRecord>> markAttendance(
    String sessionId,
    String studentId,
    String code,
  ) async {
    final Map<String, dynamic> body = {
      'studentId': studentId,
      'code': code,
    };


    final response = await http.post(
      Uri.parse('$baseUrl/sessions/$sessionId/attendance'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    if (response.statusCode == 200) {
      return Result.success(_parseRecord(jsonDecode(response.body)));
    }
    final err = jsonDecode(response.body);
    return Result.failure(_parseReason(err['error']), err['message'] ?? 'Error');
  }

  Future<List<AttendanceRecord>> recordsFor(String sessionId) async {
    try {
      final t = DateTime.now().millisecondsSinceEpoch;
      final response = await http.get(Uri.parse('$baseUrl/sessions/$sessionId/attendance?_t=$t'));
      if (response.statusCode == 200) {
        final List<dynamic> body = jsonDecode(response.body);
        return body.map((r) => AttendanceRecord(
          id: r['id'],
          sessionId: r['sessionId'],
          studentId: r['studentId'],
          markedAt: DateTime.parse(r['markedAt']),
          status: AttendanceStatus.values.firstWhere((e) => e.toString().split('.').last == r['status']),
          method: AttendanceMethod.values.firstWhere((e) => e.toString().split('.').last == r['method']),
        )).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<List<AttendanceRecord>> recordsDetailsFor(String sessionId) async {
    try {
      final t = DateTime.now().millisecondsSinceEpoch;
      final response = await http.get(Uri.parse('$baseUrl/sessions/$sessionId/attendance/details?_t=$t'));
      if (response.statusCode == 200) {
        final List<dynamic> body = jsonDecode(response.body);
        return body.map((r) => AttendanceRecord(
          id: r['id'],
          sessionId: r['sessionId'],
          studentId: r['studentId'],
          markedAt: DateTime.parse(r['markedAt']),
          status: AttendanceStatus.values.firstWhere((e) => e.toString().split('.').last == r['status']),
          method: AttendanceMethod.values.firstWhere((e) => e.toString().split('.').last == r['method']),
          studentName: r['studentName'],
          studentRollNo: r['studentRollNo'],
        )).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<Map<String, dynamic>> getStudentStats(String studentId) async {
    try {
      final t = DateTime.now().millisecondsSinceEpoch;
      final response = await http.get(Uri.parse('$baseUrl/students/$studentId/stats?_t=$t'));
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        return {
          'overallPercentage': (body['overallPercentage'] as num).toDouble(),
          'thisWeekPercentage': (body['thisWeekPercentage'] as num).toDouble(),
          'subjects': body['subjects'] as List<dynamic>? ?? [],
        };
      }
      return {'overallPercentage': 0.0, 'thisWeekPercentage': 0.0, 'subjects': []};
    } catch (e) {
      return {'overallPercentage': 0.0, 'thisWeekPercentage': 0.0, 'subjects': []};
    }
  }
}

AttendanceSession _parseSession(Map<String, dynamic> json) {
  return AttendanceSession(
    id: json['id'],
    courseCode: json['courseCode'],
    facultyId: json['facultyId'],
    status: SessionStatus.values.firstWhere((e) => e.name == json['status']),
    createdAt: DateTime.parse(json['createdAt']),
    otp: json['otp'] != null ? Otp(
      code: json['otp']['code'],
      issuedAt: DateTime.parse(json['otp']['issuedAt']),
      expiresAt: DateTime.parse(json['otp']['expiresAt']),
    ) : null,
    enrolledStudentIds: List<String>.from(json['enrolledStudentIds']),
  );
}

AttendanceRecord _parseRecord(Map<String, dynamic> json) {
  return AttendanceRecord(
    id: json['id'],
    sessionId: json['sessionId'],
    studentId: json['studentId'],
    markedAt: DateTime.parse(json['markedAt']),
    status: AttendanceStatus.values.firstWhere((e) => e.name == json['status']),
    method: AttendanceMethod.values.firstWhere((e) => e.name == json['method']),
  );
}

RejectionReason _parseReason(String? reasonStr) {
  return RejectionReason.values.firstWhere(
    (e) => e.name == reasonStr,
    orElse: () => RejectionReason.invalidOtp,
  );
}
