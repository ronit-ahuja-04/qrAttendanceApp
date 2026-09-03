import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/tactile_widgets.dart';
import '../widgets/vesit_widgets.dart';
import 'qr_scanner_screen.dart';
import 'student_profile_screen.dart';
import 'notifications_screen.dart';
import '../ams/globals.dart';
import '../ams/notification_service.dart';
import '../ams/api_services.dart';

class StudentDashboardScreen extends StatefulWidget {
  const StudentDashboardScreen({super.key, this.onProfileTap, this.scrollController});
  final VoidCallback? onProfileTap;
  final ScrollController? scrollController;

  @override
  State<StudentDashboardScreen> createState() => _StudentDashboardScreenState();
}

class _StudentDashboardScreenState extends State<StudentDashboardScreen>
    with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  double _overallPercentage = 0.0;
  List<dynamic> _subjectsStats = [];
  List<Map<String, dynamic>> _rawSessions = [];

  StreamSubscription? _eventSub;
  late AnimationController _animController;
  Timer? _timer;
  DateTime _now = DateTime.now();

  List<Map<String, dynamic>> get _formattedUpcomingSessions {
    final now = _now;
    final nowEpoch = now.millisecondsSinceEpoch;
    final dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final todayIndex = now.weekday - 1;
    final sessions = <Map<String, dynamic>>[];

    for (var session in _rawSessions) {
      final slotDayStr = session['day'] as String?;
      if (slotDayStr == null) continue;
      final slotDayIndex = dayNames.indexOf(slotDayStr);
      if (slotDayIndex < 0) continue;

      bool isToday = slotDayIndex == todayIndex;
      bool isYesterday = (todayIndex == 0 && slotDayIndex == 6) ||
          (slotDayIndex == todayIndex - 1);

      if (!isToday && !isYesterday) continue;

      final subject = session['subject'] ?? '';
      final rawFacultyName = session['facultyName'] ?? '';
      final facultyName = AmsGlobals.formatFacultyName(rawFacultyName);
      final venue = session['venue'] ?? '';
      final startTime = session['startTime'] ?? '';
      final endTime = session['endTime'] ?? '';

      String format12Hour(String timeStr) {
        if (timeStr.isEmpty || timeStr == 'N/A') return timeStr;
        try {
          final cleanT = timeStr.replaceAll(RegExp(r'\s?[aApP][mM]'), '').trim();
          final parts = cleanT.split(':');
          int h = int.parse(parts[0]);
          final m = parts[1];
          final amPm = h >= 12 ? 'PM' : 'AM';
          if (h > 12) h -= 12;
          if (h == 0) h = 12;
          return '$h:$m $amPm';
        } catch (_) {
          return timeStr;
        }
      }

      int parseToEpoch(String timeStr, bool isYesterdaySlot) {
        try {
          final isPM = timeStr.toUpperCase().contains('PM');
          final isAM = timeStr.toUpperCase().contains('AM');
          final cleanT = timeStr.replaceAll(RegExp(r'\s?[aApP][mM]'), '').trim();
          
          final parts = cleanT.split(':');
          if (parts.length >= 2) {
            int hour = int.parse(parts[0]);
            final min = int.parse(parts[1]);
            
            if (isPM && hour < 12) hour += 12;
            if (isAM && hour == 12) hour = 0;
            
            var dt = DateTime(now.year, now.month, now.day, hour, min);
            if (isYesterdaySlot) dt = dt.subtract(const Duration(days: 1));
            return dt.millisecondsSinceEpoch;
          }
        } catch (_) {}
        return nowEpoch;
      }

      int sEpoch = parseToEpoch(startTime, isYesterday);
      int eEpoch = parseToEpoch(endTime, isYesterday);
      if (eEpoch < sEpoch) eEpoch += 24 * 60 * 60 * 1000;

      if (eEpoch > nowEpoch) {
        sessions.add({
          'time': '${format12Hour(startTime)} - ${format12Hour(endTime)}',
          'subject': subject,
          'detail': '$facultyName • $venue',
          'start_epoch': sEpoch,
          'end_epoch': eEpoch,
          'original_session': session,
        });
      }
    }
    sessions.sort((a, b) =>
        (a['start_epoch'] as int).compareTo(b['start_epoch'] as int));
    return sessions;
  }

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200));
    _animController.forward();
    _timer = Timer.periodic(
        const Duration(seconds: 1), (_) { if (mounted) setState(() => _now = DateTime.now()); });
    _fetchData();
    _eventSub = NotificationService().events.listen((event) {
      if (['N003', 'N005', 'N007', 'TIMETABLE_UPDATED', 'ATTENDANCE_UPDATED']
          .contains(event['type'])) {
        _fetchData();
      }
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    _timer?.cancel();
    _eventSub?.cancel();
    super.dispose();
  }

  Future<void> _fetchData() async {
    if (mounted) setState(() => _isLoading = true);
    await Future.wait([_fetchStats(), _fetchTimetable()]);
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _fetchStats() async {
    final userId = AmsGlobals.loggedInUser?.id;
    if (userId != null) {
      final stats = await AmsGlobals.attendanceService.getStudentStats(userId);
      if (mounted) {
        setState(() {
          _overallPercentage = stats['overallPercentage'] ?? 0.0;
          _subjectsStats = stats['subjects'] ?? [];
        });
      }
    }
  }

  Future<void> _fetchTimetable() async {
    final user = AmsGlobals.loggedInUser;
    if (user != null) {
      final now = DateTime.now();
      final dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      final dayStr = dayNames[now.weekday - 1];
      final slots =
          await AmsGlobals.sessionService.getStudentTimetableToday(user.id, dayStr);
      if (mounted) setState(() => _rawSessions = slots);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.vesitGray,
      body: SafeArea(
        child: Column(
          children: [
            _Header(
              now: _now,
              studentName: AmsGlobals.loggedInUser?.formattedName ?? 'Student',
              onNotificationsTap: () => Navigator.of(context)
                  .push(MaterialPageRoute(builder: (_) => const NotificationsScreen())),
              onAvatarTap: widget.onProfileTap ?? () => Navigator.of(context)
                  .push(MaterialPageRoute(builder: (_) => const StudentProfileScreen())),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _fetchData,
                color: context.colors.vesitPrimary,
                child: ListView(
                  controller: widget.scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 130),
                  children: [
                    _StaggeredFade(
                      animation: _animController,
                      index: 0,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_isLoading)
                            const VesitSkeleton(height: 180)
                          else
                            _SubjectHealthDeck(subjects: _subjectsStats),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    _StaggeredFade(
                      animation: _animController,
                      index: 1,
                      child: Row(
                        children: [
                          Expanded(
                            child: _ActionHub(
                              title: 'Mark\nAttendance',
                              icon: Icons.qr_code_scanner_rounded,
                              highlighted: true,
                              onTap: () => Navigator.of(context).push(
                                  MaterialPageRoute(builder: (_) => const QrScannerScreen())),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _OverallCard(percentage: _overallPercentage, isLoading: _isLoading),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    _StaggeredFade(
                      animation: _animController,
                      index: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _SectionHeader(icon: Icons.schedule_rounded, title: 'NEXT UP'),
                          if (_isLoading)
                            const VesitSkeleton(height: 140)
                          else if (_formattedUpcomingSessions.isNotEmpty)
                            _LiveCountdownCard(
                                now: _now,
                                session: _formattedUpcomingSessions.first)
                          else
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              child: Text(
                                'No upcoming sessions today',
                                style: context.textStyles.vesitBodyMd
                                    .copyWith(color: context.colors.onSurfaceVariant),
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (!_isLoading && _formattedUpcomingSessions.length > 1) ...[
                      const SizedBox(height: 24),
                      _StaggeredFade(
                        animation: _animController,
                        index: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _SectionHeader(icon: Icons.calendar_today_rounded, title: 'LATER TODAY'),
                            ..._formattedUpcomingSessions.skip(1).map(
                                  (s) => Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: _SessionTile(session: s),
                                  ),
                                ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Header ──────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header({
    required this.now,
    required this.studentName,
    required this.onNotificationsTap,
    required this.onAvatarTap,
  });

  final DateTime now;
  final String studentName;
  final VoidCallback onNotificationsTap;
  final VoidCallback onAvatarTap;

  String _getGreeting() {
    final h = now.hour;
    if (h < 12) return 'Good Morning,';
    if (h < 17) return 'Good Afternoon,';
    return 'Good Evening,';
  }

  IconData _getGreetingIcon() {
    final h = now.hour;
    if (h < 12) return Icons.wb_sunny_rounded;
    if (h < 17) return Icons.cloud_outlined;
    return Icons.nights_stay_rounded;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: context.colors.surface,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 10,
              offset: const Offset(0, 2))
        ],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: onAvatarTap,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    context.colors.vesitPrimary,
                    context.colors.vesitPrimary.withValues(alpha: 0.7)
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                      color: context.colors.vesitPrimary.withValues(alpha: 0.4),
                      blurRadius: 10,
                      offset: const Offset(0, 4))
                ],
              ),
              child: AmsGlobals.loggedInUser?.profilePictureUrl != null &&
                      AmsGlobals.loggedInUser!.profilePictureUrl!.isNotEmpty
                  ? ClipOval(
                      child: Image.network(
                        AmsGlobals.loggedInUser!.profilePictureUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            const Icon(Icons.person, color: Colors.white),
                      ),
                    )
                  : const Icon(Icons.person, color: Colors.white),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(_getGreetingIcon(), size: 14, color: context.colors.vesitGold),
                    const SizedBox(width: 4),
                    Text(
                      _getGreeting(),
                      style: context.textStyles.vesitBodySm
                          .copyWith(color: context.colors.onSurfaceVariant, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  studentName,
                  style: context.textStyles.vesitHeadlineSm.copyWith(fontSize: 20),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: onNotificationsTap,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: context.colors.outlineVariant, width: 1.5),
              ),
              child: Icon(Icons.notifications_outlined,
                  color: context.colors.onSurface, size: 22),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Section Header ───────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.icon});
  final String title;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18, color: context.colors.onSurfaceVariant),
            const SizedBox(width: 8),
          ],
          Text(
            title,
            style: context.textStyles.vesitLabelBold.copyWith(
                color: context.colors.onSurfaceVariant, letterSpacing: 1.4),
          ),
        ],
      ),
    );
  }
}

// ─── Staggered Fade ──────────────────────────────────────────────────────────

class _StaggeredFade extends StatelessWidget {
  const _StaggeredFade(
      {required this.animation, required this.index, required this.child});
  final AnimationController animation;
  final int index;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final start = (index * 0.12).clamp(0.0, 0.8);
    final end = (start + 0.4).clamp(0.0, 1.0);
    final curve = CurvedAnimation(
        parent: animation,
        curve: Interval(start, end, curve: Curves.easeOut));
    return FadeTransition(
      opacity: curve,
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)
            .animate(curve),
        child: child,
      ),
    );
  }
}

// ─── Subject Health Deck (Stacked Apple-Pay Cards) ───────────────────────────

class _SubjectHealthDeck extends StatefulWidget {
  final List<dynamic> subjects;
  const _SubjectHealthDeck({required this.subjects});

  @override
  State<_SubjectHealthDeck> createState() => _SubjectHealthDeckState();
}

class _SubjectHealthDeckState extends State<_SubjectHealthDeck> {
  String _selectedType = 'Lecture';
  bool _isExpanded = false;

  static const double _cardHeight = 140.0;
  static const double _collapsedSpacing = 14.0;
  static const double _expandedSpacing = 152.0;

  Color _getCardColor(BuildContext context, dynamic s) {
    final status = s['status'] as String? ?? '';
    if (status == 'CRITICAL') return context.colors.vesitRed;
    if (status == 'WARNING') return Colors.orange.shade800;
    if (status == 'SAFE') return context.colors.vesitGreen;
    // fallback: calculate from percentage
    final pct = (s['percentage'] as num?)?.toDouble() ?? 0;
    if (pct < 50) return context.colors.vesitRed;
    if (pct < 75) return Colors.orange.shade800;
    return context.colors.vesitGreen;
  }

  bool _isLab(dynamic s) {
    final code = (s['courseCode'] as String? ?? '').toLowerCase();
    return code.contains('lab');
  }

  String _getSafeMargin(dynamic s) {
    final pct = (s['percentage'] as num?)?.toDouble() ?? 
                (s['overallPercentage'] as num?)?.toDouble() ?? 0;
    final attended = (s['attendedSessions'] as num?)?.toInt() ?? 
                     (s['attendedClasses'] as num?)?.toInt() ?? 0;
    final total = (s['totalSessions'] as num?)?.toInt() ?? 
                  (s['totalClasses'] as num?)?.toInt() ?? 0;
    if (pct >= 75 && total > 0) {
      final canMiss = ((attended - total * 0.75) / 0.75).floor();
      if (canMiss > 0) return 'Safe Margin: Can miss $canMiss classes';
    }
    if (total > 0) {
      final needed = ((total * 0.75 - attended) / (1 - 0.75)).ceil();
      if (needed > 0) return 'Need $needed more to reach 75%';
    }
    return 'Attendance on track';
  }

  @override
  Widget build(BuildContext context) {
    final filtered = widget.subjects
        .where((s) => _isLab(s) ? _selectedType == 'Lab' : _selectedType == 'Lecture')
        .toList();

    if (widget.subjects.isEmpty) {
      return Container(
        height: 140,
        decoration: BoxDecoration(
          color: context.colors.surfaceContainer,
          borderRadius: BorderRadius.circular(20),
        ),
        alignment: Alignment.center,
        child: Text('No subjects found',
            style: context.textStyles.vesitBodyMd
                .copyWith(color: context.colors.onSurfaceVariant)),
      );
    }

    final n = filtered.length;
    final totalHeight = filtered.isEmpty
        ? _cardHeight
        : _isExpanded
            ? _cardHeight + (n - 1) * _expandedSpacing
            : _cardHeight + (n - 1) * _collapsedSpacing;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Lecture / Lab toggle
        Container(
          height: 38,
          decoration: BoxDecoration(
            color: context.colors.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Stack(
            children: [
              AnimatedAlign(
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeOutCubic,
                alignment: _selectedType == 'Lecture'
                    ? Alignment.centerLeft
                    : Alignment.centerRight,
                child: FractionallySizedBox(
                  widthFactor: 0.5,
                  child: Container(
                    margin: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: context.colors.vesitPrimary,
                      borderRadius: BorderRadius.circular(17),
                      boxShadow: [
                        BoxShadow(
                            color: context.colors.vesitPrimary
                                .withValues(alpha: 0.35),
                            blurRadius: 6,
                            offset: const Offset(0, 2))
                      ],
                    ),
                  ),
                ),
              ),
              Row(
                children: ['Lecture', 'Lab'].map((type) {
                  final selected = _selectedType == type;
                  return Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => setState(
                          () { _selectedType = type; _isExpanded = false; }),
                      child: Center(
                        child: Text(type,
                            style: context.textStyles.vesitLabelBold.copyWith(
                                color: selected
                                    ? Colors.white
                                    : context.colors.onSurfaceVariant,
                                fontSize: 13)),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        // Stacked cards
        if (filtered.isEmpty)
          Container(
            height: 100,
            decoration: BoxDecoration(
              color: context.colors.surfaceContainer,
              borderRadius: BorderRadius.circular(20),
            ),
            alignment: Alignment.center,
            child: Text('No $_selectedType subjects',
                style: context.textStyles.vesitBodyMd
                    .copyWith(color: context.colors.onSurfaceVariant)),
          )
        else
          GestureDetector(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            onHorizontalDragEnd: (d) {
              final v = d.primaryVelocity ?? 0;
              if (v.abs() < 300) return;
              if (v < 0 && _selectedType == 'Lecture') {
                setState(() { _selectedType = 'Lab'; _isExpanded = false; });
              } else if (v > 0 && _selectedType == 'Lab') {
                setState(() { _selectedType = 'Lecture'; _isExpanded = false; });
              }
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 350),
              curve: Curves.fastOutSlowIn,
              height: totalHeight,
              child: Stack(
                clipBehavior: Clip.none,
                children: List.generate(filtered.length, (index) {
                  final s = filtered[index];
                  final cardColor = _getCardColor(context, s);
                  final topPos = _isExpanded
                      ? index * _expandedSpacing
                      : index * _collapsedSpacing;

                  return AnimatedPositioned(
                    duration: const Duration(milliseconds: 350),
                    curve: Curves.fastOutSlowIn,
                    top: topPos,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: _cardHeight,
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 14,
                              offset: const Offset(0, -4))
                        ],
                      ),
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  (s['courseCode'] ?? '')
                                      .replaceAll(' - Lab', '')
                                      .replaceAll(' - Lecture', ''),
                                  style: context.textStyles.vesitHeadlineSm
                                      .copyWith(
                                          color: Colors.white,
                                          fontSize: 18,
                                          height: 1.15),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${(s['overallPercentage'] ?? s['percentage'] ?? 0).toStringAsFixed(1)}%',
                                style: context.textStyles.vesitHeadlineSm
                                    .copyWith(
                                        color: Colors.white, fontSize: 28),
                              ),
                            ],
                          ),
                          const Spacer(),
                          Text(
                            '${s['attendedClasses'] ?? s['attendedSessions'] ?? 0}/${s['totalClasses'] ?? s['totalSessions'] ?? 0} Attended',
                            style: context.textStyles.vesitBodyMd
                                .copyWith(color: Colors.white70),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _getSafeMargin(s),
                            style: context.textStyles.vesitLabelBold.copyWith(
                                color: Colors.white, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
      ],
    );
  }
}

// ─── Action Hub (Mark Attendance button with blue border) ────────────────────

class _ActionHub extends StatefulWidget {
  const _ActionHub({
    required this.title,
    required this.icon,
    required this.onTap,
    this.highlighted = false,
  });
  final String title;
  final IconData icon;
  final VoidCallback onTap;
  final bool highlighted;

  @override
  State<_ActionHub> createState() => _ActionHubState();
}

class _ActionHubState extends State<_ActionHub> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) { setState(() => _pressed = false); widget.onTap(); },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: Container(
          height: 140,
          decoration: BoxDecoration(
            color: context.colors.surfaceContainer,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: widget.highlighted
                  ? context.colors.vesitPrimary
                  : context.colors.outlineVariant,
              width: widget.highlighted ? 1.8 : 1.0,
            ),
            boxShadow: widget.highlighted
                ? [
                    BoxShadow(
                        color: context.colors.vesitPrimary.withValues(alpha: 0.15),
                        blurRadius: 16,
                        offset: const Offset(0, 4))
                  ]
                : [],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.highlighted
                      ? context.colors.vesitPrimary.withValues(alpha: 0.12)
                      : context.colors.surfaceContainerHighest,
                ),
                child: Icon(
                  widget.icon,
                  size: 28,
                  color: widget.highlighted
                      ? context.colors.vesitPrimary
                      : context.colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                widget.title,
                textAlign: TextAlign.center,
                style: context.textStyles.vesitLabelBold.copyWith(
                  color: widget.highlighted
                      ? context.colors.vesitPrimary
                      : context.colors.onSurface,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Overall Circular Card ────────────────────────────────────────────────────

class _OverallCard extends StatelessWidget {
  const _OverallCard({required this.percentage, required this.isLoading});
  final double percentage;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 140,
      decoration: BoxDecoration(
        color: context.colors.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.colors.outlineVariant),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Overall',
            style: context.textStyles.vesitBodyMd
                .copyWith(color: context.colors.onSurfaceVariant),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: 80,
            height: 80,
            child: isLoading
                ? const CircularProgressIndicator(strokeWidth: 6)
                : TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0, end: percentage),
                    duration: const Duration(milliseconds: 1200),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, _) {
                      final color = context.colors.getAttendanceColor(value);
                      return Stack(
                        fit: StackFit.expand,
                        children: [
                          CircularProgressIndicator(
                            value: 1.0,
                            strokeWidth: 7,
                            color: context.colors.surfaceContainerHighest,
                          ),
                          CircularProgressIndicator(
                            value: value / 100,
                            strokeWidth: 7,
                            backgroundColor: Colors.transparent,
                            color: color,
                            strokeCap: StrokeCap.round,
                          ),
                          Center(
                            child: Text(
                              '${value.toInt()}%',
                              style: context.textStyles.vesitHeadlineSm
                                  .copyWith(color: color, fontSize: 18),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// ─── Live Countdown Card ─────────────────────────────────────────────────────

class _LiveCountdownCard extends StatelessWidget {
  const _LiveCountdownCard({required this.now, required this.session});
  final DateTime now;
  final Map<String, dynamic> session;

  String _getCountdown() {
    final sE = session['start_epoch'];
    final eE = session['end_epoch'];
    if (sE == null || eE == null) return 'Starting soon';
    final start = DateTime.fromMillisecondsSinceEpoch(sE as int);
    final end = DateTime.fromMillisecondsSinceEpoch(eE as int);
    if (now.isAfter(end)) return 'Completed';
    if (now.isAfter(start)) return 'Running now';
    final diff = start.difference(now);
    if (diff.inHours > 0) return 'In ${diff.inHours}h ${diff.inMinutes % 60}m';
    return 'In ${diff.inMinutes} mins';
  }

  bool get _isRunning {
    final sE = session['start_epoch'];
    final eE = session['end_epoch'];
    if (sE == null || eE == null) return false;
    final start = DateTime.fromMillisecondsSinceEpoch(sE as int);
    final end = DateTime.fromMillisecondsSinceEpoch(eE as int);
    return now.isAfter(start) && now.isBefore(end);
  }

  @override
  Widget build(BuildContext context) {
    final running = _isRunning;
    final accentColor =
        running ? context.colors.vesitGreen : context.colors.vesitGold;
    return Container(
      decoration: BoxDecoration(
        color: context.colors.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accentColor.withValues(alpha: 0.5), width: 1.5),
        boxShadow: [
          BoxShadow(
              color: accentColor.withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, 4))
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              PilotLight(active: true, size: 10),
              const SizedBox(width: 8),
              Text(
                running ? 'RUNNING NOW' : 'STARTING SOON',
                style: context.textStyles.vesitLabelBold
                    .copyWith(color: accentColor, letterSpacing: 1.2),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(session['subject'] as String,
              style: context.textStyles.vesitHeadlineSm
                  .copyWith(color: context.colors.onSurface, fontSize: 18)),
          const SizedBox(height: 4),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (session['type'] != null)
                _InfoPill(
                  icon: Icons.class_outlined,
                  text: session['type'],
                  color: session['type'] == 'Lab' ? context.colors.vesitOrange : context.colors.vesitPrimary,
                  bgColor: (session['type'] == 'Lab' ? context.colors.vesitOrange : context.colors.vesitPrimary).withValues(alpha: 0.15),
                ),
              if (session['original_session']['facultyName'] != null)
                _InfoPill(
                  icon: Icons.person_outline,
                  text: session['original_session']['facultyName'],
                  color: context.colors.secondary,
                  bgColor: context.colors.secondaryContainer,
                ),
              if (session['original_session']['venue'] != null)
                _InfoPill(
                  icon: Icons.room_outlined,
                  text: session['original_session']['venue'],
                  color: context.colors.vesitGreen,
                  bgColor: context.colors.vesitGreen.withValues(alpha: 0.15),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Icon(Icons.timer_outlined, size: 16, color: context.colors.vesitPrimary),
              const SizedBox(width: 6),
              Text(
                _getCountdown(),
                style: context.textStyles.vesitLabelBold
                    .copyWith(color: context.colors.vesitPrimary, fontSize: 15),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                    color: context.colors.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(999)),
                child: Text(session['time'] as String,
                    style: context.textStyles.vesitLabelBold
                        .copyWith(color: context.colors.onSurfaceVariant, fontSize: 12)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Session Tile (Later Today) ───────────────────────────────────────────────

class _SessionTile extends StatelessWidget {
  const _SessionTile({required this.session});
  final Map<String, dynamic> session;

  @override
  Widget build(BuildContext context) {
    final parts = (session['time'] as String).split(' - ');
    final startDisplay = parts.isNotEmpty ? parts[0] : session['time'];
    return Container(
      decoration: BoxDecoration(
        color: context.colors.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.colors.outlineVariant.withValues(alpha: 0.6)),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: context.colors.vesitPrimary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              startDisplay,
              style: context.textStyles.vesitLabelBold
                  .copyWith(color: context.colors.vesitPrimary, fontSize: 12),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(session['subject'] as String,
                    style: context.textStyles.vesitHeadlineSm
                        .copyWith(color: context.colors.onSurface, fontSize: 15)),
                const SizedBox(height: 3),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    if (session['type'] != null)
                      _InfoPill(
                        icon: Icons.class_outlined,
                        text: session['type'],
                        color: session['type'] == 'Lab' ? context.colors.vesitOrange : context.colors.vesitPrimary,
                        bgColor: (session['type'] == 'Lab' ? context.colors.vesitOrange : context.colors.vesitPrimary).withValues(alpha: 0.15),
                      ),
                    if (session['original_session']['facultyName'] != null)
                      _InfoPill(
                        icon: Icons.person_outline,
                        text: session['original_session']['facultyName'],
                        color: context.colors.secondary,
                        bgColor: context.colors.secondaryContainer,
                      ),
                    if (session['original_session']['venue'] != null)
                      _InfoPill(
                        icon: Icons.room_outlined,
                        text: session['original_session']['venue'],
                        color: context.colors.vesitGreen,
                        bgColor: context.colors.vesitGreen.withValues(alpha: 0.15),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({
    required this.icon,
    required this.text,
    required this.color,
    required this.bgColor,
  });

  final IconData icon;
  final String text;
  final Color color;
  final Color bgColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(text, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}
