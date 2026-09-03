import 'package:flutter/material.dart';
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
  /// Global list of timetable slots shared between the Manager and the Dashboard.
  static final List<Map<String, dynamic>> timetableSlots = [];

  /// Global notifier for ThemeMode (Light/Dark)
  static final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.light);
  static final ValueNotifier<int> refreshNotifier = ValueNotifier(0);
  
  static String? userRole;

  /// Helper to generate consistent colors based on Batch/Division
  static Color getBatchColor(String batch) {
    if (batch.startsWith('D5')) return Colors.blue;
    if (batch.startsWith('D10')) return Colors.orange;
    if (batch.startsWith('D15')) return Colors.purple;
    if (batch.startsWith('D20')) return Colors.teal;
    return const Color(0xFFB89100); // Default gold
  }

  /// Helper to reliably extract and format a student's name from their VES email or raw name.
  static String formatStudentName(String? rawName, String? email) {
    String formattedName = rawName ?? 'Unknown';
    bool parsedFromEmail = false;
    
    if (email != null && email.isNotEmpty && email.contains('@')) {
      String localPart = email.split('@').first.replaceAll(',', '.');
      List<String> parts = localPart.split('.');
      if (parts.length >= 3) {
        String first = parts[1];
        String last = parts[2];
        first = first.isEmpty ? '' : first[0].toUpperCase() + first.substring(1).toLowerCase();
        last = last.isEmpty ? '' : last[0].toUpperCase() + last.substring(1).toLowerCase();
        formattedName = '$first $last'.trim();
        parsedFromEmail = true;
      } else if (parts.length == 2) {
        String first = parts[0];
        String last = parts[1];
        first = first.isEmpty ? '' : first[0].toUpperCase() + first.substring(1).toLowerCase();
        last = last.isEmpty ? '' : last[0].toUpperCase() + last.substring(1).toLowerCase();
        formattedName = '$first $last'.trim();
        parsedFromEmail = true;
      }
    }
    
    if (!parsedFromEmail && rawName != null) {
      final parts = rawName.trim().split(' ').where((s) => s.isNotEmpty).toList();
      if (parts.length >= 2) {
        String first = parts[1];
        String last = parts[0];
        first = first.isEmpty ? '' : first[0].toUpperCase() + first.substring(1).toLowerCase();
        last = last.isEmpty ? '' : last[0].toUpperCase() + last.substring(1).toLowerCase();
        formattedName = '$first $last'.trim();
      } else if (parts.length == 1) {
        String first = parts[0];
        first = first.isEmpty ? '' : first[0].toUpperCase() + first.substring(1).toLowerCase();
        formattedName = first;
      }
    }
    return formattedName;
  }
  
  /// Helper to reliably map abbreviated faculty names like 'PN' to 'Pooja Nagdev'
  static String formatFacultyName(String rawName) {
    if (rawName.isEmpty) return rawName;
    
    // Explicit mappings for dashboard names
    final lowerName = rawName.toLowerCase().replaceAll('prof.', '').trim();
    if (lowerName == 'pn') return 'Pooja Nagdev';
    if (lowerName == 'ps') return 'Pooja Shetty';
    
    // Standard formatting (removing 'Prof.', capitalizing words)
    final parts = rawName.split(' ').where((s) => s.isNotEmpty).toList();
    var filteredParts = parts.where((p) => !['prof.', 'prof', 'dr.', 'dr', 'mr.', 'mr', 'mrs.', 'mrs', 'ms.', 'ms'].contains(p.toLowerCase())).toList();
    if (filteredParts.isEmpty) filteredParts = parts;
    
    return filteredParts.map((p) {
      if (p.isEmpty) return '';
      if (p.length <= 3) return p.toUpperCase();
      return p[0].toUpperCase() + p.substring(1).toLowerCase();
    }).join(' ');
  }
}
