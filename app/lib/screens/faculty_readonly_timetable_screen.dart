import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../ams/globals.dart';
import '../ams/api_services.dart';

String _formatTimeString(String timeStr) {
  if (timeStr == 'N/A' || timeStr.isEmpty) return timeStr;
  try {
    final parts = timeStr.trim().split(':');
    int h = int.parse(parts[0]);
    final m = parts[1].split(' ')[0];
    final amPm = h >= 12 ? 'PM' : 'AM';
    if (h > 12) h -= 12;
    if (h == 0) h = 12;
    return '$h:$m $amPm';
  } catch (e) {
    return timeStr;
  }
}

class FacultyReadonlyTimetableScreen extends StatefulWidget {
  const FacultyReadonlyTimetableScreen({super.key});

  @override
  State<FacultyReadonlyTimetableScreen> createState() => _FacultyReadonlyTimetableScreenState();
}

class _FacultyReadonlyTimetableScreenState extends State<FacultyReadonlyTimetableScreen> {
  final List<String> _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  bool _isLoading = true;
  List<Map<String, dynamic>> _slots = [];

  @override
  void initState() {
    super.initState();
    _loadTimetable();
  }

  Future<void> _loadTimetable() async {
    final user = AmsGlobals.loggedInUser;
    if (user != null) {
      try {
        final slots = await ApiSessionService().getTimetable(user.id);
        if (mounted) {
          setState(() {
            _slots = slots;
            _isLoading = false;
          });
        }
      } catch (e) {
        if (mounted) setState(() => _isLoading = false);
      }
    } else {
      if (mounted) setState(() => _isLoading = false);
    }
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
        body: _isLoading 
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
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
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
              itemCount: daySlots.length,
              itemBuilder: (context, index) {
                final slot = daySlots[index];
                return _ReadonlySlotCard(
                  slot: slot,
                  formattedStart: _formatTimeString(slot['startTime'] as String? ?? 'N/A'),
                  formattedEnd: _formatTimeString(slot['endTime'] as String? ?? 'N/A'),
                );
              },
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _ReadonlySlotCard extends StatelessWidget {
  const _ReadonlySlotCard({required this.slot, required this.formattedStart, required this.formattedEnd});
  final Map<String, dynamic> slot;
  final String formattedStart;
  final String formattedEnd;

  @override
  Widget build(BuildContext context) {
    final bool isLab = slot['type'] == 'Lab';
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: context.colors.vesitWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              slot['subject'],
              style: context.textStyles.vesitHeadlineSm.copyWith(color: context.colors.vesitTextHeading, fontSize: 18),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.access_time, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 8),
                Text('$formattedStart  —  $formattedEnd', style: context.textStyles.vesitBodyMd.copyWith(color: Colors.grey.shade600)),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                _Badge(label: slot['venue'], icon: Icons.room, color: context.colors.vesitPrimary),
                _Badge(label: slot['batchTarget'] ?? 'N/A', icon: Icons.people, color: AmsGlobals.getBatchColor(slot['batchTarget'] ?? '')),
                _Badge(
                  label: slot['type'], 
                  icon: isLab ? Icons.science : (slot['type'] == 'Tutorial' ? Icons.menu_book : Icons.book), 
                  color: isLab ? context.colors.vesitOrange : (slot['type'] == 'Tutorial' ? Colors.purple : context.colors.vesitGreen),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.icon, required this.color});
  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}
