import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/tactile_widgets.dart';
import '../ams/globals.dart';
import '../ams/models.dart';

/// "Verify Attendance" screen — reached from the dashboard's
/// "Mark Your Attendance" button. Lets the student pick the subject the
/// OTP was broadcast for, key in the 6-digit code, then submit.
///
/// This is UI-only: there's no real OTP validation or network call yet.
/// Submitting always "succeeds" after a short simulated delay so the flow
/// can be wired up to a real backend later by whoever owns that piece.
class OtpVerificationScreen extends StatefulWidget {
  const OtpVerificationScreen({super.key});

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  static const _subjects = [
    'Java Programming — CS-302',
    'Data Structures — CS-304',
    'Computer Networks — CS-306',
  ];

  String _selectedSubject = _subjects.first;
  bool _submitting = false;

  final MobileScannerController _scannerController = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
  );

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  Future<void> _processScan(String rawData) async {
    if (_submitting) return;

    setState(() => _submitting = true);
    
    // Stop scanning once we detect a code
    _scannerController.stop();

    try {
      final Map<String, dynamic> data = jsonDecode(rawData);
      final String sessionId = data['s'];
      final String code = data['o'];

      final result = await AmsGlobals.attendanceService.markAttendance(
        sessionId,
        AmsGlobals.loggedInUser!.id,
        code,
      );

      if (!mounted) return;
      setState(() => _submitting = false);

      if (!result.ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.message ?? 'Failed to mark attendance'), duration: const Duration(seconds: 2)),
        );
        // Restart scanner if failed
        _scannerController.start();
        return;
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Invalid QR Code or error: $e'), duration: const Duration(seconds: 2)),
      );
      // Restart scanner if failed
      _scannerController.start();
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _AttendanceSuccessDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.wall,
      body: SafeArea(
        child: Column(
          children: [
            _Header(onBack: () => Navigator.of(context).pop()),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
                child: Column(
                  children: [
                    RaisedPanel(
                      borderRadius: 16,
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _FieldLabel(label: 'Select Subject'),
                          const SizedBox(height: 8),
                          _SubjectDropdown(
                            value: _selectedSubject,
                            options: _subjects,
                            onChanged: (v) => setState(() => _selectedSubject = v),
                          ),
                          const SizedBox(height: 20),
                          _FieldLabel(label: 'Scan QR Code', pulsing: true),
                          const SizedBox(height: 10),
                          
                          Container(
                            height: 300,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: AppColors.debossedWell,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 6, offset: const Offset(0, 3)),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: _submitting 
                                ? const Center(child: CircularProgressIndicator())
                                : MobileScanner(
                                    controller: _scannerController,
                                    onDetect: (capture) {
                                      final List<Barcode> barcodes = capture.barcodes;
                                      for (final barcode in barcodes) {
                                        if (barcode.rawValue != null) {
                                          _processScan(barcode.rawValue!);
                                          break; // Process only the first one
                                        }
                                      }
                                    },
                                  ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.camera_alt_outlined,
                                size: 16,
                                color: AppColors.primary,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'Point your camera at the instructor\'s screen',
                                  style: AppTextStyles.labelMd.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
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

class _Header extends StatelessWidget {
  const _Header({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.outlineVariant, width: 1)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              PushSurfaceButton(
                onPressed: onBack,
                borderRadius: 999,
                child: const Padding(
                  padding: EdgeInsets.all(10),
                  child: Icon(Icons.arrow_back, color: AppColors.primary, size: 20),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text('Verify Attendance', style: AppTextStyles.headlineSm.copyWith(color: AppColors.primary)),
          const SizedBox(height: 4),
          Text(
            'Scan the QR broadcasted by your instructor',
            style: AppTextStyles.labelMd.copyWith(fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.label, this.pulsing = false});

  final String label;
  final bool pulsing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label.toUpperCase(),
          style: AppTextStyles.labelBold.copyWith(letterSpacing: 1.0),
        ),
        const SizedBox(width: 8),
        PilotLight(active: true, size: pulsing ? 7 : 6),
      ],
    );
  }
}

class _SubjectDropdown extends StatelessWidget {
  const _SubjectDropdown({
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final String value;
  final List<String> options;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.debossedWell,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 6, offset: const Offset(0, 3)),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: const Icon(Icons.expand_more, color: AppColors.onSurfaceVariant),
          style: AppTextStyles.bodyMd,
          dropdownColor: AppColors.surfaceContainer,
          borderRadius: BorderRadius.circular(12),
          items: options
              .map((s) => DropdownMenuItem(value: s, child: Text(s, overflow: TextOverflow.ellipsis)))
              .toList(),
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ),
    );
  }
}

// Removed _OtpBoxes class

class _AttendanceSuccessDialog extends StatelessWidget {
  const _AttendanceSuccessDialog();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerHighest,
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: const Icon(Icons.check_circle_outline, color: AppColors.primary, size: 48),
            ),
            const SizedBox(height: 20),
            const Text('Attendance Submitted!', style: AppTextStyles.headlineSm, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(
              'Your attendance has been recorded for this session.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMd.copyWith(color: AppColors.onSurfaceVariant, fontSize: 14),
            ),
            const SizedBox(height: 24),
            PushableButton(
              label: 'Go to Home Dashboard',
              onPressed: () {
                Navigator.of(context).pop(); // close dialog
                Navigator.of(context).pop(); // back to dashboard
              },
            ),
          ],
        ),
      ),
    );
  }
}
