import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/tactile_widgets.dart';
import '../widgets/vesit_widgets.dart';
import 'session_calendar_screen.dart';
import 'student_dashboard_screen.dart';
import '../ams/globals.dart';
import 'dart:async';
import '../ams/notification_service.dart';
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
  const _DayGroup(
      {required this.label, required this.entries, this.dim = false});

  final String label;
  final List<_AttendanceEntry> entries;
  final bool dim;
}

/// Attendance History — mirrors the "Attendance History - VESIT System"
/// Stitch export (code.html): active-session banner, today/attended/missed
/// stat wells, today's class log, and a day-grouped history list below.
class AttendanceHistoryScreen extends StatefulWidget {
  final ScrollController? scrollController;
  const AttendanceHistoryScreen({super.key, this.scrollController});

  @override
  State<AttendanceHistoryScreen> createState() =>
      _AttendanceHistoryScreenState();
}

class _AttendanceHistoryScreenState extends State<AttendanceHistoryScreen> {
  List<_AttendanceEntry> _today = [];
  List<_DayGroup> _earlierThisWeek = [];
  bool _loading = true;
  int _totalCount = 0;
  int _attendedCount = 0;
  int _missedCount = 0;

  StreamSubscription? _notificationSub;

  @override
  void initState() {
    super.initState();
    _loadHistory();
    _notificationSub = NotificationService().events.listen((event) {
      if (['TIMETABLE_UPDATED', 'ATTENDANCE_UPDATED'].contains(event['type'])) {
        _loadHistory();
      }
    });
  }

