import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';

const _gripDuration = Duration(milliseconds: 670);

enum AuthPageArrival { paw }

mixin AuthSubmitMotion<T extends StatefulWidget> on State<T> {
  bool isSubmitting = false;
  bool isSwitchingAuthPage = false;
  final authScrollController = ScrollController();

  @override
  void dispose() {
    authScrollController.dispose();
    super.dispose();
  }

  Future<void> switchAuthPage(String location) async {
    if (isSubmitting) return;
    if (MediaQuery.disableAnimationsOf(context)) {
      context.go(location);
      return;
    }
    FocusScope.of(context).unfocus();
    isSwitchingAuthPage = true;
    await submitWithPaw(() async {
      if (authScrollController.hasClients && authScrollController.offset > 0) {
        await authScrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeOutCubic,
        );
      }
      return true;
    });
    isSwitchingAuthPage = false;
    if (mounted) context.go(location, extra: AuthPageArrival.paw);
  }

  Future<bool> submitWithPaw(Future<bool> Function() submit) async {
    if (isSubmitting) return false;
    final minDuration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : _gripDuration + const Duration(milliseconds: 100);
    final stopwatch = Stopwatch()..start();
    setState(() => isSubmitting = true);
    try {
      return await submit();
    } finally {
      final remaining = minDuration - stopwatch.elapsed;
      if (mounted && remaining > Duration.zero) {
        await Future<void>.delayed(remaining);
      }
      if (mounted) setState(() => isSubmitting = false);
    }
  }
}

class AuthPageShell extends StatelessWidget {
  const AuthPageShell({
    required this.child,
    required this.isSubmitting,
    required this.scrollController,
    this.startsGripped = false,
    super.key,
  });

