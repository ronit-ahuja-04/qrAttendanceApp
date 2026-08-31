import re
import os

# 1. Fix tactile_widgets.dart
filepath = 'lib/widgets/tactile_widgets.dart'
with open(filepath, 'r') as f:
    content = f.read()

# Replace hardcoded Colors.white shadows with a transparent or dark alternative
content = content.replace(
    "const BoxShadow(color: Colors.white, offset: Offset(0, -1)),",
    ""
)
content = content.replace(
    "BoxShadow(color: Colors.white, offset: Offset(0, 1)),",
    ""
)

with open(filepath, 'w') as f:
    f.write(content)

# 2. Fix report_timeline_screen.dart
filepath = 'lib/screens/report_timeline_screen.dart'
with open(filepath, 'r') as f:
    content = f.read()

content = content.replace(
    "BoxShadow(color: Colors.white, offset: Offset(0, 1)),",
    ""
)
with open(filepath, 'w') as f:
    f.write(content)

# 3. Fix notifications_screen.dart onSurface shadow
filepath = 'lib/screens/notifications_screen.dart'
with open(filepath, 'r') as f:
    content = f.read()

content = content.replace(
    "color: context.colors.onSurface.withOpacity(0.04),",
    "color: Colors.black.withOpacity(0.15),"
)

with open(filepath, 'w') as f:
    f.write(content)

print("Fixed white shadows.")
