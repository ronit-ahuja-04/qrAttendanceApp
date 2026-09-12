import re

filepath = 'lib/screens/faculty_attendance_qr_generator_screen.dart'
with open(filepath, 'r') as f:
    content = f.read()

# Fix empty state text color
content = content.replace(
    "style: context.textStyles.labelSm),",
    "style: context.textStyles.labelSm.copyWith(color: context.colors.onSurfaceVariant)),"
)

# Fix white shadow
content = content.replace(
    "BoxShadow(color: Colors.white, offset: Offset(0, 1)),",
    ""
)

# Also let's fix the big red button at the bottom of Image 3.
# The button says "CLOSE SESSION & LOCK". It's probably an ElevatedButton or a VesitButton.
# Let's see if we can find it.
# We'll just leave the button as is for now, red is probably intended for destructive actions.
# Wait, let's grep for "CLOSE SESSION & LOCK" to be sure.

with open(filepath, 'w') as f:
    f.write(content)
