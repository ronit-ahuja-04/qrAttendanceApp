import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/tactile_widgets.dart';
import 'account_settings_screen.dart';
import 'faculty_notifications_screen.dart';
import 'login_screen.dart';
import 'update_profile_picture_screen.dart';

/// Faculty Profile & Digital ID Badge — mirrors the Stitch export
/// (code.html): circular avatar with camera-edit badge, name, staff ID
/// pill, department/designation grid, then Account Settings + Logout.
class FacultyProfileScreen extends StatelessWidget {
  const FacultyProfileScreen({super.key});

  void _logout(BuildContext context) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Column(
          children: [
            _Header(
              onNotifications: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const FacultyNotificationsScreen()),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
                children: [
                  Text(
                    'DIGITAL ID BADGE',
                    style: AppTextStyles.labelBold.copyWith(letterSpacing: 1.5),
                  ),
                  const SizedBox(height: 12),
                  _IdBadgeCard(
                    onEditPhoto: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const UpdateProfilePictureScreen()),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'MANAGEMENT OPTIONS',
                    style: AppTextStyles.labelBold.copyWith(letterSpacing: 1.5),
                  ),
                  const SizedBox(height: 12),
                  _SettingsButton(
                    icon: Icons.settings_outlined,
                    label: 'Account Settings',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const AccountSettingsScreen(
                          name: 'Prof. Vivek Sharma',
                          idLabel: 'Faculty ID: 10245',
                          department: 'Information Technology',
                          appVersion: 'VESIT 2026 Mobile App Version 1.1',
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _LogoutButton(onTap: () => _logout(context)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onNotifications});

  final VoidCallback onNotifications;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.outlineVariant)),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(Icons.arrow_back, color: AppColors.onSurfaceVariant),
          ),
          Expanded(
            child: Text(
              'VESIT',
              textAlign: TextAlign.center,
              style: AppTextStyles.headlineMd.copyWith(color: AppColors.primary),
            ),
          ),
          IconButton(
            onPressed: onNotifications,
            icon: const Icon(Icons.notifications_outlined, color: AppColors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _IdBadgeCard extends StatelessWidget {
  const _IdBadgeCard({required this.onEditPhoto});

  final VoidCallback onEditPhoto;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -20,
            left: -16,
            right: -16,
            child: Container(height: 4, color: AppColors.primary),
          ),
          Column(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 128,
                    height: 128,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.surfaceContainerHigh,
                      border: Border.all(color: AppColors.outlineVariant, width: 2),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(Icons.person, size: 56, color: AppColors.onSurfaceVariant),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: onEditPhoto,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.outlineVariant),
                          boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))],
                        ),
                        child: const Icon(Icons.photo_camera, color: Colors.white, size: 18),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text('Prof. Vivek Sharma', style: AppTextStyles.headlineSm),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.secondaryContainer,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: AppColors.outlineVariant),
                ),
                child: Text(
                  'VESIT-FE-102',
                  style: AppTextStyles.labelBold.copyWith(color: AppColors.onSecondaryContainer),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.only(top: 16),
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: AppColors.outlineVariant)),
                ),
                child: Row(
                  children: const [
                    Expanded(child: _InfoField(label: 'Department', value: 'Computer Eng.')),
                    Expanded(child: _InfoField(label: 'Designation', value: 'Assoc. Professor')),
                  ],
                ),
              ),
            ],
          ),
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
        Text(label.toUpperCase(), style: AppTextStyles.labelSm),
        const SizedBox(height: 2),
        Text(value, style: AppTextStyles.labelMd.copyWith(color: AppColors.onSurface)),
      ],
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
      borderRadius: 12,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.surfaceContainer,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.outlineVariant),
              ),
              alignment: Alignment.center,
              child: Icon(icon, color: AppColors.onSurfaceVariant),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label, style: AppTextStyles.labelMd.copyWith(color: AppColors.onSurface)),
            ),
            const Icon(Icons.chevron_right, color: AppColors.onSurfaceVariant),
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
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.errorContainer,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.error),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.5),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.error),
              ),
              alignment: Alignment.center,
              child: const Icon(Icons.logout, color: AppColors.error),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Logout',
                style: AppTextStyles.labelMd.copyWith(color: AppColors.error, fontWeight: FontWeight.bold),
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.error),
          ],
        ),
      ),
    );
  }
}
