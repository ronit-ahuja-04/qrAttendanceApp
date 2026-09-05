import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/tactile_widgets.dart';
import '../widgets/vesit_widgets.dart';
import '../ams/globals.dart';
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

  void _initSubjects() {
    final timetableSubjects = AmsGlobals.timetableSlots.map((s) => s['subject'] as String).toList();
    final customSubjects = AmsGlobals.facultySessions.map((s) => s.courseCode).toList();
    
    _subjects = [...timetableSubjects, ...customSubjects].toSet().toList();
    if (_subjects.isEmpty) _subjects = ['No Subjects'];
    _subject = _subjects.first;
  }

  @override
  void initState() {
    super.initState();
    _initSubjects();
    _updateBatchTargets();
  }

  void _updateBatchTargets() {
    final timetableBatches = AmsGlobals.timetableSlots
        .where((s) => s['subject'] == _subject)
        .map((s) => (s['batchTarget'] as String?) ?? 'All')
        .toList();
        
    final customBatches = AmsGlobals.facultySessions
        .where((s) => s.courseCode == _subject)
        .map((s) => s.batchTarget ?? 'All')
        .toList();

    _batchTargets = [...timetableBatches, ...customBatches].toSet().toList();
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
                            label: 'Batch / Target',
                            child: DebossedDropdown<String>(
                              value: _batchTarget,
                              items: _batchTargets,
                              itemLabel: (v) => v,
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
