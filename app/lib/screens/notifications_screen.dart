import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/tactile_widgets.dart';
import '../ams/globals.dart';
import '../ams/notification_service.dart';
import 'dart:async';

class _Notif {
  _Notif({
    required this.id,
    required this.tag,
    required this.tagColorName,
    required this.onTagColorName,
    required this.title,
    required this.byIcon,
    required this.by,
    required this.timeIcon,
    required this.time,
    this.body,
    this.unread = false,
  });

  final String id;
  final String tag;
  final String tagColorName;
  final String onTagColorName;
  final String title;
  final String? body;
  final IconData byIcon;
  final String by;
  final IconData timeIcon;
  final String time;
  bool unread;
}

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<_Notif> _items = [];
  bool _isLoading = true;

  StreamSubscription? _eventSub;

  @override
  void initState() {
    super.initState();
    _fetchData();
    _eventSub = NotificationService().events.listen((_) {
      _fetchData();
    });
  }

  @override
  void dispose() {
    _eventSub?.cancel();
    super.dispose();
  }



  IconData _getIcon(String name) {
    switch (name) {
      case 'person': return Icons.person;
      case 'admin_panel_settings': return Icons.admin_panel_settings;
      case 'school': return Icons.school;
      case 'engineering': return Icons.engineering;
      case 'location_city': return Icons.location_city;
      default: return Icons.notifications;
    }
  }

  String _formatDate(String isoString) {
    final d = DateTime.parse(isoString).toLocal();
    final now = DateTime.now();
    final diff = now.difference(d);
    
    String timeStr = '${d.hour > 12 ? d.hour - 12 : (d.hour == 0 ? 12 : d.hour)}:${d.minute.toString().padLeft(2, '0')} ${d.hour >= 12 ? 'PM' : 'AM'}';
    
    if (diff.inDays == 0 && now.day == d.day) {
      if (diff.inHours == 0) return '${diff.inMinutes} mins ago • $timeStr';
      return '${diff.inHours} hours ago • $timeStr';
    } else if (diff.inDays == 1 || (diff.inDays == 0 && now.day != d.day)) {
      return 'Yesterday • $timeStr';
    }
    
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[d.month - 1]} ${d.day} • $timeStr';
  }

  Future<void> _fetchData() async {
    if (_items.isEmpty) setState(() => _isLoading = true);
    final user = AmsGlobals.loggedInUser;
    if (user != null) {
      final raw = await AmsGlobals.sessionService.getNotifications(user.id);
      if (mounted) {
        setState(() {
          _items = raw.map<_Notif>((json) {
            final tag = json['tag']?.toString() ?? 'Notification';
            final isAttendance = tag.toLowerCase().contains('attendance');
            return _Notif(
              id: json['id'],
              tag: tag,
              tagColorName: isAttendance ? 'vesitGreen' : (json['tagColor'] ?? 'primaryContainer'),
              onTagColorName: isAttendance ? 'onVesitGreen' : (json['onTagColor'] ?? 'onPrimaryContainer'),
              title: json['title'] ?? '',
              body: json['body'],
              byIcon: _getIcon(json['byIcon'] ?? 'person'),
              by: json['byName'] ?? 'System',
              timeIcon: Icons.schedule,
              time: _formatDate(json['createdAt']),
              unread: json['isRead'] == 0,
            );
          }).toList();
          _isLoading = false;
        });
      }
    } else {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _markAllRead() async {
    final user = AmsGlobals.loggedInUser;
    if (user == null) return;
    
    setState(() {
      for (final n in _items) n.unread = false;
    });
    
    await AmsGlobals.sessionService.markAllNotificationsAsRead(user.id);
  }
  
  Future<void> _markRead(String id) async {
    await AmsGlobals.sessionService.markNotificationAsRead(id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.wall,
      body: SafeArea(
        child: Column(
          children: [
            _Header(onBack: () => Navigator.of(context).maybePop(), onMarkAllRead: _markAllRead),
            Expanded(
              child: _isLoading 
                ? const Center(child: CircularProgressIndicator())
                : _items.isEmpty 
                  ? Center(child: Text("No notifications yet.", style: context.textStyles.vesitBodyMd))
                  : RefreshIndicator(
                      onRefresh: _fetchData,
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                        itemCount: _items.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, i) {
                          final n = _items[i];
                          return GestureDetector(
                            onTap: () {
                              if (n.unread) {
                                setState(() => n.unread = false);
                                _markRead(n.id);
                              }
                            },
                            child: _NotifCard(n: n),
                          );
                        },
                      ),
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
      decoration: BoxDecoration(
        color: context.colors.surface,
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2))],
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: Icon(Icons.arrow_back, color: context.colors.primary),
          ),
          Expanded(
            child: Text(
              'Notifications',
              style: context.textStyles.headlineSm.copyWith(color: context.colors.primary),
            ),
          ),
          TextButton(
            onPressed: onMarkAllRead,
            child: Text('Mark all as read', style: context.textStyles.labelBold.copyWith(color: context.colors.primary)),
          ),
        ],
      ),
    );
  }
}


  Color _getSemanticColor(BuildContext context, String name, {bool isOn = false}) {
    if (name == 'vesitGreen') return context.colors.vesitGreen.withValues(alpha: 0.15);
    if (name == 'onVesitGreen') return context.colors.vesitGreen;

    switch (name) {
      case 'primaryContainer': return context.colors.primaryContainer;
      case 'onPrimaryContainer': return context.colors.onPrimaryContainer;
      case 'errorContainer': return context.colors.errorContainer;
      case 'onErrorContainer': return context.colors.onErrorContainer;
      case 'secondaryContainer': return context.colors.secondaryContainer;
      case 'onSecondaryContainer': return context.colors.onSecondaryContainer;
      case 'surfaceContainerHigh': return context.colors.surfaceContainerHighest;
      case 'onSurfaceVariant': return context.colors.onSurfaceVariant;
      default: return isOn ? context.colors.onPrimaryContainer : context.colors.primaryContainer;
    }
  }

class _NotifCard extends StatelessWidget {
  const _NotifCard({required this.n});

  final _Notif n;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: n.unread ? 1 : 0.7,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: n.unread ? context.colors.surfaceContainerHighest : context.colors.surfaceContainer,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: n.unread ? context.colors.vesitPrimary.withOpacity(0.6) : context.colors.outline.withOpacity(0.2),
            width: 1.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (n.tag.trim().isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: ShapeDecoration(
                      color: _getSemanticColor(context, n.tagColorName),
                      shape: const StadiumBorder(),
                    ),
                    child: Text(
                      n.tag.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.0,
                        color: _getSemanticColor(context, n.onTagColorName, isOn: true),
                      ),
                    ),
                  ),
                if (n.unread) const PilotLight(active: true, size: 8),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              n.title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                height: 1.4,
                color: context.colors.onSurface,
              ),
            ),
            if (n.body != null) ...[
              const SizedBox(height: 4),
              Text(n.body!, style: context.textStyles.bodyMd.copyWith(color: context.colors.onSurfaceVariant)),
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
        Icon(icon, size: 14, color: context.colors.onSurfaceVariant),
        const SizedBox(width: 6),
        Text(text, style: context.textStyles.labelSm.copyWith(color: context.colors.onSurfaceVariant)),
      ],
    );
  }
}