  final Widget child;
  final bool isSubmitting;
  final ScrollController scrollController;
  final bool startsGripped;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final compact = size.height < 720;
    final narrow = size.width < 360;
    return ColoredBox(
      color: const Color(0xFFFFF7F0),
      child: LayoutBuilder(
        builder: (context, viewport) {
          final heroHeight = viewport.maxHeight * .58;
          return SingleChildScrollView(
            controller: scrollController,
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: viewport.maxHeight),
              child: Stack(
                children: [
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    height: heroHeight,
                    child: const IgnorePointer(
                      child: CustomPaint(
                        painter: _OrangeUBackgroundPainter(),
                        foregroundPainter: _PawPatternPainter(),
                      ),
                    ),
                  ),
                  SafeArea(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: narrow ? 12 : 22,
                        vertical: compact ? 10 : 20,
                      ),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 440),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _MeowtopiaIntro(compact: compact, narrow: narrow),
                              SizedBox(height: compact ? 12 : 20),
                              _PawPanel(
                                heightBudget: viewport.maxHeight * .70,
                                isSubmitting: isSubmitting,
                                startsGripped: startsGripped,
                                child: child,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _MeowtopiaIntro extends StatelessWidget {
  const _MeowtopiaIntro({required this.compact, required this.narrow});

  final bool compact;
  final bool narrow;

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.only(top: compact ? 4 : 12),
        child: Column(
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: Image.asset(
                    'assets/images/logo.png',
                    width: narrow ? 44 : 54,
                    height: narrow ? 44 : 54,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Meowtopia',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: narrow ? 20 : 23,
                        fontWeight: FontWeight.w800,
                        letterSpacing: .2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'CAMPUS CAT WELFARE APP',
                      style: TextStyle(
                        color: const Color(0xFFFFF1E4),
                        fontSize: narrow ? 7.5 : 10,
                        letterSpacing: narrow ? .45 : 1.1,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: compact ? 12 : 18),
            Text(
              'Teman baik kucing kampus',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: compact ? 21 : 24,
                fontWeight: FontWeight.w800,
                height: 1.15,
              ),
            ),
            const SizedBox(height: 7),
            const Text(
              'Kenali kucing, temukan titik pakan, dan ikut menjaga kesejahteraan mereka.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFFFFF3E7),
                fontSize: 13,
                height: 1.45,
              ),
            ),
          ],
        ),
      );
}

class _PawPanel extends StatelessWidget {
  const _PawPanel({
    required this.child,
    required this.isSubmitting,
    required this.startsGripped,
    required this.heightBudget,
  });

  final Widget child;
  final bool isSubmitting;
  final bool startsGripped;
  final double heightBudget;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          final narrow = constraints.maxWidth < 300;
          // Size the paw against the shared card, with a height cap so the
          // form retains room on shorter screens and above the keyboard.
          final pawWidth = math.min(
            constraints.maxWidth * .57,
            heightBudget * .44,
          );
          final scale = pawWidth / 420;
          final cardTop = 218 * scale;
          final reduceMotion = MediaQuery.disableAnimationsOf(context);
          return TweenAnimationBuilder<double>(
            tween: Tween(
              begin: startsGripped && !reduceMotion ? 1.0 : 0.0,
              end: isSubmitting && !reduceMotion ? 1.0 : 0.0,
            ),
            duration: reduceMotion ? Duration.zero : _gripDuration,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x1FD6581F),
                    blurRadius: 20,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Padding(
                padding: EdgeInsets.all(narrow ? 12 : 18),
                child: child,
              ),
            ),
            builder: (context, grip, card) {
              final reach = Curves.easeInOutCubic.transform(
                (grip / .62).clamp(0.0, 1.0),
              );
              final pull = Curves.easeOutCubic.transform(
                ((grip - .62) / .38).clamp(0.0, 1.0),
              );
              final lift = 20 * pull;
              final shift = -7 * pull;
              final tilt = -.028 * pull;

              Widget paw({required bool inFront}) => Positioned.fill(
                    child: IgnorePointer(
                      child: CustomPaint(
                        painter: _PawIconPainter(
                          scale: scale,
                          edge: cardTop - lift,
                          reach: reach,
                          pull: pull,
                          inFront: inFront,
                        ),
                      ),
                    ),
                  );

              return Stack(
                clipBehavior: Clip.none,
                children: [
                  paw(inFront: false),
                  Padding(
                    padding: EdgeInsets.only(top: cardTop, bottom: 12),
                    child: Transform.translate(
                      offset: Offset(shift, -lift),
                      child: Transform.rotate(
                        angle: tilt,
                        alignment: Alignment.topCenter,
                        child: card,
                      ),
                    ),
                  ),
                  paw(inFront: true),
                ],
              );
            },
          );
        },
      );
}

class _PawIconPainter extends CustomPainter {
  const _PawIconPainter({
    required this.scale,
    required this.edge,
    required this.reach,
    required this.pull,
    required this.inFront,
  });

