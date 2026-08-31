const fs = require('fs');

// 1. UPDATE global_configure_session_screen.dart
let content = fs.readFileSync('lib/screens/global_configure_session_screen.dart', 'utf8');

const oldUpdateFaculties = `  void _updateFaculties() {
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
  }`;

const newUpdateLogic = `  bool _canClaimCredit = false;
  bool _creditToProxy = false;

  void _updateSubjects() {
    final filtered = _allSlots.where((s) => _yearFromBatch(s['batchTarget'] ?? '') == _year).toList();
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
      _faculty = '';
      _facultyId = '';
    }
  }

  void _updateSessionTypes() {
    final filtered = _allSlots.where((s) => _yearFromBatch(s['batchTarget'] ?? '') == _year && s['subject'] == _subject).toList();
    _sessionTypes = filtered.map((s) => s['type'].toString()).toSet().toList()..sort();
    if (_sessionTypes.isNotEmpty) {
      _sessionType = _sessionTypes.first;
      _updateBatches();
    } else {
      _sessionType = '';
      _batches = [];
      _batch = '';
      _faculty = '';
      _facultyId = '';
    }
  }

  void _updateBatches() {
    final filtered = _allSlots.where((s) => _yearFromBatch(s['batchTarget'] ?? '') == _year && s['subject'] == _subject && s['type'] == _sessionType).toList();
    _batches = filtered.map((s) => s['batchTarget'].toString()).toSet().toList()..sort();
    if (_batches.isNotEmpty) {
      _batch = _batches.first;
      _deriveOriginalFaculty();
    } else {
      _batch = '';
      _faculty = '';
      _facultyId = '';
    }
    setState(() {});
  }

  void _deriveOriginalFaculty() {
    final filtered = _allSlots.where((s) => _yearFromBatch(s['batchTarget'] ?? '') == _year && s['subject'] == _subject && s['type'] == _sessionType && s['batchTarget'] == _batch).toList();
    if (filtered.isNotEmpty) {
      _faculty = filtered.first['facultyName'] ?? '';
      _facultyId = filtered.first['facultyId'] ?? '';
    }
    _checkAuthorization();
  }

  void _checkAuthorization() {
    final loggedInId = AmsGlobals.loggedInUser?.id;
    final teachesSubject = _allSlots.any((s) => s['facultyId'] == loggedInId && s['subject'] == _subject);
    _canClaimCredit = teachesSubject;
    if (!_canClaimCredit) {
      _creditToProxy = false;
    }
  }`;

content = content.replace(oldUpdateFaculties, newUpdateLogic);

// Replace _updateFaculties call with _updateSubjects
content = content.replace('_updateFaculties();', '_updateSubjects();');

// Update _startSession call
const oldStartSessionCall = `final session = await AmsGlobals.sessionService.createSession(
          courseCode: '$_subject - $_sessionType',
          facultyId: _facultyId,
          batchTarget: _batch,
          isProxy: true,
          originalFacultyId: _facultyId,
        );`;
const newStartSessionCall = `final session = await AmsGlobals.sessionService.createSession(
          courseCode: '$_subject - $_sessionType',
          facultyId: _facultyId,
          batchTarget: _batch,
          isProxy: true,
          originalFacultyId: _facultyId,
          creditToProxy: _creditToProxy,
          autoApprove: !_canClaimCredit,
        );`;
content = content.replace(oldStartSessionCall, newStartSessionCall);

fs.writeFileSync('lib/screens/global_configure_session_screen.dart', content);

console.log('Frontend logic replaced successfully');
