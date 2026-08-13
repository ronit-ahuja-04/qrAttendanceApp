import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/tactile_widgets.dart';

/// Compose Announcement — ported from the Stitch export (code.html:
/// "Compose Announcement | VESIT"). Reachable from the Faculty Dashboard's
/// "Announcements" hub.
class ComposeAnnouncementScreen extends StatefulWidget {
  const ComposeAnnouncementScreen({super.key});

  @override
  State<ComposeAnnouncementScreen> createState() => _ComposeAnnouncementScreenState();
}

enum _Audience { specificClass, department }

class _ComposeAnnouncementScreenState extends State<ComposeAnnouncementScreen> {
  static const _years = ['FE', 'SE', 'TE', 'BE'];
  static const _divisions = ['A', 'B', 'C', 'ALL'];

  static const _types = [
    'Schedule Change',
    'Lecture Cancelled',
    'Test / CA',
    'Prerequisite',
    'General Notice',
  ];

  _Audience _audience = _Audience.specificClass;
  String _year = 'TE';
  String _division = 'A';
  String _type = _types.first;
  bool _notifyNow = true;

  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  void _reset() {
    setState(() {
      _audience = _Audience.specificClass;
      _year = 'TE';
      _division = 'A';
      _type = _types.first;
      _notifyNow = true;
    });
    _titleController.clear();
    _bodyController.clear();
  }

