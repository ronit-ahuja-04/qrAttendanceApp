import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'attendance_submitted_screen.dart';

import '../ams/globals.dart';
import '../ams/api_services.dart';
import '../widgets/vesit_widgets.dart';
import '../widgets/vesit_toast.dart';

enum _MarkStatus { present, absent, unmarked }

class _StudentRow {
  _StudentRow({
    required this.id,
    required this.rollNo,
    required this.name,
    this.division,
    this.electiveBatch,
    required this.status,
    required this.method,
    required this.isElective,
  });

  final String id;
  final String rollNo;
  final String name;
  final String? division;
  final String? electiveBatch;
  _MarkStatus status;
  String method;
  final bool isElective;
}

/// "Verify Attendance" — the faculty review step shown after a session's
/// live OTP window closes. Lets faculty override any student's P/A mark
/// before locking the session. Mirrors the "verify_attendance" Stitch
/// mockup.
class VerifyAttendanceScreen extends StatefulWidget {
  const VerifyAttendanceScreen({
    super.key,
    required this.sessionId,
    required this.subjectTitle,
    required this.divisionLabel,
  });

  final String sessionId;
  final String subjectTitle;
  final String divisionLabel;

  @override
  State<VerifyAttendanceScreen> createState() => _VerifyAttendanceScreenState();
}

class _VerifyAttendanceScreenState extends State<VerifyAttendanceScreen> {
  List<_StudentRow> _students = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchVerificationList();
  }

  Future<void> _fetchVerificationList() async {
    final list = await AmsGlobals.sessionService.getVerificationList(widget.sessionId);
    if (!mounted) return;
    setState(() {
      _students = list.map((item) {
        String rawName = item['name'] ?? 'Unknown';
        String email = item['email'] ?? '';
        
        // Always extract clean First/Last name from their standard VES email format
        String formattedName = AmsGlobals.formatStudentName(rawName, email);

        return _StudentRow(
          id: item['studentId'] ?? item['id'] ?? '',
          rollNo: item['rollNo'] ?? 'N/A',
          name: formattedName,
          division: item['division'],
          electiveBatch: item['electiveBatch'],
          status: (item['status'] == 'present' || item['status'] == 'pending') ? _MarkStatus.present : _MarkStatus.absent,
          method: item['method'] ?? 'Not Marked',
          isElective: widget.subjectTitle.toLowerCase().contains('soft computing') || widget.subjectTitle.toLowerCase().contains('admt'),
        );
      }).toList();
      
      // Sort alphanumerically by roll number
      int compareAlphanumeric(String a, String b) {
        final regExp = RegExp(r'(\d+|\D+)');
        final aMatches = regExp.allMatches(a).map((m) => m.group(0)!).toList();
        final bMatches = regExp.allMatches(b).map((m) => m.group(0)!).toList();
        
        for (int i = 0; i < aMatches.length && i < bMatches.length; i++) {
          final aPart = aMatches[i];
          final bPart = bMatches[i];
          
          final aInt = int.tryParse(aPart);
          final bInt = int.tryParse(bPart);
          
          if (aInt != null && bInt != null) {
            final comp = aInt.compareTo(bInt);
            if (comp != 0) return comp;
          } else {
            final comp = aPart.compareTo(bPart);
            if (comp != 0) return comp;
          }
        }
        return aMatches.length.compareTo(bMatches.length);
      }
      
      _students.sort((a, b) => compareAlphanumeric(a.rollNo, b.rollNo));

      _isLoading = false;
    });
  }

  int get _presentCount => _students.where((s) => s.status == _MarkStatus.present).length;

  void _setStatus(_StudentRow row, _MarkStatus status) {
    setState(() {
      row.status = status;
      row.method = 'Manually Marked';
    });
  }

  Future<void> _confirmAndSubmit() async {
    setState(() => _isLoading = true);
    final total = _students.length;
    final present = _presentCount;

    final updates = _students.map((s) => {
      'studentId': s.id,
      'status': s.status == _MarkStatus.present ? 'present' : 'absent'
    }).toList();

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/sessions/${widget.sessionId}/attendance/finalize'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'updates': updates}),
      );

      if (response.statusCode == 200 && mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => AttendanceSubmittedScreen(
              subjectTitle: '${widget.subjectTitle} (${widget.divisionLabel.replaceAll('DIV : ', 'Div ')})',
              presentCount: present,
              absentCount: total - present,
            ),
          ),
        );
      } else {
        throw Exception('Failed to finalize attendance');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        VesitToast.show(context: context, title: 'Error: $e', type: ToastType.info);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final total = _students.length;
    final present = _presentCount;
    final percent = total == 0 ? 0 : ((present / total) * 100).round();

    return Scaffold(
      backgroundColor: context.colors.vesitWhite,
      appBar: AppBar(
        backgroundColor: context.colors.vesitPrimary,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: context.colors.vesitWhite),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        centerTitle: true,
        title: Column(
          children: [
            Text('Verify Attendance', style: context.textStyles.vesitHeadlineSm.copyWith(color: context.colors.vesitWhite)),
            const SizedBox(height: 2),
            Text('${widget.subjectTitle} | ${widget.divisionLabel}', style: context.textStyles.vesitBodyMd.copyWith(color: context.colors.vesitWhite.withOpacity(0.8))),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: Container(
            height: 4,
            color: context.colors.vesitGold, // Progressive yellow line
          ),
        ),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else
              Positioned.fill(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 100), // padding at bottom so button doesn't hide last item
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _SummaryBar(present: present, total: total, percent: percent),
                      const SizedBox(height: 24),
                      ..._students.map(
                        (row) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _StudentTile(
                            row: row,
                            onSetStatus: (status) => _setStatus(row, status),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (!_isLoading)
              Positioned(
                bottom: 16,
                left: 16,
                right: 16,
                child: VesitButton(
                  label: 'CONFIRM & SUBMIT ATTENDANCE',
                  onPressed: _confirmAndSubmit,
                ),
              ),
          ],
        ),
      ),
    );
  }
}



