import 'models.dart';

abstract class SessionRepository {
  void save(AttendanceSession session);
  AttendanceSession? findById(String id);
  List<AttendanceSession> findAll();
}

abstract class AttendanceRepository {
  void save(AttendanceRecord record);
  List<AttendanceRecord> findBySession(String sessionId);
  bool exists(String sessionId, String studentId);
}

class InMemorySessionRepository implements SessionRepository {
  final Map<String, AttendanceSession> _store = {};

  @override
  void save(AttendanceSession session) {
    _store[session.id] = session;
  }

  @override
  AttendanceSession? findById(String id) {
    return _store[id];
  }

  @override
  List<AttendanceSession> findAll() {
    return _store.values.toList();
  }
}

class InMemoryAttendanceRepository implements AttendanceRepository {
  final List<AttendanceRecord> _store = [];

  @override
  void save(AttendanceRecord record) {
    _store.add(record);
  }

  @override
  List<AttendanceRecord> findBySession(String sessionId) {
    return _store.where((r) => r.sessionId == sessionId).toList();
  }

  @override
  bool exists(String sessionId, String studentId) {
    return _store.any((r) => r.sessionId == sessionId && r.studentId == studentId);
  }
}
