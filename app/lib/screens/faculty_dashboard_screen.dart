import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/tactile_widgets.dart';
import 'compose_announcement_screen.dart';
import 'configure_otp_screen.dart';
import 'faculty_notifications_screen.dart';
import 'faculty_profile_screen.dart';
import 'login_screen.dart';

/// The faculty landing screen — mirrors the "faculty_node_dashboard_compact"
/// Stitch mockup: a profile header (avatar + online LED + notification
/// bell) followed by three stacked action hubs (Generate Attendance OTP,
/// Announcements, Generate Report).
///
/// "Generate Attendance OTP" routes into [ConfigureOtpScreen]; the other
/// two hubs still just show a "coming soon" snack for now.
class FacultyDashboardScreen extends StatelessWidget {
  const FacultyDashboardScreen({super.key});

  void _comingSoon(BuildContext context, String label) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$label — coming soon'), duration: const Duration(seconds: 1)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Column(
          children: [
            _FacultyHeader(
              onNotificationsTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const FacultyNotificationsScreen()),
              ),
              onAvatarTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const FacultyProfileScreen()),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                child: Column(
                  children: [
                    Expanded(
                      child: _ActionHub(
                        icon: Icons.vpn_key,
                        iconFilled: true,
                        title: 'Generate Attendance OTP',
                        subtitle: 'Start a 12-second dynamic verification session',
                        highlighted: true,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const ConfigureOtpScreen()),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: _ActionHub(
                        icon: Icons.campaign_outlined,
                        title: 'Announcements',
                        subtitle: 'Broadcast updates to classes or department',
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const ComposeAnnouncementScreen()),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: _ActionHub(
                        icon: Icons.bar_chart_outlined,
                        title: 'Generate Report',
                        subtitle: 'Export attendance sheets & student logs',
                        onTap: () => _comingSoon(context, 'Report generation'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FacultyHeader extends StatelessWidget {
  const _FacultyHeader({required this.onNotificationsTap, required this.onAvatarTap});

  final VoidCallback onNotificationsTap;
  final VoidCallback onAvatarTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.outlineVariant, width: 1)),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: onAvatarTap,
            child: Stack(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.surfaceContainerHigh,
                    border: Border.all(color: AppColors.outlineVariant, width: 2),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 6, offset: const Offset(0, 2)),
                    ],
                  ),
                  child: const Icon(Icons.person, color: AppColors.onSurfaceVariant),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF22C55E),
                      border: Border.all(color: AppColors.surface, width: 2),
                      boxShadow: const [
                        BoxShadow(color: Color(0x9922C55E), blurRadius: 4),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Good Morning, Prof. Sharma',
                  style: AppTextStyles.headlineSm.copyWith(color: AppColors.primary),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  'COMPUTER ENGINEERING DEPARTMENT',
                  style: AppTextStyles.labelSm.copyWith(letterSpacing: 1.0),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Stack(
            clipBehavior: Clip.none,
            children: [
              PushSurfaceButton(
                onPressed: onNotificationsTap,
                borderRadius: 12,
                child: const Padding(
                  padding: EdgeInsets.all(10),
                  child: Icon(Icons.notifications_outlined, color: AppColors.onSurfaceVariant),
                ),
              ),
              Positioned(
                top: 6,
                right: 6,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.error,
                    boxShadow: [BoxShadow(color: Color(0x80BA1A1A), blurRadius: 4)],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// One of the three stacked action cards on the faculty dashboard. The
/// "highlighted" variant (used for Generate Attendance OTP) gets an amber
/// outline, a top accent line, and a filled/badged icon — matching the
/// primary hub in the Stitch mockup.
class _ActionHub extends StatefulWidget {
  const _ActionHub({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.iconFilled = false,
    this.highlighted = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool iconFilled;
  final bool highlighted;

  @override
  State<_ActionHub> createState() => _ActionHubState();
}

class _ActionHubState extends State<_ActionHub> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final borderColor = widget.highlighted ? AppColors.primaryContainer : AppColors.outlineVariant;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        width: double.infinity,
        transform: Matrix4.translationValues(0, _pressed ? 2 : 0, 0),
        decoration: BoxDecoration(
          color: _pressed ? AppColors.surfaceContainerHigh : AppColors.surfaceContainer,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: widget.highlighted ? 1.5 : 1),
          boxShadow: _pressed
              ? [BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 6, offset: const Offset(0, 2))]
              : [
                  BoxShadow(color: Colors.white.withOpacity(0.8), offset: const Offset(0, 1)),
                  BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 2)),
                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 4)),
                ],
        ),
        child: Stack(
          children: [
            if (widget.highlighted)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer.withOpacity(0.8),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                ),
              ),
            Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: widget.highlighted ? 64 : 56,
                          height: widget.highlighted ? 64 : 56,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: widget.highlighted
                                ? AppColors.primaryContainer.withOpacity(0.2)
                                : AppColors.surfaceContainerHighest,
                            boxShadow: const [
                              BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
                            ],
                          ),
                          child: Icon(
                            widget.icon,
                            size: widget.highlighted ? 28 : 24,
                            color: widget.highlighted ? AppColors.primaryContainer : AppColors.onSurfaceVariant,
                          ),
                        ),
                        if (widget.highlighted)
                          Positioned(
                            top: -2,
                            right: -2,
                            child: Container(
                              width: 16,
                              height: 16,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.primaryContainer,
                                border: Border.all(color: AppColors.surfaceContainer, width: 2),
                                boxShadow: [
                                  BoxShadow(color: AppColors.primaryContainer.withOpacity(0.8), blurRadius: 6),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      widget.title,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.headlineSm.copyWith(fontSize: 19),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.subtitle,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodyMd.copyWith(color: AppColors.onSurfaceVariant, fontSize: 13.5),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
