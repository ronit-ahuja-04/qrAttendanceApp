const fs = require('fs');

let content = fs.readFileSync('lib/ams/api_services.dart', 'utf8');

const regex = /Future<AttendanceSession> createSmartSeminarSession\(\{[\s\S]*?approvalStatus: 'pending',\s*\);\s*\}\s*throw Exception\('Failed to create session: \$\{response\.body\}'\);\s*\}/;

const newCode = `  Future<AttendanceSession> createSmartSeminarSession({
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
    );
    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      return AttendanceSession(
        id: body['id'], // this is the groupId
        courseCode: 'Smart Seminar',
        facultyId: proxyFacultyId,
        status: SessionStatus.scheduled,
        createdAt: DateTime.parse(body['createdAt']),
        enrolledStudentIds: [],
        approvalStatus: 'approved',
      );
    }
    throw Exception('Failed to create smart seminar: \${response.body}');
  }`;

content = content.replace(regex, newCode);
fs.writeFileSync('lib/ams/api_services.dart', content);
console.log('Fixed API Service');
