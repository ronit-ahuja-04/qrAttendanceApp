import re

filepath = 'lib/screens/notifications_screen.dart'
with open(filepath, 'r') as f:
    content = f.read()

# Instead of doing that, let's just make the fallback look good.
content = content.replace("context.colors.primaryContainer, // Fallback", "context.colors.surfaceContainerHighest,")
content = content.replace("context.colors.onPrimaryContainer,", "context.colors.onSurface,")

with open(filepath, 'w') as f:
    f.write(content)
