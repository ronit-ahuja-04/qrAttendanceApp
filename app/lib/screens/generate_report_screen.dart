import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../ams/globals.dart';
import '../ams/models.dart';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:universal_html/html.dart' as html;
import 'package:http/http.dart' as http;
import '../ams/api_services.dart';

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
      backgroundColor: context.colors.surface,
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
              Expanded(
                child: Center(
                  child: Text('No past sessions found.', style: context.textStyles.bodyLg),
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
        color: context.colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.colors.outlineVariant),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2)),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Text(
          session.courseCode,
          style: context.textStyles.headlineSm.copyWith(fontSize: 16),
        ),
        subtitle: Text(
          'Date: $dateStr at $timeStr\nStatus: ${session.status.name.toUpperCase()}',
          style: context.textStyles.labelMd,
        ),
        trailing: ElevatedButton(
          onPressed: onTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: context.colors.primaryContainer,
            foregroundColor: context.colors.onPrimaryContainer,
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
  final Widget? trailing;

  const _Header({required this.title, required this.onBack, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: context.colors.surface,
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2))],
      ),
      child: Row(
        children: [
          IconButton(icon: const Icon(Icons.arrow_back), onPressed: onBack),
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: context.textStyles.headlineSm,
            ),
          ),
          trailing ?? const SizedBox(width: 48), // Balance for centering
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
    
    // Sort alphanumerically by roll number
    int compareAlphanumeric(String a, String b) {
      final regExp = RegExp(r'(\d+|\D+)');
      final aMatches = regExp.allMatches(a).map((m) => m.group(0)!).toList();
      final bMatches = regExp.allMatches(b).map((m) => m.group(0)!).toList();
      
      for (int i = 0; i < aMatches.length && i < bMatches.length; i++) {
        final aPart = aMatches[i];
        final bPart = bMatches[i];
        
        final aInt = int.tryParse(aPart);
        final bInt = int.tryParse(bPart);
        
        if (aInt != null && bInt != null) {
          final comp = aInt.compareTo(bInt);
          if (comp != 0) return comp;
        } else {
          final comp = aPart.compareTo(bPart);
          if (comp != 0) return comp;
        }
      }
      return aMatches.length.compareTo(bMatches.length);
    }
    
    list.sort((a, b) => compareAlphanumeric(
      (a['rollNo'] ?? '').toString(),
      (b['rollNo'] ?? '').toString(),
    ));

    if (mounted) {
      setState(() {
        _students = list;
        _isLoading = false;
      });
    }
  }

  Future<void> _exportToLockedExcel() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sessionJson = prefs.getString('ams_user_session');
      String token = '';
      if (sessionJson != null) {
        try {
          token = jsonDecode(sessionJson)['token'] ?? '';
        } catch(e) {}
      }
      final url = '$baseUrl/api/report/excel/${widget.session.id}?token=$token';
      
      
      if (kIsWeb) {
        // Web download logic with Blob to hide token
        final response = await httpClient.get(Uri.parse(url));
        if (response.statusCode == 200) {
          final blob = html.Blob([response.bodyBytes]);
          final blobUrl = html.Url.createObjectUrlFromBlob(blob);
          final anchor = html.AnchorElement(href: blobUrl)
            ..setAttribute("download", 'Report_${widget.session.courseCode}.xlsx')
            ..click();
          html.Url.revokeObjectUrl(blobUrl);
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Report downloaded successfully')),
            );
          }
        } else {
          throw Exception('Failed to download from server');
        }
      } else {

        // Mobile/Desktop logic
        final response = await httpClient.get(Uri.parse(url));
        if (response.statusCode == 200) {
          final bytes = response.bodyBytes;
          final filename = 'Report_${widget.session.courseCode}_${DateTime.now().millisecondsSinceEpoch}.xlsx';
          final dir = await getApplicationDocumentsDirectory();
          final path = '${dir.path}/$filename';
          final file = File(path);
          await file.writeAsBytes(bytes);
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Report downloaded and saved successfully!')),
            );
          }
          OpenFile.open(path);
        } else {
          throw Exception('Failed to download from server');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to export report: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final presentCount = _students.where((s) => s['status'] == 'present').length;
    final total = _students.length;

    return Scaffold(
      backgroundColor: context.colors.surface,
      body: SafeArea(
        child: Column(
          children: [
            _Header(
              title: '${widget.session.courseCode} Report',
              onBack: () => Navigator.of(context).pop(),
              trailing: IconButton(
                icon: Icon(Icons.download, color: context.colors.primary),
                onPressed: _exportToLockedExcel,
                tooltip: 'Export Lockable Excel',
              ),
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
                        color: context.colors.primaryContainer,
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
                            title: Text(AmsGlobals.formatStudentName(student['name'], student['email']), style: context.textStyles.labelBold),
                            subtitle: Text(student['rollNo'] ?? 'N/A'),
                            trailing: Text(isPresent ? (student['method'] ?? '') : '', style: context.textStyles.labelSm),
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
        Text(label, style: TextStyle(color: context.colors.onPrimaryContainer, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(color: context.colors.onPrimaryContainer, fontSize: 24, fontWeight: FontWeight.w900)),
      ],
    );
  }
}
