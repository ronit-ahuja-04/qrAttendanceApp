import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'attendance_submitted_screen.dart';
import 'account_settings_screen.dart';
import '../ams/globals.dart';

enum _MarkStatus { present, absent, unmarked }

class _StudentRow {
  _StudentRow({
    required this.rollNo,
    required this.name,
    required this.status,
    required this.method,
  });

  final String rollNo;
  final String name;
  _MarkStatus status;
  final String method;
}

/// "Verify Attendance" — the faculty review step shown after a session's
/// live OTP window closes. Lets faculty override any student's P/A mark
/// before locking the session. Mirrors the "verify_attendance" Stitch
/// mockup.
class VerifyAttendanceScreen extends StatefulWidget {
  const VerifyAttendanceScreen({
    super.key,
    required this.sessionId,
    this.subjectTitle = 'DBMS',
    this.divisionLabel = 'DIV : D10A',
  });

  final String sessionId;
  final String subjectTitle;
  final String divisionLabel;

  @override
  State<VerifyAttendanceScreen> createState() => _VerifyAttendanceScreenState();
}

class _VerifyAttendanceScreenState extends State<VerifyAttendanceScreen> {
  List<_StudentRow> _students = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchVerificationList();
  }

  Future<void> _fetchVerificationList() async {
    final list = await AmsGlobals.sessionService.getVerificationList(widget.sessionId);
    if (!mounted) return;
    setState(() {
      _students = list.map((item) => _StudentRow(
        rollNo: item['rollNo'] ?? 'N/A',
        name: item['name'] ?? 'Unknown',
        status: item['status'] == 'present' ? _MarkStatus.present : _MarkStatus.absent,
        method: item['method'] ?? 'Not Marked / Timeout',
      )).toList();
      _isLoading = false;
    });
  }

  int get _presentCount => _students.where((s) => s.status == _MarkStatus.present).length;

  void _setStatus(_StudentRow row, _MarkStatus status) {
    setState(() => row.status = status);
  }

  void _confirmAndSubmit() {
    final total = _students.length;
    final present = _presentCount;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => AttendanceSubmittedScreen(
          subjectTitle: '${widget.subjectTitle} (${widget.divisionLabel.replaceAll('DIV : ', 'Div ')})',
          presentCount: present,
          absentCount: total - present,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final total = _students.length;
    final present = _presentCount;
    final percent = total == 0 ? 0 : ((present / total) * 100).round();

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Column(
          children: [
            _VerifyHeader(
              title: 'Verify Attendance',
              subtitle: '${widget.subjectTitle} | ${widget.divisionLabel}',
              onBack: () => Navigator.of(context).maybePop(),
              onSettings: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AccountSettingsScreen()),
                );
              },
            ),
            if (_isLoading)
              const Expanded(child: Center(child: CircularProgressIndicator()))
            else
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _SummaryBar(present: present, total: total, percent: percent),
                      const SizedBox(height: 12),
                      ..._students.map(
                        (row) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _StudentTile(
                            row: row,
                            onSetStatus: (status) => _setStatus(row, status),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (!_isLoading) _ConfirmBar(onPressed: _confirmAndSubmit),
          ],
        ),
      ),
    );
  }
}

class _VerifyHeader extends StatelessWidget {
  const _VerifyHeader({
    required this.title,
    required this.subtitle,
    required this.onBack,
    required this.onSettings,
  });

  final String title;
  final String subtitle;
  final VoidCallback onBack;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      color: AppColors.surface,
      child: Row(
        children: [
          _RoundIconButton(icon: Icons.arrow_back, onPressed: onBack),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title, style: AppTextStyles.headlineSm),
                Text(subtitle, style: AppTextStyles.labelSm),
              ],
            ),
          ),
          _RoundIconButton(icon: Icons.settings, onPressed: onSettings),
        ],
      ),
    );
  }
}

class _RoundIconButton extends StatefulWidget {
  const _RoundIconButton({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback onPressed;

  @override
  State<_RoundIconButton> createState() => _RoundIconButtonState();
}

class _RoundIconButtonState extends State<_RoundIconButton> {
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
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _pressed ? AppColors.debossedWell : AppColors.surfaceContainerLow,
          border: Border.all(color: AppColors.outlineVariant),
          boxShadow: _pressed
              ? [const BoxShadow(color: Color(0x33000000), blurRadius: 4, offset: Offset(0, 1))]
              : [
                  const BoxShadow(color: Colors.white, offset: Offset(0, 1)),
                  BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 4, offset: const Offset(0, 2)),
                ],
        ),
        child: Icon(widget.icon, color: AppColors.onSurface, size: 20),
      ),
    );
  }
}

class _SummaryBar extends StatelessWidget {
  const _SummaryBar({required this.present, required this.total, required this.percent});

