import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'faculty_dashboard_screen.dart';

/// "Attendance Confirmed Success" — shown after a faculty member closes
/// and locks a session. Mirrors the Stitch "Attendance Confirmed Success"
/// mockup: a large debossed/raised badge with a check icon, a summary
/// sentence, a present/absent mini-card, and a single primary action
/// that returns to the dashboard.
class AttendanceSubmittedScreen extends StatelessWidget {
  const AttendanceSubmittedScreen({
    super.key,
    required this.subjectTitle,
    required this.presentCount,
    required this.absentCount,
  });

  /// e.g. "Java Programming (Div TE-A)"
  final String subjectTitle;
  final int presentCount;
  final int absentCount;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Column(
          children: [
            _CloseBar(
              onClose: () => Navigator.of(context).popUntil((r) => r.isFirst),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const _SuccessBadge(),
                    const SizedBox(height: 32),
                    Text(
                      'Attendance Submitted!',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.headlineMd.copyWith(color: AppColors.primary),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Session records for $subjectTitle have been locked and '
                      'synchronized with the central database.',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodyLg,
                    ),
                    const SizedBox(height: 40),
                    _SummaryPill(present: presentCount, absent: absentCount),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: _HomeButton(
                onPressed: () {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const FacultyDashboardScreen()),
                    (route) => false,
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

class _CloseBar extends StatelessWidget {
  const _CloseBar({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: IconButton(
          onPressed: onClose,
          icon: const Icon(Icons.close, color: AppColors.onSurfaceVariant, size: 28),
          splashRadius: 24,
        ),
      ),
    );
  }
}

class _SuccessBadge extends StatelessWidget {
  const _SuccessBadge();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 192,
      height: 192,
      child: Center(
        child: Container(
          width: 192,
          height: 192,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.surfaceContainer,
            border: Border.all(color: AppColors.outlineVariant.withOpacity(0.3)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
                spreadRadius: -2,
              ),
            ],
          ),
          child: Center(
            child: Container(
              width: 144,
              height: 144,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.surfaceContainerLow,
                border: Border.all(color: AppColors.outlineVariant.withOpacity(0.5)),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 15, offset: const Offset(0, 10)),
                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6, offset: const Offset(0, 4)),
                  const BoxShadow(color: Colors.white, blurRadius: 0, offset: Offset(0, 2)),
                ],
              ),
              child: Center(
                child: Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primary.withOpacity(0.05),
                  ),
                  child: const Icon(Icons.check_circle, color: AppColors.primary, size: 80),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SummaryPill extends StatelessWidget {
  const _SummaryPill({required this.present, required this.absent});

  final int present;
  final int absent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outlineVariant, width: 2),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 4, offset: const Offset(0, 2)),
          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 6, offset: const Offset(0, 1)),
          const BoxShadow(color: Colors.white, blurRadius: 0, offset: Offset(0, 1)),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.groups, color: AppColors.primary, size: 20),
          const SizedBox(width: 12),
          Text(
            '$present Present • $absent Absent',
            style: AppTextStyles.labelBold.copyWith(letterSpacing: 1.2),
          ),
        ],
      ),
    );
  }
}

class _HomeButton extends StatefulWidget {
  const _HomeButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  State<_HomeButton> createState() => _HomeButtonState();
}

class _HomeButtonState extends State<_HomeButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) => setState(() => _pressed = false),
      onTap: widget.onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        width: double.infinity,
        height: 56,
        transform: Matrix4.translationValues(0, _pressed ? 2 : 0, 0),
        decoration: BoxDecoration(
          color: _pressed ? AppColors.debossedWell : AppColors.primaryContainer,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.primaryContainer.withOpacity(0.2)),
          boxShadow: _pressed
              ? [const BoxShadow(color: Color(0x33000000), blurRadius: 2)]
              : [
                  BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 6, offset: const Offset(0, 3)),
                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 1)),
                  const BoxShadow(color: Colors.white, blurRadius: 0, offset: Offset(0, 1)),
                ],
        ),
        alignment: Alignment.center,
        child: Text(
          'GO TO HOME DASHBOARD',
          style: AppTextStyles.labelBold.copyWith(
            color: AppColors.onPrimaryContainer,
            fontSize: 15,
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }
}
