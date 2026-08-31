const fs = require('fs');
let content = fs.readFileSync('lib/screens/student_timetable_screen.dart', 'utf8');
content = content.replace("import '../widgets/vesit_card.dart';", "import '../widgets/vesit_widgets.dart';");
fs.writeFileSync('lib/screens/student_timetable_screen.dart', content);
console.log('Fixed VesitCard Import');