  final int present;
  final int total;
  final int percent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        border: Border.all(color: AppColors.outline),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          const BoxShadow(color: Colors.white, offset: Offset(0, 1)),
          BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 4, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'DIVISION A - ATTENDANCE SUMMARY',
            style: AppTextStyles.labelBold.copyWith(letterSpacing: 1),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              RichText(
                text: TextSpan(
                  style: AppTextStyles.headlineMd.copyWith(color: AppColors.primary),
                  children: [
                    TextSpan(text: '$present '),
                    TextSpan(
                      text: '/ $total Present',
                      style: TextStyle(color: AppColors.onSurfaceVariant, fontSize: 20, fontWeight: FontWeight.w400),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '$percent% RATE',
                  style: AppTextStyles.labelBold.copyWith(color: AppColors.onPrimaryContainer),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: Container(
              height: 8,
              color: AppColors.errorContainer,
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: total == 0 ? 0 : (present / total).clamp(0.0, 1.0),
                child: Container(color: const Color(0xFF22C55E)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StudentTile extends StatelessWidget {
  const _StudentTile({required this.row, required this.onSetStatus});

  final _StudentRow row;
  final ValueChanged<_MarkStatus> onSetStatus;

  @override
  Widget build(BuildContext context) {
    final IconData statusIcon;
    final Color statusColor;
    switch (row.status) {
      case _MarkStatus.present:
        statusIcon = Icons.check_circle;
        statusColor = const Color(0xFF15803D);
        break;
      case _MarkStatus.absent:
        statusIcon = Icons.cancel;
        statusColor = const Color(0xFF93000A);
        break;
      case _MarkStatus.unmarked:
        statusIcon = Icons.help;
        statusColor = AppColors.onSurfaceVariant;
        break;
    }

    return Opacity(
      opacity: row.status == _MarkStatus.unmarked ? 0.75 : 1,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLow,
          border: Border.all(color: AppColors.outlineVariant),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            const BoxShadow(color: Colors.white, offset: Offset(0, 1)),
            BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 4, offset: const Offset(0, 2)),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(6),
                boxShadow: const [
                  BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2), spreadRadius: -1),
                ],
              ),
              child: Text(row.rollNo, style: AppTextStyles.labelBold.copyWith(fontSize: 12)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    row.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.labelBold.copyWith(color: AppColors.onSurface, fontSize: 13),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 14, color: statusColor),
                      const SizedBox(width: 4),
                      Text(row.method, style: AppTextStyles.labelSm.copyWith(color: statusColor)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.outlineVariant),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 3, offset: const Offset(0, 1)),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _PAButton(
                    label: 'P',
                    active: row.status == _MarkStatus.present,
                    activeBg: const Color(0xFFD4EDDA),
                    activeFg: const Color(0xFF155724),
                    onTap: () => onSetStatus(_MarkStatus.present),
                  ),
                  _PAButton(
                    label: 'A',
                    active: row.status == _MarkStatus.absent,
                    activeBg: AppColors.errorContainer,
                    activeFg: const Color(0xFF93000A),
                    onTap: () => onSetStatus(_MarkStatus.absent),
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

class _PAButton extends StatelessWidget {
  const _PAButton({
    required this.label,
    required this.active,
    required this.activeBg,
    required this.activeFg,
    required this.onTap,
  });

  final String label;
  final bool active;
  final Color activeBg;
  final Color activeFg;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: active ? activeBg : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: active
              ? [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 2, offset: const Offset(0, 1))]
              : null,
        ),
        child: Text(
          label,
          style: AppTextStyles.labelBold.copyWith(
            color: active ? activeFg : AppColors.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

class _ConfirmBar extends StatefulWidget {
  const _ConfirmBar({required this.onPressed});

  final VoidCallback onPressed;

  @override
  State<_ConfirmBar> createState() => _ConfirmBarState();
}

class _ConfirmBarState extends State<_ConfirmBar> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
      color: AppColors.surface,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapCancel: () => setState(() => _pressed = false),
        onTapUp: (_) => setState(() => _pressed = false),
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          transform: Matrix4.translationValues(0, _pressed ? 2 : 0, 0),
          decoration: BoxDecoration(
            color: _pressed ? AppColors.debossedWell : AppColors.primaryContainer,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.outlineVariant),
            boxShadow: _pressed
                ? [const BoxShadow(color: Color(0x33000000), blurRadius: 4)]
                : [
                    const BoxShadow(color: Colors.white, offset: Offset(0, 1)),
                    BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 4, offset: const Offset(0, 2)),
                  ],
          ),
          alignment: Alignment.center,
          child: Text(
            'CONFIRM & SUBMIT ATTENDANCE',
            style: AppTextStyles.labelBold.copyWith(
              color: AppColors.onPrimaryContainer,
              fontSize: 15,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }
}
