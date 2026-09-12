import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class VesitSwirlingLoader extends StatefulWidget {
  const VesitSwirlingLoader({super.key, this.size = 100.0});
  final double size;

  @override
  State<VesitSwirlingLoader> createState() => _VesitSwirlingLoaderState();
}

class _VesitSwirlingLoaderState extends State<VesitSwirlingLoader> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  final List<IconData> _icons = [
    Icons.laptop_mac,
    Icons.menu_book,
    Icons.edit,
    Icons.science,
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 2));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _controller.repeat();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Stack(
            alignment: Alignment.center,
            children: [
              // Center Logo
              Icon(Icons.school, color: context.colors.vesitPrimary, size: 32),
              
              // Orbiting Icons
              ...List.generate(_icons.length, (index) {
                final baseAngle = (index * (2 * math.pi)) / _icons.length;
                final angle = baseAngle + (_controller.value * 2 * math.pi);
                final radius = widget.size * 0.4;
                
                return Transform.translate(
                  offset: Offset(
                    radius * math.cos(angle),
                    radius * math.sin(angle),
                  ),
                  child: Transform.rotate(
                    angle: angle + (math.pi / 2), // Rotate the icon itself to face the direction of orbit
                    child: Icon(
                      _icons[index],
                      color: context.colors.vesitGold,
                      size: 24,
                    ),
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }
}
