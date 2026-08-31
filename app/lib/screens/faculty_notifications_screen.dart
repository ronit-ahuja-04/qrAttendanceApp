import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../ams/globals.dart';
import '../ams/api_services.dart';
import '../ams/notification_service.dart';

/// Faculty Notification Settings
/// A dedicated screen strictly for toggling notification preferences.
/// The actual notification inbox is accessed from the Dashboard.
class FacultyNotificationSettingsScreen extends StatefulWidget {
  const FacultyNotificationSettingsScreen({super.key});

  @override
  State<FacultyNotificationSettingsScreen> createState() => _FacultyNotificationSettingsScreenState();
}

class _FacultyNotificationSettingsScreenState extends State<FacultyNotificationSettingsScreen> {
  // Notification Preferences
  bool _alertsEnabled = true;
  bool _proxyEnabled = true;
  bool _attendanceEnabled = true;

  bool _pushEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _pushEnabled = prefs.getBool('notif_master') ?? true;
      _alertsEnabled = prefs.getBool('notif_alerts') ?? true;
      _proxyEnabled = prefs.getBool('notif_proxy') ?? true;
      _attendanceEnabled = prefs.getBool('notif_attendance') ?? true;
    });
  }

  Future<void> _savePreference(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
    _syncPrefsToBackend();
  }

  void _syncPrefsToBackend() {
    if (AmsGlobals.loggedInUser != null) {
      ApiSessionService().updateNotificationPrefs(
        AmsGlobals.loggedInUser!.id,
        {
          'notif_master': _pushEnabled,
          'notif_alerts': _alertsEnabled,
          'notif_proxy': _proxyEnabled,
          'notif_attendance': _attendanceEnabled,
        },
      );
    }
  }

  Future<void> _toggleMasterPush(bool enabled) async {
    setState(() => _pushEnabled = enabled);
    await _savePreference('notif_master', enabled);
    
    // Update Backend
    if (AmsGlobals.loggedInUser != null) {
      if (enabled) {
        // Re-register token
        if (NotificationService().currentToken != null) {
          await ApiSessionService().updateFcmToken(AmsGlobals.loggedInUser!.id, NotificationService().currentToken!);
        }
      } else {
        // Deregister token
        await ApiSessionService().updateFcmToken(AmsGlobals.loggedInUser!.id, '');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.vesitGray,
      body: SafeArea(
        child: Column(
          children: [
            _Header(onBack: () => Navigator.of(context).maybePop()),
            
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text(
                    'MASTER ALLOWANCE',
                    style: context.textStyles.vesitLabelBold.copyWith(color: Colors.grey.shade600, letterSpacing: 1.2),
                  ),
                  const SizedBox(height: 8),
                  _ToggleCard(
                    title: 'Allow Push Notifications',
                    subtitle: 'Turn this off to stop receiving all push notifications from the server.',
                    icon: Icons.notifications_active,
                    value: _pushEnabled,
                    onChanged: _toggleMasterPush,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'CHOOSE WHAT YOU GET NOTIFIED ABOUT (IN-APP)',
                    style: context.textStyles.vesitLabelBold.copyWith(color: Colors.grey.shade600, letterSpacing: 1.2),
                  ),
                  const SizedBox(height: 16),
                  
                  _ToggleCard(
                    title: 'Lecture/Lab Alerts',
                    subtitle: 'Get reminded 15 mins before your scheduled classes.',
                    icon: Icons.alarm,
                    value: _alertsEnabled,
                    onChanged: (v) {
                      setState(() => _alertsEnabled = v);
                      _savePreference('notif_alerts', v);
                    },
                  ),
                  const SizedBox(height: 12),
                  
                  _ToggleCard(
                    title: 'Proxy Approvals',
                    subtitle: 'Get notified when your proxy requests are accepted or rejected.',
                    icon: Icons.check_circle_outline,
                    value: _proxyEnabled,
                    onChanged: (v) {
                      setState(() => _proxyEnabled = v);
                      _savePreference('notif_proxy', v);
                    },
                  ),
                  const SizedBox(height: 12),
                  
                  _ToggleCard(
                    title: 'Attendance Reports',
                    subtitle: 'Receive daily summaries of your marked attendance sessions.',
                    icon: Icons.analytics_outlined,
                    value: _attendanceEnabled,
                    onChanged: (v) {
                      setState(() => _attendanceEnabled = v);
                      _savePreference('notif_attendance', v);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ToggleCard extends StatelessWidget {
  const _ToggleCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.colors.vesitWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: context.colors.vesitPrimary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(icon, color: context.colors.vesitPrimary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: context.textStyles.vesitBodyMd.copyWith(fontWeight: FontWeight.bold, color: context.colors.vesitTextHeading)),
                const SizedBox(height: 4),
                Text(subtitle, style: context.textStyles.vesitLabelSm.copyWith(color: Colors.grey.shade600, height: 1.3)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Switch(
            value: value,
            activeColor: context.colors.vesitPrimary,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onBack});

  final VoidCallback onBack;

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
            onPressed: onBack,
            icon: Icon(Icons.arrow_back, color: Colors.grey.shade600),
          ),
          Expanded(
            child: Text(
              'Notification Settings',
              textAlign: TextAlign.center,
              style: context.textStyles.vesitHeadlineMd.copyWith(color: context.colors.vesitPrimary),
            ),
          ),
          const SizedBox(width: 48), // Balance for back button
        ],
      ),
    );
  }
}
