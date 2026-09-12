import os

files = [
    '../app/lib/screens/generate_report_screen.dart',
    '../app/lib/screens/report_timeline_screen.dart'
]

for file in files:
    with open(file, 'r') as f:
        content = f.read()
    
    if "import 'package:shared_preferences/shared_preferences.dart';" not in content:
        content = "import 'package:shared_preferences/shared_preferences.dart';\nimport 'dart:convert';\n" + content
        with open(file, 'w') as f:
            f.write(content)
        print(f"Fixed {file}")

