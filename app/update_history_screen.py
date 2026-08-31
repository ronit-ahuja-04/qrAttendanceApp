import re

with open('lib/screens/attendance_history_screen.dart', 'r') as f:
    content = f.read()

# Replace the class definition and constants with a StatefulWidget
old_class_start = 'class AttendanceHistoryScreen extends StatelessWidget {'
new_class = '''import '../ams/globals.dart';

class AttendanceHistoryScreen extends StatefulWidget {
  const AttendanceHistoryScreen({super.key});

  @override
  State<AttendanceHistoryScreen> createState() => _AttendanceHistoryScreenState();
}

class _AttendanceHistoryScreenState extends State<AttendanceHistoryScreen> {
  List<_AttendanceEntry> _today = [];
  List<_DayGroup> _earlierThisWeek = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final studentId = AmsGlobals.loggedInUser?.id;
    if (studentId == null) {
      setState(() => _loading = false);
      return;
    }

    final history = await AmsGlobals.sessionService.getStudentAttendanceHistory(studentId);
    
    final today = DateTime.now();
    final todayStr = "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";
    
    final List<_AttendanceEntry> todayEntries = [];
    final Map<String, List<_AttendanceEntry>> groupMap = {};

    for (var h in history) {
      final dateIso = h['date'] as String;
      final dt = DateTime.parse(dateIso).toLocal();
      final dtStr = "${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}";
      
      final entry = _AttendanceEntry(
        subject: h['subject'] ?? 'Unknown',
        time: h['time'] ?? '--',
        location: h['location'] ?? 'Campus',
        status: h['status'] == 'present' ? _AttendanceStatus.present : _AttendanceStatus.missed,
        professor: h['professor'] ?? 'Unknown Faculty',
        compact: dtStr != todayStr, // compact for earlier days
      );

      if (dtStr == todayStr) {
        todayEntries.add(entry);
      } else {
        final Map<int, String> months = {1:'Jan',2:'Feb',3:'Mar',4:'Apr',5:'May',6:'Jun',7:'Jul',8:'Aug',9:'Sep',10:'Oct',11:'Nov',12:'Dec'};
        final isYesterday = DateTime(today.year, today.month, today.day).difference(DateTime(dt.year, dt.month, dt.day)).inDays == 1;
        final label = isYesterday ? 'Yesterday, ${months[dt.month]} ${dt.day}' : '${months[dt.month]} ${dt.day}';
        
        groupMap.putIfAbsent(label, () => []).add(entry);
      }
    }

    final List<_DayGroup> earlier = [];
    bool dimFlag = false;
    groupMap.forEach((label, entries) {
      earlier.add(_DayGroup(label: label, entries: entries, dim: dimFlag));
      dimFlag = !dimFlag; // alternate dimming for older days
    });

    if (mounted) {
      setState(() {
        _today = todayEntries;
        _earlierThisWeek = earlier;
        _loading = false;
      });
    }
  }

  void _openCalendarFilter(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SessionCalendarScreen()),
    );
  }

  void _switchSession(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SessionCalendarScreen()),
    );
  }
'''

content = content.replace(old_class_start, new_class)

# Remove the old static const _today and _earlierThisWeek and the old methods
old_methods_start = '''  static const _today = ['''
old_methods_end = '''  @override
  Widget build(BuildContext context) {'''

# We need a regex to remove everything from 'static const _today =' up to '@override Widget build'
content = re.sub(r'static const _today = \[.*?\s+void _switchSession\(BuildContext context\).*?}\n\n  @override\n  Widget build\(BuildContext context\) \{', 
                 '  @override\n  Widget build(BuildContext context) {', 
                 content, flags=re.DOTALL)

# Add a loading indicator in the build method
build_start = '''  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.vesitGray,
      body: SafeArea(
        child: Stack(
          children: ['''

new_build_start = '''  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.vesitGray,
      body: SafeArea(
        child: Stack(
          children: [
            if (_loading) const Center(child: CircularProgressIndicator()) else'''

content = content.replace(build_start, new_build_start)

# Add the 'if (_today.isEmpty) Text("No classes today")' gracefully? 
# I will just leave it as is, it maps empty arrays fine.

with open('lib/screens/attendance_history_screen.dart', 'w') as f:
    f.write(content)
