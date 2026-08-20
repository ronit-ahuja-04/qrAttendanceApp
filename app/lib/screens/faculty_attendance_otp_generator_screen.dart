import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../ams/api_services.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/tactile_widgets.dart';
import 'verify_attendance_screen.dart';
import '../ams/globals.dart';
import '../ams/models.dart';

/// "Generate Attendance OTP" — shown after a faculty member configures a
/// session and taps "Generate OTP". Displays the live, auto-expiring code
/// for students to key in, plus a running tally of who has checked in.
/// Mirrors the "faculty_otp_attendance_generator" Stitch mockup.
class FacultyAttendanceOtpGeneratorScreen extends StatefulWidget {
  const FacultyAttendanceOtpGeneratorScreen({
    super.key,
    this.subjectTitle = 'Java Programming — CS-302',
    this.sessionSubtitle = 'Lab 402 • 09:00 - 10:30 AM • Div: D10A',
    this.totalStudents = 25,
    this.otpValiditySeconds = 30,
  });

  /// e.g. "Java Programming — CS-302"
  final String subjectTitle;

  /// e.g. "Lab 402 • 09:00 - 10:30 AM • Div: D10A"
  final String sessionSubtitle;

  /// Total students enrolled in this division, for the live-attendance bar.
  final int totalStudents;

  /// How many seconds each generated OTP stays valid for.
  final int otpValiditySeconds;

  @override
  State<FacultyAttendanceOtpGeneratorScreen> createState() =>
      _FacultyAttendanceOtpGeneratorScreenState();
}

