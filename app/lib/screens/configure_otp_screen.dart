import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/tactile_widgets.dart';
import 'faculty_attendance_otp_generator_screen.dart';

/// "Configure OTP" — the faculty form that sets up a class session before
/// a dynamic, auto-expiring attendance code is generated. Mirrors the
/// "configure_otp_session" Stitch mockup: Division, Subject, Lecture
/// Timing, and Room fields inside raised module cards, topped off with a
/// full-width "Generate OTP" action.
class ConfigureOtpScreen extends StatefulWidget {
  const ConfigureOtpScreen({super.key});

  @override
  State<ConfigureOtpScreen> createState() => _ConfigureOtpScreenState();
}

class _ConfigureOtpScreenState extends State<ConfigureOtpScreen> {
  static const _divisions = [
    'Division TE-A (Computer Engg)',
    'Division TE-B (Computer Engg)',
    'Division SE-A (IT)',
  ];
  static const _subjects = [
    'Java Programming — CS-302',
    'Data Structures — CS-201',
    'Operating Systems — CS-305',
  ];
  static const _timings = [
    '09:30 AM – 10:30 AM (60 Mins)',
    '10:30 AM – 11:30 AM (60 Mins)',
    '11:30 AM – 01:30 PM (120 Mins)',
  ];

  String _division = _divisions.first;
  String _subject = _subjects.first;
  String _timing = _timings.first;
  final _roomController = TextEditingController(text: 'Lab 402');

  @override
  void dispose() {
    _roomController.dispose();
    super.dispose();
  }

  void _generateOtp() {
    // Pull the short division code out of "Division TE-A (Computer Engg)"
    // style labels so the next screen's subtitle stays compact.
    final divMatch = RegExp(r'Division\s+([^\s(]+)').firstMatch(_division);
    final divCode = divMatch != null ? divMatch.group(1)! : _division;

    // "09:30 AM – 10:30 AM (60 Mins)" -> "09:30 AM – 10:30 AM"
    final timingShort = _timing.replaceAll(RegExp(r'\s*\(.*\)\s*$'), '');

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => FacultyAttendanceOtpGeneratorScreen(
          subjectTitle: _subject,
          sessionSubtitle: '${_roomController.text} • $timingShort • Div: $divCode',
        ),
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
            _ConfigureOtpHeader(onBack: () => Navigator.of(context).maybePop()),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ConfigCard(
                      label: 'Division / Class Group',
                      child: DebossedDropdown<String>(
                        value: _division,
                        items: _divisions,
                        itemLabel: (v) => v,
                        onChanged: (v) => setState(() => _division = v!),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ConfigCard(
                      label: 'Subject & Course Code',
                      child: DebossedDropdown<String>(
                        value: _subject,
                        items: _subjects,
                        itemLabel: (v) => v,
                        onChanged: (v) => setState(() => _subject = v!),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ConfigCard(
                      label: 'Lecture Timing & Duration',
                      child: DebossedDropdown<String>(
                        value: _timing,
                        items: _timings,
                        itemLabel: (v) => v,
                        icon: Icons.schedule,
                        onChanged: (v) => setState(() => _timing = v!),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ConfigCard(
                      label: 'Room / Lab Number',
                      child: DebossedField(
                        label: '',
                        showLabel: false,
                        icon: Icons.location_on_outlined,
                        controller: _roomController,
                      ),
                    ),
                    const SizedBox(height: 24),
                    PushableButton(
                      label: 'Generate QR',
                      icon: Icons.lock_reset,
                      onPressed: _generateOtp,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'This will initiate a dynamic 12-second auto-expiring code.',
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

class _ConfigureOtpHeader extends StatelessWidget {
  const _ConfigureOtpHeader({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: AppColors.surfaceContainer,
        border: Border(bottom: BorderSide(color: AppColors.outlineVariant, width: 1)),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          PushSurfaceButton(
            onPressed: onBack,
            borderRadius: 12,
            child: const Padding(
              padding: EdgeInsets.all(8),
              child: Icon(Icons.arrow_back, color: AppColors.onSurface),
            ),
          ),
          Expanded(
            child: Text(
              'CONFIGURE QR',
              textAlign: TextAlign.center,
              style: AppTextStyles.headlineSm.copyWith(
                color: AppColors.primary,
                letterSpacing: 1.2,
                fontSize: 18,
              ),
            ),
          ),
          const SizedBox(width: 40), // balances the back button
        ],
      ),
    );
  }
}
