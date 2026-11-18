// ignore_for_file: constant_identifier_names
import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';

/// Token tampilan modul Adopsi (EN-8, Tim E-Nigma).
///
/// Prinsip: satu warna aksen (terakota), permukaan datar tanpa bayangan,
/// bagian dipisah judul dan garis tipis. Kartu hanya untuk item yang bisa
/// diketuk. Semua warna layar adopsi diambil dari sini, bukan hex di halaman.
abstract final class AdoptionTheme {
  // Warna aksen
  static const Color accent = Color(0xFFA9532F);
  static const Color accentLight = Color(0xFFF3E4DC);
  static const Color accentSurface = Color(0xFFFAF1EC);

  // Latar dan permukaan
  static const Color pageBg = Color(0xFFFBF8F5);
  static const Color cardBg = Colors.white;
  static const Color chipBg = Color(0xFFF1ECE7);

  // Teks
  static const Color textMain = AppConstants.textPrimary;
  static const Color textSub = AppConstants.textSecondary;
  static const Color textHint = Color(0xFF75665B);

  // Garis
  static const Color divider = Color(0xFFE9E2DB);
  static const Color cardBorder = Color(0xFFE4DCD4);
  static const Color inputBorder = Color(0xFFD4C6BC);

  // Status semantik (selalu dipasangkan dengan teks, tidak hanya warna)
  static const Color success = Color(0xFF2F7D4F);
  static const Color successLight = Color(0xFFE6F2EA);
  static const Color danger = Color(0xFFB3261E);
  static const Color dangerLight = Color(0xFFFBEAE8);
  static const Color warning = Color(0xFF9A6200);
  static const Color warningLight = Color(0xFFFBF1DE);
  static const Color info = Color(0xFF35618F);
  static const Color infoLight = Color(0xFFE8EFF6);

  // Radius
  static const double radiusSm = 6.0;
  static const double radiusMd = 10.0;
  static const double radiusLg = 12.0;
  static const double radiusXl = 12.0;
  static const double radiusPhoto = 10.0;

  static const BorderRadius borderSm = BorderRadius.all(Radius.circular(radiusSm));
  static const BorderRadius borderMd = BorderRadius.all(Radius.circular(radiusMd));
  static const BorderRadius borderLg = BorderRadius.all(Radius.circular(radiusLg));
  static const BorderRadius borderXl = BorderRadius.all(Radius.circular(radiusXl));
  static const BorderRadius borderPhoto = BorderRadius.all(Radius.circular(radiusPhoto));

  // Jarak
  static const double sp4 = 4.0;
  static const double sp8 = 8.0;
  static const double sp12 = 12.0;
  static const double sp16 = 16.0;
  static const double sp24 = 24.0;
  static const double sp32 = 32.0;

  static const EdgeInsets padCard = EdgeInsets.all(sp16);
  static const EdgeInsets padSection = EdgeInsets.symmetric(horizontal: sp16, vertical: sp12);
  static const EdgeInsets padPage = EdgeInsets.fromLTRB(sp16, sp16, sp16, sp32);

  /// Lebar maksimum konten agar tetap nyaman dibaca di web lebar.
  static const double maxContentWidth = 720;

  // Tipografi: judul halaman, judul bagian, isi, keterangan.
  static const TextStyle headlineStyle = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    color: textMain,
    fontFamily: 'Inter',
    height: 1.25,
  );

  static const TextStyle titleStyle = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w700,
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
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: textSub,
    fontFamily: 'Inter',
    height: 1.45,
  );

  static const TextStyle captionStyle = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: textHint,
    fontFamily: 'Inter',
    height: 1.35,
  );

  // Dekorasi: datar, border tipis, tanpa bayangan.
  static BoxDecoration get cardDecoration => BoxDecoration(
        color: cardBg,
        borderRadius: borderLg,
        border: Border.all(color: cardBorder),
      );

  /// Dipertahankan untuk kompatibilitas; sama dengan [cardDecoration].
  static BoxDecoration get heroCardDecoration => cardDecoration;

  static BoxDecoration get photoDecoration => const BoxDecoration(
        color: chipBg,
        borderRadius: borderPhoto,
      );

  // Tombol
  static ButtonStyle get primaryButtonStyle => ElevatedButton.styleFrom(
        backgroundColor: accent,
        foregroundColor: Colors.white,
        disabledBackgroundColor: chipBg,
        disabledForegroundColor: textHint,
        elevation: 0,
        minimumSize: const Size(0, 48),
        padding: const EdgeInsets.symmetric(horizontal: sp24, vertical: sp12),
        shape: const RoundedRectangleBorder(borderRadius: borderMd),
        textStyle: subtitleStyle.copyWith(color: Colors.white),
      );

  static ButtonStyle get secondaryButtonStyle => OutlinedButton.styleFrom(
        foregroundColor: accent,
        side: const BorderSide(color: inputBorder),
        minimumSize: const Size(0, 44),
        padding: const EdgeInsets.symmetric(horizontal: sp16, vertical: sp8),
        shape: const RoundedRectangleBorder(borderRadius: borderMd),
        textStyle: bodyStyle.copyWith(fontWeight: FontWeight.w600),
      );
}
