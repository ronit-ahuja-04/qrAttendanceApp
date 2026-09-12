import re

# Fix student_dashboard_screen.dart (Line 405 missing parenthesis)
with open('lib/screens/student_dashboard_screen.dart', 'r') as f:
    student_code = f.read()
student_code = student_code.replace("""                Text(
                  studentName,
                  style: context.textStyles.vesitHeadlineSm.copyWith(fontSize: 20),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
          ),""", """                Text(
                  studentName,
                  style: context.textStyles.vesitHeadlineSm.copyWith(fontSize: 20),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),""")
with open('lib/screens/student_dashboard_screen.dart', 'w') as f:
    f.write(student_code)


# Fix faculty_dashboard_screen.dart (Line 315 missing parenthesis)
with open('lib/screens/faculty_dashboard_screen.dart', 'r') as f:
    faculty_code = f.read()
faculty_code = faculty_code.replace("""                        _RecentSessionsList(isLoading: _isLoading, sessions: _allSessions, onRefresh: _loadTimetable),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),""", """                        _RecentSessionsList(isLoading: _isLoading, sessions: _allSessions, onRefresh: _loadTimetable),
                      ],
                    ),
                  ),
                ],
              ),
             ),
            );
          },
        ),""")
with open('lib/screens/faculty_dashboard_screen.dart', 'w') as f:
    f.write(faculty_code)

# Fix api_services.dart
with open('lib/ams/api_services.dart', 'r') as f:
    api_code = f.read()

# Fix 1: Move imports to top
imports = """import 'models.dart';
import 'notification_service.dart';
import 'globals.dart';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:image_picker/image_picker.dart';
"""
api_code = api_code.replace(imports, "")
api_code = api_code.replace("import 'package:shared_preferences/shared_preferences.dart';", "import 'package:shared_preferences/shared_preferences.dart';\n" + imports)

# Fix 2: Result.failure(null, ...) -> Result.failure(RejectionReason.sessionNotFound, ...)
api_code = api_code.replace("Result.failure(null, 'Failed to connect to server", "Result.failure(RejectionReason.sessionNotFound, 'Failed to connect to server")

with open('lib/ams/api_services.dart', 'w') as f:
    f.write(api_code)

# Fix models.dart (baseUrl undefined)
with open('lib/ams/models.dart', 'r') as f:
    models_code = f.read()

models_code = models_code.replace("pfp = '$baseUrl$pfp';", "pfp = 'https://qr-attendance-api-wvvs.onrender.com$pfp';")

with open('lib/ams/models.dart', 'w') as f:
    f.write(models_code)

print("Errors fixed.")
