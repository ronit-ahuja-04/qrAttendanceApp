import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/tactile_widgets.dart';
import '../widgets/vesit_widgets.dart';

enum _MarkStatus { present, missed }

class _DaySession {
  const _DaySession({
    required this.time,
    required this.subject,
    required this.detail,
    required this.status,
    this.note,
  });

  final String time;
  final String subject;
  final String detail;
  final _MarkStatus status;
  final String? note;
}

/// Session Calendar — mirrors the "Attendance Calendar & Session History"
/// Stitch export (code.html): a monthly grid with per-day attendance dots
/// and a session log for whichever day is selected.
class SessionCalendarScreen extends StatefulWidget {
  const SessionCalendarScreen({super.key});

  @override
  State<SessionCalendarScreen> createState() => _SessionCalendarScreenState();
}

class _SessionCalendarScreenState extends State<SessionCalendarScreen> {
  static const _monthLabel = 'Oct 2026';

  // day -> dots shown under that date (max 2, oldest first).
  static const Map<int, List<_MarkStatus>> _dots = {
    1: [_MarkStatus.present, _MarkStatus.present],
    2: [_MarkStatus.present],
    6: [_MarkStatus.missed],
    7: [_MarkStatus.present, _MarkStatus.present],
    8: [_MarkStatus.present],
    9: [_MarkStatus.present],
    13: [_MarkStatus.present, _MarkStatus.present],
    14: [_MarkStatus.present, _MarkStatus.missed],
    15: [_MarkStatus.present],
    16: [_MarkStatus.present],
    20: [_MarkStatus.present, _MarkStatus.present],
    21: [_MarkStatus.present],
    22: [_MarkStatus.present, _MarkStatus.present],
    23: [_MarkStatus.present],
    24: [_MarkStatus.present, _MarkStatus.missed],
  };

  static const Map<int, List<_DaySession>> _sessions = {
    24: [
      _DaySession(
        time: '09:00 - 10:30 AM',
        subject: 'Java Programming (CS-302)',
        detail: 'Dr. Julian Sterling • Lab 402',
        status: _MarkStatus.present,
        note: 'Verified via OTP @ 09:12 AM',
      ),
      _DaySession(
        time: '11:00 - 12:30 PM',
        subject: 'Database Systems (CS-301)',
        detail: 'Prof. Sarah Jenkins • Room 201',
        status: _MarkStatus.missed,
        note: 'No attendance record submitted',
      ),
    ],
    14: [
      _DaySession(
        time: '01:30 - 03:00 PM',
        subject: 'Digital Logic (CS-210)',
        detail: 'Dr. K. Iyer • Lab 405',
        status: _MarkStatus.present,
        note: 'Verified via OTP @ 01:34 PM',
      ),
      _DaySession(
        time: '03:15 - 04:45 PM',
        subject: 'Computer Networks (CS-304)',
        detail: 'Prof. S. Mehta • Room 501',
        status: _MarkStatus.missed,
        note: 'No attendance record submitted',
      ),
    ],
  };

  int _selectedDay = 24;

  List<_DaySession> get _selectedSessions => _sessions[_selectedDay] ?? [];

