import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../ams/globals.dart';
import '../ams/models.dart';
import 'dart:convert';

class GenerateReportScreen extends StatefulWidget {
  const GenerateReportScreen({super.key});

  @override
  State<GenerateReportScreen> createState() => _GenerateReportScreenState();
}

class _GenerateReportScreenState extends State<GenerateReportScreen> {
  bool _isLoading = true;
  List<AttendanceSession> _sessions = [];

  @override
  void initState() {
    super.initState();
    _fetchSessions();
  }

  Future<void> _fetchSessions() async {
    final facultyId = AmsGlobals.loggedInUser?.id ?? 'faculty-01';
    final sessions = await AmsGlobals.sessionService.getFacultySessions(facultyId);
    if (mounted) {
      setState(() {
        _sessions = sessions;
        _isLoading = false;
      });
    }
  }

  void _viewReport(AttendanceSession session) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ReportDetailScreen(session: session),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Column(
          children: [
            _Header(
              title: 'Generate Report',
              onBack: () => Navigator.of(context).pop(),
            ),
            if (_isLoading)
              const Expanded(child: Center(child: CircularProgressIndicator()))
            else if (_sessions.isEmpty)
              const Expanded(
                child: Center(
                  child: Text('No past sessions found.', style: AppTextStyles.bodyLg),
                ),
              )
            else
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _sessions.length,
                  itemBuilder: (context, index) {
                    final session = _sessions[index];
                    return _SessionCard(
                      session: session,
                      onTap: () => _viewReport(session),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SessionCard extends StatelessWidget {
  final AttendanceSession session;
  final VoidCallback onTap;

  const _SessionCard({required this.session, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final dateStr = '${session.createdAt.day}/${session.createdAt.month}/${session.createdAt.year}';
    final timeStr = '${session.createdAt.hour.toString().padLeft(2, '0')}:${session.createdAt.minute.toString().padLeft(2, '0')}';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outlineVariant),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2)),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Text(
          session.courseCode,
          style: AppTextStyles.headlineSm.copyWith(fontSize: 16),
        ),
        subtitle: Text(
          'Date: $dateStr at $timeStr\nStatus: ${session.status.name.toUpperCase()}',
          style: AppTextStyles.labelMd,
        ),
        trailing: ElevatedButton(
          onPressed: onTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryContainer,
            foregroundColor: AppColors.onPrimaryContainer,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: const Text('View Report', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final String title;
  final VoidCallback onBack;

  const _Header({required this.title, required this.onBack});

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
          IconButton(icon: const Icon(Icons.arrow_back), onPressed: onBack),
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: AppTextStyles.headlineSm,
            ),
          ),
          const SizedBox(width: 48), // Balance for centering
        ],
      ),
    );
  }
}

class ReportDetailScreen extends StatefulWidget {
  final AttendanceSession session;
  const ReportDetailScreen({super.key, required this.session});

  @override
  State<ReportDetailScreen> createState() => _ReportDetailScreenState();
}

class _ReportDetailScreenState extends State<ReportDetailScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _students = [];

  @override
  void initState() {
    super.initState();
    _fetchReport();
  }

  Future<void> _fetchReport() async {
    final list = await AmsGlobals.sessionService.getVerificationList(widget.session.id);
    if (mounted) {
      setState(() {
        _students = list;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final presentCount = _students.where((s) => s['status'] == 'present').length;
    final total = _students.length;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Column(
          children: [
            _Header(
              title: '${widget.session.courseCode} Report',
              onBack: () => Navigator.of(context).pop(),
            ),
            if (_isLoading)
              const Expanded(child: Center(child: CircularProgressIndicator()))
            else
              Expanded(
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      margin: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _Stat('Total', total.toString()),
                          _Stat('Present', presentCount.toString()),
                          _Stat('Absent', (total - presentCount).toString()),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: _students.length,
                        itemBuilder: (context, index) {
                          final student = _students[index];
                          final isPresent = student['status'] == 'present';
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: isPresent ? Colors.green.shade100 : Colors.red.shade100,
                              child: Icon(
                                isPresent ? Icons.check : Icons.close,
                                color: isPresent ? Colors.green : Colors.red,
                              ),
                            ),
                            title: Text(student['name'] ?? 'Unknown', style: AppTextStyles.labelBold),
                            subtitle: Text(student['rollNo'] ?? 'N/A'),
                            trailing: Text(student['method'] ?? '', style: AppTextStyles.labelSm),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;

  const _Stat(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: TextStyle(color: AppColors.onPrimaryContainer, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(color: AppColors.onPrimaryContainer, fontSize: 24, fontWeight: FontWeight.w900)),
      ],
    );
  }
}