class _SummaryBar extends StatelessWidget {
  const _SummaryBar({required this.present, required this.total, required this.percent});

  final int present;
  final int total;
  final int percent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.colors.vesitPrimary, // Navy blue background
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: context.colors.vesitPrimary.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ATTENDANCE SUMMARY',
            style: context.textStyles.vesitLabelBold.copyWith(color: context.colors.vesitGold, letterSpacing: 1.2),
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              RichText(
                text: TextSpan(
                  style: context.textStyles.vesitHeadlineLg.copyWith(color: context.colors.vesitWhite),
                  children: [
                    TextSpan(text: '$present '),
                    TextSpan(
                      text: '/ $total Present',
                      style: context.textStyles.vesitBodyMd.copyWith(color: context.colors.vesitWhite.withOpacity(0.8)),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: context.colors.vesitGold.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: context.colors.vesitGold.withOpacity(0.5)),
                ),
                child: Text(
                  '$percent%',
                  style: context.textStyles.vesitLabelBold.copyWith(color: context.colors.vesitGold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Container(
              height: 10,
              width: double.infinity,
              color: context.colors.vesitWhite.withOpacity(0.1),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final factor = total == 0 ? 0.0 : (present / total).clamp(0.0, 1.0);
                  return Align(
                    alignment: Alignment.centerLeft,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 800),
                      curve: Curves.fastOutSlowIn,
                      width: constraints.maxWidth * factor,
                      height: 10,
                      decoration: BoxDecoration(
                        color: context.colors.vesitGold,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StudentTile extends StatelessWidget {
  const _StudentTile({required this.row, required this.onSetStatus});

  final _StudentRow row;
  final ValueChanged<_MarkStatus> onSetStatus;

  @override
  Widget build(BuildContext context) {
    final IconData statusIcon;
    final Color statusColor;
    switch (row.status) {
      case _MarkStatus.present:
        statusIcon = Icons.check_circle;
        statusColor = const Color(0xFF15803D); // Green
        break;
      case _MarkStatus.absent:
        statusIcon = Icons.cancel;
        statusColor = const Color(0xFF93000A); // Red
        break;
      case _MarkStatus.unmarked:
        statusIcon = Icons.help;
        statusColor = Colors.grey.shade500;
        break;
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.colors.vesitWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: row.status == _MarkStatus.unmarked ? Colors.transparent : statusColor.withOpacity(0.2),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: context.colors.vesitPrimary.withOpacity(0.05),
              border: Border.all(color: context.colors.vesitPrimary.withOpacity(0.1)),
            ),
            child: Text(
              row.rollNo.replaceAll(RegExp(r'[^0-9]'), ''), // Just show the numbers if possible
              style: context.textStyles.vesitHeadlineSm.copyWith(fontSize: 16, color: context.colors.vesitPrimary),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  row.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.textStyles.vesitLabelBold.copyWith(color: context.colors.vesitPrimary, fontSize: 15),
                ),
                if (row.isElective && row.division != null && row.electiveBatch != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    '${row.division} - ${row.electiveBatch}',
                    style: context.textStyles.vesitBodySm.copyWith(color: context.colors.vesitPrimary.withOpacity(0.6), fontWeight: FontWeight.w600),
                  ),
                ],
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(statusIcon, size: 14, color: statusColor),
                    const SizedBox(width: 6),
                    Text(row.method, style: context.textStyles.vesitBodyMd.copyWith(color: statusColor, fontSize: 13)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          _PAToggle(
            status: row.status,
            onChanged: onSetStatus,
          ),
        ],
      ),
    );
  }
}

class _PAToggle extends StatelessWidget {
  const _PAToggle({
    required this.status,
    required this.onChanged,
  });

  final _MarkStatus status;
  final ValueChanged<_MarkStatus> onChanged;

  @override
  Widget build(BuildContext context) {
    const double width = 94; // Increased from 84 to prevent clipping of the 'A'
    const double height = 44;
    const double padding = 4;
    const double pillWidth = (width - (padding * 2)) / 2;

    return Container(
      width: 140,
      height: 44,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: context.colors.vesitGray.withOpacity(0.5),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: context.colors.vesitGray, width: 1),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final double pillWidth = constraints.maxWidth / 2;
          
          double leftOffset;
          Color pillColor;
          double pillOpacity;

          switch (status) {
            case _MarkStatus.present:
              leftOffset = 0;
              pillColor = const Color(0xFF15803D);
              pillOpacity = 1.0;
              break;
            case _MarkStatus.absent:
              leftOffset = pillWidth;
              pillColor = const Color(0xFF93000A);
              pillOpacity = 1.0;
              break;
            case _MarkStatus.unmarked:
            default:
              leftOffset = pillWidth / 2;
              pillColor = Colors.grey.shade400;
              pillOpacity = 0.0;
              break;
          }

          return Stack(
            children: [
              AnimatedPositioned(
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeInOut,
                left: leftOffset,
                top: 0,
                bottom: 0,
                width: pillWidth,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 400),
                  opacity: pillOpacity,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 500),
                    decoration: BoxDecoration(
                      color: pillColor,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: pillColor.withOpacity(0.4),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Row(
                children: [
                  _buildOption(context, 'Present', _MarkStatus.present),
                  _buildOption(context, 'Absent', _MarkStatus.absent),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildOption(BuildContext context, String label, _MarkStatus targetStatus) {
    final bool isActive = status == targetStatus;
    return Expanded(
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => onChanged(targetStatus),
          child: Center(
            child: AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: context.textStyles.vesitLabelBold.copyWith(
                color: isActive ? context.colors.vesitWhite : Colors.grey.shade600,
                fontSize: 14,
              ),
              child: Text(label),
            ),
          ),
        ),
      ),
    );
  }
}




