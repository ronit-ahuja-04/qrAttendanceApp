const fs = require('fs');
let code = fs.readFileSync('lib/screens/student_dashboard_screen.dart', 'utf8');

// Revert state variables
code = code.replace("  List<dynamic> _subjectsStats = [];\n  \n  List<Map<String, dynamic>> _rawSessions = [];", "  \n  List<Map<String, dynamic>> _rawSessions = [];");

// Revert _fetchStats
const fetchStatsReplacement = `        setState(() {
          _overallPercentage = stats['overallPercentage'] ?? 0.0;
          _thisWeekPercentage = stats['thisWeekPercentage'] ?? 0.0;
          _subjectsStats = stats['subjects'] ?? [];
          _isLoading = false;
        });`;
const fetchStatsOriginal = `        setState(() {
          _overallPercentage = stats['overallPercentage'] ?? 0.0;
          _thisWeekPercentage = stats['thisWeekPercentage'] ?? 0.0;
          _thisWeekPercentage = stats['thisWeekPercentage'] ?? 0.0;
          _isLoading = false;
        });`;
code = code.replace(fetchStatsReplacement, fetchStatsOriginal);

// Revert Banner
const bannerCode = `                      if (!_isLoading && _subjectsStats.any((s) => (s['overallPercentage'] as num) < 50.0))
                        _StaggeredFade(
                          animation: _animController,
                          index: 0,
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.error.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.error.withValues(alpha: 0.5)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.warning_amber_rounded, color: AppColors.error),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Warning: You are below 50% attendance in one or more subjects. Defaulter action may be taken.',
                                    style: AppTextStyles.vesitBodyMd.copyWith(color: AppColors.error, fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),\n`;
code = code.replace(bannerCode, "");

fs.writeFileSync('lib/screens/student_dashboard_screen.dart', code);
console.log("Student Dashboard reverted.");