  final double scale;
  final double edge;
  final double reach;
  final double pull;
  final bool inFront;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty || scale <= 0) return;

    final pitch = math.cos(math.pi * reach);
    final overCard = pitch < 0;
    final reachArc = math.sin(math.pi * reach);
    final tipOverlap = math.min(13.0, 35 * scale);
    final cardEdge = math.max(edge, 12.0);
    final rest = 218 * scale;
    final gripY = cardEdge - 199 * scale * .62 + tipOverlap;
    final wrist = Offset(
      size.width / 2 + scale * 62 * reachArc - 7 * pull,
      rest + (gripY - rest) * reach - scale * 45 * reachArc,
    );
    final sway = .23 * reachArc - .028 * pull;

    if (!inFront && reach > 0) {
      _paintArm(canvas, wrist, cardEdge, sway);
    }
    if (overCard != inFront) return;

    // The soft side of the paw remains visible while the wrist turns.
    final depth = pitch.abs();
    final flatten = pitch * (overCard ? .62 : 1.0);
    final coat = Paint();

    canvas.save();
    canvas.translate(wrist.dx, wrist.dy);
    canvas.rotate(sway);
    canvas.scale(scale);
    final side = Path()
      ..moveTo(-153, -5)
      ..cubicTo(-148, -27, -65, -33, 9, -32)
      ..cubicTo(84, -32, 153, -23, 154, -3)
      ..cubicTo(156, 22, 79, 27, 14, 27)
      ..cubicTo(-58, 27, -157, 21, -153, -5)
      ..close();
    final sideOpacity = (1 - depth * 2.2).clamp(0.0, 1.0);
    if (sideOpacity > 0) {
      canvas.drawPath(
          side,
          coat
            ..shader = LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                const Color(0xFFFFF8ED).withValues(alpha: sideOpacity),
                const Color(0xFFE8A672).withValues(alpha: sideOpacity),
              ],
            ).createShader(side.getBounds()));
    }

    if (depth < .005) {
      canvas.restore();
      return;
    }
    canvas.scale(1 - .12 * reach, flatten);
    canvas.translate(-210, -218);
    final outline = Path()
      ..moveTo(8, 173)
      ..cubicTo(8, 135, 31, 110, 77, 108)
      ..cubicTo(86, 108, 86, 105, 84, 95)
      ..cubicTo(75, 53, 107, 19, 151, 19)
      ..cubicTo(177, 19, 196, 31, 210, 54)
      ..quadraticBezierTo(214, 63, 220, 54)
      ..cubicTo(235, 31, 253, 19, 279, 19)
      ..cubicTo(323, 19, 354, 53, 345, 95)
      ..cubicTo(343, 105, 343, 108, 352, 108)
      ..cubicTo(396, 110, 419, 135, 419, 173)
      ..cubicTo(419, 194, 410, 211, 397, 226)
      ..cubicTo(367, 249, 311, 247, 274, 230)
      ..quadraticBezierTo(210, 207, 149, 230)
      ..cubicTo(108, 248, 58, 245, 30, 226)
      ..cubicTo(17, 211, 8, 194, 8, 173)
      ..close();

    if (overCard) {
      canvas.drawShadow(outline, const Color(0x66572B14), 7, false);
    }
    canvas.drawPath(
        outline,
        coat
          ..shader = RadialGradient(
            center: const Alignment(-.36, -.43),
            radius: 1.16,
            colors: overCard
                ? const [
                    Color(0xFFFFFCF6),
                    Color(0xFFFFEBD5),
                    Color(0xFFD89B6E)
                  ]
                : const [
                    Color(0xFFFFFDF8),
                    Color(0xFFFFF2E0),
                    Color(0xFFE2AA83)
                  ],
            stops: const [0, .61, 1],
          ).createShader(outline.getBounds()));
    canvas.drawPath(
        outline,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = const Color(0x24A55728));

    for (final center in const [
      Offset(75, 172),
      Offset(151, 90),
      Offset(279, 90),
      Offset(352, 172),
    ]) {
      final pad = Rect.fromCenter(center: center, width: 74, height: 77);
      canvas.drawOval(pad.shift(const Offset(0, 3)),
          Paint()..color = const Color(0x35BD6533));
      canvas.drawOval(
          pad,
          Paint()
            ..shader = const RadialGradient(
              center: Alignment(-.37, -.38),
              radius: .85,
              colors: [Color(0xFFFFBE8D), Color(0xFFF88948), Color(0xFFD65D2C)],
              stops: [0, .58, 1],
            ).createShader(pad));
    }
    canvas.restore();
  }

  void _paintArm(Canvas canvas, Offset wrist, double cardEdge, double sway) {
    canvas.save();
    canvas.translate(wrist.dx, wrist.dy);
    canvas.scale(scale);
    final baseY = math.max(95.0, (cardEdge - wrist.dy) / scale + 70);
    final bend = 150 * reach;
    final arm = Path()
      ..moveTo(-66, 9)
      ..cubicTo(-43, -53, bend - 37, -56, bend + 24, -24)
      ..cubicTo(bend + 89, 7, bend + 120, baseY * .62, bend + 127, baseY)
      ..quadraticBezierTo(bend + 81, baseY + 26, bend + 17, baseY)
      ..cubicTo(bend + 9, baseY * .63, bend - 7, 33, bend - 36, 19)
      ..cubicTo(bend - 64, 3, 56, 13 + sway * 48, 56, 25)
      ..quadraticBezierTo(-7, 55, -66, 9)
      ..close();

    canvas.drawShadow(arm, const Color(0x499B4416), 7, true);
    canvas.drawPath(
        arm,
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFFFF9EC),
              Color(0xFFFFD9AC),
              Color(0xFFDD9058),
              Color(0xFFB96236),
            ],
            stops: [0, .37, .72, 1],
          ).createShader(arm.getBounds()));

    canvas.clipPath(arm);
    canvas.drawPath(
      Path()
        ..moveTo(-16, -22)
        ..cubicTo(bend - 15, -59, bend + 73, -26, bend + 90, 32),
      Paint()
        ..color = const Color(0x60FFF5DB)
        ..strokeWidth = 9
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke,
    );
    final fur = Paint()
      ..color = const Color(0x309F4D27)
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    for (final offset in [0.0, 30.0]) {
      final stripe = Path()
        ..moveTo(bend + 44 + offset, -19 + offset * 1.12)
        ..quadraticBezierTo(bend + 27 + offset, -1 + offset * 1.12,
            bend + 9 + offset, 4 + offset * 1.12);
      canvas.drawPath(stripe, fur);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _PawIconPainter oldDelegate) =>
      scale != oldDelegate.scale ||
      edge != oldDelegate.edge ||
      reach != oldDelegate.reach ||
      pull != oldDelegate.pull ||
      inFront != oldDelegate.inFront;
}

