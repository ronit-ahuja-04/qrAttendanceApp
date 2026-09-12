import re

filepath = '/Users/ronitahuja/Downloads/qrAttendanceApp/app/lib/screens/student_main_layout.dart'
with open(filepath, 'r') as f:
    content = f.read()

# Add imports for AttendanceHistoryScreen and StudentTimetableScreen
if 'attendance_history_screen.dart' not in content:
    content = content.replace(
        "import 'attendance_statistics_screen.dart';",
        "import 'attendance_statistics_screen.dart';\nimport 'attendance_history_screen.dart';\nimport 'student_timetable_screen.dart';"
    )

# Update screens list
old_screens = """  final List<Widget> _screens = [
    const StudentDashboardScreen(),
    const QrScannerScreen(),
    AttendanceStatisticsScreen(),
    const StudentProfileScreen(),
  ];"""
new_screens = """  final List<Widget> _screens = [
    const StudentDashboardScreen(),
    const AttendanceHistoryScreen(),
    const StudentTimetableScreen(),
    AttendanceStatisticsScreen(),
    const StudentProfileScreen(),
  ];"""
content = content.replace(old_screens, new_screens)

# Update nav items
old_items = """                items: [
                  GlassNavItem(icon: Icons.home_rounded, label: 'Home'),
                  GlassNavItem(icon: Icons.qr_code_scanner_rounded, label: 'Scan'),
                  GlassNavItem(icon: Icons.bar_chart_rounded, label: 'Stats'),
                  GlassNavItem(icon: Icons.person_rounded, label: 'Profile'),
                ],"""
new_items = """                items: [
                  GlassNavItem(icon: Icons.home_rounded, label: 'Home'),
                  GlassNavItem(icon: Icons.history_rounded, label: 'History'),
                  GlassNavItem(icon: Icons.calendar_today_rounded, label: 'Timetable'),
                  GlassNavItem(icon: Icons.bar_chart_rounded, label: 'Stats'),
                  GlassNavItem(icon: Icons.person_rounded, label: 'Profile'),
                ],"""
content = content.replace(old_items, new_items)

with open(filepath, 'w') as f:
    f.write(content)

