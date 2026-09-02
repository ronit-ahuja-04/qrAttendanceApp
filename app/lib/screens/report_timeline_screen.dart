import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/tactile_widgets.dart';
import '../widgets/vesit_widgets.dart';
import '../widgets/vesit_toast.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:universal_html/html.dart' as html;
import 'package:http/http.dart' as http;
import '../ams/globals.dart';
import '../ams/api_services.dart';

class ReportTimelineScreen extends StatefulWidget {
  final String subject;
  final String batchTarget;

  const ReportTimelineScreen({
    super.key,
    required this.subject,
    required this.batchTarget,
  });

  @override
  State<ReportTimelineScreen> createState() => _ReportTimelineScreenState();
}

class _ReportTimelineScreenState extends State<ReportTimelineScreen> {
  DateTimeRange? _dateRange;
  bool _isDownloading = false;

  Future<void> _pickDateRange() async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _dateRange,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: context.colors.vesitPrimary,
              onPrimary: context.colors.vesitWhite,
              onSurface: context.colors.vesitTextHeading,
            ),
          ),
          child: child!,
        );
      },
    );
    if (range != null) {
      setState(() => _dateRange = range);
    }
  }

  Future<void> _generateReport() async {
    if (_dateRange == null) {
      VesitToast.show(
        context: context,
        title: 'Error',
        description: 'Please select a date range first',
        type: ToastType.error,
      );
      return;
    }

    setState(() => _isDownloading = true);

    try {
      final facultyId = AmsGlobals.loggedInUser!.id;
      final start = _dateRange!.start.toIso8601String();
      // Add almost 1 full day to the end date so it covers 23:59:59 of that day
      final end = _dateRange!.end.add(const Duration(hours: 23, minutes: 59, seconds: 59)).toIso8601String();
      final subject = Uri.encodeComponent(widget.subject);
      final batchTarget = Uri.encodeComponent(widget.batchTarget);
      
      final prefs = await SharedPreferences.getInstance();
      final sessionJson = prefs.getString('ams_user_session');
      String token = '';
      if (sessionJson != null) {
        try {
          token = jsonDecode(sessionJson)['token'] ?? '';
        } catch(e) {}
      }
      final url = '$baseUrl/api/report/bulk-excel?facultyId=$facultyId&subject=$subject&batchTarget=$batchTarget&startDate=$start&endDate=$end&token=$token';
      
      if (kIsWeb) {
        // Web download logic
        final anchor = html.AnchorElement(href: url)
          ..setAttribute("download", 'BulkReport_${widget.subject}.xlsx')
          ..target = '_blank'
          ..click();
          
        if (mounted) {
          VesitToast.show(
            context: context,
            title: 'Success',
            description: 'Report downloaded successfully',
            type: ToastType.success,
          );
        }
      } else {
        // Mobile/Desktop logic
        final response = await httpClient.get(Uri.parse(url));
        if (response.statusCode == 200) {
          final bytes = response.bodyBytes;
          final filename = 'BulkReport_${widget.subject}_${DateTime.now().millisecondsSinceEpoch}.xlsx';
          final dir = await getApplicationDocumentsDirectory();
          final path = '${dir.path}/$filename';
          final file = File(path);
          await file.writeAsBytes(bytes);
          
          if (mounted) {
            VesitToast.show(
              context: context,
              title: 'Success',
              description: 'Report saved to Downloads',
              type: ToastType.success,
            );
          }
          OpenFile.open(path);
        } else {
          final msg = response.body;
          throw Exception(msg.isNotEmpty ? msg : 'Failed to download from server');
        }
      }
    } catch (e) {
      if (mounted) {
        VesitToast.show(
          context: context,
          title: 'Export Failed',
          description: e.toString(),
          type: ToastType.error,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isDownloading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM d, yyyy');

    return Scaffold(
      backgroundColor: context.colors.vesitGray,
      body: SafeArea(
        child: Column(
          children: [
            _ReportTimelineHeader(onBack: () => Navigator.of(context).maybePop()),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    VesitCard(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          ConfigCard(
                            label: 'Selected Date Range',
                            child: InkWell(
                              onTap: _pickDateRange,
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                decoration: BoxDecoration(
                                  color: context.colors.vesitWhite,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: context.colors.vesitPrimary.withOpacity(0.3)),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.date_range, color: context.colors.vesitPrimary),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        _dateRange == null
                                            ? 'Tap to select dates'
                                            : '${dateFormat.format(_dateRange!.start)} - ${dateFormat.format(_dateRange!.end)}',
                                        style: context.textStyles.vesitBodyMd.copyWith(
                                          fontWeight: FontWeight.w600,
                                          color: _dateRange == null ? Colors.grey.shade500 : context.colors.vesitTextHeading,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          _isDownloading 
                            ? const Center(child: CircularProgressIndicator())
                            : PushableButton(
                                label: 'Generate Bulk Report',
                                icon: Icons.download,
                                onPressed: _dateRange != null ? () => _generateReport() : null,
                              ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Step 2 of 3: Select the date range to aggregate attendance for.',
                      textAlign: TextAlign.center,
                      style: context.textStyles.vesitLabelSm.copyWith(color: Colors.grey.shade600),
                    ),
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

class _ReportTimelineHeader extends StatelessWidget {
  const _ReportTimelineHeader({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: context.colors.vesitWhite,
        border: Border(bottom: BorderSide(color: Colors.grey.shade300, width: 1)),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: Icon(Icons.arrow_back, color: context.colors.vesitPrimary),
          ),
          Expanded(
            child: Text(
              'Select Timeline',
              textAlign: TextAlign.center,
              style: context.textStyles.vesitHeadlineSm.copyWith(color: context.colors.vesitPrimary),
            ),
          ),
          const SizedBox(width: 48), // balances the back button
        ],
      ),
    );
  }
}
