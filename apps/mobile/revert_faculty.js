const fs = require('fs');

let code = fs.readFileSync('lib/screens/faculty_dashboard_screen.dart', 'utf8');

// Remove import
code = code.replace("import 'faculty_defaulters_screen.dart';\n", "");

// Remove Defaulters button from Web View
const defaulterWebBtn = `                              const SizedBox(width: 24),
                              Expanded(
                                child: _ActionHub(
                                  isLoading: _isLoading,
                                  icon: Icons.warning_amber_rounded,
                                  title: 'View Defaulters',
                                  subtitle: 'See students falling below 75%',
                                  onTap: () async {
                                    await Future.delayed(const Duration(milliseconds: 150));
                                    if (!context.mounted) return;
                                    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const FacultyDefaultersScreen()));
                                  },
                                ),
                              ),\n`;
code = code.replace(defaulterWebBtn, "");

// Remove Defaulters button from Mobile View
const defaulterMobileBtn = `                            const SizedBox(width: 16),
                            Expanded(
                              child: _ActionHub(
                                isLoading: _isLoading,
                                icon: Icons.warning_amber_rounded,
                                title: 'Defaulters',
                                subtitle: 'Below 75%',
                                isCompact: true,
                                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const FacultyDefaultersScreen())),
                              ),
                            ),\n`;
code = code.replace(defaulterMobileBtn, "");

fs.writeFileSync('lib/screens/faculty_dashboard_screen.dart', code);
console.log("Faculty Dashboard reverted.");

// Delete the defaulters screen file
if (fs.existsSync('lib/screens/faculty_defaulters_screen.dart')) {
    fs.unlinkSync('lib/screens/faculty_defaulters_screen.dart');
    console.log("Faculty Defaulters screen deleted.");
}
