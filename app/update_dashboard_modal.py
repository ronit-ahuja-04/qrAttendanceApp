import re

with open('lib/screens/faculty_dashboard_screen.dart', 'r') as f:
    content = f.read()

# Replace the button rendering in the modal
modal_button_old = """                    return ElevatedButton(
                      onPressed: () {
                        Navigator.of(ctx).pop(); // Close modal
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => FacultyAttendanceQrGeneratorScreen(
                              subjectTitle: session['subject'] as String? ?? 'N/A',
                              sessionSubtitle: '${session['venue'] ?? ''} • ${_formatTimeString(session['startTime'] as String? ?? '')} - ${_formatTimeString(session['endTime'] as String? ?? '')} • Div: ${session['batchTarget'] ?? ''}',
                              batchTarget: session['batchTarget'] as String?,
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.vesitPrimary,
                        foregroundColor: AppColors.vesitWhite,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Quick Generate QR', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    );"""

modal_button_new = """                    final hasSessionToday = session['hasSessionToday'] == true;
                    
                    if (hasSessionToday) {
                      return Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Attendance record already submitted',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      );
                    }

                    return ElevatedButton(
                      onPressed: () {
                        Navigator.of(ctx).pop(); // Close modal
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => FacultyAttendanceQrGeneratorScreen(
                              subjectTitle: session['subject'] as String? ?? 'N/A',
                              sessionSubtitle: '${session['venue'] ?? ''} • ${_formatTimeString(session['startTime'] as String? ?? '')} - ${_formatTimeString(session['endTime'] as String? ?? '')} • Div: ${session['batchTarget'] ?? ''}',
                              batchTarget: session['batchTarget'] as String?,
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.vesitPrimary,
                        foregroundColor: AppColors.vesitWhite,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Quick Generate QR', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    );"""

content = content.replace(modal_button_old, modal_button_new)

with open('lib/screens/faculty_dashboard_screen.dart', 'w') as f:
    f.write(content)

