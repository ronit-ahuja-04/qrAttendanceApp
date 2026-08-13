import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/tactile_widgets.dart';

class _Notif {
  _Notif({
    required this.tag,
    required this.tagColor,
    required this.onTagColor,
    required this.title,
    required this.byIcon,
    required this.by,
    required this.timeIcon,
    required this.time,
    this.body,
    this.unread = false,
  });

  final String tag;
  final Color tagColor;
  final Color onTagColor;
  final String title;
  final String? body;
  final IconData byIcon;
  final String by;
  final IconData timeIcon;
  final String time;
  bool unread;
}

/// Notifications — ported from the Stitch export (code.html:
/// "VESIT Attendance - Notifications").
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late final List<_Notif> _items = [
    _Notif(
      tag: 'Schedule Change',
      tagColor: AppColors.primaryContainer,
      onTagColor: AppColors.onPrimaryContainer,
      title: 'Database Systems lecture relocated to Lab 301 today.',
      byIcon: Icons.person,
      by: 'Dr. Julian Sterling (Faculty)',
      timeIcon: Icons.schedule,
      time: '10 mins ago • Oct 24, 08:50 AM',
      unread: true,
    ),
    _Notif(
      tag: 'Lecture Cancelled',
      tagColor: AppColors.errorContainer,
      onTagColor: AppColors.onErrorContainer,
      title: 'Java Programming lab session canceled.',
      byIcon: Icons.admin_panel_settings,
      by: 'Prof. Vivek Sharma',
      timeIcon: Icons.schedule,
      time: '1 hour ago • Oct 24, 08:00 AM',
    ),
    _Notif(
      tag: 'Test / CA',
      tagColor: AppColors.inverseSurface,
      onTagColor: AppColors.inverseOnSurface,
      title: 'CA-1 Quiz for Computer Networks scheduled for Friday at 10:00 AM.',
      body: 'Syllabus: Modules 1 & 2.',
      byIcon: Icons.school,
      by: 'Prof. Robert Lang (Faculty)',
      timeIcon: Icons.calendar_today,
      time: 'Yesterday • Oct 23, 04:30 PM',
    ),
    _Notif(
      tag: 'Prerequisite',
      tagColor: AppColors.secondaryContainer,
      onTagColor: AppColors.onSecondaryContainer,
      title: "Please download and configure Docker desktop prior to tomorrow's OS Lab.",
      byIcon: Icons.engineering,
      by: 'Alex Rivera (Lab Assistant)',
      timeIcon: Icons.history,
      time: 'Yesterday • Oct 23, 02:15 PM',
    ),
    _Notif(
      tag: 'Facility Notice',
      tagColor: AppColors.surfaceContainerHigh,
      onTagColor: AppColors.onSurfaceVariant,
      title: 'Central Library, Room No. 302, 305, 306 booked for Campus Hackathon.',
      byIcon: Icons.location_city,
      by: 'Central Library Admin',
      timeIcon: Icons.event_note,
      time: 'Oct 22, 11:00 AM',
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
      backgroundColor: AppColors.wall,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                _Header(onBack: () => Navigator.of(context).maybePop(), onMarkAllRead: _markAllRead),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                    itemCount: _items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, i) {
                      final n = _items[i];
                      return GestureDetector(
                        onTap: () => setState(() => n.unread = false),
                        child: _NotifCard(n: n),
                      );
                    },
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
              style: AppTextStyles.headlineSm.copyWith(color: AppColors.primary),
            ),
          ),
          TextButton(
            onPressed: onMarkAllRead,
            child: Text('Mark all as read', style: AppTextStyles.labelBold.copyWith(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }
}

class _NotifCard extends StatelessWidget {
  const _NotifCard({required this.n});

  final _Notif n;

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
                Container(
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
                if (n.unread) const PilotLight(active: true, size: 8),
              ],
            ),
            const SizedBox(height: 10),
            Text(n.title, style: AppTextStyles.headlineSm.copyWith(fontSize: 16, height: 1.3)),
            if (n.body != null) ...[
              const SizedBox(height: 4),
              Text(n.body!, style: AppTextStyles.bodyMd.copyWith(color: AppColors.onSurfaceVariant)),
            ],
            const SizedBox(height: 10),
            DebossedWell(
              borderRadius: 8,
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _MetaLine(icon: n.byIcon, text: n.by),
                  const SizedBox(height: 4),
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
        Text(text, style: AppTextStyles.labelSm.copyWith(color: AppColors.onSurfaceVariant)),
      ],
    );
  }
}
