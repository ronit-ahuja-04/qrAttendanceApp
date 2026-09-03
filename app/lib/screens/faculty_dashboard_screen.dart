import 'dart:async';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/services.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../ams/api_services.dart';
import '../ams/models.dart';
import 'package:intl/intl.dart';
import '../ams/notification_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../utils/subject_icons.dart';
import '../widgets/vesit_widgets.dart';
import 'configure_session_screen.dart';
import 'global_configure_session_screen.dart';
import 'faculty_profile_screen.dart';
import 'notifications_screen.dart';
import 'report_filters_screen.dart';
import '../ams/globals.dart';
import 'faculty_attendance_qr_generator_screen.dart';
import 'proxy_approvals_screen.dart';
import 'generate_report_screen.dart';

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

String _getGreeting() {
  final istTime =
      DateTime.now().toUtc().add(const Duration(hours: 5, minutes: 30));
  final hour = istTime.hour;
  if (hour < 12) {
    return 'Good Morning';
  } else if (hour < 17) {
    return 'Good Afternoon';
  } else {
    return 'Good Evening';
  }
}

class FacultyDashboardScreen extends StatefulWidget {
  const FacultyDashboardScreen({super.key, this.onProfileTap, this.scrollController});
  final VoidCallback? onProfileTap;
  final ScrollController? scrollController;

  @override
  State<FacultyDashboardScreen> createState() => _FacultyDashboardScreenState();
}

class _FacultyDashboardScreenState extends State<FacultyDashboardScreen> {
  bool _isLoading = true;
  StreamSubscription? _eventSub;
  List<AttendanceSession> _pendingSessions = [];
  List<AttendanceSession> _allSessions = [];
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadTimetable();
    _eventSub = NotificationService().events.listen((event) {
      if (event['type'] == 'TIMETABLE_UPDATED') {
        _loadTimetable();
      }
    });
    _refreshTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
    AmsGlobals.refreshNotifier.addListener(_onGlobalRefresh);
  }

  void _onGlobalRefresh() {
    if (mounted) {
      setState(() {});
      _loadTimetable();
    }
  }

  @override
  void dispose() {
    _eventSub?.cancel();
    _refreshTimer?.cancel();
    AmsGlobals.refreshNotifier.removeListener(_onGlobalRefresh);
    super.dispose();
  }

  Future<void> _loadTimetable() async {
    final user = AmsGlobals.loggedInUser;
    if (user != null) {
      if (mounted) setState(() => _isLoading = true);
      final slots = await ApiSessionService().getTimetable(user.id);
      final sessions = await ApiSessionService().getFacultySessions(user.id);
      final pending =
          sessions.where((s) => s.approvalStatus == 'pending').toList();
      if (mounted) {
        setState(() {
          AmsGlobals.timetableSlots.clear();
          AmsGlobals.timetableSlots.addAll(slots);
          _pendingSessions = pending;
          _allSessions = sessions;
          _isLoading = false;
        });
      }
    } else {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.vesitGray,
      appBar: AppBar(
        backgroundColor: context.colors.vesitPrimary,
        title: Text('DASHBOARD',
            style: context.textStyles.vesitHeadlineSm
                .copyWith(color: context.colors.vesitWhite)),
        centerTitle: true,
        elevation: 0,
        actions: [

          IconButton(
            icon: Icon(Icons.notifications_outlined, color: context.colors.vesitWhite),
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => const NotificationsScreen()));
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final bool isWeb = constraints.maxWidth > 800;

            if (isWeb) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Left Pane (Profile) - 30% width
                  Container(
                    width: constraints.maxWidth * 0.3,
                    constraints:
                        const BoxConstraints(minWidth: 300, maxWidth: 400),
                    decoration: BoxDecoration(
                      color: context.colors.vesitWhite,
                      border: Border(
                          right: BorderSide(
                              color: Colors.grey.shade300, width: 1)),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(4, 0))
                      ],
                    ),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(32, 32, 32, 130),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _FacultyProfileBlock(isLoading: _isLoading),
                          const SizedBox(height: 40),
                          _SidebarMenu(isLoading: _isLoading, onRefresh: _loadTimetable),
                        ],
                      ),
                    ),
                  ),

                  // Right Pane (Action Hubs & Recent Activity) - 70% width
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(32, 32, 32, 130),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          IntrinsicHeight(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(
                                  child: _ActionHub(
                                    isLoading: _isLoading,
                                    icon: Icons.swap_horiz_rounded,
                                    title: 'Proxy QR',
                                    subtitle: 'Generate QR on behalf of another faculty',
                                    onTap: () async {
                                      await Future.delayed(const Duration(milliseconds: 150));
                                      if (!context.mounted) return;
                                      Navigator.of(context).push(MaterialPageRoute(
                                          builder: (_) => const GlobalConfigureSessionScreen()));
                                    },
                                  ),
                                ),
                                const SizedBox(width: 24),
                                Expanded(
                                  child: _ActionHub(
                                    isLoading: _isLoading,
                                    icon: Icons.bar_chart_outlined,
                                    title: 'Generate Report',
                                    subtitle: 'Export attendance sheets & student logs',
                                    onTap: () async {
                                      await Future.delayed(const Duration(milliseconds: 150));
                                      if (!context.mounted) return;
                                      Navigator.of(context).push(MaterialPageRoute(
                                          builder: (_) => const ReportFiltersScreen()));
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 32),
                          _buildPendingApprovalsBanner(),
                          const SizedBox(height: 16),
                          Text('Upcoming Sessions',
                              style: context.textStyles.vesitHeadlineSm),
                          const SizedBox(height: 16),
                          _UpcomingSessionsList(
                            isLoading: _isLoading,
                            allSessions: _allSessions,
                            onRefresh: _loadTimetable,
                          ),
                          const SizedBox(height: 32),
                          Text('Recent Sessions',
                              style: context.textStyles.vesitHeadlineSm),
                          const SizedBox(height: 16),
                          _RecentSessionsList(isLoading: _isLoading, sessions: _allSessions, onRefresh: _loadTimetable),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            }

            // Mobile Layout (Single Column)
            return RefreshIndicator(
              onRefresh: _loadTimetable,
              color: context.colors.vesitPrimary,
              child: SingleChildScrollView(
                controller: widget.scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                children: [
                  Container(
                    color: context.colors.vesitWhite,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 16),
                    child: _FacultyProfileCompact(isLoading: _isLoading, onTap: widget.onProfileTap),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 130),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [

                            Expanded(
                              child: _ActionHub(
                                isLoading: _isLoading,
                                icon: Icons.swap_horiz_rounded,
                                title: 'Proxy QR',
                                subtitle: 'Another faculty',
                                isCompact: true,
                                onTap: () => Navigator.of(context).push(
                                    MaterialPageRoute(
                                        builder: (_) =>
                                            const GlobalConfigureSessionScreen())),
                              ),
                            ),
                            const SizedBox(width: 16),
                              Expanded(
                                child: _ActionHub(
                                  isLoading: _isLoading,
                                  icon: Icons.bar_chart_outlined,
                                  title: 'Reports',
                                  subtitle: 'Export logs',
                                  isCompact: true,
                                  onTap: () => Navigator.of(context).push(
                                      MaterialPageRoute(
                                          builder: (_) =>
                                              const ReportFiltersScreen())),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        _buildPendingApprovalsBanner(),
                        const SizedBox(height: 16),
                        Text('Upcoming Sessions',
                            style: context.textStyles.vesitHeadlineSm),
                        const SizedBox(height: 16),
                        _UpcomingSessionsList(
                          isLoading: _isLoading,
                          allSessions: _allSessions,
                          onRefresh: _loadTimetable,
                        ),
                        const SizedBox(height: 32),
                        Text('Recent Sessions',
                            style: context.textStyles.vesitHeadlineSm),
                        const SizedBox(height: 16),
                        _RecentSessionsList(isLoading: _isLoading, sessions: _allSessions, onRefresh: _loadTimetable),
                      ],
                    ),
                  ),
                ],
              ),
             ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildPendingApprovalsBanner() {
    if (_isLoading || _pendingSessions.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded,
              color: Colors.orange.shade800, size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pending Proxy Approvals (${_pendingSessions.length})',
                  style: context.textStyles.vesitBodyMd.copyWith(
                      color: Colors.orange.shade900,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  'Other faculty members have conducted sessions on your behalf. Please review and approve them.',
                  style: context.textStyles.vesitBodySm
                      .copyWith(color: Colors.orange.shade800),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          ElevatedButton(
            onPressed: () async {
              await Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => const ProxyApprovalsScreen()));
              _loadTimetable();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange.shade600,
              foregroundColor: Colors.white,
            ),
            child: const Text('Review'),
          ),
        ],
      ),
    );
  }
}

