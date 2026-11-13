// ignore_for_file: constant_identifier_names
import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';

/// Palet & gaya khusus modul Adopsi Kucing (Tiket EN-8, Tim E-Nigma).
///
/// TIDAK mendefinisikan palet baru yang bertentangan dengan [AppConstants]
/// dan [AppTheme]. Semua warna dasar dirujuk dari [AppConstants]; kelas ini
/// menambahkan warna aksen hangat (terakota/oranye tua) dan token-token
/// layout (radius, jarak, gaya teks, style kartu) yang dipakai konsisten
/// di seluruh layar adopsi.
abstract final class AdoptionTheme {
  // ─────────────────────────────────────────────────────────────────────────
  // WARNA AKSEN — Terakota/Oranye Tua (tidak bertabrakan dengan oranye cerah
  // AppConstants.primaryColor yang dipakai fitur lain)
  // ─────────────────────────────────────────────────────────────────────────

  /// Aksen utama: oranye tua / terakota — lebih hangat dan tenang dari
  /// AppConstants.primaryColor (#F97316). Dipakai pada tombol utama,
  /// highlight, border aktif.
  static const Color accent = Color(0xFFB85C38);

  /// Versi terang aksen, dipakai sebagai latar chip, latar avatar, dsb.
  static const Color accentLight = Color(0xFFF5E6DF);

  /// Versi sangat terang untuk latar bagian hero atau banner tipis.
  static const Color accentSurface = Color(0xFFFDF3EE);

  // ─────────────────────────────────────────────────────────────────────────
  // LATAR & PERMUKAAN
  // ─────────────────────────────────────────────────────────────────────────

  /// Latar halaman adopsi — krem hangat, harmonis dengan AppConstants.backgroundColor.
  static const Color pageBg = Color(0xFFFBF7F4);

  /// Latar kartu — putih bersih dengan bayangan sangat tipis.
  static const Color cardBg = Colors.white;

  /// Latar chip netral / tag info.
  static const Color chipBg = Color(0xFFF0EBE7);

  // ─────────────────────────────────────────────────────────────────────────
  // TEKS (memakai warna AppConstants sebagai dasar)
  // ─────────────────────────────────────────────────────────────────────────

  /// Teks utama — abu sangat gelap, identik dengan AppConstants.textPrimary.
  static const Color textMain = AppConstants.textPrimary;

  /// Teks sekunder — cokelat hangat, identik dengan AppConstants.textSecondary.
  static const Color textSub = AppConstants.textSecondary;

  /// Teks keterangan / caption — lebih muda, untuk info minor.
  static const Color textHint = Color(0xFF9C8B7E);

  // ─────────────────────────────────────────────────────────────────────────
  // GARIS & BATAS
  // ─────────────────────────────────────────────────────────────────────────

  /// Garis pembatas halus antara section.
  static const Color divider = Color(0xFFEDE7E1);

  /// Border kartu: garis 1px abu muda.
  static const Color cardBorder = Color(0xFFEBE5DF);

  /// Border input aktif: gunakan [accent].
  static const Color inputBorder = Color(0xFFD4C4BB);

  // ─────────────────────────────────────────────────────────────────────────
  // STATUS SEMANTIK (lokal modul — merujuk AppConstants bila tersedia)
  // ─────────────────────────────────────────────────────────────────────────

  static const Color success = AppConstants.successColor;
  static const Color successLight = Color(0xFFD1FAE5);
  static const Color danger = AppConstants.dangerColor;
  static const Color dangerLight = Color(0xFFFEE2E2);
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningLight = Color(0xFFFEF3C7);
  static const Color info = Color(0xFF4388E8);
  static const Color infoLight = Color(0xFFDBEAFE);

  // ─────────────────────────────────────────────────────────────────────────
  // RADIUS
  // ─────────────────────────────────────────────────────────────────────────

  static const double radiusSm = 8.0;
  static const double radiusMd = 12.0; // radius utama kartu & tombol
  static const double radiusLg = 16.0;
  static const double radiusXl = 20.0;
  static const double radiusPhoto = 12.0; // sudut foto kucing (4:3 rasio)

