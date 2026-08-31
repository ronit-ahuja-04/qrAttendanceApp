import 'package:flutter/material.dart';
import 'dart:ui';

/// A page route that fades in the new page while blurring the previous one.
/// Usage:
/// Navigator.of(context).push(FadeBlurPageRoute(page: NewScreen()));
class FadeBlurPageRoute extends PageRouteBuilder {
  final Widget page;
  FadeBlurPageRoute({required this.page})
      : super(
          transitionDuration: const Duration(milliseconds: 300),
          reverseTransitionDuration: const Duration(milliseconds: 200),
          opaque: false, // Allows the previous route to be visible underneath.
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final fadeIn = FadeTransition(opacity: animation, child: child);
            return Stack(
              children: [
                BackdropFilter(
                  filter: ImageFilter.blur(
                    sigmaX: 5 * (1 - animation.value),
                    sigmaY: 5 * (1 - animation.value),
                  ),
                  child: const SizedBox.expand(),
                ),
                fadeIn,
              ],
            );
          },
        );
}