class _FacultyProfileBlock extends StatelessWidget {
  const _FacultyProfileBlock({required this.isLoading});
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final userName = AmsGlobals.loggedInUser?.formattedName ?? 'John Smith';
    final userEmail = AmsGlobals.loggedInUser?.email ?? 'faculty@ves.ac.in';

    if (isLoading) {
      return const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          VesitSkeleton(width: 80, height: 80, borderRadius: 40),
          SizedBox(height: 24),
          VesitSkeleton(width: 200, height: 32),
          SizedBox(height: 8),
          VesitSkeleton(width: 150, height: 20),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ProfileAvatar(size: 100),
        const SizedBox(height: 24),
        Text(
          '${_getGreeting()},',
          style: context.textStyles.vesitBodyLg.copyWith(
              color: context.colors.vesitTextBody, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 4),
        Text(
          userName,
          style: context.textStyles.vesitHeadlineMd
              .copyWith(color: context.colors.vesitPrimary, height: 1.3),
        ),
        const SizedBox(height: 8),
        Text(
          userEmail,
          style: context.textStyles.vesitBodyMd.copyWith(
              color: const Color(0xFFB89100), fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

class _FacultyProfileCompact extends StatelessWidget {
  const _FacultyProfileCompact({required this.isLoading, this.onTap});
  final bool isLoading;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final userName = AmsGlobals.loggedInUser?.formattedName ?? 'John Smith';
    final userEmail = AmsGlobals.loggedInUser?.email ?? 'faculty@ves.ac.in';

    if (isLoading) {
      return const Row(
        children: [
          VesitSkeleton(width: 56, height: 56, borderRadius: 28),
          SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              VesitSkeleton(width: 150, height: 20),
              SizedBox(height: 4),
              VesitSkeleton(width: 100, height: 14),
            ],
          ),
        ],
      );
    }

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Row(
        children: [
          _ProfileAvatar(size: 56),
          const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${_getGreeting()},',
                style: context.textStyles.vesitBodyLg.copyWith(
                    color: context.colors.vesitTextBody,
                    fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 2),
              Text(
                userName,
                style: context.textStyles.vesitHeadlineSm.copyWith(
                    color: context.colors.vesitPrimary, fontSize: 20, height: 1.3),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                userEmail,
                style: context.textStyles.vesitBodyMd.copyWith(
                    color: const Color(0xFFB89100),
                    fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    ),
    );
  }
}

class _SidebarMenu extends StatelessWidget {
  const _SidebarMenu({required this.isLoading, required this.onRefresh});
  final bool isLoading;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Column(
        children: List.generate(
            4,
            (index) => const Padding(
                  padding: EdgeInsets.only(bottom: 16),
                  child: VesitSkeleton(
                      width: double.infinity, height: 48, borderRadius: 8),
                )),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SidebarMenuItem(
          icon: Icons.settings,
          title: 'Profile & Settings',
          onTap: () async {
            await Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const FacultyProfileScreen()),
            );
            onRefresh();
          },
        ),
        const SizedBox(height: 16),
        _SidebarMenuItem(
          icon: Icons.logout,
          title: 'Logout',
          isDestructive: true,
          onTap: () async {
            await AmsGlobals.sessionService.logout();
            if (context.mounted) {
              Navigator.of(context).pushReplacementNamed('/');
            }
          },
        ),
      ],
    );
  }
}

