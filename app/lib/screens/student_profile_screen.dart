import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/tactile_widgets.dart';
import 'login_screen.dart';
import 'account_settings_screen.dart';
import 'notifications_screen.dart';
import 'student_dashboard_screen.dart';
import 'update_profile_picture_screen.dart';

/// Student Profile & Digital ID — mirrors the Stitch export (code.html):
/// ID badge card with photo upload well, name/roll/div/branch, contact
/// wells, then Account Settings + Logout rows.
class StudentProfileScreen extends StatelessWidget {
  const StudentProfileScreen({super.key});

  void _comingSoon(BuildContext context, String label) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$label — coming soon'), duration: const Duration(seconds: 1)),
    );
  }

  void _logout(BuildContext context) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
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
                  onBack: () {
                    if (Navigator.of(context).canPop()) {
                      Navigator.of(context).pop();
                    } else {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (_) => const StudentDashboardScreen()),
                      );
                    }
                  },
                  onNotifications: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                    children: [
                      const _DigitalIdCard(),
                      const SizedBox(height: 24),
                      _SettingsButton(
                        icon: Icons.vpn_key_outlined,
                        label: 'Account Settings',
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const AccountSettingsScreen()),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _LogoutButton(onTap: () => _logout(context)),
                    ],
                  ),
                ),
              ],
            ),
            const Align(
              alignment: Alignment.bottomCenter,
              child: TactileBottomNav(currentIndex: 3),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onBack, required this.onNotifications});

  final VoidCallback onBack;
  final VoidCallback onNotifications;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2))],
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back, color: AppColors.primary),
          ),
          Expanded(
            child: Text(
              'VESIT',
              textAlign: TextAlign.center,
              style: AppTextStyles.headlineSm.copyWith(color: AppColors.primary),
            ),
          ),
          IconButton(
            onPressed: onNotifications,
            icon: const Icon(Icons.notifications_outlined, color: AppColors.primary),
          ),
        ],
      ),
    );
  }
}

class _DigitalIdCard extends StatelessWidget {
  const _DigitalIdCard();

  @override
  Widget build(BuildContext context) {
    return RaisedPanel(
      borderRadius: 20,
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const UpdateProfilePictureScreen()),
                    ),
                    child: Container(
                    width: 110,
                    height: 130,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.outlineVariant,
                        width: 2,
                        style: BorderStyle.solid,
                      ),
                    ),
                    alignment: Alignment.center,
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.add_a_photo_outlined, color: AppColors.onSurfaceVariant, size: 30),
                        const SizedBox(height: 6),
                        Text(
                          'TAP TO UPLOAD PROFILE PICTURE',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.labelSm.copyWith(fontSize: 9, height: 1.2),
                        ),
                      ],
                    ),
                  ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: AppColors.outlineVariant),
                    ),
                    child: const Text(
                      'VALID: 2029',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.onSurface),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.only(bottom: 8),
                      decoration: const BoxDecoration(
                        border: Border(bottom: BorderSide(color: AppColors.outlineVariant)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'MANISH C. AWARI',
                            style: AppTextStyles.headlineSm.copyWith(fontSize: 19, height: 1.1),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '4500054',
                            style: AppTextStyles.labelBold.copyWith(color: AppColors.primary, fontSize: 15, letterSpacing: 1.5),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: _InfoField(label: 'Division', value: 'D10A')),
                        Expanded(child: _InfoField(label: 'Branch', value: 'INFT')),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const _ContactWell(label: 'Email ID', value: '2025.manish.awari@ves.ac.in'),
          const SizedBox(height: 10),
          const _ContactWell(label: 'Phone Number', value: '+91 12345 67890'),
        ],
      ),
    );
  }
}

class _InfoField extends StatelessWidget {
  const _InfoField({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: AppTextStyles.labelSm.copyWith(fontSize: 9, letterSpacing: 1)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.onSurface)),
      ],
    );
  }
}

class _ContactWell extends StatelessWidget {
  const _ContactWell({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return DebossedWell(
      borderRadius: 10,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(), style: AppTextStyles.labelSm.copyWith(fontSize: 9, letterSpacing: 1)),
          const SizedBox(height: 2),
          Text(value, style: AppTextStyles.bodyMd.copyWith(fontWeight: FontWeight.w600, fontSize: 13)),
        ],
      ),
    );
  }
}

class _SettingsButton extends StatelessWidget {
  const _SettingsButton({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PushSurfaceButton(
      onPressed: onTap,
      borderRadius: 16,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.outlineVariant),
              ),
              alignment: Alignment.center,
              child: Icon(icon, color: AppColors.primary),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.onSurface)),
            ),
            const Icon(Icons.chevron_right, color: AppColors.outline),
          ],
        ),
      ),
    );
  }
}

class _LogoutButton extends StatelessWidget {
  const _LogoutButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.error.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.error),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.6),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.error),
              ),
              alignment: Alignment.center,
              child: const Icon(Icons.logout, color: AppColors.error),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Text('Logout', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.error)),
            ),
            const Icon(Icons.chevron_right, color: AppColors.error),
          ],
        ),
      ),
    );
  }
}
