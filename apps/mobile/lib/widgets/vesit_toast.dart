import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

enum ToastType { success, error, info, warning }

class VesitToast {
  static void show({
    required BuildContext context,
    required String title,
    String? description,
    ToastType type = ToastType.info,
    Duration duration = const Duration(seconds: 3),
  }) {
    final overlay = Overlay.of(context);
    final overlayEntry = OverlayEntry(
      builder: (context) {
        final isMobile = MediaQuery.of(context).size.width <= 800;
        return _ToastWidget(
          title: title,
          description: description,
          type: type,
          duration: duration,
          isMobile: isMobile,
        );
      },
    );

    overlay.insert(overlayEntry);
    
    Future.delayed(duration + const Duration(milliseconds: 300)).then((_) {
      if (overlayEntry.mounted) {
        overlayEntry.remove();
      }
    });
  }
}

class _ToastWidget extends StatefulWidget {
  final String title;
  final String? description;
  final ToastType type;
  final Duration duration;
  final bool isMobile;

  const _ToastWidget({
    required this.title,
    this.description,
    required this.type,
    required this.duration,
    this.isMobile = true,
  });

  @override
  State<_ToastWidget> createState() => _ToastWidgetState();
}

class _ToastWidgetState extends State<_ToastWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _offsetAnimation = Tween<Offset>(
      begin: widget.isMobile ? const Offset(0, -1.5) : const Offset(1.5, 0), // Slide from right on desktop
      end: const Offset(0, 0),
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    _controller.forward();

    Future.delayed(widget.duration - const Duration(milliseconds: 400)).then((_) {
      if (mounted) {
        _controller.reverse();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color _getIconColor() {
    switch (widget.type) {
      case ToastType.success:
        return const Color(0xFF22C55E); // Bright Green
      case ToastType.error:
        return const Color(0xFFEF4444); // Bright Red
      case ToastType.warning:
        return const Color(0xFFF59E0B); // Amber
      case ToastType.info:
      default:
        return const Color(0xFF3B82F6); // Bright Blue
    }
  }

  IconData _getIcon() {
    switch (widget.type) {
      case ToastType.success:
        return Icons.check_circle;
      case ToastType.error:
        return Icons.error;
      case ToastType.warning:
        return Icons.warning;
      case ToastType.info:
      default:
        return Icons.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: widget.isMobile ? null : 32,
      top: widget.isMobile ? MediaQuery.of(context).padding.top + 16 : null,
      left: widget.isMobile ? 16 : null,
      right: widget.isMobile ? 16 : 32,
      child: SafeArea(
        child: Align(
          alignment: widget.isMobile ? Alignment.topCenter : Alignment.bottomRight,
          child: Material(
            color: Colors.transparent,
            child: SlideTransition(
              position: _offsetAnimation,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 400),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B), // Sleek dark slate bubble
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 10)),
                    ],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: _getIconColor().withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(_getIcon(), color: _getIconColor(), size: 20),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(height: 2),
                            Text(
                              widget.title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            if (widget.description != null && widget.description!.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                widget.description!,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