class _SidebarMenuItem extends StatefulWidget {
  const _SidebarMenuItem({
    required this.icon,
    required this.title,
    required this.onTap,
    this.isActive = false,
    this.isDestructive = false,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool isActive;
  final bool isDestructive;

  @override
  State<_SidebarMenuItem> createState() => _SidebarMenuItemState();
}

class _SidebarMenuItemState extends State<_SidebarMenuItem> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    final Color iconColor = widget.isActive
        ? context.colors.vesitPrimary
        : (widget.isDestructive ? context.colors.error : context.colors.onSurfaceVariant);
    final Color textColor = widget.isActive
        ? context.colors.vesitTextHeading
        : (widget.isDestructive ? context.colors.error : context.colors.onSurfaceVariant);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: widget.onTap,
        onHover: (hovering) => setState(() => _isHovering = hovering),
        onHighlightChanged: (highlighted) =>
            setState(() => _isHovering = highlighted),
        borderRadius: BorderRadius.circular(8),
        hoverColor: widget.isDestructive
            ? Colors.red.withValues(alpha: 0.05)
            : context.colors.surfaceContainerHighest,
        highlightColor: widget.isDestructive
            ? Colors.red.withValues(alpha: 0.1)
            : context.colors.surfaceContainerHighest,
        splashColor: widget.isDestructive
            ? Colors.red.withValues(alpha: 0.15)
            : context.colors.vesitPrimary.withValues(alpha: 0.1),
        child: AnimatedScale(
          scale: _isHovering ? 1.02 : 1.0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: widget.isActive
                  ? context.colors.vesitPrimary.withValues(alpha: 0.08)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: widget.isDestructive
                    ? Colors.red.withValues(alpha: 0.3)
                    : (widget.isActive
                        ? context.colors.vesitPrimary.withValues(alpha: 0.2)
                        : Colors.transparent),
              ),
              boxShadow: _isHovering
                  ? [
                      BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 12,
                          offset: const Offset(0, 4))
                    ]
                  : [],
            ),
            child: Row(
              children: [
                Icon(widget.icon, color: iconColor, size: 22),
                const SizedBox(width: 16),
                Text(
                  widget.title,
                  style: context.textStyles.vesitBodyLg.copyWith(
                    color: textColor,
                    fontWeight:
                        widget.isActive ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionHub extends StatefulWidget {
  const _ActionHub({
    required this.isLoading,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.highlighted = false,
    this.isCompact = false,
  });

  final bool isLoading;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool highlighted;
  final bool isCompact;

  @override
  State<_ActionHub> createState() => _ActionHubState();
}

class _ActionHubState extends State<_ActionHub> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading) {
      return VesitSkeleton(
          width: double.infinity,
          height: widget.isCompact ? 160 : 240,
          borderRadius: 16);
    }

    final bool isMobile = MediaQuery.of(context).size.width <= 800;
    final bool showHover = !isMobile && _isHovered;
    final bool showPress = isMobile && _isPressed;
    final double scale =
        isMobile ? (_isPressed ? 0.97 : 1.0) : (_isHovered ? 1.03 : 1.0);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => !isMobile ? setState(() => _isHovered = true) : null,
      onExit: (_) => !isMobile ? setState(() => _isHovered = false) : null,
      child: GestureDetector(
        onTapDown: (_) => isMobile ? setState(() => _isPressed = true) : null,
        onTapUp: (_) {
          if (isMobile) setState(() => _isPressed = false);
          widget.onTap();
        },
        onTapCancel: () => isMobile ? setState(() => _isPressed = false) : null,
        onTap: !isMobile ? widget.onTap : null,
        child: AnimatedScale(
          scale: scale,
          duration: Duration(milliseconds: isMobile ? 150 : 250),
          curve: Curves.easeOutCubic,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            decoration: BoxDecoration(
              color: context.colors.vesitWhite,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: widget.highlighted
                    ? (showHover
                        ? context.colors.vesitPrimary
                        : context.colors.vesitPrimary.withValues(alpha: 0.7))
                    : (showHover ? Colors.grey.shade300 : context.colors.surfaceContainerHighest),
                width: widget.highlighted ? 2 : 1,
              ),
              boxShadow: showHover
                  ? [
                      BoxShadow(
                        color: widget.highlighted
                            ? context.colors.vesitPrimary.withValues(alpha: 0.22)
                            : Colors.black.withValues(alpha: 0.12),
                        blurRadius: 28,
                        spreadRadius: widget.highlighted ? 3 : 0,
                        offset: const Offset(0, 10),
                      )
                    ]
                  : showPress
                      ? [
                          BoxShadow(
                            color: widget.highlighted
                                ? context.colors.vesitPrimary.withValues(alpha: 0.2)
                                : Colors.black.withValues(alpha: 0.06),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          )
                        ]
                      : [
                          BoxShadow(
                            color: widget.highlighted
                                ? context.colors.vesitPrimary
                                    .withValues(alpha: isMobile ? 0.18 : 0.10)
                                : Colors.black
                                    .withValues(alpha: isMobile ? 0.08 : 0.06),
                            blurRadius:
                                widget.highlighted ? (isMobile ? 20 : 14) : 14,
                            spreadRadius:
                                widget.highlighted ? (isMobile ? 2 : 1) : 0,
                            offset: Offset(
                                0, isMobile && widget.highlighted ? 6 : 5),
                          )
                        ],
            ),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                onTap: isMobile ? null : widget.onTap,
                borderRadius: BorderRadius.circular(16),
                hoverColor: Colors.transparent,
                splashColor: widget.highlighted
                    ? context.colors.vesitPrimary.withValues(alpha: 0.10)
                    : context.colors.vesitPrimary.withValues(alpha: 0.06),
                highlightColor: Colors.transparent,
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(widget.isCompact ? 16 : 32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          width: widget.isCompact ? 56 : 72,
                          height: widget.isCompact ? 56 : 72,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: widget.highlighted
                                ? (showHover
                                    ? context.colors.vesitPrimary
                                        .withValues(alpha: 0.18)
                                    : context.colors.vesitPrimary
                                        .withValues(alpha: 0.10))
                                : (showHover
                                    ? context.colors.surfaceContainerHighest
                                    : context.colors.vesitGray),
                          ),
                          child: Icon(widget.icon,
                              size: widget.isCompact ? 28 : 36,
                              color: widget.highlighted
                                  ? context.colors.vesitPrimary
                                  : context.colors.onSurfaceVariant),
                        ),
                        SizedBox(height: widget.isCompact ? 12 : 24),
                        Text(
                          widget.title,
                          textAlign: TextAlign.center,
                          style: context.textStyles.vesitHeadlineSm.copyWith(
                            color: showHover && widget.highlighted
                                ? context.colors.vesitPrimary
                                : context.colors.vesitTextHeading,
                            fontSize: widget.isCompact ? 18 : 24,
                          ),
                        ),
                        if (!widget.isCompact) ...[
                          const SizedBox(height: 12),
                          Text(
                            widget.subtitle,
                            textAlign: TextAlign.center,
                            style: context.textStyles.vesitBodyMd
                                .copyWith(color: context.colors.onSurfaceVariant),
                          ),
                        ]
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _UpcomingSessionsList extends StatelessWidget {
  const _UpcomingSessionsList({required this.isLoading, required this.allSessions, required this.onRefresh});
  final bool isLoading;
  final List<AttendanceSession> allSessions;
  final VoidCallback onRefresh;

  void _showSessionDetails(BuildContext context, Map<String, dynamic> session) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          decoration: BoxDecoration(
            color: context.colors.vesitWhite.withValues(alpha: 0.9),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 40,
                  offset: const Offset(0, -10)),
            ],
          ),
          padding: const EdgeInsets.all(24),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                        color: Colors.grey.shade400,
                        borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 24),
                Text('Session Details',
                    style: context.textStyles.vesitHeadlineSm
                        .copyWith(color: context.colors.vesitPrimary)),
                const SizedBox(height: 16),
                _DetailRow(
                    icon: Icons.book,
                    label: 'Subject',
                    value: session['subject'] as String? ?? 'N/A'),
                const SizedBox(height: 12),
                _DetailRow(
                    icon: Icons.schedule,
                    label: 'Time',
                    value:
                        '${_formatTimeString(session['startTime'] as String? ?? '')} - ${_formatTimeString(session['endTime'] as String? ?? '')}'),
                const SizedBox(height: 12),
                _DetailRow(
                    icon: Icons.room,
                    label: 'Venue',
                    value: session['venue'] as String? ?? 'N/A'),
                const SizedBox(height: 12),
                _DetailRow(
                    icon: Icons.people,
                    label: 'Batch',
                    value: session['batchTarget'] as String? ?? 'N/A'),
                const SizedBox(height: 32),
                StatefulBuilder(
                  builder: (context, setState) {
                    final startTimeStr = session['startTime'] as String?;
                    final endTimeStr = session['endTime'] as String?;

                    final now = DateTime.now();

                    // Calculate true course code
                    String baseSubject = session['subject'] as String? ?? 'N/A';
                    String type = session['type'] as String? ?? 'Lecture';
                    String trueCourseCode = '$baseSubject - $type';
                    String targetBatch = session['batchTarget'] as String? ?? '';
                    
                    bool sessionExistsToday = false;
                    AttendanceSession? existingSession;
                    for (var s in allSessions) {
                      if (s.slotId == session['id']) {
                        if (s.proxyFacultyId != null && 
                            s.proxyFacultyId != AmsGlobals.loggedInUser!.id && 
                            s.status != SessionStatus.completed) {
                          // The proxy hasn't submitted yet. Let the original faculty override it.
                          continue;
                        }
                        
                        // Check if session was created on the matching day
                        final sessionDate = s.createdAt;
                        bool isYesterdaySlot = false;
                        final sDay = session['day'] as String?;
                        if (sDay != null) {
                          final dayNamesList = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                          final todayIndex = now.weekday - 1;
                          final idx = dayNamesList.indexOf(sDay);
                          if (idx >= 0) {
                            if (todayIndex == 0 && idx == 6) isYesterdaySlot = true;
                            else if (idx == todayIndex - 1) isYesterdaySlot = true;
                          }
                        }
                        final targetDate = isYesterdaySlot ? now.subtract(const Duration(days: 1)) : now;
                        
                        if (sessionDate.year == targetDate.year && 
                            sessionDate.month == targetDate.month && 
                            sessionDate.day == targetDate.day) {
                          sessionExistsToday = true;
                          existingSession = s;
                          break;
                        }
                      }
                    }

                    if (sessionExistsToday) {
                      if (existingSession?.status == SessionStatus.active) {
                        return SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                backgroundColor: context.colors.vesitPrimary,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12))),
                            onPressed: () {
                              Navigator.pop(context);
                              Navigator.of(context).push(MaterialPageRoute(
                                builder: (_) => FacultyAttendanceQrGeneratorScreen(
                                  session: existingSession!,
                                )));
                            },
                            child: Text(
                              'View Active Session QR',
                              style: context.textStyles.vesitLabelBold.copyWith(
                                color: context.colors.vesitWhite,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        );
                      }

                      if (existingSession?.status == SessionStatus.scheduled) {
                        return SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                backgroundColor: context.colors.vesitPrimary,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12))),
                            onPressed: () async {
                              Navigator.pop(context);
                              await Navigator.of(context).push(MaterialPageRoute(
                                builder: (_) => FacultyAttendanceQrGeneratorScreen(
                                  session: existingSession!,
                                )));
                              onRefresh();
                            },
                            child: Text(
                              'Start Scheduled Session',
                              style: context.textStyles.vesitLabelBold.copyWith(
                                color: context.colors.vesitWhite,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        );
                      }

                      return Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                vertical: 16, horizontal: 24),
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: context.colors.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: Colors.grey.shade300, width: 1),
                            ),
                            child: Text(
                              existingSession?.proxyFacultyId != null ? 'Proxy Session Conducted' : 'Session already conducted today',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: context.colors.onSurfaceVariant,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              icon: Icon(Icons.assessment, color: context.colors.vesitPrimary),
                              label: Text(
                                'View Attendance Report',
                                style: context.textStyles.vesitLabelBold.copyWith(
                                  color: context.colors.vesitPrimary,
                                  fontSize: 16,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                side: BorderSide(color: context.colors.vesitPrimary),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: () {
                                Navigator.pop(context);
                                Navigator.of(context).push(MaterialPageRoute(
                                  builder: (_) => ReportDetailScreen(session: existingSession!),
                                ));
                              },
                            ),
                          ),
                        ],
                      );
                    }

                    bool isYesterday = false;
                    final sDay = session['day'] as String?;
                    if (sDay != null) {
                      final dayNamesList = [
                        'Mon',
                        'Tue',
                        'Wed',
                        'Thu',
                        'Fri',
                        'Sat',
                        'Sun'
                      ];
                      final todayIndex = now.weekday - 1;
                      final idx = dayNamesList.indexOf(sDay);
                      if (idx >= 0) {
                        if (todayIndex == 0 && idx == 6)
                          isYesterday = true;
                        else if (idx == todayIndex - 1) isYesterday = true;
                      }
                    }

                    DateTime? parse24(String? t,
                        {bool isEnd = false, int? startHour}) {
                      if (t == null) return null;
                      try {
                        final isPM = t.toUpperCase().contains('PM');
                        final isAM = t.toUpperCase().contains('AM');
                        final cleanT = t.replaceAll(RegExp(r'\s?[aApP][mM]'), '').trim();
                        
                        final p = cleanT.split(':');
                        if (p.length != 2) return null;
                        
                        int h = int.parse(p[0]);
                        final m = int.parse(p[1]);
                        
                        if (isPM && h < 12) h += 12;
                        if (isAM && h == 12) h = 0;
                        
                        DateTime dt = DateTime(
                            now.year, now.month, now.day, h, m);
                        if (isYesterday) {
                          dt = dt.subtract(const Duration(days: 1));
                        }
                        if (isEnd && startHour != null && h < startHour) {
                          dt = dt.add(const Duration(days: 1));
                        }
                        return dt;
                      } catch (e) {
                        return null;
                      }
                    }

                    final startHour = startTimeStr != null
                        ? int.tryParse(startTimeStr.split(':')[0])
                        : null;
                    final start = parse24(startTimeStr);
                    final end =
                        parse24(endTimeStr, isEnd: true, startHour: startHour);

                    // Update every second if it's in the future
                    if (start != null && now.isBefore(start)) {
                      Future.delayed(const Duration(seconds: 1), () {
                        if (context.mounted) setState(() {});
                      });

                      final diff = start.difference(now);
                      final hours = diff.inHours;
                      final minutes = diff.inMinutes % 60;
                      final seconds = diff.inSeconds % 60;

                      String countdown = 'Starts in ';
                      if (hours > 0) countdown += '${hours}h ';
                      countdown += '${minutes}m ${seconds}s';

                      return Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: context.colors.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          countdown,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: context.colors.onSurfaceVariant,
                          ),
                        ),
                      );
                    }

                    if (end != null && now.isAfter(end)) {
                      return Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: context.colors.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Session Ended',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: context.colors.onSurfaceVariant,
                          ),
                        ),
                      );
                    }

                    return ElevatedButton(
                      onPressed: () async {
                        Navigator.of(ctx).pop(); // Close modal
                        await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => FacultyAttendanceQrGeneratorScreen(
                              subjectTitle: trueCourseCode,
                              sessionSubtitle:
                                  '${session['venue'] ?? ''} • ${_formatTimeString(session['startTime'] as String? ?? '')} - ${_formatTimeString(session['endTime'] as String? ?? '')} • Div: ${session['batchTarget'] ?? ''}',
                              batchTarget: targetBatch,
                              slotId: session['id'],
                            ),
                          ),
                        );
                        onRefresh();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: context.colors.vesitPrimary,
                        foregroundColor: context.colors.vesitWhite,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Quick Generate QR',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Column(
        children: List.generate(
            2,
            (index) => const Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: VesitSkeleton(
                      width: double.infinity, height: 80, borderRadius: 12),
                )),
      );
    }

    final now = DateTime.now();
    final currentDayStr = DateFormat('EEE').format(now); // e.g. "Thu"

    final todaySlots = AmsGlobals.timetableSlots.where((s) {
      if (s['day'] != currentDayStr) return false;
      return true;
    }).toList();

    // Sort them by time for the dashboard
    todaySlots.sort((a, b) {
      final tA = a['startTime'] as String? ?? '00:00';
      final tB = b['startTime'] as String? ?? '00:00';
      return tA.compareTo(tB);
    });

    if (todaySlots.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Column(
            children: [
              Icon(Icons.event_available,
                  size: 48, color: Colors.grey.shade400),
              const SizedBox(height: 12),
              Text('No sessions scheduled for today.',
                  style: context.textStyles.vesitBodyLg
                      .copyWith(color: context.colors.onSurfaceVariant)),
            ],
          ),
        ),
      );
    }

    return Column(
      children: todaySlots.map((session) {
        final startTimeStrRaw = session['startTime'] as String? ?? '00:00';
        final endTimeStrRaw = session['endTime'] as String? ?? '00:00';
        final startTimeStr = _formatTimeString(startTimeStrRaw);
        final endTimeStr = _formatTimeString(endTimeStrRaw);

        String statusText = 'Scheduled';
        try {
          final sParts = startTimeStrRaw.split(':');
          final sHour = int.parse(sParts[0]);
          final sMin = int.parse(sParts[1]);
          var sDateTime = DateTime(now.year, now.month, now.day, sHour, sMin);

          final eParts = endTimeStrRaw.split(':');
          final eHour = int.parse(eParts[0]);
          final eMin = int.parse(eParts[1]);
          var eDateTime = DateTime(now.year, now.month, now.day, eHour, eMin);

          if (eDateTime.isBefore(sDateTime)) {
            eDateTime = eDateTime.add(const Duration(days: 1));
          }

          final diff = sDateTime.difference(now);

          if (now.isAfter(eDateTime)) {
            statusText = 'Completed';
          } else if (diff.isNegative) {
            statusText = 'Running now';
          } else if (diff.inHours > 0) {
            statusText = 'In ${diff.inHours} hr ${diff.inMinutes % 60} min';
          } else {
            statusText = 'In ${diff.inMinutes} mins';
          }
        } catch (e) {
          // Fallback to Scheduled
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _SessionTile(
            date: 'Today',
            time: '$startTimeStr - $endTimeStr',
            venue: session['venue'] as String? ?? 'TBA',
            course: session['subject'] as String,
            students: 60, // Placeholder, will come from backend
            status: statusText,
            isUpcoming: true,
            batch: session['batchTarget'] as String?,
            onTap: () => _showSessionDetails(context, session),
          ),
        );
      }).toList(),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow(
      {required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: context.colors.onSurfaceVariant),
        const SizedBox(width: 12),
        Text('$label: ',
            style: context.textStyles.vesitBodyMd
                .copyWith(color: context.colors.onSurfaceVariant)),
        Expanded(
            child: Text(value,
                style: context.textStyles.vesitLabelBold
                    .copyWith(color: context.colors.vesitTextHeading))),
      ],
    );
  }
}