  void _openMonthPicker() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Month picker — coming soon'), duration: Duration(seconds: 1)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.vesitGray,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                _Header(
                  monthLabel: _monthLabel,
                  onBack: () => Navigator.of(context).maybePop(),
                  onMonthTap: _openMonthPicker,
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                    children: [
                      _CalendarCard(
                        dots: _dots,
                        selectedDay: _selectedDay,
                        onDaySelected: (d) => setState(() => _selectedDay = d),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'SESSIONS FOR OCT $_selectedDay, 2026',
                        style: context.textStyles.vesitHeadlineSm.copyWith(fontSize: 18),
                      ),
                      const SizedBox(height: 10),
                      if (_selectedSessions.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          child: Text(
                            'No sessions recorded for this day.',
                            style: context.textStyles.vesitBodyMd.copyWith(color: Colors.grey.shade600),
                          ),
                        )
                      else
                        ..._selectedSessions.map(
                          (s) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _SessionCard(session: s),
                          ),
                        ),
                    ],
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
  const _Header({required this.monthLabel, required this.onBack, required this.onMonthTap});

  final String monthLabel;
  final VoidCallback onBack;
  final VoidCallback onMonthTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: context.colors.vesitWhite,
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2))],
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: Icon(Icons.arrow_back, color: Colors.grey.shade600, size: 24),
          ),
          Expanded(
            child: Text(
              'Session Calendar',
              textAlign: TextAlign.center,
              style: context.textStyles.vesitHeadlineSm.copyWith(color: context.colors.vesitPrimary),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          InkWell(
            onTap: onMonthTap,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(monthLabel, style: context.textStyles.vesitLabelBold.copyWith(color: context.colors.vesitPrimary)),
                  const SizedBox(width: 2),
                  Icon(Icons.expand_more, size: 18, color: context.colors.vesitPrimary),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CalendarCard extends StatelessWidget {
  const _CalendarCard({
    required this.dots,
    required this.selectedDay,
    required this.onDaySelected,
  });

  final Map<int, List<_MarkStatus>> dots;
  final int selectedDay;
  final ValueChanged<int> onDaySelected;

  // October 2026 starts on a Thursday, has 31 days.
  static const _leadingBlanks = 4;
  static const _daysInMonth = 31;

  @override
  Widget build(BuildContext context) {
    final cells = <Widget>[
      for (var i = 0; i < _leadingBlanks; i++) const SizedBox.shrink(),
      for (var day = 1; day <= _daysInMonth; day++)
        _DayCell(
          day: day,
          dots: dots[day] ?? [],
          selected: day == selectedDay,
          onTap: () => onDaySelected(day),
        ),
    ];

    return VesitCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const Row(
            children: [
              Expanded(child: _WeekdayLabel('S')),
              Expanded(child: _WeekdayLabel('M')),
              Expanded(child: _WeekdayLabel('T')),
              Expanded(child: _WeekdayLabel('W')),
              Expanded(child: _WeekdayLabel('T')),
              Expanded(child: _WeekdayLabel('F')),
              Expanded(child: _WeekdayLabel('S')),
            ],
          ),
          const SizedBox(height: 8),
          GridView.count(
            crossAxisCount: 7,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 4,
            crossAxisSpacing: 2,
            childAspectRatio: 0.85,
            children: cells,
          ),
        ],
      ),
    );
  }
}

class _WeekdayLabel extends StatelessWidget {
  const _WeekdayLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      textAlign: TextAlign.center,
      style: context.textStyles.vesitLabelBold.copyWith(color: Colors.grey.shade500),
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.dots,
    required this.selected,
    required this.onTap,
  });

  final int day;
  final List<_MarkStatus> dots;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: selected ? context.colors.vesitPrimary : Colors.transparent,
          boxShadow: selected
              ? [
                  BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 4, offset: const Offset(0, 2)),
                ]
              : null,
        ),
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$day',
              style: TextStyle(
                fontFamily: 'FamiljenGrotesk',
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : context.colors.vesitTextHeading,
              ),
            ),
            if (dots.isNotEmpty) ...[
              const SizedBox(height: 2),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final d in dots.take(2))
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 1),
                      child: Container(
                        width: 5,
                        height: 5,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: d == _MarkStatus.present ? Colors.green : Colors.red,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SessionCard extends StatelessWidget {
  const _SessionCard({required this.session});

  final _DaySession session;

  @override
  Widget build(BuildContext context) {
    final present = session.status == _MarkStatus.present;

    return VesitCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(session.time, style: context.textStyles.vesitLabelBold.copyWith(color: Colors.grey.shade500)),
                const SizedBox(height: 4),
                Text(
                  session.subject,
                  style: context.textStyles.vesitBodyLg.copyWith(color: context.colors.vesitTextHeading, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 2),
                Text(session.detail, style: context.textStyles.vesitBodyMd.copyWith(color: Colors.grey.shade600)),
                if (session.note != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    session.note!,
                    style: context.textStyles.vesitLabelSm.copyWith(color: present ? Colors.green : Colors.red),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            decoration: BoxDecoration(
              color: present ? const Color(0xFFE8F5E9) : Colors.red.withOpacity(0.12),
              borderRadius: BorderRadius.circular(999),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: present ? Colors.green : Colors.red,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  present ? 'PRESENT' : 'MISSED',
                  style: context.textStyles.vesitLabelBold.copyWith(fontSize: 11, color: present ? Colors.green : Colors.red),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
