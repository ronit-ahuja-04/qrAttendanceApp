import re

with open('lib/ams/api_services.dart', 'r') as f:
    content = f.read()

# Update createSmartSeminarSession
api_old = """  Future<AttendanceSession> createSmartSeminarSession({
    required String proxyFacultyId,
    required String division,
    required String startTime,
    required String endTime,
    required String date,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/sessions/smart-seminar'),
      headers: {'Content-Type': 'application/json', 'Bypass-Tunnel-Reminder': 'true'},
      body: jsonEncode({
        'proxyFacultyId': proxyFacultyId,
        'division': division,
        'startTime': startTime,
        'endTime': endTime,
        'date': date,
      }),
    );"""

api_new = """  Future<AttendanceSession> createSmartSeminarSession({
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
    );"""

content = content.replace(api_old, api_new)

with open('lib/ams/api_services.dart', 'w') as f:
    f.write(content)
