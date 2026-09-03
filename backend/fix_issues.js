const fs = require('fs');

// 1. Fix backend/database.js keyMap
let dbCode = fs.readFileSync('database.js', 'utf8');
if (!dbCode.includes("timetableslotid: 'timetableSlotId'")) {
  dbCode = dbCode.replace("facultyid: 'facultyId',", "facultyid: 'facultyId',\n    timetableslotid: 'timetableSlotId',\n    facultyname: 'facultyName',\n    facultyemail: 'facultyEmail',");
  fs.writeFileSync('database.js', dbCode);
  console.log('Fixed database.js');
}

// 2. Fix generate_report_screen.dart
let grsCode = fs.readFileSync('../app/lib/screens/generate_report_screen.dart', 'utf8');
if (!grsCode.includes("token=\$token")) {
  grsCode = grsCode.replace(
    "final url = '$baseUrl/api/report/excel/${widget.session.id}';",
    `final prefs = await SharedPreferences.getInstance();
      final sessionJson = prefs.getString('ams_user_session');
      String token = '';
      if (sessionJson != null) {
        try {
          token = jsonDecode(sessionJson)['token'] ?? '';
        } catch(e) {}
      }
      final url = '$baseUrl/api/report/excel/\${widget.session.id}?token=\$token';`
  );
  fs.writeFileSync('../app/lib/screens/generate_report_screen.dart', grsCode);
  console.log('Fixed generate_report_screen.dart');
}

// 3. Fix report_timeline_screen.dart
let rtsCode = fs.readFileSync('../app/lib/screens/report_timeline_screen.dart', 'utf8');
if (!rtsCode.includes("token=\$token")) {
  rtsCode = rtsCode.replace(
    "final url = '$baseUrl/api/report/bulk-excel?facultyId=$facultyId&subject=$subject&batchTarget=$batchTarget&startDate=$start&endDate=$end';",
    `final prefs = await SharedPreferences.getInstance();
      final sessionJson = prefs.getString('ams_user_session');
      String token = '';
      if (sessionJson != null) {
        try {
          token = jsonDecode(sessionJson)['token'] ?? '';
        } catch(e) {}
      }
      final url = '$baseUrl/api/report/bulk-excel?facultyId=$facultyId&subject=$subject&batchTarget=$batchTarget&startDate=$start&endDate=$end&token=\$token';`
  );
  fs.writeFileSync('../app/lib/screens/report_timeline_screen.dart', rtsCode);
  console.log('Fixed report_timeline_screen.dart');
}
