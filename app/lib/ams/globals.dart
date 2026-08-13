import 'api_services.dart';
import 'models.dart';

class AmsGlobals {
  static User? loggedInUser;
  static final ApiSessionService sessionService = ApiSessionService();
  static final ApiAttendanceService attendanceService = ApiAttendanceService();

  /// For testing the mock UI, we store the currently active session ID globally
  /// so that the student screen can just fetch it when verifying.
  /// (This will be fetched from the API instead on a second device).
  static String? activeSessionId;
}
