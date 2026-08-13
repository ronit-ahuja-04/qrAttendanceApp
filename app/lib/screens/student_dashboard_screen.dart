import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/tactile_widgets.dart';
import 'attendance_history_screen.dart';
import 'otp_verification_screen.dart';
import 'student_profile_screen.dart';
import 'notifications_screen.dart';

class _SessionItem {
  const _SessionItem({required this.subject, required this.location, required this.time});

  final String subject;
  final String location;
  final String time;
}

class StudentDashboardScreen extends StatelessWidget {
  const StudentDashboardScreen({super.key});

  static const _sessions = [
    _SessionItem(subject: 'Software Engineering', location: 'Room 402', time: '11:30 AM'),
    _SessionItem(subject: 'Mobile Computing', location: 'Lab 3', time: '02:30 PM'),
  ];

  void _comingSoon(BuildContext context, String label) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$label — coming soon'), duration: const Duration(seconds: 1)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.wall,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                _Header(
                  onNotificationsTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                  ),
                  onAvatarTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const StudentProfileScreen()),
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                    children: [
                      _SectionHeader(icon: null, ledDot: true, title: 'Attendance Overview'),
                      const SizedBox(height: 10),
                      const Row(
                        children: [
                          Expanded(child: _StatCard(label: 'Overall', value: '89%')),
                          SizedBox(width: 16),
                          Expanded(child: _StatCard(label: 'This Week', value: '94%')),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _HistoryRow(
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const AttendanceHistoryScreen()),
                        ),
                      ),
                      const SizedBox(height: 24),
                      _MarkAttendanceButton(
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const OtpVerificationScreen()),
                        ),
                      ),
                      const SizedBox(height: 24),
                      _SectionHeader(icon: Icons.schedule_outlined, title: 'Upcoming Sessions'),
                      const SizedBox(height: 10),
                      ..._sessions.map(
                        (s) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _SessionCard(item: s),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Align(
              alignment: Alignment.bottomCenter,
              child: TactileBottomNav(currentIndex: 0),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onNotificationsTap, required this.onAvatarTap});

  final VoidCallback onNotificationsTap;
  final VoidCallback onAvatarTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2))],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: onAvatarTap,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.surfaceContainerHighest,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 6, offset: const Offset(0, 2)),
                ],
              ),
              child: const Icon(Icons.person, color: AppColors.onSurfaceVariant),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Student Portal', style: AppTextStyles.headlineSm, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text('Hello, Sachin', style: AppTextStyles.labelMd.copyWith(fontSize: 13)),
              ],
            ),
          ),
          PushSurfaceButton(
            onPressed: onNotificationsTap,
            borderRadius: 999,
            child: const Padding(
              padding: EdgeInsets.all(10),
              child: Icon(Icons.notifications_outlined, color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.icon, this.ledDot = false});

  final String title;
  final IconData? icon;
  final bool ledDot;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (ledDot) ...[
          const PilotLight(active: true, size: 8),
          const SizedBox(width: 8),
        ] else if (icon != null) ...[
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 8),
        ],
        Text(
          title.toUpperCase(),
          style: AppTextStyles.labelBold.copyWith(color: AppColors.onSurface, letterSpacing: 1.2),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return RaisedPanel(
      borderRadius: 16,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
      child: Column(
        children: [
          Text(
            label.toUpperCase(),
            style: AppTextStyles.labelMd.copyWith(fontSize: 12, letterSpacing: 0.8),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'FamiljenGrotesk',
              fontSize: 40,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PushSurfaceButton(
      onPressed: onTap,
      borderRadius: 16,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            const Icon(Icons.history, color: AppColors.primary, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'VIEW ATTENDANCE HISTORY',
                style: AppTextStyles.labelBold.copyWith(color: AppColors.onSurface, letterSpacing: 1.2),
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}

/// The big amber "Mark Your Attendance" CTA. Purely navigational — it
/// pushes the student to the OTP verification screen where the actual
/// subject + code entry happens. No backend call here.
class _MarkAttendanceButton extends StatefulWidget {
  const _MarkAttendanceButton({required this.onTap});

  final VoidCallback onTap;

  @override
  State<_MarkAttendanceButton> createState() => _MarkAttendanceButtonState();
}

class _MarkAttendanceButtonState extends State<_MarkAttendanceButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        width: double.infinity,
        transform: Matrix4.translationValues(0, _pressed ? 2 : 0, 0),
        padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 16),
        decoration: BoxDecoration(
          color: _pressed ? const Color(0xFFE19216) : AppColors.primaryContainer,
          borderRadius: BorderRadius.circular(16),
          boxShadow: _pressed
              ? [const BoxShadow(color: AppColors.primary, offset: Offset(0, 1))]
              : [
                  const BoxShadow(color: AppColors.primary, offset: Offset(0, 4)),
                  BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 6)),
                ],
        ),
        alignment: Alignment.center,
        child: Text(
          'MARK YOUR ATTENDANCE',
          textAlign: TextAlign.center,
          style: AppTextStyles.headlineSm.copyWith(
            color: AppColors.onPrimaryContainer,
            fontSize: 20,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}

class _SessionCard extends StatelessWidget {
  const _SessionCard({required this.item});

  final _SessionItem item;

  @override
  Widget build(BuildContext context) {
    return RaisedPanel(
      borderRadius: 16,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.subject, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.onSurface)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined, size: 14, color: AppColors.onSurfaceVariant),
                    const SizedBox(width: 4),
                    Text(item.location, style: AppTextStyles.labelMd.copyWith(fontSize: 13)),
                  ],
                ),
              ],
            ),
          ),
          DebossedWell(
            borderRadius: 8,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Text(item.time, style: AppTextStyles.labelBold.copyWith(color: AppColors.onSurface, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}