  static const BorderRadius borderSm = BorderRadius.all(Radius.circular(radiusSm));
  static const BorderRadius borderMd = BorderRadius.all(Radius.circular(radiusMd));
  static const BorderRadius borderLg = BorderRadius.all(Radius.circular(radiusLg));
  static const BorderRadius borderXl = BorderRadius.all(Radius.circular(radiusXl));
  static const BorderRadius borderPhoto = BorderRadius.all(Radius.circular(radiusPhoto));

  // ─────────────────────────────────────────────────────────────────────────
  // JARAK (spacing tokens)
  // ─────────────────────────────────────────────────────────────────────────

  static const double sp4 = 4.0;
  static const double sp8 = 8.0;
  static const double sp12 = 12.0;
  static const double sp16 = 16.0;
  static const double sp24 = 24.0;
  static const double sp32 = 32.0;

  static const EdgeInsets padCard = EdgeInsets.all(sp16);
  static const EdgeInsets padSection = EdgeInsets.symmetric(horizontal: sp16, vertical: sp12);
  static const EdgeInsets padPage = EdgeInsets.fromLTRB(sp16, sp16, sp16, sp32);

  // ─────────────────────────────────────────────────────────────────────────
  // TIPOGRAFI — Maksimal 3 ukuran + weight
  // ─────────────────────────────────────────────────────────────────────────

  /// Judul kartu / section heading  (16 / bold)
  static const TextStyle titleStyle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: textMain,
    fontFamily: 'Inter',
    height: 1.3,
  );

  /// Sub-judul / nama kucing  (14 / semibold)
  static const TextStyle subtitleStyle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: textMain,
    fontFamily: 'Inter',
    height: 1.35,
  );

  /// Teks isi / deskripsi  (12 / regular)
  static const TextStyle bodyStyle = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: textSub,
    fontFamily: 'Inter',
    height: 1.4,
  );

  /// Keterangan / caption / chip label  (11 / medium)
  static const TextStyle captionStyle = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: textHint,
    fontFamily: 'Inter',
    height: 1.3,
  );

  // ─────────────────────────────────────────────────────────────────────────
  // STYLE KARTU — border 1px + bayangan sangat tipis
  // ─────────────────────────────────────────────────────────────────────────

  /// Dekorasi kartu standar modul adopsi.
  static BoxDecoration get cardDecoration => BoxDecoration(
        color: cardBg,
        borderRadius: borderLg,
        border: Border.all(color: cardBorder, width: 1),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0C000000), // ~5% opacity — sangat tipis
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      );

  /// Dekorasi kartu hero (kartu pertama / featured — sedikit lebih menonjol).
  static BoxDecoration get heroCardDecoration => BoxDecoration(
        color: cardBg,
        borderRadius: borderXl,
        border: Border.all(color: accentLight, width: 1),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000), // ~8% opacity
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      );

  /// Dekorasi latar foto kucing (rasio 4:3, sudut membulat 12).
  static BoxDecoration get photoDecoration => BoxDecoration(
        color: accentSurface,
        borderRadius: borderPhoto,
        border: Border.all(color: cardBorder, width: 1),
      );

  // ─────────────────────────────────────────────────────────────────────────
  // STYLE TOMBOL
  // ─────────────────────────────────────────────────────────────────────────

  /// Style tombol utama (terakota/aksen, teks putih).
  static ButtonStyle get primaryButtonStyle => ElevatedButton.styleFrom(
        backgroundColor: accent,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: sp24, vertical: sp12),
        shape: const RoundedRectangleBorder(borderRadius: borderMd),
        textStyle: subtitleStyle.copyWith(color: Colors.white),
      );

  /// Style tombol sekunder (outline terakota, teks aksen).
  static ButtonStyle get secondaryButtonStyle => OutlinedButton.styleFrom(
        foregroundColor: accent,
        side: const BorderSide(color: accent, width: 1.5),
        padding: const EdgeInsets.symmetric(horizontal: sp16, vertical: sp8),
        shape: const RoundedRectangleBorder(borderRadius: borderMd),
        textStyle: captionStyle.copyWith(color: accent, fontWeight: FontWeight.w600),
      );
}

