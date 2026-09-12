import os
import re

lib_dir = '/Users/ronitahuja/Downloads/qrAttendanceApp/app/lib/screens'

files = [
    'student_dashboard_screen.dart',
    'student_profile_screen.dart',
    'attendance_history_screen.dart',
    'account_settings_screen.dart',
    'session_calendar_screen.dart',
    'student_timetable_screen.dart',
]

for filename in files:
    filepath = os.path.join(lib_dir, filename)
    if not os.path.exists(filepath):
        continue
    
    with open(filepath, 'r') as f:
        content = f.read()
    
    # Regex to find:
    # const Align(
    #   alignment: Alignment.bottomCenter,
    #   child: TactileBottomNav(currentIndex: X),
    # ),
    # or variations.
    
    new_content = re.sub(
        r'const\s+Align\(\s*alignment:\s*Alignment\.bottomCenter,\s*child:\s*TactileBottomNav\(currentIndex:\s*\d+\)(?:\s*//.*?)?,\s*\),?',
        '',
        content,
        flags=re.DOTALL
    )
    
    if new_content != content:
        with open(filepath, 'w') as f:
            f.write(new_content)
        print(f"Removed TactileBottomNav from {filename}")
    else:
        # Maybe it's missing 'const'
        new_content2 = re.sub(
            r'Align\(\s*alignment:\s*Alignment\.bottomCenter,\s*child:\s*TactileBottomNav\(currentIndex:\s*\d+\)(?:\s*//.*?)?,\s*\),?',
            '',
            content,
            flags=re.DOTALL
        )
        if new_content2 != content:
            with open(filepath, 'w') as f:
                f.write(new_content2)
            print(f"Removed TactileBottomNav (no const) from {filename}")
        else:
            print(f"Could not find exact block in {filename}")

