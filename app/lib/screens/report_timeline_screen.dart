import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/tactile_widgets.dart';
import 'generate_report_screen.dart';

enum ReportTimeline { weekly, monthly, semester }

extension on ReportTimeline {
  String get title {
    switch (this) {
      case ReportTimeline.weekly:
        return 'Weekly Report';
      case ReportTimeline.monthly:
        return 'Monthly Report';
      case ReportTimeline.semester:
        return 'Current Semester';
    }
  }

  String get subtitle {
    switch (this) {
      case ReportTimeline.weekly:
        return 'Last 7 days of attendance';
      case ReportTimeline.monthly:
        return 'Current calendar month';
      case ReportTimeline.semester:
        return 'Full semester aggregate';
    }
  }
}

/// "Select Timeline" — Step 2 of 3 in the Generate Report flow. Mirrors the
/// "Generate Report - Step 2" Stitch mockup (code.html): a raised card of
/// radio-style timeline options (Weekly / Monthly / Semester) and a sticky
/// bottom "GENERATE REPORT" action.
class ReportTimelineScreen extends StatefulWidget {
  const ReportTimelineScreen({super.key});

  @override
  State<ReportTimelineScreen> createState() => _ReportTimelineScreenState();
}

class _ReportTimelineScreenState extends State<ReportTimelineScreen> {
  ReportTimeline _selected = ReportTimeline.monthly;

  void _generateReport() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const GenerateReportScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                _ReportTimelineHeader(onBack: () => Navigator.of(context).maybePop()),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 140),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: const [
                          BoxShadow(color: Colors.white, offset: Offset(0, 1)),
                          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 4)),
                        ],
                      ),
                      child: Column(
                        children: [
                          for (final option in ReportTimeline.values) ...[
                            _TimelineOption(
                              timeline: option,
                              selected: _selected == option,
                              onTap: () => setState(() => _selected = option),
                            ),
                            if (option != ReportTimeline.values.last) const SizedBox(height: 12),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppColors.surface.withOpacity(0),
                      AppColors.surface,
                      AppColors.surface,
                    ],
                  ),
                ),
                child: Column(
                  children: [
                    PushableButton(
                      label: 'Generate Report',
                      icon: Icons.description,
                      onPressed: _generateReport,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Report will be exported as a downloadable spreadsheet.',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.labelSm,
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

class _TimelineOption extends StatelessWidget {
  const _TimelineOption({
    required this.timeline,
    required this.selected,
    required this.onTap,
  });

  final ReportTimeline timeline;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected ? AppColors.surface : AppColors.surfaceContainer,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.primaryContainer : Colors.transparent,
            width: 2,
          ),
          boxShadow: selected
              ? [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 4, offset: const Offset(0, 2))]
              : null,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(timeline.title, style: AppTextStyles.labelBold.copyWith(color: AppColors.onSurface)),
                  const SizedBox(height: 4),
                  Text(timeline.subtitle, style: AppTextStyles.bodyMd.copyWith(color: AppColors.onSurfaceVariant, fontSize: 13)),
                ],
              ),
            ),
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.debossedWell,
                border: Border.all(
                  color: selected ? AppColors.primaryContainer : AppColors.outline,
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 3, offset: const Offset(0, 2)),
                ],
              ),
              alignment: Alignment.center,
              child: selected
                  ? Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primaryContainer,
                        boxShadow: [
                          BoxShadow(color: AppColors.primaryContainer.withOpacity(0.5), blurRadius: 8),
                        ],
                      ),
                    )
                  : null,
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
              'Select Timeline',
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
