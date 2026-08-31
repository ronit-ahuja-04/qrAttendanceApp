import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class VesitCard extends StatelessWidget {
  const VesitCard({super.key, required this.child, this.padding});

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: context.colors.vesitWhite,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

class VesitTextField extends StatefulWidget {
  const VesitTextField({
    super.key,
    required this.label,
    required this.icon,
    this.hint,
    this.obscureText = false,
    this.keyboardType,
    this.controller,
    this.validator,
    this.onFieldSubmitted,
    this.showVisibilityToggle = false,
  });

  final String label;
  final IconData icon;
  final String? hint;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onFieldSubmitted;
  final bool showVisibilityToggle;

  @override
  State<VesitTextField> createState() => _VesitTextFieldState();
}

class _VesitTextFieldState extends State<VesitTextField> {
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
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 6),
          child: Text(widget.label, style: context.textStyles.vesitLabelBold),
        ),
        TextFormField(
          controller: widget.controller,
          obscureText: _obscured,
          keyboardType: widget.keyboardType,
          validator: widget.validator,
          onFieldSubmitted: widget.onFieldSubmitted,
          autocorrect: widget.keyboardType == TextInputType.emailAddress ? false : true,
          enableSuggestions: widget.keyboardType == TextInputType.emailAddress ? false : true,
          style: context.textStyles.vesitBodyMd,
          decoration: InputDecoration(
            hintText: widget.hint,
            hintStyle: context.textStyles.vesitBodyMd.copyWith(color: Colors.grey.shade500),
            prefixIcon: Icon(widget.icon, color: context.colors.vesitPrimary),
            suffixIcon: widget.showVisibilityToggle
                ? IconButton(
                    icon: Icon(
                      _obscured ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                      color: Colors.grey.shade600,
                    ),
                    onPressed: () => setState(() => _obscured = !_obscured),
                  )
                : null,
            filled: true,
            fillColor: context.colors.surfaceContainerHighest,
            contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: context.colors.primary, width: 2)),
            errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: context.colors.error, width: 1)),
          ),
        ),
      ],
    );
  }
}

class VesitButton extends StatelessWidget {
  const VesitButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: context.colors.vesitPrimary,
          foregroundColor: context.colors.vesitWhite,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          elevation: 0,
        ),
        child: isLoading
            ? SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(color: context.colors.vesitWhite, strokeWidth: 2),
              )
            : Text(label, style: context.textStyles.vesitButtonText),
      ),
    );
  }
}

class VesitRoleToggle extends StatelessWidget {
  const VesitRoleToggle({super.key, required this.value, required this.onChanged});

  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double width = constraints.maxWidth;
        final double pillWidth = (width - 8) / 2; // 8 is total padding

        return Container(
          height: 48,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: context.colors.vesitGray,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Stack(
            children: [
              // Sliding pill
              AnimatedPositioned(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                left: value == 'student' ? 0 : pillWidth,
                top: 0,
                bottom: 0,
                width: pillWidth,
                child: Container(
                  decoration: BoxDecoration(
                    color: context.colors.vesitWhite,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.grey.shade300, width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.12),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      )
                    ],
                  ),
                ),
              ),
              // Text buttons
              Row(
                children: [
                  _option(context, 'student', 'STUDENT'),
                  _option(context, 'faculty', 'FACULTY'),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _option(BuildContext context, String role, String text) {
    final active = value == role;
    return Expanded(
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => onChanged(role),
          child: Center(
            child: AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              style: context.textStyles.vesitLabelBold.copyWith(
                color: active ? context.colors.vesitPrimary : Colors.grey.shade600,
              ),
              child: Text(text),
            ),
          ),
        ),
      ),
    );
  }
}

class VesitSegmentedToggle extends StatelessWidget {
  const VesitSegmentedToggle({
    super.key,
    required this.value,
    required this.onChanged,
    required this.firstLabel,
    required this.secondLabel,
  });

  final bool value; // false = first, true = second
  final ValueChanged<bool> onChanged;
  final String firstLabel;
  final String secondLabel;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double width = constraints.maxWidth;
        final double pillWidth = (width - 8) / 2; // 8 is total padding

        return Container(
          height: 48,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: context.colors.vesitGray,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Stack(
            children: [
              // Sliding pill
              AnimatedPositioned(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                left: !value ? 0 : pillWidth,
                top: 0,
                bottom: 0,
                width: pillWidth,
                child: Container(
                  decoration: BoxDecoration(
                    color: context.colors.vesitWhite,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.grey.shade300, width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      )
                    ],
                  ),
                ),
              ),
              // Text buttons
              Row(
                children: [
                  _option(context, false, firstLabel),
                  _option(context, true, secondLabel),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _option(BuildContext context, bool optionValue, String text) {
    final active = value == optionValue;
    return Expanded(
      child: GestureDetector(
        onTap: () => onChanged(optionValue),
        behavior: HitTestBehavior.opaque,
        child: Center(
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 250),
            style: context.textStyles.vesitLabelBold.copyWith(
              color: active ? context.colors.vesitTextHeading : Colors.grey.shade500,
              fontSize: 12,
            ),
            child: Text(text),
          ),
        ),
      ),
    );
  }
}

class VesitSkeleton extends StatefulWidget {
  const VesitSkeleton({super.key, this.width, this.height, this.borderRadius = 8});
  final double? width;
  final double? height;
  final double borderRadius;

  @override
  State<VesitSkeleton> createState() => _VesitSkeletonState();
}

class _VesitSkeletonState extends State<VesitSkeleton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000))..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.3, end: 0.7).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _animation,
      child: Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          borderRadius: BorderRadius.circular(widget.borderRadius),
        ),
      ),
    );
  }
}

class VesitDropdown<T> extends StatelessWidget {
  const VesitDropdown({
    super.key,
    required this.label,
    required this.icon,
    required this.value,
    required this.items,
    required this.onChanged,
    required this.itemLabel,
  });

  final String label;
  final IconData icon;
  final T value;
  final List<T> items;
  final ValueChanged<T?> onChanged;
  final String Function(T) itemLabel;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 6),
          child: Text(label, style: context.textStyles.vesitLabelBold),
        ),
        DropdownButtonFormField<T>(
          value: value,
          isExpanded: true,
          onChanged: (val) {
            FocusManager.instance.primaryFocus?.unfocus();
            onChanged(val);
          },
          items: items.map((e) => DropdownMenuItem(value: e, child: Row(children: [Expanded(child: Text(itemLabel(e), overflow: TextOverflow.ellipsis, maxLines: 1))]))).toList(),
          style: context.textStyles.vesitBodyMd.copyWith(color: context.colors.vesitTextBody),
          dropdownColor: context.colors.surfaceContainerHigh,
          icon: Icon(Icons.arrow_drop_down, color: context.colors.vesitPrimary),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: context.colors.vesitPrimary),
            filled: true,
            fillColor: context.colors.surfaceContainerHighest,
            contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: context.colors.primary, width: 2)),
          ),
        ),
      ],
    );
  }
}
