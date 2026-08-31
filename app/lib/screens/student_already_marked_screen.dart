import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../routes/fade_blur_route.dart';
import '../widgets/vesit_loader.dart';
import 'student_main_layout.dart';

class StudentAlreadyMarkedScreen extends StatefulWidget {
  const StudentAlreadyMarkedScreen({
    super.key,
  });

  @override
  State<StudentAlreadyMarkedScreen> createState() =>
      _StudentAlreadyMarkedScreenState();
}

class _StudentAlreadyMarkedScreenState extends State<StudentAlreadyMarkedScreen>
    with TickerProviderStateMixin {
  late final AnimationController _circleCtrl;
  late final AnimationController _checkCtrl;
  late final AnimationController _contentCtrl;
  late final AnimationController _confettiCtrl;

  late final Animation<double> _circleProgress;
  late final Animation<double> _checkProgress;
  late final Animation<double> _scaleBounce;
  late final Animation<double> _contentFade;
  late final Animation<Offset> _contentSlide;

  final _player = AudioPlayer();
  final _rng = math.Random(42);
  late final List<_ConfettiPiece> _pieces;

  bool _isRedirecting = false;

  @override
  void initState() {
    super.initState();

    _circleCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _circleProgress =
        CurvedAnimation(parent: _circleCtrl, curve: Curves.easeOut);

    _checkCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _checkProgress = CurvedAnimation(
        parent: _checkCtrl,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOut));
    _scaleBounce = TweenSequence<double>([
      TweenSequenceItem(
          tween: Tween(begin: 1.0, end: 1.18)
              .chain(CurveTween(curve: Curves.easeOut)),
          weight: 40),
      TweenSequenceItem(
          tween: Tween(begin: 1.18, end: 1.0)
              .chain(CurveTween(curve: Curves.elasticOut)),
          weight: 60),
    ]).animate(_checkCtrl);

    _contentCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _contentFade =
        CurvedAnimation(parent: _contentCtrl, curve: Curves.easeOut);
    _contentSlide =
        Tween<Offset>(begin: const Offset(0, 0.12), end: Offset.zero).animate(
            CurvedAnimation(parent: _contentCtrl, curve: Curves.easeOutCubic));

    // Confetti runs for 2.5 s
    _confettiCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2500));

    _pieces = List.generate(80, (_) => _ConfettiPiece(_rng));

    _runSequence();
  }

  Future<void> _runSequence() async {
    await Future.delayed(const Duration(milliseconds: 100));
    
    // Chime begins alongside the animation
    _player.play(AssetSource('sounds/success.wav'));
    
    await _circleCtrl.forward();
    
    // Confetti burst exactly when checkmark starts drawing
    _confettiCtrl.forward();
    await _checkCtrl.forward();
    await _contentCtrl.forward();

    // Auto-redirect sequence
    await Future.delayed(const Duration(milliseconds: 1500));
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
    _circleCtrl.dispose();
    _checkCtrl.dispose();
    _contentCtrl.dispose();
    _confettiCtrl.dispose();
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.vesitWhite,
      body: Stack(
        children: [
          // Background Gradient (subtle)
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0, -0.2),
                  radius: 0.8,
                  colors: [
                    context.colors.vesitPrimary.withOpacity(0.04),
                    context.colors.vesitWhite,
                  ],
                ),
              ),
            ),
          ),

          // Confetti Layer
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _confettiCtrl,
              builder: (ctx, child) {
                return CustomPaint(
                  painter: _ConfettiPainter(
                      progress: _confettiCtrl.value,
                      pieces: _pieces,
                      origin: Offset(MediaQuery.of(context).size.width / 2, MediaQuery.of(context).size.height * 0.4)),
                );
              },
            ),
          ),

          // Main Center Content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Animated Checkmark Icon
                SizedBox(
                  width: 120,
                  height: 120,
                  child: AnimatedBuilder(
                    animation: Listenable.merge([_circleCtrl, _checkCtrl]),
                    builder: (ctx, child) {
                      return Transform.scale(
                        scale: _scaleBounce.value,
                        child: CustomPaint(
                    painter: _SuccessPainter(circleProgress: _circleProgress.value,
                            checkProgress: _checkProgress.value,
                          colors: context.colors),
                        ),
                      );
                    },
                  ),
                ),

                SizedBox(height: 32),

                // Text Content sliding in
                FadeTransition(
                  opacity: _contentFade,
                  child: SlideTransition(
                    position: _contentSlide,
                    child: Column(
                      children: [
                        Text(
                          'Already Marked!',
                          style: context.textStyles.vesitHeadlineLg.copyWith(
                            color: context.colors.vesitPrimary,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 12),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 40),
                          child: Text(
                            "Your attendance for this session was already recorded earlier. You're good to go!",
                            style: context.textStyles.vesitBodyLg.copyWith(
                              color: context.colors.vesitPrimary.withValues(alpha: 0.7),
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

          // Bottom Loading Overlay
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
                padding: EdgeInsets.fromLTRB(24, 24, 24, 48),
                decoration: BoxDecoration(
                  color: context.colors.vesitWhite,
                  boxShadow: [
                    BoxShadow(
                      color: context.colors.vesitPrimary.withValues(alpha: 0.08),
                      blurRadius: 24,
                      offset: const Offset(0, -8),
                    )
                  ],
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(32)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const VesitSwirlingLoader(size: 20),
                    SizedBox(width: 16),
                    Text(
                      'Returning to dashboard...',
                      style: context.textStyles.vesitLabelBold.copyWith(
                        color: context.colors.vesitPrimary.withValues(alpha: 0.7),
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

class _ConfettiPiece {
  final double angle;
  final double speed;
  final double w;
  final double h;
  final double initRot;
  final double spinRate;
  final Color color;
  final bool isRect;
  final double delay;

  static const _colors = [
    Color(0xFF002147), // vesitPrimary
    Color(0xFFe7b909), // vesitGold
    Color(0xFF4CAF50),
    Color(0xFFE91E63),
    Color(0xFF03A9F4),
    Color(0xFFFF5722),
    Color(0xFFFFC107),
    Color(0xFFFFFFFF), // vesitWhite
  ];

  _ConfettiPiece(math.Random rng)
      : angle = rng.nextDouble() * math.pi * 2,
        speed = 180 + rng.nextDouble() * 220,
        w = 5 + rng.nextDouble() * 9,
        h = 3 + rng.nextDouble() * 6,
        initRot = rng.nextDouble() * math.pi * 2,
        spinRate = (rng.nextBool() ? 1 : -1) * (3 + rng.nextDouble() * 8),
        color = _colors[rng.nextInt(_colors.length)],
        isRect = rng.nextBool(),
        delay = rng.nextDouble() * 0.08;
}

class _ConfettiPainter extends CustomPainter {
  const _ConfettiPainter({
    required this.progress,
    required this.pieces,
    required this.origin,
  });

  final double progress;
  final List<_ConfettiPiece> pieces;
  final Offset origin;

  static const double _gravity = 600;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;

    for (final p in pieces) {
      final t = (progress - p.delay).clamp(0.0, 1.0);
      if (t <= 0) continue;

      final dx = p.speed * math.cos(p.angle) * t;
      final dy = p.speed * math.sin(p.angle) * t + 0.5 * _gravity * t * t;

      final x = origin.dx + dx;
      final y = origin.dy + dy;

      final opacity = t < 0.7 ? 1.0 : (1.0 - (t - 0.7) / 0.3);

      final paint = Paint()
        ..color = p.color.withOpacity(opacity.clamp(0.0, 1.0))
        ..style = PaintingStyle.fill;

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(p.initRot + t * p.spinRate);

      if (p.isRect) {
        canvas.drawRect(
            Rect.fromCenter(center: Offset.zero, width: p.w, height: p.h),
            paint);
      } else {
        canvas.drawOval(
            Rect.fromCenter(center: Offset.zero, width: p.w, height: p.h),
            paint);
      }

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) =>
      old.progress != progress || old.origin != origin;
}

class _SuccessPainter extends CustomPainter {
  const _SuccessPainter({required this.circleProgress, required this.checkProgress, required this.colors});

  final double circleProgress;
  final double checkProgress;
  final AppThemeColors colors;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 6;

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = colors.vesitPrimary.withOpacity(0.07)
        ..style = PaintingStyle.fill,
    );

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * circleProgress,
      false,
      Paint()
        ..color = colors.vesitPrimary
        ..style = PaintingStyle.stroke
        ..strokeWidth = 7
        ..strokeCap = StrokeCap.round,
    );

    if (checkProgress > 0) {
      canvas.drawCircle(
        center,
        radius + 10,
        Paint()
          ..color = colors.vesitGold.withOpacity(0.4 * checkProgress)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3,
      );

      final cp = Paint()
        ..color = colors.vesitPrimary
        ..style = PaintingStyle.stroke
        ..strokeWidth = 7.5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

      final ex = size.width * 0.46, ey = size.height * 0.60;
      final lx = size.width * 0.28, ly = size.height * 0.44;
      final rx = size.width * 0.72, ry = size.height * 0.30;

      final s1 = (checkProgress * 2).clamp(0.0, 1.0);
      if (s1 > 0) {
        canvas.drawPath(
            Path()
              ..moveTo(lx, ly)
              ..lineTo(lx + (ex - lx) * s1, ly + (ey - ly) * s1),
            cp);
      }
      final s2 = ((checkProgress - 0.5) * 2).clamp(0.0, 1.0);
      if (s2 > 0) {
        canvas.drawPath(
            Path()
              ..moveTo(ex, ey)
              ..lineTo(ex + (rx - ex) * s2, ey + (ry - ey) * s2),
            cp);
      }
    }
  }

  @override
  bool shouldRepaint(_SuccessPainter o) =>
      o.circleProgress != circleProgress || o.checkProgress != checkProgress;
}

class _SummaryPill extends StatelessWidget {
  const _SummaryPill({required this.present, required this.absent});
  final int present;
  final int absent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      decoration: BoxDecoration(
        color: context.colors.vesitWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.colors.vesitGold, width: 2),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.groups, color: context.colors.vesitPrimary, size: 20),
          SizedBox(width: 12),
          Text('$present Present  •  $absent Absent',
              style:
                  context.textStyles.vesitLabelBold.copyWith(letterSpacing: 1.1)),
        ],
      ),
    );
  }
}
