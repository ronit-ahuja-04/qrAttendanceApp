const fs = require('fs');
let content = fs.readFileSync('lib/screens/student_timetable_screen.dart', 'utf8');
const imports = `import 'package:flutter/material.dart';
import '../ams/globals.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/tactile_widgets.dart';
import '../widgets/vesit_card.dart';
import 'student_dashboard_screen.dart';`;

content = content.replace(/import[\s\S]*?import 'student_dashboard_screen\.dart';/, imports);
fs.writeFileSync('lib/screens/student_timetable_screen.dart', content);
console.log('Fixed Screen');
