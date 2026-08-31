import 'package:flutter/material.dart';
import '../ams/globals.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/tactile_widgets.dart';
import '../widgets/vesit_widgets.dart';
import 'login_screen.dart';

import 'notifications_screen.dart';
import 'student_dashboard_screen.dart';
import 'student_main_layout.dart';
import 'update_profile_picture_screen.dart';
import 'change_password_screen.dart';
import 'faculty_notifications_screen.dart';

/// Student Profile & Digital ID — mirrors the Stitch export (code.html):
/// ID badge card with photo upload well, name/roll/div/branch, contact
/// wells, then Account Settings + Logout rows.
class StudentProfileScreen extends StatefulWidget {
  final ScrollController? scrollController;
  const StudentProfileScreen({super.key, this.scrollController});

  @override
  State<StudentProfileScreen> createState() => _StudentProfileScreenState();
}

class _StudentProfileScreenState extends State<StudentProfileScreen> {
  void _logout(BuildContext context) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  void _refresh() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.vesitGray,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                _Header(
                  onNotifications: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                  ),
                ),
                Expanded(
                  child: ListView(
                    controller: widget.scrollController,
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 130),
                    children: [
                      _DigitalIdCard(
                        onEditPhoto: () async {
                          await Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const UpdateProfilePictureScreen()),
                          );
                          _refresh();
                        },
                      ),
                      const SizedBox(height: 24),
                      _SettingsButton(
                        icon: Icons.notifications_none_outlined,
                        label: 'Push Notifications',
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const FacultyNotificationSettingsScreen()),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _SettingsButton(
                        icon: Icons.lock_reset_outlined,
                        label: 'Change Password',
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const ChangePasswordScreen()),
                        ),
                      ),
                      const SizedBox(height: 12),
                      ValueListenableBuilder<ThemeMode>(
                        valueListenable: AmsGlobals.themeNotifier,
                        builder: (context, themeMode, _) {
                          final isDark = themeMode == ThemeMode.dark || 
                              (themeMode == ThemeMode.system && MediaQuery.of(context).platformBrightness == Brightness.dark);
                          return _SettingsButton(
                            icon: isDark ? Icons.dark_mode : Icons.light_mode,
                            label: 'Dark Mode',
                            trailing: Switch(
                              value: isDark,
                              activeColor: context.colors.vesitPrimary,
                              onChanged: (val) {
                                AmsGlobals.themeNotifier.value = val ? ThemeMode.dark : ThemeMode.light;
                              },
                            ),
                            onTap: () {
                               AmsGlobals.themeNotifier.value = isDark ? ThemeMode.light : ThemeMode.dark;
                            },
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      _LogoutButton(onTap: () => _logout(context)),
                    ],
                  ),
                ),
              ],
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
      height: 80,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: context.colors.vesitWhite,
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2))],
      ),
      child: Row(
        children: [
          const SizedBox(width: 24), // to balance notifications icon
          Expanded(
            child: Text(
              'Profile',
              textAlign: TextAlign.center,
              style: context.textStyles.vesitHeadlineSm.copyWith(color: context.colors.vesitPrimary),
            ),
          ),
          IconButton(
            onPressed: onNotifications,
            icon: Icon(Icons.notifications_outlined, color: context.colors.vesitPrimary),
          ),
        ],
      ),
    );
  }
}

class _DigitalIdCard extends StatelessWidget {
  const _DigitalIdCard({required this.onEditPhoto});

  final VoidCallback onEditPhoto;