  @override
  void dispose() {
    _notificationSub?.cancel();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    final studentId = AmsGlobals.loggedInUser?.id;
    if (studentId == null) {
      setState(() => _loading = false);
      return;
    }

    final history =
        await AmsGlobals.sessionService.getStudentAttendanceHistory(studentId);

    final today = DateTime.now();
    final todayStr =
        "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";

    final List<_AttendanceEntry> todayEntries = [];
    final Map<String, List<_AttendanceEntry>> groupMap = {};

    for (var h in history) {
      final dateIso = h['date'] as String;
      final dt = DateTime.parse(dateIso).toLocal();
      final dtStr =
          "${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}";

      final entry = _AttendanceEntry(
        subject: h['subject'] ?? 'Unknown',
        time: h['time'] ?? '--',
        location: h['location'] ?? 'Campus',
        status: h['status'] == 'present'
            ? _AttendanceStatus.present
            : _AttendanceStatus.missed,
        professor: h['professor'] ?? 'Unknown Faculty',
        compact: dtStr != todayStr, // compact for earlier days
      );

      if (dtStr == todayStr) {
        todayEntries.add(entry);
      } else {
        final Map<int, String> months = {
          1: 'Jan',
          2: 'Feb',
          3: 'Mar',
          4: 'Apr',
          5: 'May',
          6: 'Jun',
          7: 'Jul',
          8: 'Aug',
          9: 'Sep',
          10: 'Oct',
          11: 'Nov',
          12: 'Dec'
        };
        final isYesterday = DateTime(today.year, today.month, today.day)
                .difference(DateTime(dt.year, dt.month, dt.day))
                .inDays ==
            1;
        final label = isYesterday
            ? 'Yesterday, ${months[dt.month]} ${dt.day}'
            : '${months[dt.month]} ${dt.day}';

        groupMap.putIfAbsent(label, () => []).add(entry);
      }
    }

    final List<_DayGroup> earlier = [];
    bool dimFlag = false;

    // Sort groupMap keys (dates) descending to pick top 5
    // But our keys are "Yesterday, Oct 23" which is hard to sort.
    // Actually the history is already sorted DESC from backend!
    int count = 0;
    groupMap.forEach((label, entries) {
      if (count < 5) {
        earlier.add(_DayGroup(label: label, entries: entries, dim: dimFlag));
        dimFlag = !dimFlag;
        count++;
      }
    });

    int attended = 0;
    int missed = 0;
    for (var h in history) {
      if (h['status'] == 'present')
        attended++;
      else
        missed++;
    }

    if (mounted) {
      setState(() {
        _today = todayEntries;
        _earlierThisWeek = earlier;
        _totalCount = history.length;
        _attendedCount = attended;
        _missedCount = missed;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.vesitGray,
      body: SafeArea(
        child: Stack(
          children: [
            if (_loading)
              const Center(child: CircularProgressIndicator())
            else
              Column(
                children: [
                  const _Header(),
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: _loadHistory,
                      color: context.colors.vesitPrimary,
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        controller: widget.scrollController,
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 130),
                        children: [
                        _DateBanner(),
                        const SizedBox(height: 12),
                        _StatsRow(
                            total: _totalCount,
                            attended: _attendedCount,
                            missed: _missedCount),
                        const SizedBox(height: 24),
                        const _SectionDivider(title: "Today's Log"),
                        const SizedBox(height: 10),
                        if (_today.isEmpty)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Text('No log yet!',
                                style: TextStyle(color: Colors.grey.shade500)),
                          )
                        else
                          ..._today.map(
                            (e) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _AttendanceCard(entry: e),
                            ),
                          ),
                        const SizedBox(height: 12),
                        const _SectionDivider(title: 'Earlier This Week'),
                        const SizedBox(height: 10),
                        if (_earlierThisWeek.isEmpty)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Text('-',
                                style: TextStyle(
                                    color: Colors.grey.shade500, fontSize: 24)),
                          )
                        else
                          ..._earlierThisWeek.map(
                            (day) => Padding(
                              padding: const EdgeInsets.only(bottom: 14),
                              child: Opacity(
                                opacity: day.dim ? 0.8 : 1,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.only(
                                          left: 4, bottom: 6),
                                      child: Text(day.label,
                                          style: context.textStyles.labelMd
                                              .copyWith(fontSize: 13)),
                                    ),
                                    ...day.entries.map(
                                      (e) => Padding(
                                        padding:
                                            const EdgeInsets.only(bottom: 8),
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
                ),
              ],
              ),
            
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: context.colors.vesitWhite,
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2))
        ],
      ),
      child: Center(
        child: Text(
          'Attendance History',
          textAlign: TextAlign.center,
          style: context.textStyles.vesitHeadlineSm
              .copyWith(color: context.colors.vesitPrimary),
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}

class _DateBanner extends StatelessWidget {
  const _DateBanner();

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final Map<int, String> days = {
      1: 'Monday',
      2: 'Tuesday',
      3: 'Wednesday',
      4: 'Thursday',
      5: 'Friday',
      6: 'Saturday',
      7: 'Sunday'
    };
    final Map<int, String> months = {
      1: 'Jan',
      2: 'Feb',
      3: 'Mar',
      4: 'Apr',
      5: 'May',
      6: 'Jun',
      7: 'Jul',
      8: 'Aug',
      9: 'Sep',
      10: 'Oct',
      11: 'Nov',
      12: 'Dec'
    };

    return VesitCard(
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
                  'TODAY\'S DATE',
                  style: context.textStyles.vesitLabelBold.copyWith(
                      letterSpacing: 1.2, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 2),
                Text(
                    '${days[now.weekday]}, ${months[now.month]} ${now.day} ${now.year}',
                    style: context.textStyles.vesitHeadlineSm),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow(
      {required this.total, required this.attended, required this.missed});
  final int total;
  final int attended;
  final int missed;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
            child: _StatWell(
                label: 'Total',
                value: '$total',
                valueColor: context.colors.vesitTextHeading)),
        const SizedBox(width: 8),
        Expanded(
            child: _StatWell(
                label: 'Attended',
                value: '$attended',
                valueColor: context.colors.vesitPrimary)),
        const SizedBox(width: 8),
        Expanded(
            child: _StatWell(
                label: 'Missed', value: '$missed', valueColor: Colors.red)),
      ],
    );
  }
}

class _StatWell extends StatelessWidget {
  const _StatWell(
      {required this.label, required this.value, required this.valueColor});

  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.colors.vesitWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      child: Column(
        children: [
          Text(label,
              style: context.textStyles.vesitLabelSm
                  .copyWith(color: Colors.grey.shade600)),
          const SizedBox(height: 4),
          Text(
            value,
            style: context.textStyles.vesitLabelBold
                .copyWith(fontSize: 16, color: valueColor),
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
          style: context.textStyles.vesitLabelBold
              .copyWith(color: Colors.grey.shade600, letterSpacing: 1.2),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Container(height: 1, color: Colors.grey.shade300),
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
    final badgeBg =
        present ? const Color(0xFFE8F5E9) : Colors.red.withOpacity(0.12);
    final badgeFg = present ? const Color(0xFF2E7D32) : Colors.red;

    return VesitCard(
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
                    color: context.colors.vesitTextHeading,
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
                      style: context.textStyles.vesitLabelBold
                          .copyWith(fontSize: 11, color: badgeFg),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(Icons.schedule, size: 14, color: Colors.grey.shade500),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  entry.time,
                  style: context.textStyles.vesitBodyMd
                      .copyWith(fontSize: 12, color: Colors.grey.shade600),
                ),
              ),
            ],
          ),
          if (entry.professor != null) ...[
            const SizedBox(height: 2),
            Text(
              entry.professor!,
              style: context.textStyles.vesitLabelSm.copyWith(
                  fontWeight: FontWeight.w600, color: Colors.grey.shade600),
            ),
          ],
        ],
      ),
    );
  }
}
