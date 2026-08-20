import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/tactile_widgets.dart';

class _MonthBar {
  const _MonthBar(this.label, this.heightFraction);
  final String label;
  final double heightFraction;
}

class _SubjectStat {
  const _SubjectStat(this.name, this.attended, this.total);
  final String name;
  final int attended;
  final int total;

  double get percent => total == 0 ? 0 : attended / total;
  bool get isLow => percent < 0.75;
}

/// "Statistics & Insights" — mirrors the "Detailed Attendance Statistics"
/// Stitch mockup (code.html): a radial overall-percentage ring, a quick
/// metrics grid, a monthly trend bar chart, and a per-subject breakdown.
class AttendanceStatisticsScreen extends StatelessWidget {
  const AttendanceStatisticsScreen({super.key});

  static const _months = [
    _MonthBar('July', 0.80),
    _MonthBar('Aug', 0.95),
    _MonthBar('Sept', 0.88),
    _MonthBar('Oct', 0.89),
  ];

  static const _subjects = [
    _SubjectStat('Java Programming', 23, 25),
    _SubjectStat('Computer Networks', 14, 20),
    _SubjectStat('Database Systems', 22, 25),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Column(
          children: [
            _StatisticsHeader(onBack: () => Navigator.of(context).maybePop()),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                children: [
                  const Row(
                    children: [
                      Expanded(child: _StatCard(label: 'Overall', value: '89.0%')),
                      SizedBox(width: 16),
                      Expanded(child: _StatCard(label: 'This Week', value: '92.0%')),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const _MonthlyTrendCard(months: _months, thresholdFraction: 0.75),
                  const SizedBox(height: 16),
                  Text(
                    'SUBJECT BREAKDOWN',
                    style: AppTextStyles.headlineSm.copyWith(fontSize: 20, letterSpacing: 0.6),
                  ),
                  const SizedBox(height: 10),
                  for (final subject in _subjects) ...[
                    _SubjectRow(subject: subject),
                    const SizedBox(height: 12),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatisticsHeader extends StatelessWidget {
  const _StatisticsHeader({required this.onBack});

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
              child: Icon(Icons.arrow_back, color: AppColors.onSurface),
            ),
          ),
          Expanded(
            child: Text(
              'Statistics & Insights',
              textAlign: TextAlign.center,
              style: AppTextStyles.headlineSm.copyWith(color: AppColors.primary),
              overflow: TextOverflow.ellipsis,
            ),
          ),

        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return RaisedPanel(
      borderRadius: 16,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
      child: Column(
        children: [
          Text(
            label.toUpperCase(),
            style: AppTextStyles.labelMd.copyWith(fontSize: 12, letterSpacing: 0.8),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'FamiljenGrotesk',
              fontSize: 40,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class _MonthlyTrendCard extends StatelessWidget {
  const _MonthlyTrendCard({required this.months, required this.thresholdFraction});

  final List<_MonthBar> months;
  final double thresholdFraction;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outlineVariant),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Monthly Trend', style: AppTextStyles.labelBold),
          const SizedBox(height: 12),
          SizedBox(
            height: 150,
            child: Stack(
              children: [
                Positioned(
                  left: 0,
                  right: 0,
                  top: 150 * (1 - thresholdFraction) - 24,
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 1,
                          decoration: const BoxDecoration(
                            border: Border(top: BorderSide(color: AppColors.outlineVariant, width: 1)),
                          ),
                        ),
                      ),
                      Text(' 75% Min', style: AppTextStyles.labelSm.copyWith(fontSize: 10)),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 22),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      for (final month in months)
                        Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Container(
                              width: 32,
                              height: 104 * month.heightFraction,
                              decoration: const BoxDecoration(
                                color: AppColors.primaryContainer,
                                borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      for (final month in months)
                        Text(month.label, style: AppTextStyles.labelSm),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SubjectRow extends StatelessWidget {
  const _SubjectRow({required this.subject});

  final _SubjectStat subject;

  @override
  Widget build(BuildContext context) {
    final color = subject.isLow ? AppColors.error : AppColors.primary;
    final barColor = subject.isLow ? AppColors.errorContainer : AppColors.primaryContainer;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.outlineVariant),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(subject.name, style: AppTextStyles.labelBold.copyWith(color: AppColors.onSurface)),
              ),
              Row(
                children: [
                  if (subject.isLow) ...[
                    const Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 16),
                    const SizedBox(width: 4),
                  ],
                  Text(
                    '${(subject.percent * 100).round()}%',
                    style: TextStyle(
                      fontFamily: 'FamiljenGrotesk',
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '(${subject.attended}/${subject.total})',
                    style: AppTextStyles.labelSm,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: SizedBox(
              height: 8,
              child: Stack(
                children: [
                  Container(color: AppColors.debossedWell),
                  FractionallySizedBox(
                    widthFactor: subject.percent.clamp(0, 1),
                    child: Container(color: barColor),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
