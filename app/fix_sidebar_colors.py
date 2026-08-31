import re

filepath = '/Users/ronitahuja/Downloads/qrAttendanceApp/app/lib/screens/faculty_dashboard_screen.dart'
with open(filepath, 'r') as f:
    content = f.read()

# Replace hardcoded grey colors with dark-theme friendly variants
content = content.replace("Colors.grey.shade600", "context.colors.onSurfaceVariant")
content = content.replace("Colors.grey.shade700", "context.colors.onSurfaceVariant")
content = content.replace("Colors.grey.shade100", "context.colors.surfaceContainerHighest")
content = content.replace("Colors.grey.shade200", "context.colors.surfaceContainerHighest")

# Note: Colors.red.shade600 -> context.colors.error
content = content.replace("Colors.red.shade600", "context.colors.error")

with open(filepath, 'w') as f:
    f.write(content)
print("Updated sidebar colors.")
