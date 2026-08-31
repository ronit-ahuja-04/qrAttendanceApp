const fs = require('fs');

const content = `import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/vesit_widgets.dart';
import 'faculty_attendance_qr_generator_screen.dart';
import '../ams/globals.dart';
import '../ams/api_services.dart' show baseUrl;

class GlobalConfigureSessionScreen extends StatefulWidget {
  const GlobalConfigureSessionScreen({super.key});

  @override
  State<GlobalConfigureSessionScreen> createState() =>
      _GlobalConfigureSessionScreenState();
}

class _GlobalConfigureSessionScreenState
    extends State<GlobalConfigureSessionScreen> {
  bool _loading = true;
  String? _error;
  bool _isCombinedSeminar = false;

  List<Map<String, dynamic>> _allSlots = [];

  List<String> _years = [];
  List<String> _faculties = [];
  List<String> _subjects = [];
  List<String> _sessionTypes = [];
  List<String> _batches = [];

  String _year = '';
  String _faculty = '';
  String _facultyId = '';
  String _subject = '';
  String _sessionType = '';
  String _batch = '';

  // For Combined Seminars
  List<Map<String, dynamic>> _seminarTargets = [];

  final _roomController = TextEditingController(text: 'Lab 402');

  @override
  void initState() {
    super.initState();
    _fetchAllSlots();
  }

  @override
  void dispose() {
    _roomController.dispose();
    super.dispose();
  }

  String _yearFromBatch(String batchTarget) {
    if (batchTarget.startsWith('TE -')) return 'TE (Elective)';
    if (batchTarget.contains('D15')) return 'TE (D15)';
    if (batchTarget.contains('D16')) return 'SE';
    if (batchTarget.contains('D17')) return 'FE';
    return 'Other';
  }

  Future<void> _fetchAllSlots() async {
    try {
      final res = await http.get(Uri.parse('\$baseUrl/timetable'));
      if (res.statusCode == 200) {
        final List<dynamic> data = jsonDecode(res.body);
        _allSlots = data.map((e) => e as Map<String, dynamic>).toList();

        final rawYears = _allSlots.map((s) => _yearFromBatch(s['batchTarget'] ?? '')).toSet().toList();
        rawYears.sort();
        _years = rawYears;
        
        if (_years.isNotEmpty) {
          _year = _years.first;
          _updateFaculties();
        }

        setState(() {
          _loading = false;
        });
      } else {
        setState(() {
          _error = 'Failed to load timetable';
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _updateFaculties() {
    final filtered = _allSlots.where((s) => _yearFromBatch(s['batchTarget'] ?? '') == _year).toList();
    final uniqueFac = <String, String>{};
    for (var s in filtered) {
      if (s['facultyName'] != null) {
        uniqueFac[s['facultyName']] = s['facultyId'];
      }
    }
    _faculties = uniqueFac.keys.toList()..sort();
    if (_faculties.isNotEmpty) {
      _faculty = _faculties.first;
      _facultyId = uniqueFac[_faculty]!;
      _updateSubjects();
    } else {
      _faculty = '';
      _facultyId = '';
      _subjects = [];
      _subject = '';
      _sessionTypes = [];
      _sessionType = '';
      _batches = [];
      _batch = '';
    }
  }

  void _updateSubjects() {
    final filtered = _allSlots.where((s) => _yearFromBatch(s['batchTarget'] ?? '') == _year && s['facultyId'] == _facultyId).toList();
    _subjects = filtered.map((s) => s['subject'].toString()).toSet().toList()..sort();
    if (_subjects.isNotEmpty) {
      _subject = _subjects.first;
      _updateSessionTypes();
    } else {
      _subject = '';
      _sessionTypes = [];
      _sessionType = '';
      _batches = [];
      _batch = '';
    }
  }

  void _updateSessionTypes() {
    final filtered = _allSlots.where((s) => _yearFromBatch(s['batchTarget'] ?? '') == _year && s['facultyId'] == _facultyId && s['subject'] == _subject).toList();
    _sessionTypes = filtered.map((s) => s['type'].toString()).toSet().toList()..sort();
    if (_sessionTypes.isNotEmpty) {
      _sessionType = _sessionTypes.first;
      _updateBatches();
    } else {
      _sessionType = '';
      _batches = [];
      _batch = '';
    }
  }

  void _updateBatches() {
    final filtered = _allSlots.where((s) => _yearFromBatch(s['batchTarget'] ?? '') == _year && s['facultyId'] == _facultyId && s['subject'] == _subject && s['type'] == _sessionType).toList();
    _batches = filtered.map((s) => s['batchTarget'].toString()).toSet().toList()..sort();
    if (_batches.isNotEmpty) {
      _batch = _batches.first;
    } else {
      _batch = '';
    }
    setState(() {});
  }

  void _addTargetToSeminar() {
    if (_batch.isEmpty) return;
    setState(() {
      _seminarTargets.add({
        'originalFacultyName': _faculty,
        'originalFacultyId': _facultyId,
        'courseCode': '\$_subject - \$_sessionType',
        'batchTarget': _batch,
      });
    });
  }

  void _removeTarget(int index) {
    setState(() {
      _seminarTargets.removeAt(index);
    });
  }

  Future<void> _startSession() async {
    if (_isCombinedSeminar) {
      if (_seminarTargets.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please add at least one target for the seminar.')));
        return;
      }
      setState(() => _loading = true);
      try {
        final session = await AmsGlobals.attendanceService.createSeminarSession(
          proxyFacultyId: AmsGlobals.loggedInUser!.id,
          targets: _seminarTargets,
        );
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => FacultyAttendanceQrGeneratorScreen(
              session: session,
              roomInfo: _roomController.text,
            ),
          ),
        );
      } catch (e) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } else {
      if (_batch.isEmpty) return;
      setState(() => _loading = true);
      try {
        final session = await AmsGlobals.attendanceService.createSession(
          courseCode: '\$_subject - \$_sessionType',
          facultyId: _facultyId,
          batchTarget: _batch,
          isProxy: true,
          originalFacultyId: _facultyId,
        );
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => FacultyAttendanceQrGeneratorScreen(
              session: session,
              roomInfo: _roomController.text,
            ),
          ),
        );
      } catch (e) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  Widget _buildDropdown(String label, String value, List<String> items, ValueChanged<String?> onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<String>(
        value: items.contains(value) ? value : null,
        items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildTargetSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildDropdown('Academic Year', _year, _years, (v) {
          if (v != null) {
            _year = v;
            _updateFaculties();
          }
        }),
        _buildDropdown('Original Faculty', _faculty, _faculties, (v) {
          if (v != null) {
            _faculty = v;
            final uniqueFac = <String, String>{};
            final filtered = _allSlots.where((s) => _yearFromBatch(s['batchTarget'] ?? '') == _year).toList();
            for (var s in filtered) {
              if (s['facultyName'] != null) {
                uniqueFac[s['facultyName']] = s['facultyId'];
              }
            }
            _facultyId = uniqueFac[_faculty] ?? '';
            _updateSubjects();
          }
        }),
        _buildDropdown('Subject', _subject, _subjects, (v) {
          if (v != null) {
            _subject = v;
            _updateSessionTypes();
          }
        }),
        _buildDropdown('Session Type', _sessionType, _sessionTypes, (v) {
          if (v != null) {
            _sessionType = v;
            _updateBatches();
          }
        }),
        _buildDropdown('Batch / Division', _batch, _batches, (v) {
          if (v != null) {
            setState(() { _batch = v; });
          }
        }),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.vesitGray,
      appBar: AppBar(
        backgroundColor: AppColors.vesitPrimary,
        title: Text('Proxy Setup', style: AppTextStyles.vesitHeadlineSm.copyWith(color: AppColors.vesitWhite)),
        iconTheme: const IconThemeData(color: AppColors.vesitWhite),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!, style: const TextStyle(color: Colors.red)))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 500),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: InkWell(
                                    onTap: () => setState(() => _isCombinedSeminar = false),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                      decoration: BoxDecoration(
                                        color: !_isCombinedSeminar ? AppColors.vesitPrimary : Colors.transparent,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        'Single Class',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: !_isCombinedSeminar ? Colors.white : Colors.grey.shade600,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: InkWell(
                                    onTap: () => setState(() => _isCombinedSeminar = true),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                      decoration: BoxDecoration(
                                        color: _isCombinedSeminar ? AppColors.vesitPrimary : Colors.transparent,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        'Combined Seminar',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: _isCombinedSeminar ? Colors.white : Colors.grey.shade600,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          
                          if (_isCombinedSeminar) ...[
                            VesitCard(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Text('Add Target Class', style: AppTextStyles.vesitHeadlineSm),
                                  const SizedBox(height: 16),
                                  _buildTargetSelector(),
                                  const SizedBox(height: 8),
                                  OutlinedButton.icon(
                                    onPressed: _batch.isNotEmpty ? _addTargetToSeminar : null,
                                    icon: const Icon(Icons.add),
                                    label: const Text('Add to Seminar'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: AppColors.vesitPrimary,
                                      side: const BorderSide(color: AppColors.vesitPrimary),
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                            if (_seminarTargets.isNotEmpty)
                              VesitCard(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    Text('Selected Targets', style: AppTextStyles.vesitHeadlineSm),
                                    const SizedBox(height: 16),
                                    ..._seminarTargets.asMap().entries.map((entry) {
                                      final t = entry.value;
                                      return Container(
                                        margin: const EdgeInsets.only(bottom: 8),
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.grey.shade50,
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: Colors.grey.shade200),
                                        ),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(t['courseCode'], style: const TextStyle(fontWeight: FontWeight.bold)),
                                                  Text('\${t['originalFacultyName']} • \${t['batchTarget']}', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                                                ],
                                              ),
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.delete_outline, color: Colors.red),
                                              onPressed: () => _removeTarget(entry.key),
                                            )
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                  ],
                                ),
                              ),
                          ] else ...[
                            VesitCard(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Text('Proxy Class Details', style: AppTextStyles.vesitHeadlineSm),
                                  const SizedBox(height: 16),
                                  _buildTargetSelector(),
                                ],
                              ),
                            ),
                          ],
                          
                          const SizedBox(height: 24),
                          VesitTextField(
                            controller: _roomController,
                            label: 'Room Number (e.g. Lab 402)',
                            prefixIcon: Icons.room,
                          ),
                          const SizedBox(height: 32),
                          ElevatedButton(
                            onPressed: _startSession,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.vesitPrimary,
                              foregroundColor: AppColors.vesitWhite,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 2,
                            ),
                            child: const Text('GENERATE PROXY QR', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
    );
  }
}
`;

fs.writeFileSync('app/lib/screens/global_configure_session_screen.dart', content);
console.log('Done');
