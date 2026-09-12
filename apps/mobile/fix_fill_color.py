import re

filepath = 'lib/screens/global_configure_session_screen.dart'
with open(filepath, 'r') as f:
    content = f.read()

content = content.replace("fillColor: Colors.white,", "fillColor: context.colors.surfaceContainerHighest,")

with open(filepath, 'w') as f:
    f.write(content)

