import re

filepath = 'lib/screens/global_configure_session_screen.dart'
with open(filepath, 'r') as f:
    content = f.read()

# Remove _buildDropdown definition
content = re.sub(r'Widget _buildDropdown.*?return Padding.*?,\s*\n\s*\),\s*\n\s*\);\s*\n\s*\}', '', content, flags=re.DOTALL)

# Replace _buildDropdown calls with VesitDropdown
# Note: we need to handle the icons. Let's map them.
# Academic Year -> Icons.calendar_today
# Original Faculty -> Icons.person
# Subject -> Icons.book
# Session Type -> Icons.science
# Batch / Division -> Icons.group
# Division (Seminar) -> Icons.group

content = content.replace(
    "_buildDropdown('Academic Year', _year, _years, (v) {",
    "Padding(padding: EdgeInsets.only(bottom: 16), child: VesitDropdown<String>(label: 'Academic Year', icon: Icons.calendar_today, value: _year, items: _years, itemLabel: (v) => v, onChanged: (v) {"
)
content = content.replace(
    "_buildDropdown('Original Faculty', _faculty, _faculties, (v) {",
    "Padding(padding: EdgeInsets.only(bottom: 16), child: VesitDropdown<String>(label: 'Original Faculty', icon: Icons.person, value: _faculty, items: _faculties, itemLabel: (v) => v, onChanged: (v) {"
)
content = content.replace(
    "_buildDropdown('Subject', _subject, _subjects, (v) {",
    "Padding(padding: EdgeInsets.only(bottom: 16), child: VesitDropdown<String>(label: 'Subject', icon: Icons.book, value: _subject, items: _subjects, itemLabel: (v) => v, onChanged: (v) {"
)
content = content.replace(
    "_buildDropdown('Session Type', _sessionType, _sessionTypes, (v) {",
    "Padding(padding: EdgeInsets.only(bottom: 16), child: VesitDropdown<String>(label: 'Session Type', icon: Icons.science, value: _sessionType, items: _sessionTypes, itemLabel: (v) => v, onChanged: (v) {"
)
content = content.replace(
    "_buildDropdown('Batch / Division', _batch, _batches, (v) {",
    "Padding(padding: EdgeInsets.only(bottom: 16), child: VesitDropdown<String>(label: 'Batch / Division', icon: Icons.group, value: _batch, items: _batches, itemLabel: (v) => v, onChanged: (v) {"
)
content = content.replace(
    "_buildDropdown('Division', _seminarDivision,\n                                      _getDivisionsForYear(), (v) {",
    "Padding(padding: EdgeInsets.only(bottom: 16), child: VesitDropdown<String>(label: 'Division', icon: Icons.group, value: _seminarDivision, items: _getDivisionsForYear(), itemLabel: (v) => v, onChanged: (v) {"
)

# Remember to close the Padding widget!
# Let's use regex to append "}))," instead of "}),"
content = re.sub(r'(_updateFaculties\(\);\s*\n\s*)\}\),', r'\1})),', content)
content = re.sub(r'(_updateSubjects\(\);\s*\n\s*)\}\),', r'\1})),', content)
content = re.sub(r'(_updateSessionTypes\(\);\s*\n\s*)\}\),', r'\1})),', content)
content = re.sub(r'(_updateBatches\(\);\s*\n\s*)\}\),', r'\1})),', content)

# For setState wrappers
content = re.sub(r'(_batch = v;\s*\n\s*\}\);\s*\n\s*)\}\),', r'\1})),', content)
content = re.sub(r'(_seminarDivision = v;\s*\n\s*\}\);\s*\n\s*\}?)\}\),', r'\1})),', content)

with open(filepath, 'w') as f:
    f.write(content)
