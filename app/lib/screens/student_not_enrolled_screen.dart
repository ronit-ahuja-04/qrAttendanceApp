import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../routes/fade_blur_route.dart';
import '../widgets/vesit_loader.dart';
import 'student_main_layout.dart';

class StudentNotEnrolledScreen extends StatefulWidget {
  const StudentNotEnrolledScreen({super.key});

  @override
  State<StudentNotEnrolledScreen> createState() =>
      _StudentNotEnrolledScreenState();
}

class _StudentNotEnrolledScreenState extends State<StudentNotEnrolledScreen>
    with TickerProviderStateMixin {
  late final AnimationController _shakeCtrl;
  late final AnimationController _contentCtrl;

  late final Animation<double> _shakeAnimation;
  late final Animation<double> _contentFade;
  late final Animation<Offset> _contentSlide;

  final _player = AudioPlayer();
  bool _isRedirecting = false;

  @override
  void initState() {
    super.initState();

    // Rapid shaking animation (left to right)
    _shakeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));

    _shakeAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0).chain(CurveTween(curve: Curves.easeIn)), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: -1.0).chain(CurveTween(curve: Curves.easeInOut)), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -1.0, end: 1.0).chain(CurveTween(curve: Curves.easeInOut)), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: -1.0).chain(CurveTween(curve: Curves.easeInOut)), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -1.0, end: 0.0).chain(CurveTween(curve: Curves.easeOut)), weight: 1),
    ]).animate(_shakeCtrl);

    _contentCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _contentFade =
        CurvedAnimation(parent: _contentCtrl, curve: Curves.easeOut);
    _contentSlide =
        Tween<Offset>(begin: const Offset(0, 0.12), end: Offset.zero).animate(
            CurvedAnimation(parent: _contentCtrl, curve: Curves.easeOutCubic));

    _runSequence();
  }

  Future<void> _runSequence() async {
    await Future.delayed(const Duration(milliseconds: 100));
    
    // Play the warning chime
    _player.play(AssetSource('sounds/warning.wav'));
    
    // Start shaking and fade in content
    _shakeCtrl.forward();
    await _contentCtrl.forward();

    // Auto-redirect sequence after showing the warning
    await Future.delayed(const Duration(milliseconds: 2500));
    if (!mounted) return;

    setState(() => _isRedirecting = true);
    await Future.delayed(const Duration(milliseconds: 600)); // allow redirect loader to fade in
    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      FadeBlurPageRoute(page: const StudentMainLayout()),
      (route) => false,
    );
  }

  @override
  void dispose() {
    _shakeCtrl.dispose();
    _contentCtrl.dispose();
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.vesitWhite,
      body: Stack(
        children: [
          // Background Gradient (subtle red/orange tint)
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0, -0.2),
                  radius: 0.8,
                  colors: [
                    const Color(0xFF93000A).withOpacity(0.06), // Very light error red
                    context.colors.vesitWhite,
                  ],
                ),
              ),
            ),
          ),

          // Main Center Content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Animated Warning Icon
                AnimatedBuilder(
                  animation: _shakeCtrl,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(_shakeAnimation.value * 20, 0),
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: const Color(0xFF93000A).withOpacity(0.08),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.error_outline_rounded,
                          color: Color(0xFF93000A), // Red warning color
                          size: 72,
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 32),

                // Text Content sliding in
                FadeTransition(
                  opacity: _contentFade,
                  child: SlideTransition(
                    position: _contentSlide,
                    child: Column(
                      children: [
                        Text(
                          'Not Enrolled!',
                          style: context.textStyles.vesitHeadlineLg.copyWith(
                            color: const Color(0xFF93000A),
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 40),
                          child: Text(
                            'You are not enrolled in this session batch or division. Please check your schedule.',
                            style: context.textStyles.vesitBodyLg.copyWith(
                              color: context.colors.vesitPrimary.withOpacity(0.7),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Bottom Loading Overlay (returning to dashboard)
          AnimatedPositioned(
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOutCubic,
            bottom: _isRedirecting ? 0 : -100,
            left: 0,
            right: 0,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 400),
              opacity: _isRedirecting ? 1.0 : 0.0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 48),
                decoration: BoxDecoration(
                  color: context.colors.vesitWhite,
                  boxShadow: [
                    BoxShadow(
                      color: context.colors.vesitPrimary.withOpacity(0.08),
                      blurRadius: 24,
                      offset: const Offset(0, -8),
                    )
                  ],
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(32)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const VesitSwirlingLoader(size: 20),
                    const SizedBox(width: 16),
                    Text(
                      'Returning to dashboard...',
                      style: context.textStyles.vesitLabelBold.copyWith(
                        color: context.colors.vesitPrimary.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}


