import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/vesit_widgets.dart';
import 'faculty_attendance_qr_generator_screen.dart';
import '../ams/globals.dart';
import '../widgets/vesit_toast.dart';

/// "Configure Session" — the faculty form that sets up a class session before
/// a dynamic, auto-expiring attendance code is generated. Mirrors the
/// "configure_qr_session" Stitch mockup: Division, Subject, Lecture
/// Timing, and Room fields inside raised module cards, topped off with a
/// full-width "Generate QR" action.
class ConfigureSessionScreen extends StatefulWidget {
  const ConfigureSessionScreen({super.key});

  @override
  State<ConfigureSessionScreen> createState() => _ConfigureSessionScreenState();
}

class _ConfigureSessionScreenState extends State<ConfigureSessionScreen> {
  List<String> _subjects = ['Unknown Subject'];
  List<String> _batches = ['Unknown Batch'];
  List<String> _sessionTypes = ['Lecture (60 Mins)'];

  String _batch = '';
  String _subject = '';
  String _sessionType = '';
  final _roomController = TextEditingController(text: 'Lab 402');

  @override
  void initState() {
    super.initState();
    _initScopes();
  }

  void _initScopes() {
    final scopes = AmsGlobals.loggedInUser?.scopes ?? [];
    if (scopes.isNotEmpty) {
      _subjects = scopes.map((s) => s['subject'] as String).toSet().toList()..sort();
      _subject = _subjects.isNotEmpty ? _subjects.first : '';
      _updateDependentDropdowns();
    }
    if (_subjects.isEmpty) _subjects = ['Unknown Subject'];
    if (_subject.isEmpty) _subject = _subjects.first;
  }

  void _updateDependentDropdowns() {
    final scopes = AmsGlobals.loggedInUser?.scopes ?? [];
    final validScopes = scopes.where((s) => s['subject'] == _subject).toList();
    
    if (validScopes.isNotEmpty) {
      _sessionTypes = validScopes.map((s) {
        final type = s['type'] as String;
        return type.toLowerCase().contains('lab') ? 'Lab' : 'Lecture';
      }).toSet().toList()..sort();
      if (!_sessionTypes.contains(_sessionType)) _sessionType = _sessionTypes.isNotEmpty ? _sessionTypes.first : 'Lecture';
      _updateBatchesForSessionType();
    } else {
      _sessionTypes = ['Lecture'];
      _sessionType = 'Lecture';
      _batches = ['Unknown Batch'];
      _batch = 'Unknown Batch';
    }
  }

  void _updateBatchesForSessionType() {
    final scopes = AmsGlobals.loggedInUser?.scopes ?? [];
    final validScopes = scopes.where((s) {
      if (s['subject'] != _subject) return false;
      final type = (s['type'] as String).toLowerCase().contains('lab') ? 'Lab' : 'Lecture';
      return type == _sessionType;
    }).toList();
    
    if (validScopes.isNotEmpty) {
      _batches = validScopes.map((s) => s['batchTarget'] as String).toSet().toList()..sort();
      if (!_batches.contains(_batch)) _batch = _batches.isNotEmpty ? _batches.first : 'Unknown Batch';
    } else {
      _batches = ['Unknown Batch'];
      _batch = 'Unknown Batch';
    }
  }

  @override
  void dispose() {
    _roomController.dispose();
    super.dispose();
  }

  void _generateQr() {
    // UI Validation - 2 sec top snackbar
    if (_batch.contains('ADMT') && !_subject.toLowerCase().contains('admt') && !_subject.toLowerCase().contains('database')) {
      VesitToast.show(context: context, title: 'Mismatch: Target is ADMT but Subject is not.', type: ToastType.info);
      return;
    }
    
    String formatTime(DateTime t) {
      final h = t.hour > 12 ? t.hour - 12 : (t.hour == 0 ? 12 : t.hour);
      final m = t.minute.toString().padLeft(2, '0');
      return '$h:$m';
    }
    
    final timingShort = '${formatTime(DateTime.now())} – ${formatTime(DateTime.now().add(const Duration(hours: 1)))}';

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => FacultyAttendanceQrGeneratorScreen(
          subjectTitle: '$_subject - ${_sessionType.contains("Lab") ? "Lab" : "Lecture"}',
          sessionSubtitle: '${_roomController.text} • $timingShort • Target: $_batch',
          batchTarget: _batch,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.vesitWhite,
      body: SafeArea(
        child: Column(
          children: [
            _ConfigureSessionHeader(onBack: () => Navigator.of(context).maybePop()),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 600),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        VesitDropdown<String>(
                          label: 'Subject',
                          icon: Icons.book_outlined,
                          value: _subject,
                          items: _subjects,
                          itemLabel: (v) => v,
                          onChanged: (v) {
                            setState(() {
                              _subject = v!;
                              _updateDependentDropdowns();
                            });
                          },
                        ),
                        const SizedBox(height: 20),
                        VesitDropdown<String>(
                          label: 'Session Type',
                          icon: Icons.science_outlined,
                          value: _sessionType,
                          items: _sessionTypes,
                          itemLabel: (v) => v,
                          onChanged: (v) {
                            if (v != null) {
                              setState(() {
                                _sessionType = v;
                                _updateBatchesForSessionType();
                              });
                            }
                          },
                        ),
                        if (!_sessionType.toLowerCase().contains('lecture')) ...[
                          const SizedBox(height: 20),
                          VesitDropdown<String>(
                            label: 'Batch',
                            icon: Icons.people_outline,
                            value: _batch,
                            items: _batches,
                            itemLabel: (v) => v,
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => _batch = val);
                              }
                            },
                          ),
                        ],
                        const SizedBox(height: 20),
                        VesitTextField(
                          label: 'Room / Lab Number',
                          icon: Icons.location_on_outlined,
                          controller: _roomController,
                        ),
                        const SizedBox(height: 32),
                        VesitButton(
                          label: 'Generate QR',
                          onPressed: _generateQr,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'This session will remain active for 30 seconds, generating a new secure QR code every 2 seconds.',
                          textAlign: TextAlign.center,
                          style: context.textStyles.vesitBodyMd.copyWith(color: Colors.grey.shade500),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConfigureSessionHeader extends StatelessWidget {
  const _ConfigureSessionHeader({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: context.colors.vesitWhite,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back, color: context.colors.vesitTextHeading),
            onPressed: onBack,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Configure Session',
              style: context.textStyles.vesitHeadlineSm,
            ),
          ),
          IconButton(
            icon: Icon(Icons.help_outline, color: context.colors.vesitPrimary),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Select the correct class and timing to generate a secure QR code.'),
                  duration: Duration(seconds: 3),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