class _FacultyAttendanceOtpGeneratorScreenState
    extends State<FacultyAttendanceOtpGeneratorScreen> {
  late AttendanceSession _session;
  late String _otp;
  late int _secondsLeft;
  bool _autoRefresh = true; // Auto-refresh is ON by default to prevent cheating
  int _presentCount = 0;
  List<String> _presentStudentNames = [];
  Timer? _timer;
  Timer? _pollingTimer;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initSession();
  }

  Future<void> _initSession() async {
    try {
      var session = await AmsGlobals.sessionService.createSession(
        courseCode: widget.subjectTitle,
        facultyId: AmsGlobals.loggedInUser?.id ?? 'faculty-01',
        enrolledStudentIds: List.generate(26, (i) => 'student-${i.toString().padLeft(2, '0')}'),
      );
      
      final result = await AmsGlobals.sessionService.startSession(session.id, widget.otpValiditySeconds);
      if (result.ok) {
        session = result.value!;
      }
      _session = session;
      AmsGlobals.activeSessionId = _session.id;

      _otp = _session.otp?.code ?? '000000';
      _secondsLeft = widget.otpValiditySeconds;
      _presentCount = 0;
      
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _startTimer();
        _startPolling();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to initialize session: $e')));
        Navigator.of(context).maybePop();
      }
    }
  }

  void _startPolling() {
    _pollingTimer = Timer.periodic(const Duration(seconds: 1), (_) async {
      if (!mounted) return;
      try {
        final records = await AmsGlobals.attendanceService.recordsDetailsFor(_session.id);
        if (records.length != _presentCount && mounted) {
          setState(() {
            _presentCount = records.length;
            _presentStudentNames = records.map((r) => r.studentName ?? 'Unknown').toList();
          });
        }
      } catch (e) {
        print("POLLING ERROR: $e");
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pollingTimer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) async {
      if (!mounted) {
        t.cancel();
        return;
      }
      if (_secondsLeft > 0) {
        setState(() {
          _secondsLeft--;
        });
      } else {
        // Rotate OTP
        final result = await AmsGlobals.sessionService.rotateOtp(_session.id, widget.otpValiditySeconds);
        if (result.ok && mounted) {
          setState(() {
            _session = result.value!;
            _otp = _session.otp?.code ?? "000000";
            _secondsLeft = widget.otpValiditySeconds;
          });
        }
      }
    });
  }

  void _setAutoRefresh(bool value) {
    setState(() => _autoRefresh = value);
    if (value && (_timer == null || !_timer!.isActive)) {
      _secondsLeft = widget.otpValiditySeconds;
      _startTimer();
    }
  }

  void _closeSession() {
    _timer?.cancel();
    _pollingTimer?.cancel();
    AmsGlobals.sessionService.closeSession(_session.id);
    AmsGlobals.activeSessionId = null;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => VerifyAttendanceScreen(sessionId: _session.id)),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.surface,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final progress = widget.totalStudents == 0
        ? 0.0
        : (_presentCount / widget.totalStudents).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Column(
          children: [
            _GeneratorHeader(onBack: () => Navigator.of(context).maybePop()),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _ClassDetailsCard(
                      title: widget.subjectTitle,
                      subtitle: widget.sessionSubtitle,
                      autoRefresh: _autoRefresh,
                      onToggle: _setAutoRefresh,
                    ),
                    const SizedBox(height: 16),
                    _OtpLiveCard(
                      sessionId: _session.id,
                      otp: _otp,
                      secondsLeft: _secondsLeft,
                      totalSeconds: widget.otpValiditySeconds,
                    ),
                    const SizedBox(height: 16),
                    _AttendanceProgressCard(
                      present: _presentCount,
                      total: widget.totalStudents,
                      progress: progress,
                    ),
                    const SizedBox(height: 16),
                    _PresentStudentsList(names: _presentStudentNames),
                    const SizedBox(height: 40),
                    _CloseSessionButton(onPressed: _closeSession),
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

class _GeneratorHeader extends StatelessWidget {
  const _GeneratorHeader({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.outlineVariant, width: 1)),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          PushSurfaceButton(
            onPressed: onBack,
            borderRadius: 10,
            child: const Padding(
              padding: EdgeInsets.all(8),
              child: Icon(Icons.arrow_back, color: AppColors.onSurfaceVariant),
            ),
          ),
          Expanded(
            child: Text(
              'Generate Attendance QR',
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.headlineSm.copyWith(fontSize: 18),
            ),
          ),
          PushSurfaceButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Ask students to enter the code shown on this screen.'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            borderRadius: 10,
            child: const Padding(
              padding: EdgeInsets.all(8),
              child: Icon(Icons.help_outline, color: AppColors.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }
}

class _ClassDetailsCard extends StatelessWidget {
  const _ClassDetailsCard({
    required this.title,
    required this.subtitle,
    required this.autoRefresh,
    required this.onToggle,
  });

  final String title;
  final String subtitle;
  final bool autoRefresh;
  final ValueChanged<bool> onToggle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.outline.withOpacity(0.2)),
        boxShadow: const [
          BoxShadow(color: Colors.white, offset: Offset(0, 1)),
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3)),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 2)),
                  ],
                ),
                child: const Icon(Icons.menu_book_outlined, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.labelBold.copyWith(color: AppColors.onSurface, fontSize: 14),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.labelSm,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              PushSurfaceButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Edit session — coming soon'), duration: Duration(seconds: 1)),
                  );
                },
                borderRadius: 8,
                child: const Padding(
                  padding: EdgeInsets.all(7),
                  child: Icon(Icons.edit_outlined, color: AppColors.onSurfaceVariant, size: 18),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: AppColors.outlineVariant),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.sync, color: AppColors.onSurfaceVariant, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Dynamic QR Auto-Refresh',
                  style: AppTextStyles.labelMd.copyWith(color: AppColors.onSurface),
                ),
              ),
              Switch(
                value: autoRefresh,
                onChanged: onToggle,
                activeColor: Colors.white,
                activeTrackColor: AppColors.primary,
                inactiveThumbColor: Colors.white,
                inactiveTrackColor: AppColors.outline,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OtpLiveCard extends StatelessWidget {
  const _OtpLiveCard({
    required this.sessionId,
    required this.otp,
    required this.secondsLeft,
    required this.totalSeconds,
  });

  final String sessionId;
  final String otp;
  final int secondsLeft;
  final int totalSeconds;

  @override
  Widget build(BuildContext context) {
    final spacedOtp = '${otp.substring(0, 3)}   ${otp.substring(3)}';
    final fraction = totalSeconds == 0 ? 0.0 : secondsLeft / totalSeconds;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.outline, width: 2),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 12, offset: const Offset(0, 6)),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              const PilotLight(active: true, size: 9),
              const SizedBox(width: 6),
              Text(
                'LIVE',
                style: AppTextStyles.labelSm.copyWith(
                  color: AppColors.primary,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'SCAN TO REGISTER',
            textAlign: TextAlign.center,
            style: AppTextStyles.labelMd.copyWith(letterSpacing: 1.5),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: QrImageView(
              data: jsonEncode({"s": sessionId, "o": otp, "t": DateTime.now().millisecondsSinceEpoch}),
              version: QrVersions.auto,
              size: 200.0,
              gapless: false,
              eyeStyle: const QrEyeStyle(
                eyeShape: QrEyeShape.square,
                color: Colors.black,
              ),
              dataModuleStyle: const QrDataModuleStyle(
                dataModuleShape: QrDataModuleShape.circle,
                color: Colors.black,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('QR EXPIRES IN:', style: AppTextStyles.labelSm),
              Text(
                '00:${secondsLeft.toString().padLeft(2, '0')}s',
                style: AppTextStyles.labelBold.copyWith(color: AppColors.error, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: Container(
              height: 10,
              decoration: BoxDecoration(
                color: AppColors.debossedWell,
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 4, offset: const Offset(0, 2)),
                ],
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: fraction.clamp(0.0, 1.0),
                child: Container(color: AppColors.error),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AttendanceProgressCard extends StatelessWidget {
  const _AttendanceProgressCard({
    required this.present,
    required this.total,
    required this.progress,
  });

  final int present;
  final int total;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final percent = total == 0 ? 0 : (progress * 100).round();
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.outline.withOpacity(0.2)),
        boxShadow: const [
          BoxShadow(color: Colors.white, offset: Offset(0, 1)),
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.groups_outlined, color: AppColors.onSurfaceVariant, size: 20),
                  const SizedBox(width: 8),
                  Text('Live Attendance', style: AppTextStyles.labelBold.copyWith(color: AppColors.onSurface)),
                ],
              ),
              DebossedWell(
                borderRadius: 6,
                child: Text('$present / $total', style: AppTextStyles.labelMd.copyWith(color: AppColors.onSurface)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Container(
              height: 16,
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: AppColors.debossedWell,
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 4, offset: const Offset(0, 2)),
                ],
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: progress.clamp(0.0, 1.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerRight,
            child: Text('$percent% Present', style: AppTextStyles.labelSm),
          ),
        ],
      ),
    );
  }
}

class _CloseSessionButton extends StatefulWidget {
  const _CloseSessionButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  State<_CloseSessionButton> createState() => _CloseSessionButtonState();
}

class _CloseSessionButtonState extends State<_CloseSessionButton> {
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
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: _pressed ? AppColors.debossedWell : AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.outline, width: 2),
          boxShadow: _pressed
              ? []
              : [
                  BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 2)),
                ],
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lock_outline, color: AppColors.onSurface, size: 18),
            const SizedBox(width: 8),
            Text(
              'CLOSE SESSION & LOCK',
              style: AppTextStyles.labelBold.copyWith(color: AppColors.onSurface, letterSpacing: 1.2),
            ),
          ],
        ),
      ),
    );
  }
}

class _PresentStudentsList extends StatelessWidget {
  const _PresentStudentsList({required this.names});
  final List<String> names;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.outline.withOpacity(0.2)),
        boxShadow: const [
          BoxShadow(color: Colors.white, offset: Offset(0, 1)),
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Present Students',
            style: AppTextStyles.labelBold.copyWith(color: AppColors.onSurface),
          ),
          const SizedBox(height: 12),
          if (names.isEmpty)
            Text('No students have marked attendance yet.', style: AppTextStyles.labelSm),
          ...names.map((name) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              children: [
                const Icon(Icons.check_circle, color: AppColors.primary, size: 16),
                const SizedBox(width: 8),
                Text(name, style: AppTextStyles.labelMd),
              ],
            ),
          )),
        ],
      ),
    );
  }
}
