import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/tactile_widgets.dart';
import 'change_password_screen.dart';

/// Account Settings — ported from the Stitch export (code.html:
/// "VESIT Account Settings"). Security + Preferences rows, reachable
/// from the Profile tab / Profile screen's "Account Settings" row.
class AccountSettingsScreen extends StatefulWidget {
  const AccountSettingsScreen({
    super.key,
    this.name = 'Manish Awari',
    this.idLabel = 'Student ID: 4500454',
    this.department = 'Information Technology',
    this.appVersion = 'VESIT Mobile App Version 4.2.1-stable',
  });

  final String name;
  final String idLabel;
  final String department;
  final String appVersion;

  @override
  State<AccountSettingsScreen> createState() => _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends State<AccountSettingsScreen> {
  bool _pushNotifications = false;

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
                  onBack: () => Navigator.of(context).maybePop(),
                  onHelp: () => _comingSoon(context, 'Help'),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                    children: [
                      _ProfileBrief(
                        name: widget.name,
                        idLabel: widget.idLabel,
                        department: widget.department,
                      ),
                      const SizedBox(height: 24),
                      _SectionLabel('Security'),
                      const SizedBox(height: 8),
                      _SettingsRow(
                        icon: Icons.vpn_key_outlined,
                        label: 'Change Password',
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const ChangePasswordScreen()),
                        ),
                      ),
                      const SizedBox(height: 24),
                      _SectionLabel('Preferences'),
                      const SizedBox(height: 8),
                      _ToggleRow(
                        icon: Icons.notifications_outlined,
                        label: 'Push Notifications',
                        value: _pushNotifications,
                        onChanged: (v) => setState(() => _pushNotifications = v),
                      ),
                      const SizedBox(height: 32),
                      Center(
                        child: Text(
                          widget.appVersion,
                          style: AppTextStyles.labelSm.copyWith(color: AppColors.outline),
                        ),
                      ),
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
  const _Header({required this.onBack, required this.onHelp});

  final VoidCallback onBack;
  final VoidCallback onHelp;

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
              'Account Settings',
              textAlign: TextAlign.center,
              style: AppTextStyles.headlineSm.copyWith(color: AppColors.primary),
            ),
          ),
          IconButton(
            onPressed: onHelp,
            icon: const Icon(Icons.help_outline, color: AppColors.primary),
          ),
        ],
      ),
    );
  }
}

class _ProfileBrief extends StatelessWidget {
  const _ProfileBrief({required this.name, required this.idLabel, required this.department});

  final String name;
  final String idLabel;
  final String department;

  @override
  Widget build(BuildContext context) {
    return RaisedPanel(
      borderRadius: 20,
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.secondaryContainer,
                  border: Border.all(color: AppColors.surface, width: 4),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 6, offset: const Offset(0, 2))],
                ),
                alignment: Alignment.center,
                child: const Icon(Icons.person, size: 44, color: AppColors.onSurfaceVariant),
              ),
              Positioned(
                bottom: 2,
                right: 2,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: const BoxDecoration(color: AppColors.surface, shape: BoxShape.circle),
                  alignment: Alignment.center,
                  child: const PilotLight(active: true, size: 8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(name, style: AppTextStyles.headlineSm),
          const SizedBox(height: 4),
          Text(
            idLabel,
            style: AppTextStyles.bodyMd.copyWith(color: AppColors.onSurfaceVariant),
          ),
          Text(
            department,
            style: AppTextStyles.bodyMd.copyWith(color: AppColors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        text.toUpperCase(),
        style: AppTextStyles.labelBold.copyWith(color: AppColors.onSurfaceVariant, letterSpacing: 1.5),
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({required this.icon, required this.label, required this.onTap});

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
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.debossedWell,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.outlineVariant),
              ),
              alignment: Alignment.center,
              child: Icon(icon, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.onSurface)),
            ),
            const Icon(Icons.chevron_right, color: AppColors.outline),
          ],
        ),
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({required this.icon, required this.label, required this.value, required this.onChanged});

  final IconData icon;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outlineVariant.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.debossedWell,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.outlineVariant),
            ),
            alignment: Alignment.center,
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.onSurface)),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: Colors.white,
            activeTrackColor: AppColors.primaryContainer,
          ),
        ],
      ),
    );
  }
}
