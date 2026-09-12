const fs = require('fs');

let content = fs.readFileSync('lib/screens/global_configure_session_screen.dart', 'utf8');

// Replace _buildTargetSelector logic
const oldSelector = `  Widget _buildTargetSelector() {
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
  }`;

const newSelector = `  Widget _buildTargetSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildDropdown('Academic Year', _year, _years, (v) {
          if (v != null) {
            _year = v;
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
            setState(() {
              _batch = v;
              _deriveOriginalFaculty();
            });
          }
        }),
      ],
    );
  }`;

content = content.replace(oldSelector, newSelector);

// Add Radio buttons in build
const oldRoomInput = `                          VesitTextField(
                            controller: _roomController,
                            label: 'Room Number (e.g. Lab 402)',
                            icon: Icons.room,
                          ),
                          const SizedBox(height: 32),`;

const newRoomInput = `                          VesitTextField(
                            controller: _roomController,
                            label: 'Room Number (e.g. Lab 402)',
                            icon: Icons.room,
                          ),
                          if (!_isCombinedSeminar && _canClaimCredit) ...[
                            const SizedBox(height: 24),
                            VesitCard(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Text('Take Attendance For:', style: AppTextStyles.vesitHeadlineSm),
                                  const SizedBox(height: 8),
                                  RadioListTile<bool>(
                                    title: const Text('Myself (Takeover Slot)'),
                                    value: true,
                                    groupValue: _creditToProxy,
                                    activeColor: AppColors.vesitPrimary,
                                    onChanged: (val) {
                                      setState(() { _creditToProxy = val!; });
                                    },
                                  ),
                                  RadioListTile<bool>(
                                    title: Text('Original Faculty (\${_faculty.isEmpty ? "Unknown" : _faculty})'),
                                    value: false,
                                    groupValue: _creditToProxy,
                                    activeColor: AppColors.vesitPrimary,
                                    onChanged: (val) {
                                      setState(() { _creditToProxy = val!; });
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                          const SizedBox(height: 32),`;

content = content.replace(oldRoomInput, newRoomInput);

fs.writeFileSync('lib/screens/global_configure_session_screen.dart', content);

console.log('UI updated');