  void _broadcast() {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add a title before broadcasting')),
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Announcement broadcast'), duration: Duration(seconds: 1)),
    );
    Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Column(
          children: [
            _Header(
              onClose: () => Navigator.of(context).maybePop(),
              onReset: _reset,
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                children: [
                  _Section(
                    label: 'Target Audience',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _AudiencePill(
                                label: 'Specific Class / Subject',
                                selected: _audience == _Audience.specificClass,
                                onTap: () => setState(() => _audience = _Audience.specificClass),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _AudiencePill(
                                label: 'Entire Department',
                                selected: _audience == _Audience.department,
                                onTap: () => setState(() => _audience = _Audience.department),
                              ),
                            ),
                          ],
                        ),
                        if (_audience == _Audience.specificClass) ...[
                          const SizedBox(height: 16),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.only(left: 2, bottom: 6),
                                      child: Text(
                                        'YEAR',
                                        style: AppTextStyles.labelBold.copyWith(
                                          color: AppColors.outline,
                                          fontSize: 10,
                                          letterSpacing: 1.2,
                                        ),
                                      ),
                                    ),
                                    DebossedDropdown<String>(
                                      value: _year,
                                      items: _years,
                                      itemLabel: (v) => v,
                                      onChanged: (v) => setState(() => _year = v!),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.only(left: 2, bottom: 6),
                                      child: Text(
                                        'DIVISION',
                                        style: AppTextStyles.labelBold.copyWith(
                                          color: AppColors.outline,
                                          fontSize: 10,
                                          letterSpacing: 1.2,
                                        ),
                                      ),
                                    ),
                                    DebossedDropdown<String>(
                                      value: _division,
                                      items: _divisions,
                                      itemLabel: (v) => v,
                                      onChanged: (v) => setState(() => _division = v!),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _Section(
                    label: 'Announcement Type',
                    child: SizedBox(
                      height: 40,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _types.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (context, i) {
                          final t = _types[i];
                          return _TypeChip(
                            label: t,
                            selected: t == _type,
                            onTap: () => setState(() => _type = t),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _Section(
                    label: 'Content',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: AppColors.debossedWell,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 6, offset: const Offset(0, 3)),
                            ],
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          child: TextField(
                            controller: _titleController,
                            style: AppTextStyles.bodyMd,
                            decoration: InputDecoration(
                              hintText: 'e.g., CA-1 Quiz Rescheduled & Updated Syllabus',
                              hintStyle: AppTextStyles.bodyMd.copyWith(color: AppColors.outlineVariant),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          decoration: BoxDecoration(
                            color: AppColors.debossedWell,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 6, offset: const Offset(0, 3)),
                            ],
                          ),
                          padding: const EdgeInsets.all(14),
                          child: TextField(
                            controller: _bodyController,
                            style: AppTextStyles.bodyMd,
                            minLines: 5,
                            maxLines: 5,
                            decoration: InputDecoration(
                              hintText: "Dear Students, Please note that Friday's CA-1 quiz has been postponed...",
                              hintStyle: AppTextStyles.bodyMd.copyWith(color: AppColors.outlineVariant),
                              border: InputBorder.none,
                              isDense: true,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _Section(
                    label: 'Options',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainer.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.outlineVariant, width: 2),
                          ),
                          child: Column(
                            children: [
                              const Icon(Icons.attach_file, color: AppColors.secondary, size: 28),
                              const SizedBox(height: 8),
                              Text(
                                'Attach File or Syllabus PDF (Optional)',
                                textAlign: TextAlign.center,
                                style: AppTextStyles.labelMd.copyWith(color: AppColors.secondary),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Send Push Notification Immediately',
                                    style: AppTextStyles.labelBold.copyWith(color: AppColors.onSurface, fontSize: 14),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Alert students on their mobile lockscreen',
                                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: AppColors.outline),
                                  ),
                                ],
                              ),
                            ),
                            _PhysicalToggle(
                              value: _notifyNow,
                              onChanged: (v) => setState(() => _notifyNow = v),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
            _BottomAction(onBroadcast: _broadcast),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onClose, required this.onReset});

  final VoidCallback onClose;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.outlineVariant, width: 1)),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2))],
      ),
      child: Row(
        children: [
          PushSurfaceButton(
            onPressed: onClose,
            borderRadius: 999,
            child: const Padding(
              padding: EdgeInsets.all(8),
              child: Icon(Icons.close, color: AppColors.primary),
            ),
          ),
          Expanded(
            child: Text(
              'Announcement',
              textAlign: TextAlign.center,
              style: AppTextStyles.headlineSm.copyWith(color: AppColors.primary),
            ),
          ),
          TextButton(
            onPressed: onReset,
            child: Text(
              'RESET',
              style: AppTextStyles.labelBold.copyWith(color: AppColors.secondary, letterSpacing: 1.2),
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outlineVariant, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            label.toUpperCase(),
            style: AppTextStyles.labelBold.copyWith(color: AppColors.onSurfaceVariant, letterSpacing: 1.5, fontSize: 11),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _AudiencePill extends StatelessWidget {
  const _AudiencePill({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryContainer.withOpacity(0.1) : AppColors.surfaceContainer,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? AppColors.primary : AppColors.outlineVariant, width: selected ? 1.5 : 1),
          boxShadow: selected
              ? [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 4, offset: const Offset(0, 2))]
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                    spreadRadius: -2,
                  ),
                ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? AppColors.primaryContainer : AppColors.secondary,
                boxShadow: selected
                    ? [BoxShadow(color: AppColors.primaryContainer.withOpacity(0.7), blurRadius: 8)]
                    : null,
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: AppTextStyles.labelBold.copyWith(
                  color: selected ? AppColors.onPrimaryContainer : AppColors.secondary,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TypeStyle {
  const _TypeStyle({required this.bg, required this.border, required this.text});
  final Color bg;
  final Color border;
  final Color text;
}

class _TypeChip extends StatelessWidget {
  const _TypeChip({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  _TypeStyle _styleFor(String label) {
    switch (label) {
      case 'Schedule Change':
        return const _TypeStyle(bg: AppColors.primaryContainer, border: AppColors.primary, text: AppColors.onPrimaryContainer);
      case 'Lecture Cancelled':
        return _TypeStyle(bg: AppColors.errorContainer.withOpacity(0.5), border: AppColors.error.withOpacity(0.3), text: AppColors.error);
      case 'Prerequisite':
        return _TypeStyle(bg: AppColors.secondaryContainer.withOpacity(0.3), border: AppColors.outline, text: AppColors.secondary);
      case 'General Notice':
        return const _TypeStyle(bg: Colors.transparent, border: AppColors.outlineVariant, text: AppColors.outline);
      case 'Test / CA':
      default:
        return const _TypeStyle(bg: AppColors.surface, border: AppColors.outlineVariant, text: AppColors.onSurface);
    }
  }

  @override
  Widget build(BuildContext context) {
    final style = _styleFor(label);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: style.bg,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: style.border, width: selected ? 2 : 1),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 4, offset: const Offset(0, 2)),
            if (selected) BoxShadow(color: style.border.withOpacity(0.35), blurRadius: 6),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          label.toUpperCase(),
          style: AppTextStyles.labelBold.copyWith(
            color: style.text,
            fontSize: 11,
          ),
        ),
      ),
    );
  }
}

/// The rounded on/off toggle switch used for "Send Push Notification
/// Immediately" — mirrors the physical toggle switch in the Stitch export.
class _PhysicalToggle extends StatelessWidget {
  const _PhysicalToggle({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 48,
        height: 24,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: value ? AppColors.primary : AppColors.secondary,
          borderRadius: BorderRadius.circular(999),
          boxShadow: const [
            BoxShadow(color: Colors.black26, blurRadius: 3, offset: Offset(0, 1)),
          ],
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 150),
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 16,
            height: 16,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 2, offset: Offset(0, 1))],
            ),
          ),
        ),
      ),
    );
  }
}

class _BottomAction extends StatelessWidget {
  const _BottomAction({required this.onBroadcast});

  final VoidCallback onBroadcast;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.outlineVariant, width: 1)),
      ),
      child: Column(
        children: [
          PushableButton(
            label: 'Broadcast Announcement Now',
            icon: Icons.campaign,
            onPressed: onBroadcast,
          ),
          const SizedBox(height: 8),
          Text(
            'This will instantly notify all enrolled students in the selected group via mobile notification and faculty dashboard.',
            textAlign: TextAlign.center,
            style: AppTextStyles.labelSm.copyWith(color: AppColors.outline, fontSize: 10),
          ),
        ],
      ),
    );
  }
}
