import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/tactile_widgets.dart';
import '../ams/globals.dart';
import '../ams/models.dart';
import 'student_attendance_success_screen.dart';
import 'student_not_enrolled_screen.dart';
import 'student_already_marked_screen.dart';
import '../widgets/vesit_toast.dart';

/// "Verify Attendance" screen — reached from the dashboard's
/// "Mark Your Attendance" button. Lets the student pick the subject the
/// QR was broadcast for, key in the 6-digit code, then submit.
///
/// This is UI-only: there's no real QR validation or network call yet.
/// Submitting always "succeeds" after a short simulated delay so the flow
/// can be wired up to a real backend later by whoever owns that piece.
class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  bool _submitting = false;
  double _zoomScale = 0.0;

  final MobileScannerController _scannerController = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    detectionTimeoutMs: 1000,
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
        if (result.reason == RejectionReason.studentNotEnrolled) {
          if (!mounted) return;
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const StudentNotEnrolledScreen()),
          );
          return;
        }
        if (result.reason == RejectionReason.duplicateAttendance) {
          if (!mounted) return;
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const StudentAlreadyMarkedScreen()),
          );
          return;
        }
        VesitToast.show(context: context, title: result.message ?? 'Failed to mark attendance', type: ToastType.info);
        return;
      }
    } catch (e, st) {
      if (!mounted) return;
      setState(() => _submitting = false);
      // Ignore json decoding errors from partial/invalid barcodes
      // to prevent "Invalid QR" flashing before a successful scan.
      return;
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const StudentAttendanceSuccessScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.wall,
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
                          _FieldLabel(label: 'Scan QR Code', pulsing: true),
                          const SizedBox(height: 16),
                          
                          Container(
                            height: 400,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: context.colors.debossedWell,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 6, offset: const Offset(0, 3)),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Stack(
                                children: [
                                  MobileScanner(
                                    controller: _scannerController,
                                    onDetect: (capture) {
                                      final List<Barcode> barcodes = capture.barcodes;
                                      for (final barcode in barcodes) {
                                        // Auto-zoom logic based on barcode bounding box
                                        if (barcode.corners.length == 4) {
                                          final dx = barcode.corners[0].dx - barcode.corners[1].dx;
                                          final dy = barcode.corners[0].dy - barcode.corners[1].dy;
                                          final width = math.sqrt(dx * dx + dy * dy);
                                          
                                          // If barcode is small on screen, zoom in gradually
                                          if (width > 0 && width < 120 && _zoomScale < 1.0) {
                                            _zoomScale += 0.05;
                                            if (_zoomScale > 1.0) _zoomScale = 1.0;
                                            _scannerController.setZoomScale(_zoomScale);
                                          }
                                        }

                                        if (barcode.rawValue != null) {
                                          _processScan(barcode.rawValue!);
                                          break; // Process only the first one
                                        }
                                      }
                                    },
                                  ),
                                  if (_submitting)
                                    Container(
                                      color: Colors.black54,
                                      child: const Center(
                                        child: CircularProgressIndicator(),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.camera_alt_outlined,
                                size: 16,
                                color: context.colors.primary,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'Point your camera at the instructor\'s screen',
                                  style: context.textStyles.labelMd.copyWith(
                                    color: context.colors.primary,
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
      decoration: BoxDecoration(
        color: context.colors.surface,
        border: Border(bottom: BorderSide(color: context.colors.outlineVariant, width: 1)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              PushSurfaceButton(
                onPressed: onBack,
                borderRadius: 999,
                child: Padding(
                  padding: EdgeInsets.all(10),
                  child: Icon(Icons.arrow_back, color: context.colors.primary, size: 20),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text('Verify Attendance', style: context.textStyles.headlineSm.copyWith(color: context.colors.primary)),
          const SizedBox(height: 4),
          Text(
            'Scan the QR broadcasted by your instructor',
            style: context.textStyles.labelMd.copyWith(fontSize: 12),
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
          style: context.textStyles.labelBold.copyWith(letterSpacing: 1.0),
        ),
        const SizedBox(width: 8),
        PilotLight(active: true, size: pulsing ? 7 : 6),
      ],
    );
  }
}



// Removed _OtpBoxes class


