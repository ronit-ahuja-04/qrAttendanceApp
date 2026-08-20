import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/tactile_widgets.dart';
import 'report_timeline_screen.dart';

/// "Report Details" — Step 1 of 3 in the Generate Report flow. Mirrors the
/// "Generate Report - Step 1" Stitch mockup (code.html): Division and
/// Subject dropdowns inside a raised card, a 3-dot progress indicator, and
/// a "CONTINUE TO TIMELINE" action that proceeds to the session timeline.
class ReportFiltersScreen extends StatefulWidget {
  const ReportFiltersScreen({super.key});

  @override
  State<ReportFiltersScreen> createState() => _ReportFiltersScreenState();
}

class _ReportFiltersScreenState extends State<ReportFiltersScreen> {
  static const _divisions = [
    'TE - Division A',
    'TE - Division B',
    'BE - Division A',
  ];
  static const _subjects = [
    'Java Programming',
    'Database Management',
    'Operating Systems',
  ];

  String _division = _divisions.first;
  String _subject = _subjects.first;

  void _continueToTimeline() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const ReportTimelineScreen(),
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
            _ReportFiltersHeader(onBack: () => Navigator.of(context).maybePop()),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const _ProgressDots(step: 0, total: 3),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.outlineVariant, width: 1),
                        boxShadow: const [
                          BoxShadow(color: Colors.white, offset: Offset(0, 1)),
                          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 4)),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          ConfigCard(
                            label: 'Division',
                            child: DebossedDropdown<String>(
                              value: _division,
                              items: _divisions,
                              itemLabel: (v) => v,
                              onChanged: (v) => setState(() => _division = v!),
                            ),
                          ),
                          const SizedBox(height: 16),
                          ConfigCard(
                            label: 'Subject Name',
                            child: DebossedDropdown<String>(
                              value: _subject,
                              items: _subjects,
                              itemLabel: (v) => v,
                              onChanged: (v) => setState(() => _subject = v!),
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
                      style: AppTextStyles.labelSm.copyWith(color: AppColors.onSurfaceVariant),
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
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.outlineVariant, width: 1)),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          PushSurfaceButton(
            onPressed: onBack,
            borderRadius: 999,
            child: const Padding(
              padding: EdgeInsets.all(8),
              child: Icon(Icons.arrow_back, color: AppColors.primary),
            ),
          ),
          Expanded(
            child: Text(
              'Report Details',
              textAlign: TextAlign.center,
              style: AppTextStyles.headlineSm.copyWith(color: AppColors.primary),
            ),
          ),
          const SizedBox(width: 40), // balances the back button
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
            color: active ? AppColors.primary : AppColors.surfaceContainerHigh,
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