class _OrangeUBackgroundPainter extends CustomPainter {
  const _OrangeUBackgroundPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(w, 0)
      ..lineTo(w, h * .75)
      ..cubicTo(w * .82, h * .75, w * .76, h, w * .50, h)
      ..cubicTo(w * .24, h, w * .18, h * .75, 0, h * .75)
      ..close();
    final paint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFFFA43A), AppConstants.primaryColor],
      ).createShader(Offset.zero & size);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _OrangeUBackgroundPainter oldDelegate) => false;
}

class _PawPatternPainter extends CustomPainter {
  const _PawPatternPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final orangeShape = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height * .75)
      ..cubicTo(
        size.width * .82,
        size.height * .75,
        size.width * .76,
        size.height,
        size.width * .50,
        size.height,
      )
      ..cubicTo(
        size.width * .24,
        size.height,
        size.width * .18,
        size.height * .75,
        0,
        size.height * .75,
      )
      ..close();
    canvas.save();
    canvas.clipPath(orangeShape);
    final paint = Paint()..color = const Color(0x20FFFFFF);
    _drawPaw(canvas, paint, Offset(size.width * .12, size.height * .28), 24);
    _drawPaw(canvas, paint, Offset(size.width * .88, size.height * .32), 34);
    _drawPaw(canvas, paint, Offset(size.width * .75, size.height * .83), 18);
    canvas.restore();
  }

  void _drawPaw(Canvas canvas, Paint paint, Offset center, double radius) {
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(center.dx, center.dy + radius * .58),
        width: radius * 1.5,
        height: radius * 1.15,
      ),
      paint,
    );
    for (var i = 0; i < 3; i++) {
      final dx = (i - 1) * radius * .72;
      canvas.drawCircle(
        Offset(center.dx + dx, center.dy - radius * .12 + (i == 1 ? 0 : 3)),
        radius * .34,
        paint,
      );
    }
    canvas.drawCircle(
      Offset(center.dx - radius * .89, center.dy + radius * .38),
      radius * .31,
      paint,
    );
    canvas.drawCircle(
      Offset(center.dx + radius * .89, center.dy + radius * .38),
      radius * .31,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _PawPatternPainter oldDelegate) => false;
}
