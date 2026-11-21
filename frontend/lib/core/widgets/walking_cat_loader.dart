import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/meow_style.dart';

/// Animasi loading ringan 2.5D kucing kampus (Oyen Meowtopia) berjalan alami
/// dengan siklus langkah 4-ketukan (4-beat feline walk) berbasis CustomPainter
/// dan teks "Memuat..." di bawahnya.
class WalkingCatLoader extends StatefulWidget {
  const WalkingCatLoader({
    super.key,
    this.label = 'Memuat',
    this.size = 156,
    this.onDark = false,
    this.compact = false,
  });

  /// Teks utama di bawah animasi (titik tiga "..." otomatis ditambahkan).
  final String label;

  /// Lebar kanvas kucing (tinggi dihitung proporsional 0.66x).
  final double size;

  /// Aktifkan bila ditempatkan di latar gelap (mis. pratinjau kamera).
  final bool onDark;

  /// Mode ringkas dengan jarak vertikal lebih rapat.
  final bool compact;

  @override
  State<WalkingCatLoader> createState() => _WalkingCatLoaderState();
}

class _WalkingCatLoaderState extends State<WalkingCatLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    // 3 siklus langkah penuh dalam 3.3 detik (~1.1s per siklus langkah + kedipan mata berkala)
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3300),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final textColor = widget.onDark ? Colors.white : MeowStyle.ink;
    final dotColor = widget.onDark
        ? MeowStyle.peach
        : MeowStyle.orangeDark;
    final canvasWidth = widget.size;
    final canvasHeight = widget.size * 0.66;

    return Semantics(
      label: '${widget.label}...',
      liveRegion: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          RepaintBoundary(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                final progress = reduceMotion ? 0.18 : _controller.value;
                return CustomPaint(
                  size: Size(canvasWidth, canvasHeight),
                  painter: _WalkingCat25DPainter(
                    cycleProgress: progress,
                    onDark: widget.onDark,
                  ),
                );
              },
            ),
          ),
          SizedBox(height: widget.compact ? 4 : 8),
          AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              final dotPhase = reduceMotion ? 0.65 : (_controller.value * 3.0) % 1.0;
              return Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    widget.label,
                    style: TextStyle(
                      fontSize: widget.compact ? 12.5 : 13.5,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.2,
                      color: textColor,
                    ),
                  ),
                  for (var i = 0; i < 3; i++)
                    _AnimatedDot(
                      phase: dotPhase,
                      index: i,
                      color: dotColor,
                      fontSize: widget.compact ? 14 : 15,
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _AnimatedDot extends StatelessWidget {
  const _AnimatedDot({
    required this.phase,
    required this.index,
    required this.color,
    required this.fontSize,
  });

  final double phase;
  final int index;
  final Color color;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final wave = math.sin((phase * 2 * math.pi) - (index * 0.85));
    final opacity = 0.28 + 0.72 * ((wave + 1) * 0.5);
    final lift = -1.8 * math.max(0.0, wave);

    return Transform.translate(
      offset: Offset(0, lift),
      child: Opacity(
        opacity: opacity,
        child: Text(
          '.',
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ),
    );
  }
}

class _WalkingCat25DPainter extends CustomPainter {
  _WalkingCat25DPainter({
    required this.cycleProgress,
    required this.onDark,
  });

  /// 0..1 mewakili 3 siklus langkah penuh agar kedipan mata & gerakan telinga terasa natural.
  final double cycleProgress;
  final bool onDark;

  static const double _designW = 200.0;
  static const double _designH = 132.0;
  static const double _groundY = 107.0;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = math.min(size.width / _designW, size.height / _designH);
    final dx = (size.width - _designW * scale) * 0.5;
    final dy = (size.height - _designH * scale) * 0.5;

    canvas.save();
    canvas.translate(dx, dy);
    canvas.scale(scale, scale);

    // 1 siklus langkah (0..1)
    final t = (cycleProgress * 3.0) % 1.0;
    final tau = t * 2 * math.pi;

    // Gerakan vertikal tubuh yang halus (2 puncak per siklus langkah kucing)
    final bodyBob = math.sin(tau * 2 - 0.35) * 1.9;
    final shoulderBob = math.sin(tau * 2 + 0.45) * 1.4;
    final hipBob = math.sin(tau * 2 - 0.85) * 1.6;
    final bodyPitch = math.sin(tau) * 0.022;

    // 4-beat lateral feline walk sequence:
    // Back-Left (0.00) -> Front-Left (0.25) -> Back-Right (0.50) -> Front-Right (0.75)
    final backLeftFoot = _computeFoot(
      phase: (t + 0.00) % 1.0,
      centerX: 67.5,
      groundY: _groundY - 2.6,
      stride: 26.0,
      liftHeight: 8.5,
    );
    final frontLeftFoot = _computeFoot(
      phase: (t + 0.25) % 1.0,
      centerX: 124.5,
      groundY: _groundY - 2.6,
      stride: 26.0,
      liftHeight: 9.0,
    );
    final backRightFoot = _computeFoot(
      phase: (t + 0.50) % 1.0,
      centerX: 64.0,
      groundY: _groundY,
      stride: 26.0,
      liftHeight: 8.8,
    );
    final frontRightFoot = _computeFoot(
      phase: (t + 0.75) % 1.0,
      centerX: 121.0,
      groundY: _groundY,
      stride: 26.0,
      liftHeight: 9.2,
    );

    // 1. Lantai 2.5D, jejak bergerak, dan bayangan kontak dinamis
    _drawGroundAndShadows(
      canvas,
      t: t,
      bodyBob: bodyBob,
      feet: [backLeftFoot, frontLeftFoot, backRightFoot, frontRightFoot],
    );

    // 2. Kaki sisi jauh (kedalaman 2.5D lebih gelap)
    _drawHindLeg(
      canvas,
      hip: Offset(66.5, 67.5 + hipBob),
      foot: backLeftFoot,
      isNear: false,
    );
    _drawFrontLeg(
      canvas,
      shoulder: Offset(123.5, 66.5 + shoulderBob),
      foot: frontLeftFoot,
      isNear: false,
    );

    // 3. Ekor melengkung S-curve yang mengayun lembut
    _drawTail(canvas, tau: tau, hipBob: hipBob);

    // 4. Tubuh 2.5D dengan shading volumetrik, belang tabby, dan kalung Meowtopia
    _drawTorso(
      canvas,
      bodyBob: bodyBob,
      shoulderBob: shoulderBob,
      hipBob: hipBob,
      pitch: bodyPitch,
      tau: tau,
    );

    // 5. Kaki sisi dekat (lebih terang + kaus kaki krem + highlight 2.5D)
    _drawHindLeg(
      canvas,
      hip: Offset(62.5, 69.5 + hipBob),
      foot: backRightFoot,
      isNear: true,
    );
    _drawFrontLeg(
      canvas,
      shoulder: Offset(119.5, 68.5 + shoulderBob),
      foot: frontRightFoot,
      isNear: true,
    );

    // 6. Kepala 2.5D perspektif 3/4 dengan kedipan mata & kumis
    _drawHead(
      canvas,
      cycleProgress: cycleProgress,
      tau: tau,
      shoulderBob: shoulderBob,
    );

    canvas.restore();
  }

  _FootPose _computeFoot({
    required double phase,
    required double centerX,
    required double groundY,
    required double stride,
    required double liftHeight,
  }) {
    // Duty factor 0.64: kaki menapak 64% siklus (bergerak mundur konstan di tanah)
    const stanceDuty = 0.64;
    if (phase < stanceDuty) {
      final u = phase / stanceDuty;
      final x = centerX + stride * 0.5 - stride * u;
      return _FootPose(
        position: Offset(x, groundY),
        grounded: 1.0,
        pawTilt: 0.0,
      );
    }

    // Fase ayunan (swing): mengangkat lalu melangkah maju dengan kurva halus
    final u = (phase - stanceDuty) / (1.0 - stanceDuty);
    final smoothU = u * u * (3 - 2 * u);
    final x = centerX - stride * 0.5 + stride * smoothU;
    final arc = math.sin(math.pi * u);
    final y = groundY - liftHeight * math.pow(arc, 1.15).toDouble();
    final tilt = math.sin(math.pi * u) * 0.35;
    return _FootPose(
      position: Offset(x, y),
      grounded: 1.0 - arc,
      pawTilt: tilt,
    );
  }

  /// Analitik 2-bone Inverse Kinematics untuk sendi lutut/siku kucing.
  Offset _solveTwoBoneIk({
    required Offset root,
    required Offset target,
    required double len1,
    required double len2,
    required double bendSign,
  }) {
    final dx = target.dx - root.dx;
    final dy = target.dy - root.dy;
    final rawDist = math.sqrt(dx * dx + dy * dy);
    final maxReach = (len1 + len2) - 0.6;
    final minReach = (len1 - len2).abs() + 0.6;
    final dist = rawDist.clamp(minReach, maxReach);

    final baseAngle = math.atan2(dy, dx);
    final cosAngle =
        ((len1 * len1 + dist * dist - len2 * len2) / (2 * len1 * dist))
            .clamp(-1.0, 1.0);
    final offsetAngle = math.acos(cosAngle);
    final jointAngle = baseAngle + bendSign * offsetAngle;

    return Offset(
      root.dx + math.cos(jointAngle) * len1,
      root.dy + math.sin(jointAngle) * len1,
    );
  }

  void _drawGroundAndShadows(
    Canvas canvas, {
    required double t,
    required double bodyBob,
    required List<_FootPose> feet,
  }) {
    // Bidang jalur 2.5D lembut
    final groundRect = Rect.fromCenter(
      center: const Offset(102, _groundY + 1.5),
      width: 158,
      height: 16,
    );
    final groundPaint = Paint()
      ..shader = RadialGradient(
        colors: onDark
            ? [
                Colors.white.withValues(alpha: 0.14),
                Colors.white.withValues(alpha: 0.0),
              ]
            : [
                MeowStyle.peach.withValues(alpha: 0.55),
                MeowStyle.peach.withValues(alpha: 0.0),
              ],
      ).createShader(groundRect);
    canvas.drawOval(groundRect, groundPaint);

    // Partikel tanah & jejak kaki kecil bergeser mundur selaras kecepatan langkah
    const trackWidth = 136.0;
    const trackStart = 34.0;
    for (var i = 0; i < 6; i++) {
      final p = (i / 6.0 - t + 1.0) % 1.0;
      final x = trackStart + p * trackWidth;
      final y = _groundY + (i.isEven ? 3.8 : 0.6);
      final fade = math.sin(math.pi * p).clamp(0.0, 1.0);
      final pebblePaint = Paint()
        ..color = (onDark ? MeowStyle.peach : MeowStyle.brown)
            .withValues(alpha: fade * (onDark ? 0.34 : 0.24));

      if (i % 2 == 0) {
        // Jejak tapak mungil di permukaan 2.5D
        canvas.drawOval(
          Rect.fromCenter(center: Offset(x, y), width: 5.2, height: 2.2),
          pebblePaint,
        );
      } else {
        // Garis aksen tanah meluncur
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset(x, y), width: 8.5, height: 1.5),
            const Radius.circular(1),
          ),
          pebblePaint,
        );
      }
    }

    // Bayangan ambient tubuh di tanah (mengecil lembut saat tubuh sedikit naik)
    final shadowScale = 1.0 - (bodyBob * 0.015);
    final bodyShadowRect = Rect.fromCenter(
      center: const Offset(96, _groundY + 1.2),
      width: 88 * shadowScale,
      height: 10.5 * shadowScale,
    );
    final bodyShadowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          (onDark ? Colors.black : const Color(0xFF5D3418))
              .withValues(alpha: onDark ? 0.42 : 0.22),
          (onDark ? Colors.black : const Color(0xFF5D3418))
              .withValues(alpha: 0.0),
        ],
      ).createShader(bodyShadowRect);
    canvas.drawOval(bodyShadowRect, bodyShadowPaint);

    // Bayangan kontak langsung di bawah tiap tapak yang menapak
    for (final foot in feet) {
      if (foot.grounded <= 0.15) continue;
      final alpha = (foot.grounded * (onDark ? 0.35 : 0.20)).clamp(0.0, 0.4);
      final r = Rect.fromCenter(
        center: Offset(foot.position.dx + 1.5, foot.position.dy + 1.2),
        width: 13.0 * (0.7 + 0.3 * foot.grounded),
        height: 4.0,
      );
      canvas.drawOval(
        r,
        Paint()
          ..color = (onDark ? Colors.black : const Color(0xFF5D3418))
              .withValues(alpha: alpha),
      );
    }
  }

  void _drawFrontLeg(
    Canvas canvas, {
    required Offset shoulder,
    required _FootPose foot,
    required bool isNear,
  }) {
    // Siku kaki depan kucing menekuk sedikit ke belakang (bendSign = +1 pada +y ke bawah)
    final elbow = _solveTwoBoneIk(
      root: shoulder,
      target: Offset(foot.position.dx - 1.5, foot.position.dy - 3.5),
      len1: 21.5,
      len2: 20.5,
      bendSign: 1.0,
    );
    final ankle = Offset(foot.position.dx - 1.0, foot.position.dy - 3.2);

    final baseColor = isNear ? const Color(0xFFF97316) : const Color(0xFFC25210);
    final deepColor = isNear ? const Color(0xFFD65812) : const Color(0xFF983A08);
    final sockColor = isNear ? const Color(0xFFFFF4E6) : const Color(0xFFDCC4AE);

    // Lengan atas (lebih berisi di dekat bahu)
    final upperPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          isNear ? const Color(0xFFFFA552) : baseColor,
          deepColor,
        ],
      ).createShader(Rect.fromPoints(shoulder, elbow).inflate(8))
      ..strokeWidth = isNear ? 11.2 : 9.8
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawLine(shoulder, elbow, upperPaint);

    // Lengan bawah (meruncing halus ke pergelangan)
    final lowerPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [baseColor, deepColor],
      ).createShader(Rect.fromPoints(elbow, ankle).inflate(6))
      ..strokeWidth = isNear ? 8.2 : 7.2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawLine(elbow, ankle, lowerPaint);

    // Kaus kaki krem & tapak empuk
    _drawPaw(
      canvas,
      ankle: ankle,
      foot: foot,
      sockColor: sockColor,
      isNear: isNear,
    );
  }

  void _drawHindLeg(
    Canvas canvas, {
    required Offset hip,
    required _FootPose foot,
    required bool isNear,
  }) {
    // Pergelangan belakang (hock) kucing menekuk ke belakang untuk siluet anatomi realistis
    final hock = _solveTwoBoneIk(
      root: hip,
      target: Offset(foot.position.dx - 1.5, foot.position.dy - 3.5),
      len1: 23.0,
      len2: 21.0,
      bendSign: 1.0,
    );
    final ankle = Offset(foot.position.dx - 1.0, foot.position.dy - 3.2);

    final lightColor = isNear ? const Color(0xFFFFA34F) : const Color(0xFFC75512);
    final midColor = isNear ? const Color(0xFFF97316) : const Color(0xFFB3480C);
    final deepColor = isNear ? const Color(0xFFCA500E) : const Color(0xFF8D3507);
    final sockColor = isNear ? const Color(0xFFFFF4E6) : const Color(0xFFDCC4AE);

    // Paha atas berotot (memberi volume 2.5D di pangkal pinggul)
    final thighRect = Rect.fromCenter(
      center: Offset(hip.dx - 1.5, hip.dy + 6.5),
      width: isNear ? 22.0 : 19.0,
      height: isNear ? 25.0 : 22.0,
    );
    final thighPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.35, -0.45),
        radius: 0.9,
        colors: [lightColor, midColor, deepColor],
      ).createShader(thighRect);
    canvas.drawOval(thighRect, thighPaint);

    // Betis (dari paha menuju hock)
    final upperPaint = Paint()
      ..color = midColor
      ..strokeWidth = isNear ? 10.6 : 9.2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(hip.dx - 1.0, hip.dy + 3.0), hock, upperPaint);

    // Metatarsal ramping (hock -> tapak)
    final lowerPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [midColor, deepColor],
      ).createShader(Rect.fromPoints(hock, ankle).inflate(5))
      ..strokeWidth = isNear ? 7.6 : 6.8
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawLine(hock, ankle, lowerPaint);

    _drawPaw(
      canvas,
      ankle: ankle,
      foot: foot,
      sockColor: sockColor,
      isNear: isNear,
    );
  }

  void _drawPaw(
    Canvas canvas, {
    required Offset ankle,
    required _FootPose foot,
    required Color sockColor,
    required bool isNear,
  }) {
    canvas.save();
    canvas.translate(foot.position.dx, foot.position.dy - 2.0);
    canvas.rotate(foot.pawTilt);

    // Pergelangan kaus kaki krem
    final sockPaint = Paint()..color = sockColor;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: const Offset(-0.5, -2.5), width: 7.4, height: 7.5),
        const Radius.circular(3.5),
      ),
      sockPaint,
    );

    // Tapak oval menghadap ke depan (+x)
    final pawRect = Rect.fromCenter(
      center: const Offset(2.2, 0.2),
      width: isNear ? 12.2 : 10.8,
      height: isNear ? 6.2 : 5.5,
    );
    canvas.drawOval(pawRect, sockPaint);

    // Shading bawah tapak untuk kedalaman 2.5D
    final padShade = Paint()
      ..color = const Color(0xFF8C4A22).withValues(alpha: isNear ? 0.22 : 0.30);
    canvas.drawArc(pawRect, 0.2, math.pi - 0.4, false, padShade);

    canvas.restore();
  }

  void _drawTail(
    Canvas canvas, {
    required double tau,
    required double hipBob,
  }) {
    final sway1 = math.sin(tau) * 5.2;
    final sway2 = math.cos(tau - 0.5) * 6.5;

    final start = Offset(53.0, 56.5 + hipBob);
    final ctrl1 = Offset(34.0 + sway1 * 0.4, 52.0 + hipBob + sway1 * 0.3);
    final ctrl2 = Offset(30.0 + sway1, 25.0 + sway2 * 0.5);
    final tip = Offset(19.0 + sway2 * 0.7, 23.0 + sway1 * 0.5);

    final tailPath = Path()
      ..moveTo(start.dx, start.dy)
      ..cubicTo(ctrl1.dx, ctrl1.dy, ctrl2.dx, ctrl2.dy, tip.dx, tip.dy);

    // Bayangan bawah ekor untuk dimensi 2.5D
    canvas.drawPath(
      tailPath.shift(const Offset(0, 1.5)),
      Paint()
        ..color = const Color(0xFFAD400A)
        ..strokeWidth = 9.2
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke,
    );

    // Badan ekor bergradasi
    final tailPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.bottomRight,
        end: Alignment.topLeft,
        colors: [
          Color(0xFFEA6412),
          Color(0xFFFF9840),
          Color(0xFFD9580E),
        ],
      ).createShader(const Rect.fromLTWH(10, 14, 50, 52))
      ..strokeWidth = 8.4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawPath(tailPath, tailPaint);

    // Highlight tipis sisi atas ekor
    canvas.drawPath(
      tailPath.shift(const Offset(0.5, -1.2)),
      Paint()
        ..color = const Color(0xFFFFCC96).withValues(alpha: 0.45)
        ..strokeWidth = 2.1
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke,
    );

    // Ujung ekor krem khas Oyen
    canvas.drawCircle(
      tip,
      4.1,
      Paint()..color = const Color(0xFFFFF2E2),
    );
  }

  void _drawTorso(
    Canvas canvas, {
    required double bodyBob,
    required double shoulderBob,
    required double hipBob,
    required double pitch,
    required double tau,
  }) {
    canvas.save();
    canvas.translate(93.0, 62.0 + bodyBob);
    canvas.rotate(pitch);
    canvas.translate(-93.0, -(62.0 + bodyBob));

    final sY = shoulderBob - bodyBob;
    final hY = hipBob - bodyBob;

    // Siluet tubuh kucing organik (pundak, lengkung punggung, pinggul, dada, perut)
    final bodyPath = Path()
      ..moveTo(52.0, 63.0 + bodyBob + hY)
      // Pinggul ke punggung atas
      ..cubicTo(
        50.0, 47.0 + bodyBob + hY,
        66.0, 43.0 + bodyBob + hY,
        88.0, 46.0 + bodyBob,
      )
      // Punggung tengah ke pundak/leher
      ..cubicTo(
        106.0, 48.0 + bodyBob + sY,
        119.0, 42.0 + bodyBob + sY,
        133.0, 47.0 + bodyBob + sY,
      )
      // Dada membusung hangat
      ..cubicTo(
        142.0, 52.0 + bodyBob + sY,
        141.0, 69.0 + bodyBob + sY,
        129.0, 76.0 + bodyBob + sY,
      )
      // Perut ramping alami kucing berjalan
      ..cubicTo(
        112.0, 81.5 + bodyBob,
        86.0, 82.0 + bodyBob,
        68.0, 77.5 + bodyBob + hY,
      )
      // Menutup ke pinggul belakang
      ..cubicTo(
        56.0, 75.0 + bodyBob + hY,
        52.5, 70.0 + bodyBob + hY,
        52.0, 63.0 + bodyBob + hY,
      )
      ..close();

    final bodyBounds = Rect.fromLTWH(48, 40 + bodyBob, 96, 46);

    // 2.5D Volumetric Lighting Gradient (sumber cahaya hangat kiri-atas)
    final bodyFill = Paint()
      ..shader = const LinearGradient(
        begin: Alignment(-0.4, -1.0),
        end: Alignment(0.3, 1.0),
        colors: [
          Color(0xFFFFB463),
          Color(0xFFF97316),
          Color(0xFFDF5C0E),
          Color(0xFFC24A0B),
        ],
        stops: [0.0, 0.36, 0.78, 1.0],
      ).createShader(bodyBounds);
    canvas.drawPath(bodyPath, bodyFill);

    // Clip konten dalam siluet tubuh (bulu perut krem + belang tabby + highlight punggung)
    canvas.save();
    canvas.clipPath(bodyPath);

    // Bulu dada & perut krem lembut
    final bellyRect = Rect.fromLTWH(68, 69.5 + bodyBob, 72, 16);
    canvas.drawOval(
      bellyRect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFFFFF1E0).withValues(alpha: 0.78),
            const Color(0xFFF5DFC8).withValues(alpha: 0.92),
          ],
        ).createShader(bellyRect),
    );

    // Belang tabby melengkung lembut di punggung (mackerel stripes)
    final stripePaint = Paint()
      ..color = const Color(0xFFB33E08).withValues(alpha: 0.34)
      ..strokeWidth = 4.6
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    for (var i = 0; i < 4; i++) {
      final sx = 70.0 + i * 13.5;
      final stripe = Path()
        ..moveTo(sx, 43.0 + bodyBob)
        ..quadraticBezierTo(
          sx - 4.0,
          54.0 + bodyBob,
          sx + 1.5,
          63.5 + bodyBob,
        );
      canvas.drawPath(stripe, stripePaint);
    }

    // Rim highlight sinar matahari sepanjang punggung atas
    final rimPath = Path()
      ..moveTo(58.0, 48.0 + bodyBob + hY)
      ..quadraticBezierTo(92.0, 44.5 + bodyBob, 128.0, 46.5 + bodyBob + sY);
    canvas.drawPath(
      rimPath,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.32)
        ..strokeWidth = 2.6
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke,
    );

    canvas.restore();

    // Kalung resmi Meowtopia (Teal) + lonceng/tag QR kecil berayun halus
    final collarStart = Offset(125.0, 46.8 + bodyBob + sY);
    final collarCtrl = Offset(133.5, 57.5 + bodyBob + sY);
    final collarEnd = Offset(137.0, 62.5 + bodyBob + sY);

    final collarPath = Path()
      ..moveTo(collarStart.dx, collarStart.dy)
      ..quadraticBezierTo(
        collarCtrl.dx,
        collarCtrl.dy,
        collarEnd.dx,
        collarEnd.dy,
      );

    canvas.drawPath(
      collarPath,
      Paint()
        ..color = const Color(0xFF0E8F82)
        ..strokeWidth = 4.6
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke,
    );
    canvas.drawPath(
      collarPath.shift(const Offset(0.5, -0.6)),
      Paint()
        ..color = MeowStyle.teal
        ..strokeWidth = 3.0
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke,
    );

    // Lonceng emas mungil di kalung ikut berayun pelan
    final bellSwing = math.sin(tau * 2 + 0.7) * 1.4;
    final bellCenter = Offset(
      138.2 + bellSwing,
      64.8 + bodyBob + sY,
    );
    canvas.drawCircle(
      bellCenter,
      3.3,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-0.4, -0.4),
          colors: [Color(0xFFFFF0A6), Color(0xFFF59E0B), Color(0xFFB45309)],
        ).createShader(Rect.fromCircle(center: bellCenter, radius: 3.3)),
    );
    canvas.drawCircle(
      bellCenter.translate(-1.0, -1.0),
      0.9,
      Paint()..color = Colors.white.withValues(alpha: 0.85),
    );

    canvas.restore();
  }

  void _drawHead(
    Canvas canvas, {
    required double cycleProgress,
    required double tau,
    required double shoulderBob,
  }) {
    // Kucing menjaga kestabilan kepala saat berjalan (bob lebih kecil & lembut)
    final headBob = shoulderBob * 0.45 + math.sin(tau * 2 - 0.2) * 0.6;
    final headTilt = math.sin(tau) * 0.035;
    final headCenter = Offset(142.5, 45.0 + headBob);

    // Kedipan mata alami sekali setiap ~3 siklus langkah
    final blinkPhase = (cycleProgress - 0.78).abs();
    final blinkFactor = blinkPhase < 0.045
        ? (1.0 - math.cos((blinkPhase / 0.045) * math.pi)) * 0.5
        : 1.0;

    // Gerakan telinga halus sesekali
    final earTwitch = cycleProgress > 0.36 && cycleProgress < 0.44
        ? math.sin(((cycleProgress - 0.36) / 0.08) * math.pi) * 0.14
        : 0.0;

    canvas.save();
    canvas.translate(headCenter.dx, headCenter.dy);
    canvas.rotate(headTilt);

    // 1. Telinga jauh (sisi kanan-belakang, lebih gelap untuk perspektif 2.5D)
    final farEar = Path()
      ..moveTo(3.0, -12.0)
      ..quadraticBezierTo(11.5, -24.5, 14.5, -18.5)
      ..quadraticBezierTo(16.0, -12.0, 12.5, -5.5)
      ..close();
    canvas.drawPath(farEar, Paint()..color = const Color(0xFFC54E0D));

    // 2. Bentuk kepala 3/4 dengan pipi lembut
    const headRect = Rect.fromLTWH(-18, -16, 36, 31);
    final headPath = Path()
      ..moveTo(-15.5, -2.0)
      ..cubicTo(-16.0, -14.0, -5.0, -17.5, 5.5, -15.5)
      ..cubicTo(15.0, -13.5, 19.0, -4.5, 18.0, 4.0)
      ..cubicTo(17.0, 12.0, 8.0, 15.5, -2.0, 15.0)
      ..cubicTo(-12.0, 14.5, -17.5, 8.0, -15.5, -2.0)
      ..close();

    final headFill = Paint()
      ..shader = const RadialGradient(
        center: Alignment(-0.35, -0.45),
        radius: 0.95,
        colors: [
          Color(0xFFFFB96E),
          Color(0xFFF97316),
          Color(0xFFD65810),
        ],
        stops: [0.0, 0.58, 1.0],
      ).createShader(headRect);
    canvas.drawPath(headPath, headFill);

    // 3. Moncong & pipi bawah krem lembut (perspektif 3/4 ke kanan)
    final muzzlePath = Path()
      ..moveTo(-5.0, 3.0)
      ..cubicTo(2.0, 0.5, 14.5, 0.5, 18.2, 5.0)
      ..cubicTo(18.5, 11.5, 10.5, 15.2, 1.5, 14.8)
      ..cubicTo(-6.5, 14.2, -9.0, 8.0, -5.0, 3.0)
      ..close();
    canvas.drawPath(
      muzzlePath,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFF8F0), Color(0xFFF3DEC7)],
        ).createShader(const Rect.fromLTWH(-8, 0, 28, 16)),
    );

    // 4. Belang dahi "M" halus
    final browStripe = Paint()
      ..color = const Color(0xFFB33E08).withValues(alpha: 0.42)
      ..strokeWidth = 1.9
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawLine(const Offset(-2.5, -13.0), const Offset(0.0, -8.5), browStripe);
    canvas.drawLine(const Offset(2.0, -13.5), const Offset(3.5, -8.8), browStripe);
    canvas.drawLine(const Offset(6.2, -12.5), const Offset(6.8, -8.5), browStripe);

    // 5. Telinga dekat (dengan bagian dalam peach & sedikit gerakan earTwitch)
    canvas.save();
    canvas.translate(-6.5, -11.0);
    canvas.rotate(-earTwitch);
    final nearEarOuter = Path()
      ..moveTo(-5.5, 3.5)
      ..quadraticBezierTo(-5.0, -12.5, 1.0, -11.5)
      ..quadraticBezierTo(6.5, -9.5, 7.5, 2.5)
      ..close();
    canvas.drawPath(
      nearEarOuter,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFA955), Color(0xFFEA6412)],
        ).createShader(const Rect.fromLTWH(-6, -12, 14, 16)),
    );
    final nearEarInner = Path()
      ..moveTo(-2.5, 1.8)
      ..quadraticBezierTo(-1.8, -7.8, 1.2, -7.2)
      ..quadraticBezierTo(4.0, -5.8, 4.5, 1.5)
      ..close();
    canvas.drawPath(nearEarInner, Paint()..color = const Color(0xFFFFC2A3));
    canvas.restore();

    // 6. Mata 2.5D ekspresif (mata dekat + sedikit mata sisi jauh pada wajah 3/4)
    _drawEye(canvas, center: const Offset(4.8, -1.5), rx: 3.1, ry: 3.5, blinkFactor: blinkFactor);
    _drawEye(canvas, center: const Offset(14.0, -1.8), rx: 2.0, ry: 2.9, blinkFactor: blinkFactor);

    // 7. Hidung mungil merah muda & senyum manis
    final nosePath = Path()
      ..moveTo(10.0, 2.5)
      ..lineTo(14.0, 2.5)
      ..lineTo(12.2, 5.2)
      ..close();
    canvas.drawPath(nosePath, Paint()..color = const Color(0xFFEC6B6B));

    final mouthPaint = Paint()
      ..color = const Color(0xFF6B351A)
      ..strokeWidth = 1.25
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final mouthPath = Path()
      ..moveTo(12.2, 5.2)
      ..lineTo(12.2, 7.0)
      ..moveTo(8.5, 7.4)
      ..quadraticBezierTo(10.4, 9.2, 12.2, 7.0)
      ..quadraticBezierTo(13.8, 9.0, 15.2, 7.3);
    canvas.drawPath(mouthPath, mouthPaint);

    // 8. Kumis halus melengkung
    final whiskerPaint = Paint()
      ..color = (onDark ? Colors.white : const Color(0xFF5D3A24))
          .withValues(alpha: 0.45)
      ..strokeWidth = 0.9
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    // Kumis pipi dekat
    canvas.drawLine(const Offset(5.0, 5.5), const Offset(-6.5, 4.0), whiskerPaint);
    canvas.drawLine(const Offset(5.2, 7.5), const Offset(-6.0, 8.2), whiskerPaint);
    // Kumis sisi depan
    canvas.drawLine(const Offset(16.0, 5.2), const Offset(24.5, 4.2), whiskerPaint);
    canvas.drawLine(const Offset(15.8, 7.2), const Offset(23.8, 7.8), whiskerPaint);

    canvas.restore();
  }

  void _drawEye(
    Canvas canvas, {
    required Offset center,
    required double rx,
    required double ry,
    required double blinkFactor,
  }) {
    if (blinkFactor < 0.22) {
      // Kelopak mata tertutup lembut saat berkedip
      final closed = Path()
        ..moveTo(center.dx - rx, center.dy)
        ..quadraticBezierTo(center.dx, center.dy + 1.8, center.dx + rx, center.dy);
      canvas.drawPath(
        closed,
        Paint()
          ..color = const Color(0xFF2D1A10)
          ..strokeWidth = 1.5
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke,
      );
      return;
    }

    final actualRy = ry * blinkFactor;
    final eyeRect = Rect.fromCenter(
      center: center,
      width: rx * 2,
      height: actualRy * 2,
    );

    // Iris amber-emerald hangat + pupil gelap
    canvas.drawOval(eyeRect, Paint()..color = const Color(0xFF1E293B));
    final irisRect = Rect.fromCenter(
      center: center.translate(0, actualRy * 0.12),
      width: rx * 1.45,
      height: actualRy * 1.45,
    );
    canvas.drawOval(
      irisRect,
      Paint()
        ..color = const Color(0xFF10B981).withValues(alpha: 0.35),
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: center,
        width: rx * 0.95,
        height: actualRy * 1.35,
      ),
      Paint()..color = const Color(0xFF0F172A),
    );

    // Kilau specular putih untuk kesan hidup 2.5D
    canvas.drawCircle(
      center.translate(-rx * 0.28, -actualRy * 0.32),
      rx * 0.32,
      Paint()..color = Colors.white.withValues(alpha: 0.92),
    );
  }

  @override
  bool shouldRepaint(covariant _WalkingCat25DPainter oldDelegate) =>
      oldDelegate.cycleProgress != cycleProgress || oldDelegate.onDark != onDark;
}

class _FootPose {
  const _FootPose({
    required this.position,
    required this.grounded,
    required this.pawTilt,
  });

  final Offset position;
  final double grounded;
  final double pawTilt;
}
