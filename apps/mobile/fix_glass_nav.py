import re

filepath = '/Users/ronitahuja/Downloads/qrAttendanceApp/app/lib/widgets/glass_bottom_nav.dart'
with open(filepath, 'r') as f:
    content = f.read()

content = content.replace("          ),\n        ),\n      ),\n    );\n  }\n}", "          ),\n        ),\n      ),\n    );\n  }\n}")
# That didn't work. Let's just append ')' to the line before the last '  }'
content = content.replace("    );\n  }\n}", "      ),\n    );\n  }\n}")

with open(filepath, 'w') as f:
    f.write(content)
