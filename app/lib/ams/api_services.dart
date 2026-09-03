import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'models.dart';
import 'notification_service.dart';
import 'globals.dart';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:image_picker/image_picker.dart';

String get baseUrl {
  // Use localhost (now that backend binds to IPv6 as well)
  return 'http://localhost:3000';
}

class ApiSessionService {
  Future<void> updateFcmToken(String userId, String token) async {
    try {
      await http.post(
        Uri.parse('$baseUrl/update-fcm-token'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'userId': userId, 'fcmToken': token}),
      );
    } catch (e) {
      print('UPDATE FCM TOKEN ERROR: $e');
    }
  }

  Future<void> updateNotificationPrefs(String userId, Map<String, bool> prefs) async {
    try {
      await http.post(
        Uri.parse('$baseUrl/update-notification-prefs'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'userId': userId, 'prefs': prefs}),
      );
    } catch (e) {
      print('UPDATE NOTIF PREFS ERROR: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getTimetable(String facultyId) async {
    try {
      final cacheBuster = DateTime.now().millisecondsSinceEpoch;
      final response = await http.get(
        Uri.parse('$baseUrl/timetable/${Uri.encodeComponent(facultyId)}?_t=$cacheBuster'),
        headers: {
          'Cache-Control': 'no-cache, no-store, must-revalidate',
          'Pragma': 'no-cache',
          'Expires': '0',
          'Bypass-Tunnel-Reminder': 'true',
        },
      );
      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(jsonDecode(response.body));
      }
    } catch (e) {
      print('GET TIMETABLE ERROR: $e');
    }
    return [];
  }

  Future<List<Map<String, dynamic>>> getStudentTimetableToday(String studentId, String day) async {
    try {
      final cacheBuster = DateTime.now().millisecondsSinceEpoch;
      final response = await http.get(
        Uri.parse('$baseUrl/api/timetable/student/${Uri.encodeComponent(studentId)}?day=${Uri.encodeComponent(day)}&_t=$cacheBuster'),
        headers: {
          'Cache-Control': 'no-cache, no-store, must-revalidate',
          'Pragma': 'no-cache',
          'Expires': '0',
          'Bypass-Tunnel-Reminder': 'true',
        },
      );
      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(jsonDecode(response.body));
      }
    } catch (e) {
      print('GET STUDENT TIMETABLE TODAY ERROR: $e');
    }
    return [];
  }

  Future<List<Map<String, dynamic>>> getStudentTimetableFull(String studentId) async {
    try {
      final cacheBuster = DateTime.now().millisecondsSinceEpoch;
      final response = await http.get(
        Uri.parse('$baseUrl/api/timetable/student/${Uri.encodeComponent(studentId)}?_t=$cacheBuster'),
        headers: {
          'Cache-Control': 'no-cache, no-store, must-revalidate',
          'Pragma': 'no-cache',
          'Expires': '0',
          'Bypass-Tunnel-Reminder': 'true',
        },
      );
      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(jsonDecode(response.body));
      }
    } catch (e) {
      print('GET STUDENT TIMETABLE FULL ERROR: $e');
    }
    return [];
  }

  Future<List<Map<String, dynamic>>> getStudentAttendanceHistory(String studentId) async {
    try {
      final cacheBuster = DateTime.now().millisecondsSinceEpoch;
      final response = await http.get(
        Uri.parse('$baseUrl/api/attendance/student/${Uri.encodeComponent(studentId)}/history?_t=$cacheBuster'),
        headers: {
          'Cache-Control': 'no-cache, no-store, must-revalidate',
          'Pragma': 'no-cache',
          'Expires': '0',
          'Bypass-Tunnel-Reminder': 'true',
        },
      );
      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(jsonDecode(response.body));
      }
    } catch (e) {
      print('GET STUDENT ATTENDANCE HISTORY ERROR: $e');
    }
    return [];
  }

  Future<String?> createTimetableSlot(Map<String, dynamic> slotData) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/timetable'),
        headers: {'Content-Type': 'application/json', 'Bypass-Tunnel-Reminder': 'true'},
        body: jsonEncode(slotData),
      );
      if (response.statusCode == 200) return null;
      return jsonDecode(response.body)['error'] ?? 'Unknown error occurred';
    } catch (e) {
      print('CREATE TIMETABLE SLOT ERROR: $e');
      return e.toString();
    }
  }

  Future<String?> updateTimetableSlot(String id, Map<String, dynamic> slotData) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/api/timetable/${Uri.encodeComponent(id)}'),
        headers: {'Content-Type': 'application/json', 'Bypass-Tunnel-Reminder': 'true'},
        body: jsonEncode(slotData),
      );
      if (response.statusCode == 200) return null;
      return jsonDecode(response.body)['error'] ?? 'Unknown error occurred';
    } catch (e) {
      print('UPDATE TIMETABLE SLOT ERROR: $e');
      return e.toString();
    }
  }

  Future<bool> deleteTimetableSlot(String id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/api/timetable/${Uri.encodeComponent(id)}'),
        headers: {'Bypass-Tunnel-Reminder': 'true'},
      );
      return response.statusCode == 200;
    } catch (e) {
      print('DELETE TIMETABLE SLOT ERROR: $e');
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> getNotifications(String userId) async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/api/notifications/$userId'));
      if (res.statusCode == 200) {
        return List<Map<String, dynamic>>.from(jsonDecode(res.body));
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<bool> markNotificationAsRead(String id) async {
    try {
      final res = await http.put(Uri.parse('$baseUrl/api/notifications/$id/read'));
      return res.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<bool> markAllNotificationsAsRead(String userId) async {
    try {
      final res = await http.put(Uri.parse('$baseUrl/api/notifications/user/$userId/read-all'));
      return res.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<User?> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Content-Type': 'application/json', 'Bypass-Tunnel-Reminder': 'true'},
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

  Future<void> logout() async {
    NotificationService().disconnectSse();
    final currentUser = AmsGlobals.loggedInUser;
    if (currentUser != null) {
      await updateFcmToken(currentUser.id, '');
    }
    try {
      await FirebaseMessaging.instance.deleteToken();
    } catch (e) {
      print('Error deleting FCM token: $e');
    }
  }

  /// Requests a password reset OTP for [email].
  /// The OTP is sent to the user's email. Throws an error message string on failure.
  Future<void> forgotPassword(String email) async {
    final response = await http.post(
      Uri.parse('$baseUrl/forgot-password'),
      headers: {'Content-Type': 'application/json', 'Bypass-Tunnel-Reminder': 'true'},
      body: jsonEncode({'email': email}),
    );
    if (response.statusCode != 200) {
      final body = jsonDecode(response.body);
      throw body['error'] ?? 'Failed to send reset code';
    }
  }

  /// Resets password using the OTP [token] and [newPassword].
  /// Throws an error message string on failure.
  Future<void> resetPassword(String token, String newPassword) async {
    final response = await http.post(
      Uri.parse('$baseUrl/reset-password'),
      headers: {'Content-Type': 'application/json', 'Bypass-Tunnel-Reminder': 'true'},
      body: jsonEncode({'token': token, 'newPassword': newPassword}),
    );
    if (response.statusCode != 200) {
      final body = jsonDecode(response.body);
      throw body['error'] ?? 'Failed to reset password';
    }
  }

  /// Changes the user's password if current password is correct.
  Future<void> changePassword(String userId, String currentPassword, String newPassword) async {
    final response = await http.post(
      Uri.parse('$baseUrl/change-password'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'userId': userId,
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      }),
    );
    if (response.statusCode != 200) {
      final body = jsonDecode(response.body);
      throw body['error'] ?? 'Failed to change password';
    }
  }

  Future<User?> uploadProfilePicture(String userId, XFile file) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/users/$userId/profile-picture'),
      );
      
      if (kIsWeb) {
        final bytes = await file.readAsBytes();
        request.files.add(http.MultipartFile.fromBytes(
          'profilePicture',
          bytes,
          filename: file.name,
        ));
      } else {
        request.files.add(await http.MultipartFile.fromPath(
          'profilePicture',
          file.path,
        ));
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final url = data['profilePictureUrl'];
        return AmsGlobals.loggedInUser = User(
          id: AmsGlobals.loggedInUser!.id,
          role: AmsGlobals.loggedInUser!.role,
          name: AmsGlobals.loggedInUser!.name,
          email: AmsGlobals.loggedInUser!.email,
          rollNo: AmsGlobals.loggedInUser!.rollNo,
          profilePictureUrl: url,
        );
      }
      return null;
    } catch (e) {
      print('UPLOAD PROFILE PICTURE ERROR: $e');
      return null;
    }
  }

  Future<AttendanceSession> createSession({
    required String courseCode,
    required String facultyId,
    List<String>? enrolledStudentIds,
    String? batchTarget,
    bool isProxy = false,
    String? originalFacultyId,
    bool creditToProxy = false,
    bool autoApprove = false,
    String? slotId,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/sessions'),
      headers: {'Content-Type': 'application/json', 'Bypass-Tunnel-Reminder': 'true'},
      body: jsonEncode({
        'courseCode': courseCode,
        'facultyId': facultyId,
        'enrolledStudentIds': enrolledStudentIds ?? [],
        'batchTarget': batchTarget ?? '',
        if (isProxy) 'isProxy': true,
        if (isProxy && originalFacultyId != null) 'originalFacultyId': originalFacultyId,
        if (isProxy) 'creditToProxy': creditToProxy,
        if (isProxy) 'autoApprove': autoApprove,
        if (slotId != null) 'slotId': slotId,
      }),
    );
    if (response.statusCode == 200) {
      return _parseSession(jsonDecode(response.body));
    }
    throw Exception('Failed to create session: ${response.body}');
  }

  Future<AttendanceSession> createSmartSeminarSession({
    required String proxyFacultyId,
    required List<String> divisions,
    required String startTime,
    required String endTime,
    required String date,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/sessions/smart-seminar'),
      headers: {'Content-Type': 'application/json', 'Bypass-Tunnel-Reminder': 'true'},
      body: jsonEncode({
        'proxyFacultyId': proxyFacultyId,
        'divisions': divisions,
        'startTime': startTime,
        'endTime': endTime,
        'date': date,
      }),
    );
    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      return AttendanceSession(
        id: body['id'], // this is the groupId
        courseCode: 'Smart Seminar',
        facultyId: proxyFacultyId,
        status: SessionStatus.scheduled,
        createdAt: DateTime.parse(body['createdAt']).toLocal(),
        enrolledStudentIds: [],
        approvalStatus: 'approved',
      );
    }
    throw Exception('Failed to create smart seminar: \${response.body}');
  }

  Future<Result<AttendanceSession>> startSession(String sessionId, int ttlSeconds) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/sessions/$sessionId/start'),
      headers: {'Content-Type': 'application/json', 'Bypass-Tunnel-Reminder': 'true'},
      body: jsonEncode({'totalSessionSeconds': ttlSeconds}),
    );
    if (response.statusCode == 200) {
      return Result.success(_parseSession(jsonDecode(response.body)));
    }
    final err = jsonDecode(response.body);
    return Result.failure(_parseReason(err['error']), err['message'] ?? 'Error');
  }

  Future<Result<AttendanceSession>> rotateQrCode(String sessionId, int ttlSeconds) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/sessions/$sessionId/rotate-qr'),
      headers: {'Content-Type': 'application/json', 'Bypass-Tunnel-Reminder': 'true'},
      body: jsonEncode({'validitySeconds': ttlSeconds}),
    );
    if (response.statusCode == 200) {
      return Result.success(_parseSession(jsonDecode(response.body)));
    }
    final err = jsonDecode(response.body);
    return Result.failure(_parseReason(err['error']), err['message'] ?? 'Error');
  }

  Future<Result<bool>> closeSession(String sessionId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/sessions/$sessionId/close'),
      headers: {'Content-Type': 'application/json', 'Bypass-Tunnel-Reminder': 'true'},
    );
    if (response.statusCode == 200) {
      return Result.success(true);
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
      final response = await http.get(Uri.parse('$baseUrl/api/sessions/faculty/${Uri.encodeComponent(facultyId)}?_t=$cacheBuster'));
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
  Future<bool> approveProxySession(String sessionId) async {
    try {
      final response = await http.put(Uri.parse('$baseUrl/api/sessions/$sessionId/approve'));
      return response.statusCode == 200;
    } catch (e) {
      print('APPROVE SESSION ERROR: $e');
      return false;
    }
  }

  Future<bool> declineProxySession(String sessionId) async {
    try {
      final response = await http.put(Uri.parse('$baseUrl/api/sessions/$sessionId/decline'));
      return response.statusCode == 200;
    } catch (e) {
      print('DECLINE SESSION ERROR: $e');
      return false;
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
      'sessionId': sessionId,
      'studentId': studentId,
      'code': code,
    };


    final response = await http.post(
      Uri.parse('$baseUrl/api/attendance/mark'),
      headers: {'Content-Type': 'application/json', 'Bypass-Tunnel-Reminder': 'true'},
      body: jsonEncode(body),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return Result.success(_parseRecord(data['record'] ?? data));
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
          markedAt: DateTime.parse(r['markedAt']).toLocal(),
          status: r['status'] == 'present' ? AttendanceStatus.present : AttendanceStatus.absent,
          method: (r['method'] == 'qr' || r['method'] == 'qrCode') 
              ? AttendanceMethod.qrCode 
              : AttendanceMethod.manual,
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
          markedAt: DateTime.parse(r['markedAt']).toLocal(),
          status: r['status'] == 'present' ? AttendanceStatus.present : AttendanceStatus.absent,
          method: (r['method'] == 'qr' || r['method'] == 'qrCode') 
              ? AttendanceMethod.qrCode 
              : AttendanceMethod.manual,
          studentName: AmsGlobals.formatStudentName(r['studentName'], r['email']),
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
      final response = await http.get(Uri.parse('$baseUrl/api/attendance/student/${Uri.encodeComponent(studentId)}/stats'));
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
      print('GET STUDENT STATS ERROR: $e');
      return {'overallPercentage': 0.0, 'thisWeekPercentage': 0.0, 'subjects': []};
    }
  }


}

