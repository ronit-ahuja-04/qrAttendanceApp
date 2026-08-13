import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../screens/student_profile_screen.dart';
import '../screens/student_dashboard_screen.dart';
import '../screens/attendance_history_screen.dart';

/// A "raised plastic" panel — the main card surface used for the
/// login/registration forms.
class RaisedPanel extends StatelessWidget {
  const RaisedPanel({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius = 24,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(borderRadius),
        border: const Border(
          bottom: BorderSide(color: AppColors.debossedWell, width: 2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}

/// A "debossed well" text field — looks pressed into the surface.
class DebossedField extends StatefulWidget {
  const DebossedField({
    super.key,
    required this.label,
    required this.icon,
    this.hint,
    this.obscureText = false,
    this.keyboardType,
    this.controller,
    this.validator,
    this.showVisibilityToggle = false,
    this.showLabel = true,
  });

  final String label;
  final IconData icon;
  final String? hint;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final bool showVisibilityToggle;
  final bool showLabel;

  @override
  State<DebossedField> createState() => _DebossedFieldState();
}

class _DebossedFieldState extends State<DebossedField> {
  late bool _obscured;

  @override
  void initState() {
    super.initState();
    _obscured = widget.obscureText;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.showLabel)
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 6),
            child: Text(widget.label.toUpperCase(), style: AppTextStyles.labelBold),
          ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.debossedWell,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            children: [
              Icon(widget.icon, color: AppColors.outline, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: TextFormField(
                  controller: widget.controller,
                  obscureText: _obscured,
                  keyboardType: widget.keyboardType,
                  validator: widget.validator,
                  style: AppTextStyles.bodyMd,
                  decoration: InputDecoration(
                    hintText: widget.hint,
                    hintStyle: AppTextStyles.bodyMd.copyWith(color: AppColors.outlineVariant),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              if (widget.showVisibilityToggle)
                GestureDetector(
                  onTap: () => setState(() => _obscured = !_obscured),
                  child: Icon(
                    _obscured ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                    color: AppColors.outline,
                    size: 20,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// The amber "pushable" button with a pressed animation, mirroring the
/// three-layer CSS button from the Stitch export.
class PushableButton extends StatefulWidget {
  const PushableButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
  });

  final String label;
  final VoidCallback onPressed;
  final IconData? icon;

  @override
  State<PushableButton> createState() => _PushableButtonState();
}

class _PushableButtonState extends State<PushableButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) => setState(() => _pressed = false),
      onTap: widget.onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        width: double.infinity,
        height: 52,
        transform: Matrix4.translationValues(0, _pressed ? 2 : 0, 0),
        decoration: BoxDecoration(
          color: _pressed ? const Color(0xFFE19216) : AppColors.primaryContainer,
          borderRadius: BorderRadius.circular(14),
          boxShadow: _pressed
              ? [const BoxShadow(color: AppColors.primary, offset: Offset(0, 1))]
              : [
                  const BoxShadow(color: AppColors.primary, offset: Offset(0, 4)),
                  BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 6)),
                ],
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.label.toUpperCase(),
              style: AppTextStyles.labelBold.copyWith(color: Colors.white, fontSize: 15, letterSpacing: 1.2),
            ),
            if (widget.icon != null) ...[
              const SizedBox(width: 8),
              Icon(widget.icon, color: Colors.white, size: 18),
            ],
          ],
        ),
      ),
    );
  }
}

/// The small amber "power-on" LED indicator dot.
class LedDot extends StatelessWidget {
  const LedDot({super.key, this.active = true});

  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: active ? AppColors.primaryContainer : AppColors.secondary,
        boxShadow: active
            ? [const BoxShadow(color: AppColors.amberGlow, blurRadius: 8, spreadRadius: 1)]
            : null,
      ),
    );
  }
}

enum UserRole { student, faculty }

/// The pill-shaped STUDENT / FACULTY rocker switch used on the login screen.
class RoleToggle extends StatelessWidget {
  const RoleToggle({super.key, required this.value, required this.onChanged});

  final UserRole value;
  final ValueChanged<UserRole> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.debossedWell,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        children: [
          _option(context, 'STUDENT', UserRole.student),
          _option(context, 'FACULTY', UserRole.faculty),
        ],
      ),
    );
  }

  Widget _option(BuildContext context, String text, UserRole role) {
    final active = value == role;
    return Expanded(
      child: GestureDetector(
        onTap: () => onChanged(role),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: active ? AppColors.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
            boxShadow: active
                ? [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 2))]
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            text,
            style: AppTextStyles.labelBold.copyWith(
              color: active ? AppColors.onSurface : AppColors.onSurfaceVariant,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}

/// Shared top app bar used across screens ("VESIT" wordmark + subtitle).
class TactileAppBar extends StatelessWidget implements PreferredSizeWidget {
  const TactileAppBar({super.key, this.trailingTitle});

  final String? trailingTitle;

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            Image.asset(
              'assets/images/logo.png',
              height: 34,
              fit: BoxFit.contain,
            ),
            const SizedBox(width: 8),
            const Text('VESIT', style: AppTextStyles.displayLg),
            const Spacer(),
            if (trailingTitle != null)
              Text(trailingTitle!, style: AppTextStyles.headlineSm.copyWith(fontSize: 16)),
          ],
        ),
      ),
    );
  }
}

