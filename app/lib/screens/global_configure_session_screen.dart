import 'dart:convert';
import 'package:flutter/material.dart';
import '../ams/globals.dart';
import 'package:http/http.dart' as http;
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/vesit_widgets.dart';
import 'faculty_attendance_qr_generator_screen.dart';
import '../ams/globals.dart';
import '../ams/api_services.dart' show baseUrl;
import '../widgets/vesit_toast.dart';

class GlobalConfigureSessionScreen extends StatefulWidget {
  const GlobalConfigureSessionScreen({super.key, this.scrollController});
  final ScrollController? scrollController;

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
  List<Map<String, dynamic>> _activeSessionsToday = [];

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

  // For Proxy Single Class
  String _proxyDivision = '';
  Map<String, dynamic>? _selectedActiveSlot;

  // For Smart Seminars
  String _seminarDivision = 'D15A';
  TimeOfDay _seminarStartTime = TimeOfDay.now();
  TimeOfDay _seminarEndTime = TimeOfDay(
      hour: (TimeOfDay.now().hour + 2) % 24, minute: TimeOfDay.now().minute);

  List<Map<String, String>> _seminarTargets = [];

  final _roomController = TextEditingController(text: 'Seminar Hall');

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

  List<String> _getDivisionsForYear() {
    if (_year == 'TE (D15)') return ['D15A', 'D15B', 'D15C'];
    if (_year == 'SE') return ['D16A', 'D16B'];
    if (_year == 'FE') return ['D17A', 'D17B', 'D17C'];
    return ['D15A', 'D15B', 'D15C'];
  }

  String _yearFromBatch(String batchTarget) {
    if (batchTarget.toLowerCase().contains('admt') || 
        batchTarget.toLowerCase().contains('soft computing') || 
        batchTarget.startsWith('TE -')) {
      return 'TE (Elective)';
    }
    if (batchTarget.contains('D15')) return 'TE (D15)';
    if (batchTarget.contains('D16')) return 'SE';
    if (batchTarget.contains('D17')) return 'FE';
    return 'Other';
  }

  String _formatTime(dynamic timeStr) {
    if (timeStr == null) return '';
    final parts = timeStr.toString().split(':');
    if (parts.length < 2) return timeStr.toString();
    int hour = int.tryParse(parts[0]) ?? 0;
    int min = int.tryParse(parts[1]) ?? 0;
    final ampm = hour >= 12 && hour < 24 ? 'PM' : 'AM';
    hour = hour % 12;
    if (hour == 0) hour = 12;
    final minStr = min.toString().padLeft(2, '0');
    return '$hour:$minStr $ampm';
  }

  Future<void> _fetchAllSlots() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/timetable'));
      final activeRes = await http.get(Uri.parse('$baseUrl/api/sessions/today/all'));
      
