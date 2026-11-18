// ignore_for_file: constant_identifier_names
import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/meow_style.dart';

/// Token tampilan modul Adopsi (EN-8, Tim E-Nigma).
///
/// Semua nilai diturunkan dari [MeowStyle] dan [AppConstants] supaya adopsi
/// sejalan dengan fitur lain (Beranda, Spot Makan, Cat Hunter): oranye tim,
/// latar gradasi peach ke mint, kartu kaca bersudut 24, tombol kapsul.
abstract final class AdoptionTheme {
  // Warna aksen (oranye tim)
  static const Color accent = MeowStyle.orange;
  static const Color accentDark = MeowStyle.orangeDark;
  static const Color accentLight = MeowStyle.peach;
  static const Color accentSurface = AppConstants.primaryLight;

  // Latar dan permukaan
  static const Color pageBg = MeowStyle.background;
  static const Color bgPeach = Color(0xFFFFE7D9);
  static const Color bgMint = Color(0xFFE5F8F0);
  static const Color cardBg = Colors.white;
  static const Color glassBg =
      Color(0xD1FFFFFF); // putih 82%, sama dengan GlassCard
  static const Color chipBg = MeowStyle.lilac;

  // Teks
  static const Color textMain = MeowStyle.ink;
  static const Color textSub = MeowStyle.brown;
  static const Color textHint = Color(0xFF75665B);

  // Garis
  static const Color divider = Color(0xFFEDE6F0);
  static const Color cardBorder = Colors.white;
  static const Color inputBorder = Color(0xFFE2DCE6);

  // Status semantik (selalu dipasangkan dengan teks, tidak hanya warna)
  static const Color success = MeowStyle.green;
  static const Color successLight = Color(0xFFE3F7EE);
  static const Color danger = MeowStyle.danger;
  static const Color dangerLight = Color(0xFFFBE9EA);
  static const Color warning = Color(0xFF9A6200);
  static const Color warningLight = Color(0xFFFFF3DC);
  static const Color info = MeowStyle.blue;
  static const Color infoLight = Color(0xFFE8F0FC);

  // Radius (mengikuti GlassCard dan MeowPill)
  static const double radiusSm = 12.0;
  static const double radiusMd = 16.0;
  static const double radiusLg = 24.0;
  static const double radiusXl = 24.0;
  static const double radiusPhoto = 20.0;

  static const BorderRadius borderSm =
      BorderRadius.all(Radius.circular(radiusSm));
  static const BorderRadius borderMd =
      BorderRadius.all(Radius.circular(radiusMd));
  static const BorderRadius borderLg =
      BorderRadius.all(Radius.circular(radiusLg));
  static const BorderRadius borderXl =
      BorderRadius.all(Radius.circular(radiusXl));
  static const BorderRadius borderPhoto =
      BorderRadius.all(Radius.circular(radiusPhoto));
  static const BorderRadius borderPill = BorderRadius.all(Radius.circular(30));

  // Jarak
  static const double sp4 = 4.0;
  static const double sp8 = 8.0;
  static const double sp12 = 12.0;
  static const double sp16 = 16.0;
  static const double sp24 = 24.0;
  static const double sp32 = 32.0;

  static const EdgeInsets padCard = EdgeInsets.all(18);
  static const EdgeInsets padSection =
      EdgeInsets.symmetric(horizontal: sp16, vertical: sp12);
  static const EdgeInsets padPage = EdgeInsets.fromLTRB(20, 20, 20, 20);

  /// Lebar maksimum konten, sama dengan MeowPage.
  static const double maxContentWidth = 720;

  /// Gradasi latar halaman, sama dengan MeowPage.
  static const LinearGradient pageGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [bgPeach, pageBg, bgMint, pageBg],
    stops: [0, .35, .7, 1],
  );

  // Tipografi (mengikuti ukuran di Beranda dan Spot Makan)
  static const TextStyle headlineStyle = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    letterSpacing: -.7,
    color: textMain,
    fontFamily: 'Inter',
    height: 1.25,
  );

  static const TextStyle titleStyle = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w600,
    color: textMain,
    fontFamily: 'Inter',
    height: 1.3,
  );

  static const TextStyle subtitleStyle = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: textMain,
    fontFamily: 'Inter',
    height: 1.35,
  );

  static const TextStyle bodyStyle = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: textSub,
    fontFamily: 'Inter',
    height: 1.5,
  );

  static const TextStyle captionStyle = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: textHint,
    fontFamily: 'Inter',
    height: 1.4,
  );

  // Dekorasi: kartu kaca seperti GlassCard.
  static BoxDecoration get cardDecoration => BoxDecoration(
        color: glassBg,
        borderRadius: borderLg,
        border: Border.all(color: Colors.white, width: 1.2),
        boxShadow: const [
          BoxShadow(
              color: Color(0x0F9D4300), blurRadius: 28, offset: Offset(0, 8)),
        ],
      );

  static BoxDecoration get heroCardDecoration => cardDecoration;

  static BoxDecoration get photoDecoration => const BoxDecoration(
        color: chipBg,
        borderRadius: borderPhoto,
      );

  // Tombol kapsul seperti MeowButton.
  static ButtonStyle get primaryButtonStyle => FilledButton.styleFrom(
        backgroundColor: accent,
        foregroundColor: Colors.white,
        disabledBackgroundColor: chipBg,
        disabledForegroundColor: textHint,
        minimumSize: const Size(0, 52),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 15),
        shape: const StadiumBorder(),
        textStyle: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      );

  static ButtonStyle get secondaryButtonStyle => FilledButton.styleFrom(
        backgroundColor: MeowStyle.lilac,
        foregroundColor: textMain,
        minimumSize: const Size(0, 52),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        shape: const StadiumBorder(),
        textStyle: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      );
}