/// Small "debossed well" pill/box — used for date chips, stat boxes,
/// and the pilot-light status badges.
class DebossedWell extends StatelessWidget {
  const DebossedWell({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    this.borderRadius = 8,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.debossedWell,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 6, offset: const Offset(0, 3)),
          const BoxShadow(color: Colors.white, blurRadius: 0, offset: Offset(0, 1)),
        ],
      ),
      child: child,
    );
  }
}

/// The amber "pilot light" indicator (on) or its dim/off counterpart.
class PilotLight extends StatelessWidget {
  const PilotLight({super.key, this.active = true, this.size = 8});

  final bool active;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: active ? AppColors.primaryContainer : const Color(0xFF474742),
        boxShadow: active
            ? [
                BoxShadow(color: AppColors.primaryContainer.withOpacity(0.7), blurRadius: 8),
              ]
            : null,
      ),
    );
  }
}

/// A push-style button that isn't full width / amber — used for the
/// secondary quick-action tiles ("History", "Timetable", notification bell).
class PushSurfaceButton extends StatefulWidget {
  const PushSurfaceButton({
    super.key,
    required this.child,
    required this.onPressed,
    this.borderRadius = 16,
  });

  final Widget child;
  final VoidCallback onPressed;
  final double borderRadius;

  @override
  State<PushSurfaceButton> createState() => _PushSurfaceButtonState();
}

class _PushSurfaceButtonState extends State<PushSurfaceButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) => setState(() => _pressed = false),
      onTap: widget.onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        transform: Matrix4.translationValues(0, _pressed ? 2 : 0, 0),
        decoration: BoxDecoration(
          color: _pressed ? AppColors.debossedWell : AppColors.surface,
          borderRadius: BorderRadius.circular(widget.borderRadius),
          boxShadow: _pressed
              ? [
                  BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 6, offset: const Offset(0, 2)),
                ]
              : [
                  const BoxShadow(color: Colors.white, offset: Offset(0, -1)),
                  BoxShadow(color: Colors.black.withOpacity(0.15), offset: const Offset(0, 4)),
                ],
        ),
        child: widget.child,
      ),
    );
  }
}

/// A labelled "module" card — the raised outlined container used to group
/// a single form control on the Configure OTP screen (mirrors the
/// `module-raised` divs in the "configure_otp_session" Stitch mockup).
class ConfigCard extends StatelessWidget {
  const ConfigCard({super.key, required this.label, required this.child});

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
        boxShadow: const [
          BoxShadow(color: Colors.white, offset: Offset(0, 1)),
          BoxShadow(color: Colors.black12, blurRadius: 3, offset: Offset(0, 1)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 2, bottom: 8),
            child: Text(label.toUpperCase(), style: AppTextStyles.labelBold),
          ),
          child,
        ],
      ),
    );
  }
}

/// A "debossed well" dropdown — same pressed-in look as [DebossedField],
/// used for the Division, Subject, and Timing selects on the Configure
/// OTP screen.
class DebossedDropdown<T> extends StatelessWidget {
  const DebossedDropdown({
    super.key,
    required this.value,
    required this.items,
    required this.itemLabel,
    required this.onChanged,
    this.icon,
  });

  final T value;
  final List<T> items;
  final String Function(T) itemLabel;
  final ValueChanged<T?> onChanged;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.debossedWell,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 6, offset: const Offset(0, 3)),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, color: AppColors.outline, size: 20),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<T>(
                value: value,
                isExpanded: true,
                icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.onSurfaceVariant),
                style: AppTextStyles.bodyMd,
                dropdownColor: AppColors.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(12),
                items: items
                    .map((e) => DropdownMenuItem<T>(value: e, child: Text(itemLabel(e))))
                    .toList(),
                onChanged: onChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The shared bottom navigation bar. Only `homeLabel` is functional for
/// now (screens outside the current scope just show a "coming soon" snack).
class TactileBottomNav extends StatelessWidget {
  const TactileBottomNav({super.key, required this.currentIndex});

  final int currentIndex;

  static const _items = [
    (icon: Icons.home_outlined, activeIcon: Icons.home, label: 'Home'),
    (icon: Icons.calendar_today_outlined, activeIcon: Icons.calendar_today, label: 'Attendance'),
    (icon: Icons.schedule_outlined, activeIcon: Icons.schedule, label: 'Timetable'),
    (icon: Icons.person_outline, activeIcon: Icons.person, label: 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 76,
      decoration: const BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, -4))],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(_items.length, (i) {
            final item = _items[i];
            final active = i == currentIndex;
            return GestureDetector(
              onTap: () {
                if (active) return;
                if (item.label == 'Profile') {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const StudentProfileScreen()),
                  );
                  return;
                }
                if (item.label == 'Home') {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const StudentDashboardScreen()),
                  );
                  return;
                }
                if (item.label == 'Attendance') {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const AttendanceHistoryScreen()),
                  );
                  return;
                }
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${item.label} — coming soon'), duration: const Duration(seconds: 1)),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: active ? AppColors.surfaceContainerHighest : Colors.transparent,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      active ? item.activeIcon : item.icon,
                      color: active ? AppColors.primaryContainer : AppColors.secondary,
                      size: 24,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.label.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: active ? AppColors.primaryContainer : AppColors.secondary,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
