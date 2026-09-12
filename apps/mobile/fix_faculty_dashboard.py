import re

# Fix FACULTY DASHBOARD to DASHBOARD
filepath = '/Users/ronitahuja/Downloads/qrAttendanceApp/app/lib/screens/faculty_dashboard_screen.dart'
with open(filepath, 'r') as f:
    content = f.read()

content = content.replace("Text('FACULTY DASHBOARD',", "Text('DASHBOARD',")

with open(filepath, 'w') as f:
    f.write(content)

# Fix Proxy Setup overflow
filepath = '/Users/ronitahuja/Downloads/qrAttendanceApp/app/lib/screens/global_configure_session_screen.dart'
with open(filepath, 'r') as f:
    content = f.read()

content = content.replace(
    "DropdownButtonFormField<String>(",
    "DropdownButtonFormField<String>(\n        isExpanded: true,"
)
content = content.replace(
    ".map((e) => DropdownMenuItem(value: e, child: Text(e)))",
    ".map((e) => DropdownMenuItem(value: e, child: Text(e, overflow: TextOverflow.ellipsis)))"
)

with open(filepath, 'w') as f:
    f.write(content)

print("Updates completed.")
