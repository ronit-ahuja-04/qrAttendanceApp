import 'package:flutter/material.dart';
import '../ams/globals.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/tactile_widgets.dart';
import '../widgets/vesit_widgets.dart';
import 'student_dashboard_screen.dart';

class StudentTimetableScreen extends StatefulWidget {
  final ScrollController? scrollController;
  const StudentTimetableScreen({super.key, this.scrollController});

  @override
  State<StudentTimetableScreen> createState() => _StudentTimetableScreenState();
}

class _StudentTimetableScreenState extends State<StudentTimetableScreen> {
  bool _loading = true;
  List<Map<String, dynamic>> _slots = [];
  final List<String> _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

  @override
  void initState() {
    super.initState();
    _fetchTimetable();
  }

  Future<void> _fetchTimetable() async {
    final userId = AmsGlobals.loggedInUser?.id;
    if (userId == null) return;
    
    final slots = await AmsGlobals.sessionService.getStudentTimetableFull(userId);
    if (mounted) {
      setState(() {
        _slots = slots;
        _sortSlots();
        _loading = false;
      });
    }
  }

  void _sortSlots() {
    _slots.sort((a, b) {
      final aStart = a['startTime'] as String? ?? '00:00';
      final bStart = b['startTime'] as String? ?? '00:00';
      return aStart.compareTo(bStart);
    });
  }

  String _formatTimeString(String t) {
    if (t.isEmpty) return 'N/A';
    final parts = t.split(':');
    if (parts.length < 2) return t;
    int hour = int.tryParse(parts[0]) ?? 0;
    final min = parts[1];
    final ampm = hour >= 12 ? 'PM' : 'AM';
    if (hour == 0) hour = 12;
    if (hour > 12) hour -= 12;
    return '$hour:$min $ampm';
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: _days.length,
      child: Scaffold(
        backgroundColor: context.colors.vesitGray,
        appBar: AppBar(
          backgroundColor: context.colors.vesitWhite,
          elevation: 0,
          centerTitle: true,
          automaticallyImplyLeading: false,
          title: Text('My Timetable', style: context.textStyles.vesitHeadlineSm.copyWith(color: context.colors.vesitPrimary)),
          bottom: TabBar(
            isScrollable: true,
            labelColor: context.colors.vesitPrimary,
            unselectedLabelColor: Colors.grey.shade500,
            indicatorColor: context.colors.vesitPrimary,
            indicatorWeight: 3,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
            tabs: _days.map((day) => Tab(text: day)).toList(),
          ),
        ),
        body: Stack(
          children: [
            if (_loading)
              const Center(child: CircularProgressIndicator())
            else
              TabBarView(
                children: _days.map((day) {
                  final daySlots = _slots.where((s) => s['day'] == day).toList();
                  if (daySlots.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.weekend_outlined, size: 64, color: Colors.grey.shade400),
                          const SizedBox(height: 16),
                          Text('No classes on $day.', style: context.textStyles.vesitBodyLg.copyWith(color: Colors.grey.shade600)),
                        ],
                      ),
                    );
                  }
                  return ListView.builder(
                    controller: widget.scrollController,
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 130), // padding for bottom nav
                    itemCount: daySlots.length,
                    itemBuilder: (context, index) {
                      final slot = daySlots[index];
                      return _StudentSlotCard(
                        slot: slot,
                        formattedStart: _formatTimeString(slot['startTime'] as String? ?? 'N/A'),
                        formattedEnd: _formatTimeString(slot['endTime'] as String? ?? 'N/A'),
                      );
                    },
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }
}

class _StudentSlotCard extends StatelessWidget {
  final Map<String, dynamic> slot;
  final String formattedStart;
  final String formattedEnd;

  const _StudentSlotCard({
    required this.slot,
    required this.formattedStart,
    required this.formattedEnd,
  });

  @override
  Widget build(BuildContext context) {
    final type = slot['type'] as String? ?? 'Lecture';
    final subject = slot['subject'] as String? ?? 'Unknown Subject';
    final venue = slot['venue'] as String? ?? 'Unknown Venue';
    final rawFacultyName = slot['facultyName'] as String? ?? 'Unknown Faculty';
    final facultyName = AmsGlobals.formatFacultyName(rawFacultyName);
    final isLab = type.toLowerCase() == 'lab';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: VesitCard(
        padding: EdgeInsets.zero,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              border: Border(left: BorderSide(color: isLab ? context.colors.vesitOrange : context.colors.vesitPrimary, width: 6)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(formattedStart, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 4),
                      Text(formattedEnd, style: TextStyle(color: Colors.grey.shade700, fontSize: 13, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(width: 16),
                  Container(width: 1, height: 40, color: Colors.grey.shade200),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          subject,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.person, size: 14, color: Colors.grey.shade600),
                            const SizedBox(width: 4),
                            Expanded(child: Text(facultyName, style: TextStyle(color: Colors.grey.shade700, fontSize: 13), overflow: TextOverflow.ellipsis)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.location_on, size: 14, color: Colors.grey.shade500),
                            const SizedBox(width: 4),
                            Text(venue, style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                            const SizedBox(width: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(color: isLab ? context.colors.vesitOrange.withOpacity(0.15) : context.colors.vesitPrimary.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                              child: Text(type, style: TextStyle(fontSize: 11, color: isLab ? context.colors.vesitOrange : context.colors.vesitPrimary, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
