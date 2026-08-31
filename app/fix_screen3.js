const fs = require('fs');
let content = fs.readFileSync('lib/screens/global_configure_session_screen.dart', 'utf8');

const regex = /  void _addTargetToSeminar\(\) {[\s\S]*?  void _removeTarget\(int index\) {[\s\S]*?  }/;
content = content.replace(regex, "");

fs.writeFileSync('lib/screens/global_configure_session_screen.dart', content);
console.log('Fixed Seminar Targets');
