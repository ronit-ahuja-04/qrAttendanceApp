import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../ams/globals.dart';
import '../ams/models.dart';
import 'generate_report_screen.dart';
import 'dart:async';
import '../ams/notification_service.dart';
class FacultySessionHistoryScreen extends StatefulWidget {
  const FacultySessionHistoryScreen({super.key});

  @override
  State<FacultySessionHistoryScreen> createState() => _FacultySessionHistoryScreenState();
}

class _FacultySessionHistoryScreenState extends State<FacultySessionHistoryScreen> {
  bool _isLoading = true;
  List<AttendanceSession> _sessions = [];

  StreamSubscription? _notificationSub;

  @override
  void initState() {
    super.initState();
    _loadHistory();
    _notificationSub = NotificationService().events.listen((event) {
      if (['TIMETABLE_UPDATED', 'ATTENDANCE_UPDATED', 'ATTENDANCE_SUBMITTED', 'PROXY_AUTO_APPROVED', 'PROXY_APPROVED'].contains(event['type'])) {
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
    if (_sessions.isEmpty) setState(() => _isLoading = true);
    final allSessions = await AmsGlobals.sessionService.getFacultySessions(AmsGlobals.loggedInUser!.id);
    
    // Only show completed sessions in history
    _sessions = allSessions.where((s) => s.status == SessionStatus.closed).toList();
    
    // Sort by most recent first
    _sessions.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.vesitGray,
      appBar: AppBar(
        backgroundColor: context.colors.vesitWhite,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text('Session History', style: context.textStyles.vesitHeadlineSm.copyWith(color: context.colors.vesitPrimary)),
      ),
      body: RefreshIndicator(
        onRefresh: _loadHistory,
        color: context.colors.vesitPrimary,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _sessions.isEmpty
                ? CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      SliverFillRemaining(
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.history_toggle_off, size: 64, color: Colors.grey.shade400),
                              const SizedBox(height: 16),
                              Text('No completed sessions found.', style: context.textStyles.vesitBodyLg.copyWith(color: Colors.grey.shade600)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  )
                : ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                    itemCount: _sessions.length,
                    itemBuilder: (context, index) {
                      final session = _sessions[index];
                      return _HistoryCard(session: session);
                    },
                  ),
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({required this.session});
  final AttendanceSession session;

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM d, yyyy');
    final timeFormat = DateFormat('h:mm a');
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: context.colors.vesitWhite,
        borderRadius: BorderRadius.circular(16),
        elevation: 0,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => ReportDetailScreen(session: session)),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        session.courseCode,
                        style: context.textStyles.vesitHeadlineSm.copyWith(color: context.colors.vesitTextHeading, fontSize: 16),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Icon(Icons.chevron_right, color: Colors.grey.shade400),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.calendar_today, size: 14, color: Colors.grey.shade600),
                    const SizedBox(width: 6),
                    Text(dateFormat.format(session.createdAt), style: context.textStyles.vesitBodyMd.copyWith(color: Colors.grey.shade600)),
                    const SizedBox(width: 16),
                    Icon(Icons.access_time, size: 14, color: Colors.grey.shade600),
                    const SizedBox(width: 6),
                    Text(timeFormat.format(session.createdAt), style: context.textStyles.vesitBodyMd.copyWith(color: Colors.grey.shade600)),
                  ],
                ),
                if (session.batchTarget != null && session.batchTarget!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AmsGlobals.getBatchColor(session.batchTarget!).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AmsGlobals.getBatchColor(session.batchTarget!).withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.people, size: 12, color: AmsGlobals.getBatchColor(session.batchTarget!)),
                        const SizedBox(width: 6),
                        Text(
                          session.batchTarget!, 
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AmsGlobals.getBatchColor(session.batchTarget!))
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
