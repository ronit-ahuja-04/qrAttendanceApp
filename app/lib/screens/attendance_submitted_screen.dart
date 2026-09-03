import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../routes/fade_blur_route.dart';
import '../widgets/vesit_loader.dart';
import 'faculty_main_layout.dart';

class AttendanceSubmittedScreen extends StatefulWidget {
  const AttendanceSubmittedScreen({
    super.key,
    required this.subjectTitle,
    required this.presentCount,
    required this.absentCount,
  });

  final String subjectTitle;
  final int presentCount;
  final int absentCount;

  @override
  State<AttendanceSubmittedScreen> createState() =>
      _AttendanceSubmittedScreenState();
}

class _AttendanceSubmittedScreenState extends State<AttendanceSubmittedScreen>
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
    await _circleCtrl.forward();
    // Chime + confetti burst exactly when checkmark starts drawing
    _player.play(AssetSource('sounds/success.wav'));
    _confettiCtrl.forward();
    await _checkCtrl.forward();
    await _contentCtrl.forward();

    // Auto-redirect sequence
    await Future.delayed(const Duration(milliseconds: 1500));
    if (!mounted) return;
    setState(() => _isRedirecting = true);

    // Simulate network buffering / DB save
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      FadeBlurPageRoute(page: const FacultyMainLayout()),
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
      backgroundColor: context.colors.vesitGray,
      body: Stack(
        children: [
          // Confetti — full screen, origin = centre of badge
          LayoutBuilder(builder: (context, constraints) {
            final origin = Offset(
              constraints.maxWidth / 2,
              constraints.maxHeight * 0.38,
            );
            return AnimatedBuilder(
              animation: _confettiCtrl,
              builder: (_, __) => CustomPaint(
                size: Size(constraints.maxWidth, constraints.maxHeight),
                painter: _ConfettiPainter(
                  progress: _confettiCtrl.value,
                  pieces: _pieces,
                  origin: origin,
                ),
              ),
            );
          }),

          // Main content
          SafeArea(
            child: SizedBox(
              width: double.infinity,
              child: Column(
                children: [
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AnimatedBuilder(
                            animation:
                                Listenable.merge([_circleCtrl, _checkCtrl]),
                            builder: (_, __) => ScaleTransition(
                              scale: _scaleBounce,
                              child: SizedBox(
                                width: 160,
                                height: 160,
                                child: CustomPaint(
                    painter: _SuccessPainter(circleProgress: _circleProgress.value,
                                    checkProgress: _checkProgress.value, colors: context.colors),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: 36),
                          FadeTransition(
                            opacity: _contentFade,
                            child: SlideTransition(
                              position: _contentSlide,
                              child: Column(
                                children: [
                                  Text(
                                    'Attendance Submitted!',
                                    textAlign: TextAlign.center,
                                    style: context.textStyles.vesitHeadlineMd
                                        .copyWith(color: context.colors.vesitPrimary),
                                  ),
                                  SizedBox(height: 14),
                                  Text(
                                    'Session records for ${widget.subjectTitle} have been '
                                    'locked and synchronized with the central database.',
                                    textAlign: TextAlign.center,
                                    style: context.textStyles.vesitBodyLg,
                                  ),
                                  SizedBox(height: 36),
                                  _SummaryPill(
                                    present: widget.presentCount,
                                    absent: widget.absentCount,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Blur overlay during auto-redirect
          if (_isRedirecting)
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                child: Container(
                  color: Colors.black.withOpacity(0.4),
                  alignment: Alignment.center,
                  child: SafeArea(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const VesitSwirlingLoader(size: 64),
                        SizedBox(height: 24),
                        Text(
                          'Saving to Central Database...',
                          style: context.textStyles.vesitLabelBold.copyWith(color: context.colors.vesitWhite),
                        ),
                      ],
                    ),
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
  const _SuccessPainter(
      {required this.circleProgress, required this.checkProgress, required this.colors});

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