  @override
  Widget build(BuildContext context) {
    final user = AmsGlobals.loggedInUser;
    
    return VesitCard(
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
                    onTap: onEditPhoto,
                    child: Container(
                      width: 110,
                      height: 130,
                      decoration: BoxDecoration(
                        color: context.colors.vesitGray,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.grey.shade300,
                          width: 2,
                          style: BorderStyle.solid,
                        ),
                        image: user?.profilePictureUrl != null && user!.profilePictureUrl!.isNotEmpty
                            ? DecorationImage(
                                image: NetworkImage(user.profilePictureUrl!),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      alignment: Alignment.center,
                      padding: const EdgeInsets.all(10),
                      child: user?.profilePictureUrl == null
                          ? Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.add_a_photo_outlined, color: Colors.grey.shade600, size: 30),
                                const SizedBox(height: 6),
                                Text(
                                  'TAP TO UPLOAD PROFILE PICTURE',
                                  textAlign: TextAlign.center,
                                  style: context.textStyles.vesitLabelSm.copyWith(fontSize: 9, height: 1.2),
                                ),
                              ],
                            )
                          : null,
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
                      decoration: BoxDecoration(
                        border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                            Text(
                              user?.formattedName.toUpperCase() ?? 'MANISH C. AWARI',
                              style: context.textStyles.vesitHeadlineSm.copyWith(fontSize: 19, height: 1.1),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              user?.rollNo ?? '4500054',
                              style: context.textStyles.vesitLabelBold.copyWith(color: context.colors.vesitPrimary, fontSize: 15, letterSpacing: 1.5),
                            ),
                            if (user?.branch != null) ...[
                              const SizedBox(height: 8),
                              Text(
                                'BRANCH',
                                style: context.textStyles.vesitLabelSm.copyWith(color: Colors.grey.shade600, fontSize: 10),
                              ),
                              Text(
                                user!.branch!.toUpperCase(),
                                style: context.textStyles.vesitBodySm.copyWith(color: context.colors.onSurface),
                              ),
                            ],
                            if (user?.division != null) ...[
                              const SizedBox(height: 8),
                              Text(
                                'DIVISION',
                                style: context.textStyles.vesitLabelSm.copyWith(color: Colors.grey.shade600, fontSize: 10),
                              ),
                              Text(
                                user!.division!.toUpperCase(),
                                style: context.textStyles.vesitBodySm.copyWith(color: context.colors.onSurface),
                              ),
                            ],
                            if (user?.coreBatch != null) ...[
                              const SizedBox(height: 8),
                              Text(
                                'CORE BATCH',
                                style: context.textStyles.vesitLabelSm.copyWith(color: Colors.grey.shade600, fontSize: 10),
                              ),
                              Text(
                                user!.coreBatch!.toUpperCase(),
                                style: context.textStyles.vesitBodySm.copyWith(color: context.colors.onSurface),
                              ),
                            ],
                            if (user?.electiveBatch != null) ...[
                              const SizedBox(height: 8),
                              Text(
                                'ELECTIVE BATCH',
                                style: context.textStyles.vesitLabelSm.copyWith(color: Colors.grey.shade600, fontSize: 10),
                              ),
                              Text(
                                user!.electiveBatch!.toUpperCase(),
                                style: context.textStyles.vesitBodySm.copyWith(color: context.colors.onSurface),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _ContactWell(label: 'Email ID', value: user?.email ?? '2025.manish.awari@ves.ac.in'),
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
        Text(label.toUpperCase(), style: context.textStyles.vesitLabelSm.copyWith(fontSize: 9, letterSpacing: 1)),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: context.colors.vesitTextHeading)),
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
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: context.colors.vesitGray,
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(), style: context.textStyles.vesitLabelSm.copyWith(fontSize: 9, letterSpacing: 1, color: Colors.grey.shade600)),
            const SizedBox(height: 4),
          Text(value, style: context.textStyles.vesitBodyMd.copyWith(fontWeight: FontWeight.w600, fontSize: 14)),
        ],
      ),
    );
  }
}

class _SettingsButton extends StatelessWidget {
  const _SettingsButton({
    required this.label,
    required this.icon,
    required this.onTap,
    this.trailing,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.colors.vesitWhite,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: context.colors.vesitPrimary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: context.colors.vesitPrimary, size: 20),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(label, style: context.textStyles.vesitBodyMd.copyWith(fontWeight: FontWeight.w600)),
                ),
                trailing ?? const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
              ],
            ),
          ),
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
          color: context.colors.error.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: context.colors.error),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.6),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: context.colors.error),
              ),
              alignment: Alignment.center,
              child: Icon(Icons.logout, color: context.colors.error),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text('Logout', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: context.colors.error)),
            ),
            Icon(Icons.chevron_right, color: context.colors.error),
          ],
        ),
      ),
    );
  }
}