class _RecentSessionsList extends StatelessWidget {
  const _RecentSessionsList({required this.isLoading, required this.sessions, required this.onRefresh});
  final bool isLoading;
  final List<AttendanceSession> sessions;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Column(
        children: List.generate(
            3,
            (index) => const Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: VesitSkeleton(
                      width: double.infinity, height: 80, borderRadius: 12),
                )),
      );
    }

    final recentSessions = sessions.where((s) => s.status == SessionStatus.closed || s.status == SessionStatus.active).toList();
    recentSessions.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final topSessions = recentSessions.take(5).toList();

    if (topSessions.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Column(
            children: [
              Icon(Icons.history, size: 48, color: Colors.grey.shade400),
              const SizedBox(height: 12),
              Text('No recent sessions.',
                  style: context.textStyles.vesitBodyLg
                      .copyWith(color: context.colors.onSurfaceVariant)),
            ],
          ),
        ),
      );
    }

    return Column(
      children: topSessions.map((session) {
        final timeStr = DateFormat('h:mm a').format(session.createdAt);
        final dateStr = DateFormat('MMM d, yyyy').format(session.createdAt);

        final isProxiedBySomeoneElse = session.proxyFacultyId != null && session.proxyFacultyId != session.facultyId;
        final isPendingProxy = isProxiedBySomeoneElse && session.approvalStatus == 'pending';

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _SessionTile(
            date: dateStr,
            time: timeStr,
            venue: session.status == SessionStatus.active ? 'Running' : 'Completed',
            course: session.courseCode,
            students: 0,
            status: session.status == SessionStatus.active ? 'Live' : 'Closed',
            isUpcoming: session.status == SessionStatus.active,
            batch: session.batchTarget,
            isProxiedBySomeoneElse: isPendingProxy,
            onTap: () {},
            actionLabel: isPendingProxy
                ? 'Proxied'
                : (session.status == SessionStatus.active ? 'Force Close' : 'View Report'),
            onAction: isPendingProxy ? null : () async {
              if (session.status == SessionStatus.active) {
                await AmsGlobals.sessionService.closeSession(session.id);
                onRefresh();
              } else {
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => ReportDetailScreen(session: session)));
              }
            },
          ),
        );
      }).toList(),
    );
  }
}

