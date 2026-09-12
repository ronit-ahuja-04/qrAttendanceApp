import re

filepath = '/Users/ronitahuja/Downloads/qrAttendanceApp/app/lib/screens/student_dashboard_screen.dart'
with open(filepath, 'r') as f:
    content = f.read()

# Fix Overall card
# color: Colors.white, inside decoration of Overall card
# Let's target the exact string:
content = content.replace(
    "color: Colors.white,\n                                  borderRadius: BorderRadius.circular(16),\n                                  boxShadow: [",
    "color: context.colors.surfaceContainer,\n                                  borderRadius: BorderRadius.circular(16),\n                                  boxShadow: ["
)

content = content.replace(
    "Text('Overall', style: context.textStyles.vesitBodyMd.copyWith(color: Colors.grey.shade600, fontWeight: FontWeight.bold)),",
    "Text('Overall', style: context.textStyles.vesitBodyMd.copyWith(color: context.colors.onSurfaceVariant, fontWeight: FontWeight.bold)),"
)

content = content.replace(
    "backgroundColor: Colors.grey.shade100,",
    "backgroundColor: context.colors.surfaceContainerHighest,"
)

# Fix Lecture/Lab toggle
content = content.replace(
    "color: Colors.grey.shade200,\n            borderRadius: BorderRadius.circular(20),",
    "color: context.colors.surfaceContainerHighest,\n            borderRadius: BorderRadius.circular(20),"
)

content = content.replace(
    "color: _selectedType == 'Lecture' ? Colors.white : Colors.grey.shade600",
    "color: _selectedType == 'Lecture' ? context.colors.onPrimaryContainer : context.colors.onSurfaceVariant"
)

content = content.replace(
    "color: _selectedType == 'Lab' ? Colors.white : Colors.grey.shade600",
    "color: _selectedType == 'Lab' ? context.colors.onPrimaryContainer : context.colors.onSurfaceVariant"
)

with open(filepath, 'w') as f:
    f.write(content)
print("Updated student_dashboard_screen.dart")
