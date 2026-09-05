import 'package:flutter/material.dart';
import '../ams/globals.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/tactile_widgets.dart';
import '../widgets/vesit_widgets.dart';
import 'login_screen.dart';
import 'update_profile_picture_screen.dart';
import 'change_password_screen.dart';
import 'faculty_notifications_screen.dart';
import 'faculty_timetable_manager_screen.dart';

/// Faculty Profile & Digital ID Badge — mirrors the Stitch export
/// (code.html): circular avatar with camera-edit badge, name, staff ID
/// pill, department/designation grid, then Account Settings + Logout.
class FacultyProfileScreen extends StatefulWidget {
  const FacultyProfileScreen({super.key, this.scrollController});
  final ScrollController? scrollController;

  @override
  State<FacultyProfileScreen> createState() => _FacultyProfileScreenState();
}

class _FacultyProfileScreenState extends State<FacultyProfileScreen> {
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
    final user = AmsGlobals.loggedInUser;
    
    // Hardcoded for INFT
    const String department = 'INFT';
    
    return Scaffold(
      backgroundColor: context.colors.vesitGray,
      body: SafeArea(
        child: Column(
          children: [
            const _Header(),
            Expanded(
              child: ListView(
                controller: widget.scrollController,
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 130),
                children: [
                  Text(
                    'DIGITAL ID BADGE',
                    style: context.textStyles.vesitLabelBold.copyWith(letterSpacing: 1.5, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 12),
                  _IdBadgeCard(
                    onEditPhoto: () async {
                      await Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const UpdateProfilePictureScreen()),
                      );
                      _refresh();
                    },
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'MANAGEMENT OPTIONS',
                    style: context.textStyles.vesitLabelBold.copyWith(letterSpacing: 1.5, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 12),
                  if (user?.role != 'student')
                    _SettingsButton(
                      icon: Icons.calendar_month_outlined,
                      label: 'Manage Timetable',
                      onTap: () async {
                        await Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const FacultyTimetableManagerScreen()),
                        );
                        _refresh();
                      },
                    ),
                  if (user?.role != 'student') const SizedBox(height: 12),
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
                            AmsGlobals.setTheme(val ? ThemeMode.dark : ThemeMode.light);
                          },
                        ),
                        onTap: () {
                           AmsGlobals.setTheme(isDark ? ThemeMode.light : ThemeMode.dark);
                        },
                      );
                    },
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
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: context.colors.vesitWhite,
        border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).maybePop(),
            icon: Icon(Icons.arrow_back, color: Colors.grey.shade600),
          ),
          Expanded(
            child: Text(
              'VESIT',
              textAlign: TextAlign.center,
              style: context.textStyles.vesitHeadlineMd.copyWith(color: context.colors.vesitPrimary),
            ),
          ),
          const SizedBox(width: 48),
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
    final user = AmsGlobals.loggedInUser;
    final name = user?.formattedName ?? 'Faculty Member';
    final rawId = user?.rollNo ?? (user?.role == 'faculty' ? 'FACULTY' : user?.id) ?? "0000";
    final rollNo = rawId.toUpperCase().replaceAll('VESIT-', '').replaceAll('FAC-', '');
    
    // Hardcoded for INFT
    const String department = 'INFT';
    
    // Generate initials for fallback avatar
    String initials = "U";
    if (name.isNotEmpty) {
      List<String> parts = name.split(" ");
      if (parts.length >= 2 && parts[1].isNotEmpty) {
        initials = "${parts[0][0]}${parts[1][0]}".toUpperCase();
      } else {
        initials = parts[0][0].toUpperCase();
      }
    }

    return VesitCard(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
      child: Stack(
        children: [
          Positioned(
            top: -20,
            left: -16,
            right: -16,
            child: Container(height: 4, color: context.colors.vesitPrimary),
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
                      color: context.colors.vesitGray,
                      border: Border.all(color: Colors.grey.shade300, width: 2),
                    ),
                    alignment: Alignment.center,
                    child: (user?.profilePictureUrl != null && user!.profilePictureUrl!.isNotEmpty)
                        ? ClipOval(
                            child: Image.network(
                              user.profilePictureUrl!,
                              width: 128,
                              height: 128,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Text(initials, style: context.textStyles.vesitHeadlineMd.copyWith(color: context.colors.vesitPrimary)),
                            ),
                          )
                        : Text(initials, style: context.textStyles.vesitHeadlineMd.copyWith(color: context.colors.vesitPrimary)),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: onEditPhoto,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: context.colors.vesitPrimary,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.grey.shade300),
                          boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))],
                        ),
                        child: const Icon(Icons.photo_camera, color: Colors.white, size: 18),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(name, style: context.textStyles.vesitHeadlineSm, textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: context.colors.vesitPrimary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: context.colors.vesitPrimary.withOpacity(0.2)),
                ),
                child: Text(
                  rollNo,
                  style: context.textStyles.vesitLabelBold.copyWith(color: context.colors.vesitPrimary),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.only(top: 16),
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: Colors.grey.shade300)),
                ),
                alignment: Alignment.center,
                child: const _InfoField(label: 'Department', value: department, centerAlign: true),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoField extends StatelessWidget {
  const _InfoField({required this.label, required this.value, this.centerAlign = false});

  final String label;
  final String value;
  final bool centerAlign;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: centerAlign ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: context.textStyles.vesitLabelSm.copyWith(color: Colors.grey.shade600)),
        const SizedBox(height: 2),
        Text(value, style: context.textStyles.vesitBodyMd.copyWith(color: context.colors.vesitTextHeading)),
      ],
    );
  }
}

class _SettingsButton extends StatefulWidget {
  const _SettingsButton({required this.icon, required this.label, required this.onTap, this.trailing});

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  State<_SettingsButton> createState() => _SettingsButtonState();
}

class _SettingsButtonState extends State<_SettingsButton> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: _isHovering ? 1.02 : 1.0,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: context.colors.vesitWhite,
          borderRadius: BorderRadius.circular(12),
          boxShadow: _isHovering ? [
            BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 12, offset: const Offset(0, 4))
          ] : [
            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            onHover: (h) => setState(() => _isHovering = h),
            onHighlightChanged: (h) => setState(() => _isHovering = h),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: context.colors.vesitPrimary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    child: Icon(widget.icon, color: context.colors.vesitPrimary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(widget.label, style: context.textStyles.vesitBodyMd.copyWith(color: context.colors.vesitTextHeading)),
                  ),
                  widget.trailing ?? const Icon(Icons.chevron_right, color: Colors.grey),
                ],
              ),
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
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: context.colors.error.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: context.colors.error.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: context.colors.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: Icon(Icons.logout, color: context.colors.error),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Logout',
                style: context.textStyles.vesitBodyMd.copyWith(color: context.colors.error, fontWeight: FontWeight.bold),
              ),
            ),
            Icon(Icons.chevron_right, color: context.colors.error),
          ],
        ),
      ),
    );
  }
}
