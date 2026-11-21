import 'package:flutter/material.dart';

const authEmailServicesEnabled = bool.fromEnvironment(
  'MEOWTOPIA_ENABLE_EMAIL_SERVICES',
);

class AuthEmailOptionsPreview extends StatelessWidget {
  const AuthEmailOptionsPreview({super.key});

  @override
  Widget build(BuildContext context) {
    final style = OutlinedButton.styleFrom(
      disabledForegroundColor: const Color(0xFF765C4B),
      side: const BorderSide(color: Color(0xFFF0DCCB)),
      minimumSize: const Size(0, 42),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Google dan OTP belum aktif',
          textAlign: TextAlign.center,
          style: TextStyle(color: Color(0xFF765C4B), fontSize: 12),
        ),
        const SizedBox(height: 4),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 4,
          children: [
            OutlinedButton.icon(
              onPressed: null,
              style: style,
              icon: const AuthGoogleMark(),
              label: const Text('Google'),
            ),
            OutlinedButton.icon(
              onPressed: null,
              style: style,
              icon: const Icon(Icons.mail_outline_rounded, size: 18),
              label: const Text('OTP email'),
            ),
          ],
        ),
      ],
    );
  }
}

class AuthGoogleMark extends StatelessWidget {
  const AuthGoogleMark({super.key});

  @override
  Widget build(BuildContext context) => const CustomPaint(
        size: Size(22, 22),
        painter: _GoogleMarkPainter(),
      );
}

class _GoogleMarkPainter extends CustomPainter {
  const _GoogleMarkPainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 48, size.height / 48);
    final red = Path()
      ..moveTo(24, 9.5)
      ..cubicTo(27.54, 9.5, 30.71, 10.72, 33.21, 13.1)
      ..lineTo(40.06, 6.25)
      ..cubicTo(35.9, 2.38, 30.47, 0, 24, 0)
      ..cubicTo(14.62, 0, 6.51, 5.38, 2.56, 13.22)
      ..lineTo(10.54, 19.41)
      ..cubicTo(12.43, 13.72, 17.74, 9.5, 24, 9.5)
      ..close();
    final blue = Path()
      ..moveTo(46.98, 24.55)
      ..cubicTo(46.98, 22.98, 46.83, 21.46, 46.6, 20)
      ..lineTo(24, 20)
      ..lineTo(24, 29.02)
      ..lineTo(36.94, 29.02)
      ..cubicTo(36.36, 31.98, 34.68, 34.5, 32.19, 36.2)
      ..lineTo(39.92, 42.2)
      ..cubicTo(44.43, 38.02, 46.98, 31.84, 46.98, 24.55)
      ..close();
    final yellow = Path()
      ..moveTo(10.53, 28.59)
      ..cubicTo(10.02, 27.15, 9.75, 25.62, 9.75, 24)
      ..cubicTo(9.75, 22.38, 10.02, 20.85, 10.51, 19.41)
      ..lineTo(2.53, 13.22)
      ..cubicTo(.93, 16.48, 0, 20.13, 0, 24)
      ..cubicTo(0, 27.87, .93, 31.52, 2.56, 34.78)
      ..lineTo(10.53, 28.59)
      ..close();
    final green = Path()
      ..moveTo(24, 48)
      ..cubicTo(30.48, 48, 35.93, 45.87, 39.91, 42.2)
      ..lineTo(32.18, 36.2)
      ..cubicTo(30.04, 37.65, 27.29, 38.5, 24, 38.5)
      ..cubicTo(17.74, 38.5, 12.43, 34.28, 10.53, 28.59)
      ..lineTo(2.56, 34.78)
      ..cubicTo(6.51, 42.62, 14.62, 48, 24, 48)
      ..close();

    for (final (path, color) in [
      (red, const Color(0xFFEA4335)),
      (blue, const Color(0xFF4285F4)),
      (yellow, const Color(0xFFFBBC05)),
      (green, const Color(0xFF34A853)),
    ]) {
      canvas.drawPath(path, Paint()..color = color);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _GoogleMarkPainter oldDelegate) => false;
}
