import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/tactile_widgets.dart';
import 'session_calendar_screen.dart';
import 'student_dashboard_screen.dart';

enum _AttendanceStatus { present, missed }

class _AttendanceEntry {
  const _AttendanceEntry({
    required this.subject,
    required this.time,
    required this.location,
    required this.status,
    this.professor,
    this.compact = false,
  });

  final String subject;
  final String time;
  final String location;
  final _AttendanceStatus status;
  final String? professor;
  final bool compact;
}

class _DayGroup {
  const _DayGroup({required this.label, required this.entries, this.dim = false});

  final String label;
  final List<_AttendanceEntry> entries;
  final bool dim;
}

/// Attendance History — mirrors the "Attendance History - VESIT System"
/// Stitch export (code.html): active-session banner, today/attended/missed
/// stat wells, today's class log, and a day-grouped history list below.
class AttendanceHistoryScreen extends StatelessWidget {
  const AttendanceHistoryScreen({super.key});

  static const _today = [
    _AttendanceEntry(
      subject: 'Java Programming',
      time: '09:00 - 10:30 | Lab 402',
      location: 'Lab 402',
      status: _AttendanceStatus.present,
      professor: 'Prof. R. Deshmukh',
    ),
    _AttendanceEntry(
      subject: 'Computer Networks',
      time: '11:00 - 12:30 | Room 501',
      location: 'Room 501',
      status: _AttendanceStatus.missed,
      professor: 'Prof. S. Mehta',
    ),
    _AttendanceEntry(
      subject: 'Digital Logic',
      time: '01:30 - 03:00 | Lab 405',
      location: 'Lab 405',
      status: _AttendanceStatus.present,
      professor: 'Dr. K. Iyer',
    ),
  ];

  static const _earlierThisWeek = [
    _DayGroup(
      label: 'Yesterday, Oct 23',
      entries: [
        _AttendanceEntry(
          subject: 'Data Structures',
          time: '09:00 - 11:00 | Hall A',
          location: 'Hall A',
          status: _AttendanceStatus.present,
          compact: true,
        ),
      ],
    ),
    _DayGroup(
      label: 'Oct 22',
      dim: true,
      entries: [
        _AttendanceEntry(
          subject: 'Cyber Ethics',
          time: '02:00 - 04:00 | Seminar Hall',
          location: 'Seminar Hall',
          status: _AttendanceStatus.present,
          compact: true,
        ),
      ],
    ),
  ];

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.wall,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                _Header(
                  onBack: () {
                    if (Navigator.of(context).canPop()) {
                      Navigator.of(context).pop();
                    } else {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (_) => const StudentDashboardScreen()),
                      );
                    }
                  },
                  onFilterTap: () => _openCalendarFilter(context),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                    children: [
                      _ActiveSessionBanner(onSwap: () => _switchSession(context)),
                      const SizedBox(height: 12),
                      const _StatsRow(),
                      const SizedBox(height: 24),
                      const _SectionDivider(title: "Today's Log"),
                      const SizedBox(height: 10),
                      ..._today.map(
                        (e) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _AttendanceCard(entry: e),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const _SectionDivider(title: 'Earlier This Week'),
                      const SizedBox(height: 10),
                      ..._earlierThisWeek.map(
                        (day) => Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: Opacity(
                            opacity: day.dim ? 0.8 : 1,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(left: 4, bottom: 6),
                                  child: Text(day.label, style: AppTextStyles.labelMd.copyWith(fontSize: 13)),
                                ),
                                ...day.entries.map(
                                  (e) => Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: _AttendanceCard(entry: e),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Align(
              alignment: Alignment.bottomCenter,
              child: TactileBottomNav(currentIndex: 1),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onBack, required this.onFilterTap});

  final VoidCallback onBack;
  final VoidCallback onFilterTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2))],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: onBack,
            child: const Icon(Icons.arrow_back, color: AppColors.onSurface, size: 24),
          ),
          Expanded(
            child: Text(
              'Attendance History',
              textAlign: TextAlign.center,
              style: AppTextStyles.headlineSm,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          GestureDetector(
            onTap: onFilterTap,
            child: const Icon(Icons.calendar_month, color: AppColors.primary, size: 24),
          ),
        ],
      ),
    );
  }
}

class _ActiveSessionBanner extends StatelessWidget {
  const _ActiveSessionBanner({required this.onSwap});

  final VoidCallback onSwap;

  @override
  Widget build(BuildContext context) {
    return RaisedPanel(
      borderRadius: 16,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          const PilotLight(active: true, size: 8),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ACTIVE SESSION',
                  style: AppTextStyles.labelBold.copyWith(letterSpacing: 1.2),
                ),
                const SizedBox(height: 2),
                const Text('Today, Oct 24', style: AppTextStyles.headlineSm),
              ],
            ),
          ),
          PushSurfaceButton(
            onPressed: onSwap,
            borderRadius: 10,
            child: const Padding(
              padding: EdgeInsets.all(10),
              child: Icon(Icons.swap_horiz, color: AppColors.primary, size: 22),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(child: _StatWell(label: 'Total', value: '4 Classes', valueColor: AppColors.onSurface)),
        SizedBox(width: 8),
        Expanded(child: _StatWell(label: 'Attended', value: '3', valueColor: AppColors.primary)),
        SizedBox(width: 8),
        Expanded(child: _StatWell(label: 'Missed', value: '1', valueColor: AppColors.error)),
      ],
    );
  }
}

class _StatWell extends StatelessWidget {
  const _StatWell({required this.label, required this.value, required this.valueColor});

  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return DebossedWell(
      borderRadius: 12,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      child: Column(
        children: [
          Text(label, style: AppTextStyles.labelSm),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTextStyles.labelBold.copyWith(fontSize: 16, color: valueColor),
          ),
        ],
      ),
    );
  }
}

class _SectionDivider extends StatelessWidget {
  const _SectionDivider({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title.toUpperCase(),
          style: AppTextStyles.labelBold.copyWith(color: AppColors.onSurfaceVariant, letterSpacing: 1.2),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Container(height: 1, color: AppColors.outlineVariant.withOpacity(0.3)),
        ),
      ],
    );
  }
}

class _AttendanceCard extends StatelessWidget {
  const _AttendanceCard({required this.entry});

  final _AttendanceEntry entry;

  @override
  Widget build(BuildContext context) {
    final present = entry.status == _AttendanceStatus.present;
    final badgeBg = present ? const Color(0xFFE8F5E9) : AppColors.error.withOpacity(0.12);
    final badgeFg = present ? const Color(0xFF2E7D32) : AppColors.error;

    return RaisedPanel(
      borderRadius: 16,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  entry.subject,
                  style: TextStyle(
                    fontFamily: 'Karla',
                    fontWeight: FontWeight.bold,
                    fontSize: entry.compact ? 15 : 16,
                    color: AppColors.onSurface,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      present ? Icons.check_circle : Icons.cancel,
                      size: 13,
                      color: badgeFg,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      present ? 'PRESENT' : 'MISSED',
                      style: AppTextStyles.labelBold.copyWith(fontSize: 11, color: badgeFg),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.schedule, size: 14, color: AppColors.secondary),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  entry.time,
                  style: AppTextStyles.labelMd.copyWith(fontSize: 12),
                ),
              ),
            ],
          ),
          if (entry.professor != null) ...[
            const SizedBox(height: 2),
            Text(
              entry.professor!,
              style: AppTextStyles.labelSm.copyWith(fontWeight: FontWeight.w600),
            ),
          ],
        ],
      ),
    );
  }
}