class _SessionTile extends StatefulWidget {
  const _SessionTile(
      {required this.date,
      required this.time,
      required this.venue,
      required this.course,
      required this.students,
      required this.status,
      this.isUpcoming = false,
      this.batch,
      this.isProxiedBySomeoneElse = false,
      this.onTap,
      this.actionLabel = 'View Report',
      this.onAction});
  final String date;
  final String time;
  final String venue;
  final String course;
  final int students;
  final String status;
  final bool isUpcoming;
  final String? batch;
  final bool isProxiedBySomeoneElse;
  final VoidCallback? onTap;
  final String actionLabel;
  final VoidCallback? onAction;

  @override
  State<_SessionTile> createState() => _SessionTileState();
}

class _SessionTileState extends State<_SessionTile> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width <= 800;
    final bool showHover = !isMobile && _isHovered;
    final bool showPress = isMobile && _isPressed;
    final double scale =
        isMobile ? (_isPressed ? 0.97 : 1.0) : (_isHovered ? 1.02 : 1.0);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => !isMobile ? setState(() => _isHovered = true) : null,
      onExit: (_) => !isMobile ? setState(() => _isHovered = false) : null,
      child: GestureDetector(
        onTapDown: (_) => isMobile ? setState(() => _isPressed = true) : null,
        onTapUp: (_) {
          if (isMobile) setState(() => _isPressed = false);
          widget.onTap?.call();
        },
        onTapCancel: () => isMobile ? setState(() => _isPressed = false) : null,
        onTap: !isMobile ? widget.onTap : null,
        child: AnimatedScale(
          scale: scale,
          duration: Duration(milliseconds: isMobile ? 150 : 250),
          curve: Curves.easeOutCubic,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            decoration: BoxDecoration(
              color: context.colors.vesitWhite,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: widget.isUpcoming
                    ? (showHover
                        ? context.colors.vesitPrimary.withValues(alpha: 0.7)
                        : context.colors.vesitPrimary.withValues(alpha: 0.35))
                    : (showHover ? Colors.grey.shade300 : context.colors.surfaceContainerHighest),
                width: widget.isUpcoming ? 1.5 : 1,
              ),
              boxShadow: showHover
                  ? [
                      BoxShadow(
                        color: widget.isUpcoming
                            ? context.colors.vesitPrimary.withValues(alpha: 0.18)
                            : Colors.black.withValues(alpha: 0.10),
                        blurRadius: 20,
                        spreadRadius: widget.isUpcoming ? 2 : 0,
                        offset: const Offset(0, 8),
                      )
                    ]
                  : showPress
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          )
                        ]
                      : [
                          BoxShadow(
                            color: widget.isUpcoming
                                ? context.colors.vesitPrimary
                                    .withValues(alpha: isMobile ? 0.12 : 0.08)
                                : Colors.black
                                    .withValues(alpha: isMobile ? 0.06 : 0.05),
                            blurRadius:
                                widget.isUpcoming ? (isMobile ? 16 : 10) : 10,
                            spreadRadius:
                                widget.isUpcoming ? (isMobile ? 1 : 0) : 0,
                            offset: const Offset(0, 4),
                          )
                        ],
            ),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                onTap: isMobile ? null : widget.onTap,
                borderRadius: BorderRadius.circular(16),
                hoverColor: Colors.transparent,
                splashColor: widget.isUpcoming
                    ? context.colors.vesitPrimary.withValues(alpha: 0.10)
                    : context.colors.vesitPrimary.withValues(alpha: 0.05),
                highlightColor: Colors.transparent,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                            color: widget.isUpcoming
                                ? context.colors.vesitPrimary.withValues(alpha: 0.1)
                                : context.colors.vesitGray,
                            borderRadius: BorderRadius.circular(12)),
                        child: Icon(
                            SubjectIcons.getIconForSubject(widget.course),
                            color: widget.isUpcoming
                                ? context.colors.vesitPrimary
                                : context.colors.onSurfaceVariant,
                            size: 28),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(widget.course,
                                style: context.textStyles.vesitLabelBold.copyWith(
                                    color: widget.isUpcoming
                                        ? context.colors.vesitPrimary
                                        : context.colors.vesitTextHeading,
                                    fontSize: 16)),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Icon(
                                    widget.isUpcoming
                                        ? Icons.calendar_today
                                        : Icons.history,
                                    size: 14,
                                    color: Colors.grey.shade500),
                                const SizedBox(width: 4),
                                Text(
                                  widget.date,
                                  style: context.textStyles.vesitBodyMd
                                      .copyWith(color: context.colors.onSurfaceVariant),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                      color: context.colors.vesitPrimary.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(6)),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.schedule, size: 12, color: context.colors.vesitPrimary),
                                      const SizedBox(width: 4),
                                      Text(widget.time,
                                          style: TextStyle(
                                              fontSize: 11,
                                              color: context.colors.vesitPrimary,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 0.5)),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                      color: context.colors.vesitOrange.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(6)),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.location_on, size: 12, color: context.colors.vesitOrange),
                                      const SizedBox(width: 4),
                                      Text(widget.venue,
                                          style: TextStyle(
                                              fontSize: 11,
                                              color: context.colors.vesitOrange,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 0.5)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            if (widget.batch != null) ...[
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AmsGlobals.getBatchColor(widget.batch!)
                                      .withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                      color: AmsGlobals.getBatchColor(
                                              widget.batch!)
                                          .withValues(alpha: 0.3)),
                                ),
                                child: Text(
                                  widget.batch!,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color:
                                        AmsGlobals.getBatchColor(widget.batch!),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: widget.isUpcoming
                                  ? context.colors.vesitGold.withValues(alpha: 0.15)
                                  : context.colors.vesitGray,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(widget.status,
                                style: context.textStyles.vesitLabelBold.copyWith(
                                    color: widget.isUpcoming
                                        ? context.colors.vesitGold
                                        : context.colors.onSurfaceVariant,
                                    fontSize: 12)),
                          ),
                          const SizedBox(height: 8),
                          if (widget.status.toUpperCase() == 'COMPLETED') ...[
                            Row(
                              children: [
                                Icon(Icons.people_outline,
                                    size: 16, color: Colors.grey.shade500),
                                const SizedBox(width: 4),
                                Text('${widget.students} Present',
                                    style: context.textStyles.vesitBodyMd.copyWith(
                                        color: context.colors.onSurfaceVariant,
                                        fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ],
                        ],
                      ),
                      if (widget.isProxiedBySomeoneElse) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.orange.withOpacity(0.3)),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.warning_amber_rounded, color: Colors.orange.shade700, size: 16),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Attendance is being handled by a Proxy (pending approval).',
                                  style: context.textStyles.vesitBodySm.copyWith(color: Colors.orange.shade800),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (widget.onAction != null) ...[
                  Divider(height: 1, color: Colors.grey.shade200),
                  InkWell(
                    onTap: widget.onAction,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: widget.isUpcoming 
                            ? context.colors.vesitGold.withValues(alpha: 0.1)
                            : context.colors.vesitPrimary.withValues(alpha: 0.05),
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(16),
                          bottomRight: Radius.circular(16),
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        widget.actionLabel,
                        style: context.textStyles.vesitLabelBold.copyWith(
                          color: widget.isUpcoming 
                              ? context.colors.vesitGold
                              : context.colors.vesitPrimary,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    ),
  ),
);
  }
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({required this.size});
  final double size;

  @override
  Widget build(BuildContext context) {
    final user = AmsGlobals.loggedInUser;
    final pfpUrl = user?.profilePictureUrl;
    final name = user?.formattedName ?? '';
    final borderWidth = size > 80 ? 4.0 : 2.0;

    String initials = "U";
    if (name.isNotEmpty) {
      List<String> parts = name.trim().split(RegExp(r'\s+'));
      if (parts.length >= 2 && parts[1].isNotEmpty) {
        initials = "${parts[0][0]}${parts[1][0]}".toUpperCase();
      } else {
        initials = parts[0][0].toUpperCase();
      }
    }

    return Stack(
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: context.colors.vesitGray,
            border: Border.all(
                color: context.colors.vesitPrimary.withValues(alpha: 0.2),
                width: borderWidth),
            boxShadow: size > 80
                ? [
                    BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 4))
                  ]
                : [],
          ),
          child: ClipOval(
            child: pfpUrl != null
                ? Image.network(pfpUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _buildInitials(context, initials))
                : _buildInitials(context, initials),
          ),
        ),
        Positioned(
          bottom: size * 0.04,
          right: size * 0.04,
          child: Container(
            width: size * 0.28,
            height: size * 0.28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF22C55E),
              border:
                  Border.all(color: context.colors.vesitWhite, width: borderWidth),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInitials(BuildContext context, String initials) {
    return Container(
      color: context.colors.vesitPrimary,
      alignment: Alignment.center,
      child: Text(
        initials,
        style: context.textStyles.vesitHeadlineMd.copyWith(
            color: context.colors.vesitWhite,
            fontSize: size * 0.4),
      ),
    );
  }
}
