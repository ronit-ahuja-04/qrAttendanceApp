const fs = require('fs');

let content = fs.readFileSync('lib/screens/global_configure_session_screen.dart', 'utf8');

// 1. Add new variables
const oldVars = `  // For Combined Seminars
  List<Map<String, dynamic>> _seminarTargets = [];

  final _roomController = TextEditingController(text: 'Lab 402');`;

const newVars = `  // For Smart Seminars
  String _seminarDivision = 'D15A';
  TimeOfDay _seminarStartTime = TimeOfDay.now();
  TimeOfDay _seminarEndTime = TimeOfDay(hour: (TimeOfDay.now().hour + 2) % 24, minute: TimeOfDay.now().minute);

  final _roomController = TextEditingController(text: 'Seminar Hall');`;
content = content.replace(oldVars, newVars);

// 2. Add Helper to get divisions for year
const helperTarget = `  String _yearFromBatch(String batchTarget) {`;
const helperReplacement = `  List<String> _getDivisionsForYear() {
    if (_year == 'TE (D15)') return ['D15A', 'D15B', 'D15C'];
    if (_year == 'SE') return ['D16A', 'D16B'];
    if (_year == 'FE') return ['D17A', 'D17B', 'D17C'];
    return ['D15A', 'D15B', 'D15C'];
  }

  String _yearFromBatch(String batchTarget) {`;
content = content.replace(helperTarget, helperReplacement);

// 3. Update _startSession
const oldStartSession = `  Future<void> _startSession() async {
    if (_isCombinedSeminar) {
      if (_seminarTargets.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please add at least one target for the seminar.')));
        return;
      }
      setState(() => _loading = true);
      try {
        final session = await AmsGlobals.sessionService.createSeminarSession(
          proxyFacultyId: AmsGlobals.loggedInUser!.id,
          targets: _seminarTargets,
        );
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => FacultyAttendanceQrGeneratorScreen(
              session: session,
              sessionSubtitle: '$_subject • \${_roomController.text.isNotEmpty ? _roomController.text : "Seminar"}',
            ),
          ),
        );
      } catch (e) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }`;

const newStartSession = `  Future<void> _startSession() async {
    if (_isCombinedSeminar) {
      setState(() => _loading = true);
      try {
        final now = DateTime.now();
        final startDt = DateTime(now.year, now.month, now.day, _seminarStartTime.hour, _seminarStartTime.minute);
        final endDt = DateTime(now.year, now.month, now.day, _seminarEndTime.hour, _seminarEndTime.minute);
        
        final session = await AmsGlobals.sessionService.createSmartSeminarSession(
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
              sessionSubtitle: 'Seminar • \${_roomController.text.isNotEmpty ? _roomController.text : "Seminar Hall"} • Target: $_seminarDivision',
            ),
          ),
        );
      } catch (e) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }`;
content = content.replace(oldStartSession, newStartSession);

// 4. Update the _isCombinedSeminar UI part in build()
// We'll replace the entire section for `if (_isCombinedSeminar) ...[ ... ] else ...[ ... ]`
const uiStart = `                          if (_isCombinedSeminar) ...[`;
const uiEnd = `                          ] else ...[`;

const oldUiFull = content.substring(content.indexOf(uiStart), content.indexOf(uiEnd) + uiEnd.length);

const newUiFull = `                          if (_isCombinedSeminar) ...[
                            VesitCard(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Text('Smart Seminar Setup', style: AppTextStyles.vesitHeadlineSm),
                                  const SizedBox(height: 16),
                                  _buildDropdown('Academic Year', _year, _years, (v) {
                                    if (v != null) {
                                      setState(() {
                                        _year = v;
                                        final divs = _getDivisionsForYear();
                                        _seminarDivision = divs.isNotEmpty ? divs.first : '';
                                      });
                                    }
                                  }),
                                  _buildDropdown('Division', _seminarDivision, _getDivisionsForYear(), (v) {
                                    if (v != null) {
                                      setState(() { _seminarDivision = v; });
                                    }
                                  }),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: InkWell(
                                          onTap: () async {
                                            final time = await showTimePicker(context: context, initialTime: _seminarStartTime);
                                            if (time != null) setState(() => _seminarStartTime = time);
                                          },
                                          child: InputDecorator(
                                            decoration: InputDecoration(
                                              labelText: 'Start Time',
                                              filled: true,
                                              fillColor: Colors.white,
                                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                                            ),
                                            child: Text(_seminarStartTime.format(context)),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: InkWell(
                                          onTap: () async {
                                            final time = await showTimePicker(context: context, initialTime: _seminarEndTime);
                                            if (time != null) setState(() => _seminarEndTime = time);
                                          },
                                          child: InputDecorator(
                                            decoration: InputDecoration(
                                              labelText: 'End Time',
                                              filled: true,
                                              fillColor: Colors.white,
                                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                                            ),
                                            child: Text(_seminarEndTime.format(context)),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  const Text('The backend will automatically find all lectures/labs overlapping with this time and award attendance to the original faculties.', style: TextStyle(fontSize: 12, color: Colors.grey)),
                                ],
                              ),
                            ),
                          ] else ...[`;

content = content.replace(oldUiFull, newUiFull);

fs.writeFileSync('lib/screens/global_configure_session_screen.dart', content);
console.log('UI updated for Smart Seminars');