      if (res.statusCode == 200) {
        final List<dynamic> data = jsonDecode(res.body);
        _allSlots = data.map((e) => e as Map<String, dynamic>).toList();
        
        if (activeRes.statusCode == 200) {
          final List<dynamic> activeData = jsonDecode(activeRes.body);
          _activeSessionsToday = activeData.map((e) => e as Map<String, dynamic>).toList();
        }

        final rawYears = _allSlots
            .map((s) => _yearFromBatch(s['batchTarget'] ?? ''))
            .toSet()
            .toList();
        rawYears.sort();
        _years = rawYears;

        if (_years.isNotEmpty) {
          _year = _years.first;
          final divs = _getDivisionsForYear();
          if (divs.isNotEmpty) _proxyDivision = divs.first;
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
    final filtered = _allSlots
        .where((s) => _yearFromBatch(s['batchTarget'] ?? '') == _year)
        .toList();
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
    final filtered = _allSlots
        .where((s) =>
            _yearFromBatch(s['batchTarget'] ?? '') == _year &&
            s['facultyId'] == _facultyId)
        .toList();
    _subjects = filtered.map((s) => s['subject'].toString()).toSet().toList()
      ..sort();
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
    final filtered = _allSlots
        .where((s) =>
            _yearFromBatch(s['batchTarget'] ?? '') == _year &&
            s['facultyId'] == _facultyId &&
            s['subject'] == _subject)
        .toList();
    _sessionTypes = filtered.map((s) => s['type'].toString()).toSet().toList()
      ..sort();
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
    final filtered = _allSlots
        .where((s) =>
            _yearFromBatch(s['batchTarget'] ?? '') == _year &&
            s['facultyId'] == _facultyId &&
            s['subject'] == _subject &&
            s['type'] == _sessionType)
        .toList();
    _batches = filtered.map((s) => s['batchTarget'].toString()).toSet().toList()
      ..sort();
    if (_batches.isNotEmpty) {
      _batch = _batches.first;
    } else {
      _batch = '';
    }
    setState(() {});
  }

  Future<void> _startSession() async {
    if (_isCombinedSeminar) {
      setState(() => _loading = true);
      try {
        final now = DateTime.now();
        final startDt = DateTime(now.year, now.month, now.day,
            _seminarStartTime.hour, _seminarStartTime.minute);
        final endDt = DateTime(now.year, now.month, now.day,
            _seminarEndTime.hour, _seminarEndTime.minute);

        if (_seminarTargets.isEmpty) {
          setState(() => _loading = false);
          VesitToast.show(context: context, title: "Please add at least one division.", type: ToastType.info);
          return;
        }

        final session =
            await AmsGlobals.sessionService.createSmartSeminarSession(
          proxyFacultyId: AmsGlobals.loggedInUser!.id,
          divisions: _seminarTargets.map((e) => e['division']!).toList(),
          startTime: startDt.toIso8601String(),
          endTime: endDt.toIso8601String(),
          date: now.toIso8601String(),
        );
        if (!mounted) return;

        final targetsStr = _seminarTargets.map((e) => e['division']).join(', ');
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => FacultyAttendanceQrGeneratorScreen(
              session: session,
              sessionSubtitle:
                  'Seminar • ${_roomController.text.isNotEmpty ? _roomController.text : "Seminar Hall"} • Targets: $targetsStr',
            ),
          ),
        );
      } catch (e) {
        setState(() => _loading = false);
        VesitToast.show(context: context, title: e.toString(), type: ToastType.info);
      }
    } else {
      if (_selectedActiveSlot == null) return;
      setState(() => _loading = true);
      try {
        final slot = _selectedActiveSlot!;
        final session = await AmsGlobals.sessionService.createSession(
          courseCode: '${slot['subject']} - ${slot['type']}',
          facultyId: AmsGlobals.loggedInUser!.id,
          batchTarget: slot['batchTarget'],
          isProxy: true,
          originalFacultyId: slot['facultyId'],
          slotId: slot['id'],
        );
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => FacultyAttendanceQrGeneratorScreen(
              session: session,
              sessionSubtitle:
                  '${slot['subject']} • ${_roomController.text.isNotEmpty ? _roomController.text : "Room TBD"} • Target: ${slot['batchTarget']}',
            ),
          ),
        );
      } catch (e) {
        setState(() => _loading = false);
        VesitToast.show(context: context, title: e.toString(), type: ToastType.info);
      }
    }
  }

  List<Map<String, dynamic>> _getActiveSlotsForDivision() {
    if (_proxyDivision.isEmpty && _year != 'TE (Elective)') return [];
    
    final now = DateTime.now();
    final currentDay = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][now.weekday - 1];
    final currentMinutes = now.hour * 60 + now.minute;
    
    return _allSlots.where((slot) {
      if (slot['day'] != currentDay) return false;
      
      final bt = (slot['batchTarget'] ?? '').toString();
      final isElective = _yearFromBatch(bt) == 'TE (Elective)';
      
      if (_year == 'TE (Elective)') {
        // If Elective is selected, only show elective slots. 
        if (!isElective) return false;
      } else {
        // Normal filtering by Division
        if (!bt.contains(_proxyDivision)) {
          return false;
        }
      }
      
      final stStr = slot['startTime'].toString().split(':');
      final etStr = slot['endTime'].toString().split(':');
      if (stStr.length < 2 || etStr.length < 2) return false;
      
      final startMin = int.parse(stStr[0]) * 60 + int.parse(stStr[1]);
      int endMin = int.parse(etStr[0]) * 60 + int.parse(etStr[1]);
      
      if (endMin < startMin) endMin += 24 * 60;
      
      // Check if slot overlaps current time
      bool isTimeActive = currentMinutes >= startMin && currentMinutes <= endMin;
      if (!isTimeActive && endMin > 24 * 60) {
        final currentMinutesNextDay = currentMinutes + 24 * 60;
        isTimeActive = currentMinutesNextDay >= startMin && currentMinutesNextDay <= endMin;
      }
      
      if (!isTimeActive) return false;
      
      // EXCLUDE if a session is already created for this EXACT slot today
      final alreadyCreated = _activeSessionsToday.any((active) => active['slotId'] == slot['id']);
      if (alreadyCreated) return false;

      return true;
    }).toList();
  }

  Widget _buildTargetSelector() {
    final activeSlots = _getActiveSlotsForDivision();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
            padding: EdgeInsets.only(bottom: 16),
            child: VesitDropdown<String>(
                label: 'Academic Year',
                icon: Icons.calendar_today,
                value: _year,
                items: _years,
                itemLabel: (String v) => v,
                onChanged: (String? v) {
                  if (v != null) {
                    setState(() {
                      _year = v;
                      final divs = _getDivisionsForYear();
                      _proxyDivision = divs.isNotEmpty ? divs.first : '';
                      _selectedActiveSlot = null;
                      _updateFaculties();
                    });
                  }
                })),
        if (_year != 'TE (Elective)')
          Padding(
              padding: EdgeInsets.only(bottom: 16),
              child: VesitDropdown<String>(
                  label: 'Division',
                  icon: Icons.group,
                  value: _proxyDivision,
                  items: _getDivisionsForYear(),
                  itemLabel: (String v) => v,
                  onChanged: (String? v) {
                    if (v != null) {
                      setState(() {
                        _proxyDivision = v;
                        _selectedActiveSlot = null;
                      });
                    }
                  })),
        const SizedBox(height: 8),
        Text('Active Live Classes', style: context.textStyles.vesitLabelSm),
        const SizedBox(height: 8),
        if (activeSlots.isEmpty)
          Container(
            padding: EdgeInsets.symmetric(vertical: 24),
            decoration: BoxDecoration(
              color: context.colors.surfaceContainerHighest.withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Text('No active classes right now.',
                textAlign: TextAlign.center,
                style: context.textStyles.vesitBodyMd.copyWith(color: Colors.grey.shade600)),
          )
        else
          Column(
            children: activeSlots.map((slot) {
              final isSelected = _selectedActiveSlot == slot;
              return InkWell(
                onTap: () {
                  setState(() => _selectedActiveSlot = slot);
                },
                child: Container(
                  margin: EdgeInsets.only(bottom: 8),
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isSelected ? context.colors.vesitPrimary.withOpacity(0.08) : context.colors.vesitWhite,
                    border: Border.all(color: isSelected ? context.colors.vesitPrimary : Colors.grey.shade300, width: isSelected ? 1.5 : 1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                          color: isSelected ? context.colors.vesitPrimary : Colors.grey),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${slot['subject']} - ${slot['type']}',
                                style: context.textStyles.vesitBodyLg.copyWith(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 2),
                            Text('${slot['facultyName'] ?? 'Unknown'} • ${slot['batchTarget']}',
                                style: context.textStyles.vesitLabelSm.copyWith(color: Colors.grey.shade600)),
                            const SizedBox(height: 2),
                            Text('${_formatTime(slot['startTime'])} - ${_formatTime(slot['endTime'])}',
                                style: context.textStyles.vesitLabelSm.copyWith(color: context.colors.vesitPrimary)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.vesitGray,
      appBar: AppBar(
        backgroundColor: context.colors.vesitPrimary,
        title: Text('Proxy Setup',
            style: context.textStyles.vesitHeadlineSm
                .copyWith(color: context.colors.vesitWhite)),
        iconTheme: IconThemeData(color: context.colors.vesitWhite),
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Text(_error!, style: TextStyle(color: Colors.red)))
              : SingleChildScrollView(
                  controller: widget.scrollController,
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 130),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 500),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          VesitSegmentedToggle(
                            value: _isCombinedSeminar,
                            onChanged: (val) {
                              setState(() => _isCombinedSeminar = val);
                            },
                            firstLabel: 'SINGLE CLASS',
                            secondLabel: 'COMBINED SEMINAR',
                          ),
                          SizedBox(height: 24),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            transitionBuilder: (Widget child, Animation<double> animation) {
                              return FadeTransition(
                                opacity: animation,
                                child: SlideTransition(
                                  position: Tween<Offset>(
                                    begin: const Offset(0.05, 0),
                                    end: Offset.zero,
                                  ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
                                  child: child,
                                ),
                              );
                            },
                            child: _isCombinedSeminar
                                ? VesitCard(
                                    key: const ValueKey('combined'),
                                    padding: EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.stretch,
                                      children: [
                                        Text('Smart Seminar Setup',
                                            style: context.textStyles.vesitHeadlineSm),
                                        SizedBox(height: 16),
                                        Padding(
                                            padding: EdgeInsets.only(bottom: 16),
                                            child: VesitDropdown<String>(
                                                label: 'Academic Year',
                                                icon: Icons.calendar_today,
                                                value: _year,
                                                items: _years,
                                                itemLabel: (String v) => v,
                                                onChanged: (String? v) {
                                                  if (v != null) {
                                                    setState(() {
                                                      _year = v;
                                                      final divs = _getDivisionsForYear();
                                                      _seminarDivision = divs.isNotEmpty ? divs.first : '';
                                                    });
                                                  }
                                                })),
                                        Padding(
                                            padding: EdgeInsets.only(bottom: 16),
                                            child: VesitDropdown<String>(
                                                label: 'Division',
                                                icon: Icons.group,
                                                value: _seminarDivision,
                                                items: _getDivisionsForYear(),
                                                itemLabel: (String v) => v,
                                                onChanged: (String? v) {
                                                  if (v != null) {
                                                    setState(() {
                                                      _seminarDivision = v;
                                                    });
                                                  }
                                                })),
                                        Align(
                                          alignment: Alignment.centerRight,
                                          child: TextButton.icon(
                                            onPressed: () {
                                              setState(() {
                                                if (!_seminarTargets.any((t) =>
                                                    t['year'] == _year &&
                                                    t['division'] == _seminarDivision)) {
                                                  _seminarTargets.add({
                                                    'year': _year,
                                                    'division': _seminarDivision
                                                  });
                                                }
                                              });
                                            },
                                            icon: Icon(Icons.add_circle,
                                                color: context.colors.vesitPrimary),
                                            label: Text('Add Division',
                                                style: TextStyle(
                                                    color: context.colors.vesitPrimary,
                                                    fontWeight: FontWeight.bold)),
                                          ),
                                        ),
                                        if (_seminarTargets.isNotEmpty) ...[
                                          SizedBox(height: 8),
                                          Wrap(
                                            spacing: 8,
                                            runSpacing: 8,
                                            children: _seminarTargets
                                                .asMap()
                                                .entries
                                                .map((entry) {
                                              final int index = entry.key;
                                              final Map<String, String> target = entry.value;
                                              return Chip(
                                                label: Text(
                                                    '${target['year']} - ${target['division']}',
                                                    style: TextStyle(fontSize: 12)),
                                                deleteIcon: Icon(Icons.close, size: 16),
                                                onDeleted: () {
                                                  setState(() {
                                                    _seminarTargets.removeAt(index);
                                                  });
                                                },
                                                backgroundColor: context.colors.vesitPrimary.withOpacity(0.1),
                                                side: BorderSide.none,
                                              );
                                            }).toList(),
                                          ),
                                          SizedBox(height: 16),
                                        ],
                                        Row(
                                          children: [
                                            Expanded(
                                              child: InkWell(
                                                onTap: () async {
                                                  final t = await showTimePicker(
                                                      context: context,
                                                      initialTime: _seminarStartTime);
                                                  if (t != null)
                                                    setState(() => _seminarStartTime = t);
                                                },
                                                child: Container(
                                                  padding: const EdgeInsets.all(16),
                                                  decoration: BoxDecoration(
                                                    color: context.colors.surfaceContainerHighest,
                                                    borderRadius: BorderRadius.circular(12),
                                                  ),
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Text('Start Time',
                                                          style: context.textStyles.vesitLabelSm),
                                                      const SizedBox(height: 8),
                                                      Text(_seminarStartTime.format(context),
                                                          style: context.textStyles.vesitBodyLg
                                                              .copyWith(color: context.colors.onSurfaceVariant)),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),
                                            SizedBox(width: 16),
                                            Expanded(
                                              child: InkWell(
                                                onTap: () async {
                                                  final t = await showTimePicker(
                                                      context: context,
                                                      initialTime: _seminarEndTime);
                                                  if (t != null)
                                                    setState(() => _seminarEndTime = t);
                                                },
                                                child: Container(
                                                  padding: const EdgeInsets.all(16),
                                                  decoration: BoxDecoration(
                                                    color: context.colors.surfaceContainerHighest,
                                                    borderRadius: BorderRadius.circular(12),
                                                  ),
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Text('End Time',
                                                          style: context.textStyles.vesitLabelSm),
                                                      const SizedBox(height: 8),
                                                      Text(_seminarEndTime.format(context),
                                                          style: context.textStyles.vesitBodyLg
                                                              .copyWith(color: context.colors.onSurfaceVariant)),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        SizedBox(height: 8),
                                        Text(
                                            'The backend will automatically find all lectures/labs overlapping with this time and award attendance to the original faculties.',
                                            style: TextStyle(fontSize: 12, color: Colors.grey)),
                                      ],
                                    ),
                                  )
                                : VesitCard(
                                    key: const ValueKey('single'),
                                    padding: EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.stretch,
                                      children: [
                                        Text('Proxy Class Details',
                                            style: context.textStyles.vesitHeadlineSm),
                                        SizedBox(height: 16),
                                        _buildTargetSelector(),
                                      ],
                                    ),
                                  ),
                          ),
                          SizedBox(height: 24),
                          VesitTextField(
                            controller: _roomController,
                            label: 'Room Number (e.g. Lab 402)',
                            icon: Icons.room,
                          ),
                          SizedBox(height: 32),
                          ElevatedButton(
                            onPressed: _startSession,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: context.colors.vesitPrimary,
                              foregroundColor: context.colors.vesitWhite,
                              padding: EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              elevation: 2,
                            ),
                            child: Text('GENERATE PROXY QR',
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.2)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
    );
  }
}
