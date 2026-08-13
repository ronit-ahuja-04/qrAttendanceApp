import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/tactile_widgets.dart';
import 'compose_announcement_screen.dart';

class _FacNotif {
  _FacNotif({
    required this.tag,
    required this.tagColor,
    required this.onTagColor,
    required this.body,
    required this.byIcon,
    required this.by,
    required this.timeIcon,
    required this.time,
    this.unread = false,
  });

  final String tag;
  final Color tagColor;
  final Color onTagColor;
  final String body;
  final IconData byIcon;
  final String by;
  final IconData timeIcon;
  final String time;
  bool unread;
}

/// Faculty Notifications — ported from the Stitch export (code.html:
/// "Faculty Notifications - VESIT"). Reachable from the Faculty Dashboard's
/// notification bell.
class FacultyNotificationsScreen extends StatefulWidget {
  const FacultyNotificationsScreen({super.key});

  @override
  State<FacultyNotificationsScreen> createState() => _FacultyNotificationsScreenState();
}

class _FacultyNotificationsScreenState extends State<FacultyNotificationsScreen> {
  late final List<_FacNotif> _items = [
    _FacNotif(
      tag: 'Admin Notice / Room Reallocation',
      tagColor: AppColors.primaryContainer,
      onTagColor: AppColors.onPrimaryContainer,
      body: 'Room 402 maintenance scheduled. Your 11:00 AM Database Systems lecture moved to Lab 301.',
      byIcon: Icons.account_circle,
      by: 'HOD / Academic Office',
      timeIcon: Icons.schedule,
      time: '15 mins ago',
      unread: true,
    ),
    _FacNotif(
      tag: 'Attendance Alert / Critical',
      tagColor: AppColors.errorContainer,
      onTagColor: AppColors.onErrorContainer,
      body: '5 students in Computer Networks (CS-302) have fallen below the 75% mandatory attendance threshold.',
      byIcon: Icons.bolt,
      by: 'Automated System Alert',
      timeIcon: Icons.schedule,
      time: '2 hours ago',
      unread: true,
    ),
    _FacNotif(
      tag: 'Lab Preparation',
      tagColor: AppColors.inverseSurface,
      onTagColor: AppColors.inverseOnSurface,
      body: "OS & Systems Lab hardware setups for tomorrow's session have been configured and verified.",
      byIcon: Icons.engineering,
      by: 'Alex Rivera (Lab Asst)',
      timeIcon: Icons.calendar_today,
      time: 'Yesterday',
    ),
    _FacNotif(
      tag: 'Faculty Meeting',
      tagColor: AppColors.secondaryContainer,
      onTagColor: AppColors.onSecondaryContainer,
      body: 'Monthly Department Curriculum Review meeting scheduled in Conference Room B.',
      byIcon: Icons.groups,
      by: 'Dean of Engineering',
      timeIcon: Icons.event,
      time: 'Oct 22, 02:00 PM',
    ),
  ];

  void _markAllRead() {
    setState(() {
      for (final n in _items) {
        n.unread = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Column(
          children: [
            _Header(onBack: () => Navigator.of(context).maybePop(), onMarkAllRead: _markAllRead),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                children: [
                  _SendAnnouncementCta(
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const ComposeAnnouncementScreen()),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...List.generate(_items.length * 2 - 1, (i) {
                    if (i.isOdd) return const SizedBox(height: 12);
                    final n = _items[i ~/ 2];
                    return GestureDetector(
                      onTap: () => setState(() => n.unread = false),
                      child: _NotifCard(n: n),
                    );
                  }),
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
  const _Header({required this.onBack, required this.onMarkAllRead});

  final VoidCallback onBack;
  final VoidCallback onMarkAllRead;

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
              'Notifications',
              textAlign: TextAlign.center,
              style: AppTextStyles.headlineSm.copyWith(color: AppColors.primary),
            ),
          ),
          TextButton(
            onPressed: onMarkAllRead,
            child: Text('Mark all as read', style: AppTextStyles.labelBold.copyWith(color: AppColors.primary, fontSize: 12)),
          ),
        ],
      ),
    );
  }
}

class _SendAnnouncementCta extends StatelessWidget {
  const _SendAnnouncementCta({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outlineVariant),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primaryContainer,
              boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 1))],
            ),
            alignment: Alignment.center,
            child: const Icon(Icons.campaign, color: AppColors.onPrimaryContainer),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Need to notify students?',
                  style: AppTextStyles.headlineSm.copyWith(fontSize: 16),
                ),
                const SizedBox(height: 2),
                Text(
                  'Broadcast class changes, assignments, or CA dates',
                  style: AppTextStyles.bodyMd.copyWith(color: AppColors.onSurfaceVariant, fontSize: 12.5),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.primaryContainer,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  const BoxShadow(color: AppColors.onPrimaryContainer, offset: Offset(0, 2)),
                  BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 4)),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.add, color: AppColors.onPrimaryContainer, size: 18),
                  const SizedBox(width: 2),
                  Text(
                    'Send',
                    style: AppTextStyles.labelBold.copyWith(color: AppColors.onPrimaryContainer, fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NotifCard extends StatelessWidget {
  const _NotifCard({required this.n});

  final _FacNotif n;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: n.unread ? 1 : 0.9,
      child: RaisedPanel(
        borderRadius: 12,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: n.tagColor,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: n.onTagColor.withOpacity(0.2)),
                    ),
                    child: Text(
                      n.tag.toUpperCase(),
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.8, color: n.onTagColor),
                    ),
                  ),
                ),
                if (n.unread) const SizedBox(width: 8),
                if (n.unread) const PilotLight(active: true, size: 10),
              ],
            ),
            const SizedBox(height: 10),
            Text(n.body, style: AppTextStyles.bodyMd.copyWith(color: AppColors.onSurface, height: 1.35)),
            const SizedBox(height: 10),
            DebossedWell(
              borderRadius: 8,
              padding: const EdgeInsets.all(8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _MetaLine(icon: n.byIcon, text: n.by),
                  _MetaLine(icon: n.timeIcon, text: n.time),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetaLine extends StatelessWidget {
  const _MetaLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.onSurfaceVariant),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            text,
            style: AppTextStyles.labelSm.copyWith(color: AppColors.onSurfaceVariant),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
