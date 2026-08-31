import re

with open('lib/screens/global_configure_session_screen.dart', 'r') as f:
    content = f.read()

# 1. Add _seminarTargets to state
state_old = """  String _seminarDivision = 'D15A';
  TimeOfDay _seminarStartTime = TimeOfDay.now();
  TimeOfDay _seminarEndTime = TimeOfDay(hour: (TimeOfDay.now().hour + 2) % 24, minute: TimeOfDay.now().minute);"""

state_new = """  String _seminarDivision = 'D15A';
  TimeOfDay _seminarStartTime = TimeOfDay.now();
  TimeOfDay _seminarEndTime = TimeOfDay(hour: (TimeOfDay.now().hour + 2) % 24, minute: TimeOfDay.now().minute);
  
  List<Map<String, String>> _seminarTargets = [];"""

content = content.replace(state_old, state_new)

# 2. Update _startSession for combined seminar
start_session_old = """        final session = await AmsGlobals.sessionService.createSmartSeminarSession(
          proxyFacultyId: AmsGlobals.loggedInUser!.id,
          division: _seminarDivision,
          startTime: startDt.toIso8601String(),
          endTime: endDt.toIso8601String(),
          date: now.toIso8601String(),
        );
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => FacultyAttendanceQrGeneratorScreen(
              session: session,
              sessionSubtitle: 'Seminar • ${_roomController.text.isNotEmpty ? _roomController.text : "Seminar Hall"} • Target: $_seminarDivision',
            ),
          ),
        );"""

start_session_new = """        if (_seminarTargets.isEmpty) {
          setState(() => _loading = false);
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please add at least one division.")));
          return;
        }
        
        final session = await AmsGlobals.sessionService.createSmartSeminarSession(
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
              sessionSubtitle: 'Seminar • ${_roomController.text.isNotEmpty ? _roomController.text : "Seminar Hall"} • Targets: $targetsStr',
            ),
          ),
        );"""
        
content = content.replace(start_session_old, start_session_new)


# 3. Add UI elements for targets
ui_old = """                                  _buildDropdown('Division', _seminarDivision, _getDivisionsForYear(), (v) {
                                    if (v != null) {
                                      setState(() { _seminarDivision = v; });
                                    }
                                  }),"""

ui_new = """                                  _buildDropdown('Division', _seminarDivision, _getDivisionsForYear(), (v) {
                                    if (v != null) {
                                      setState(() { _seminarDivision = v; });
                                    }
                                  }),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: TextButton.icon(
                                      onPressed: () {
                                        setState(() {
                                          if (!_seminarTargets.any((t) => t['year'] == _year && t['division'] == _seminarDivision)) {
                                            _seminarTargets.add({'year': _year, 'division': _seminarDivision});
                                          }
                                        });
                                      },
                                      icon: const Icon(Icons.add_circle, color: AppColors.vesitPrimary),
                                      label: const Text('Add Division', style: TextStyle(color: AppColors.vesitPrimary, fontWeight: FontWeight.bold)),
                                    ),
                                  ),
                                  if (_seminarTargets.isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: _seminarTargets.asMap().entries.map((entry) {
                                        final int index = entry.key;
                                        final Map<String, String> target = entry.value;
                                        return Chip(
                                          label: Text('${target['year']} - ${target['division']}', style: const TextStyle(fontSize: 12)),
                                          deleteIcon: const Icon(Icons.close, size: 16),
                                          onDeleted: () {
                                            setState(() {
                                              _seminarTargets.removeAt(index);
                                            });
                                          },
                                          backgroundColor: AppColors.vesitPrimary.withOpacity(0.1),
                                          side: BorderSide.none,
                                        );
                                      }).toList(),
                                    ),
                                    const SizedBox(height: 16),
                                  ],"""
content = content.replace(ui_old, ui_new)


with open('lib/screens/global_configure_session_screen.dart', 'w') as f:
    f.write(content)