AttendanceSession _parseSession(Map<String, dynamic> json) {
  List<String> parseEnrolled(dynamic val) {
    if (val == null) return [];
    if (val is String) {
      try {
        return List<String>.from(jsonDecode(val));
      } catch (_) {
        return [];
      }
    }
    if (val is List) {
      return List<String>.from(val);
    }
    return [];
  }

  return AttendanceSession(
    id: json['id'],
    courseCode: json['courseCode'],
    facultyId: json['facultyId'],
    status: SessionStatus.values.firstWhere((e) => e.name == json['status']),
    createdAt: DateTime.parse(json['createdAt']).toLocal(),
    qrCode: json['qrCode'] != null ? QrCode(
      code: json['qrCode']['code'],
      issuedAt: DateTime.parse(json['qrCode']['issuedAt']).toLocal(),
      expiresAt: DateTime.parse(json['qrCode']['expiresAt']).toLocal(),
    ) : null,
    enrolledStudentIds: parseEnrolled(json['enrolledStudentIds']),
    approvalStatus: json['approvalStatus'] ?? 'approved',
    proxyFacultyId: json['proxyFacultyId'],
    proxyFacultyName: json['proxyFacultyName'],
    batchTarget: json['batchTarget'],
    slotId: json['slotId'],
  );
}

AttendanceRecord _parseRecord(Map<String, dynamic> json) {
  return AttendanceRecord(
    id: json['id'],
    sessionId: json['sessionId'],
    studentId: json['studentId'],
    markedAt: DateTime.parse(json['markedAt']).toLocal(),
    status: json['status'] == 'present' ? AttendanceStatus.present : AttendanceStatus.absent,
    method: (json['method'] == 'qr' || json['method'] == 'qrCode')
        ? AttendanceMethod.qrCode
        : AttendanceMethod.manual,
  );
}

RejectionReason _parseReason(String? reasonStr) {
  return RejectionReason.values.firstWhere(
    (e) => e.name == reasonStr,
    orElse: () => RejectionReason.invalidQrCode,
  );
}
