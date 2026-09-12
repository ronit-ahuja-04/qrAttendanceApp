import 'dart:convert';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/tactile_widgets.dart';
import '../widgets/vesit_widgets.dart';
import '../ams/globals.dart';
import '../ams/api_services.dart' show baseUrl, httpClient;
import 'report_timeline_screen.dart';

/// "Report Details" — Step 1 of 3 in the Generate Report flow. Mirrors the
/// "Generate Report - Step 1" Stitch mockup (code.html): Division and
/// Subject dropdowns inside a raised card, a 3-dot progress indicator, and
/// a "CONTINUE TO TIMELINE" action that proceeds to the session timeline.
class ReportFiltersScreen extends StatefulWidget {
  const ReportFiltersScreen({super.key, this.scrollController});
  final ScrollController? scrollController;

  @override
  State<ReportFiltersScreen> createState() => _ReportFiltersScreenState();
}

class _ReportFiltersScreenState extends State<ReportFiltersScreen> {
  late List<String> _subjects;
  late String _subject;
  late List<String> _batchTargets;
  late String _batchTarget;
  List<Map<String, dynamic>> _globalSlots = [];

  String _cleanSubject(String subject) {
    return subject.replaceAll(RegExp(r'\s*-\s*(Lecture|Normal|Practical|Lab|Tutorial)$', caseSensitive: false), '').trim();
  }

  void _initSubjects() {
    final myId = AmsGlobals.loggedInUser?.id;
    final timetableSubjects = AmsGlobals.timetableSlots.map((s) => _cleanSubject(s['subject'] as String)).toList();
    // Only include subjects from sessions where this faculty is the actual teacher (not a proxy)
    final customSubjects = AmsGlobals.facultySessions
        .where((s) => s.facultyId == myId)
        .map((s) => _cleanSubject(s.courseCode))
        .toList();
    
    _subjects = [...timetableSubjects, ...customSubjects].toSet().toList();
    _subjects.sort();
    if (_subjects.isEmpty) _subjects = ['No Subjects'];
    _subject = _subjects.first;
  }

  Future<void> _fetchGlobalSubjectsForCoordinator() async {
    final user = AmsGlobals.loggedInUser;
    if (user != null && user.isCoordinator) {
      try {
        final res = await httpClient.get(Uri.parse('$baseUrl/timetable'));
        if (res.statusCode == 200) {
          final List<dynamic> data = jsonDecode(res.body);
          _globalSlots = data.map((e) => e as Map<String, dynamic>).toList();
          final globalSubjects = _globalSlots.map((s) => _cleanSubject(s['subject'] as String)).toList();
          if (mounted) {
            setState(() {
              _subjects = [..._subjects, ...globalSubjects].toSet().toList();
              _subjects.sort();
              _subject = _subjects.first;
              _updateBatchTargets();
            });
          }
        }
      } catch (e) {
        print('Error fetching global subjects for coordinator: $e');
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _initSubjects();
    _updateBatchTargets();
    _fetchGlobalSubjectsForCoordinator();
  }

  void _updateBatchTargets() {
    final myId = AmsGlobals.loggedInUser?.id;
    final timetableBatches = AmsGlobals.timetableSlots
        .where((s) => _cleanSubject(s['subject']) == _subject)
        .map((s) => (s['batchTarget'] as String?) ?? 'All')
        .toList();
        
    // Only include batches from sessions where this faculty is the actual teacher (not a proxy)
    final customBatches = AmsGlobals.facultySessions
        .where((s) => s.facultyId == myId && _cleanSubject(s.courseCode) == _subject)
        .map((s) => s.batchTarget ?? 'All')
        .toList();

    final globalBatches = _globalSlots
        .where((s) => _cleanSubject(s['subject']) == _subject)
        .map((s) => (s['batchTarget'] as String?) ?? 'All')
        .toList();

    _batchTargets = [...timetableBatches, ...customBatches, ...globalBatches].toSet().toList();
    _batchTargets.sort();
    if (_batchTargets.isEmpty) _batchTargets = ['All'];
    _batchTarget = _batchTargets.first;
  }

  void _continueToTimeline() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ReportTimelineScreen(
          subject: _subject,
          batchTarget: _batchTarget,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.vesitGray,
      body: SafeArea(
        child: Column(
          children: [
            _ReportFiltersHeader(onBack: () => Navigator.of(context).maybePop()),
            Expanded(
              child: SingleChildScrollView(
                controller: widget.scrollController,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const _ProgressDots(step: 0, total: 3),
                    const SizedBox(height: 8),
                    VesitCard(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          ConfigCard(
                            label: 'Subject Name',
                            child: DebossedDropdown<String>(
                              value: _subject,
                              items: _subjects,
                              itemLabel: (v) => v,
                              onChanged: (v) {
                                setState(() {
                                  _subject = v!;
                                  _updateBatchTargets();
                                });
                              },
                            ),
                          ),
                          const SizedBox(height: 16),
                          ConfigCard(
                            label: 'Batch',
                            child: DebossedDropdown<String>(
                              value: _batchTarget,
                              items: _batchTargets,
                              itemLabel: (v) {
                                // Format from "D15A - Batch A" to "D15-A batch-A"
                                if (v == 'All') return 'All';
                                return v
                                  .replaceAllMapped(RegExp(r'^([A-Z0-9]+)\s*-\s*Batch\s*([A-Z0-9]+)$', caseSensitive: false), (m) {
                                    final d = m[1]!;
                                    // Insert hyphen in division e.g. D15A -> D15-A
                                    final div = d.length > 3 ? '${d.substring(0, d.length - 1)}-${d.substring(d.length - 1)}' : d;
                                    return '$div batch-${m[2]}';
                                  })
                                  .replaceAllMapped(RegExp(r'^([A-Z0-9]+)\s*-\s*All$', caseSensitive: false), (m) {
                                    final d = m[1]!;
                                    final div = d.length > 3 ? '${d.substring(0, d.length - 1)}-${d.substring(d.length - 1)}' : d;
                                    return '$div All';
                                  });
                              },
                              onChanged: (v) => setState(() => _batchTarget = v!),
                            ),
                          ),
                          const SizedBox(height: 20),
                          PushableButton(
                            label: 'Continue to Timeline',
                            icon: Icons.arrow_forward,
                            onPressed: _continueToTimeline,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Step 1 of 3: Select the target class to generate an attendance report.',
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

class _ReportFiltersHeader extends StatelessWidget {
  const _ReportFiltersHeader({required this.onBack});

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
              'Report Details',
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

class _ProgressDots extends StatelessWidget {
  const _ProgressDots({required this.step, required this.total});

  final int step;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(total, (i) {
        final active = i == step;
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: 48,
          height: 8,
          decoration: BoxDecoration(
            color: active ? context.colors.vesitPrimary : Colors.grey.shade300,
            borderRadius: BorderRadius.circular(999),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(active ? 0.3 : 0.1), blurRadius: 2, offset: const Offset(0, 1)),
            ],
          ),
        );
      }),
    );
  }
}
