import 'package:flutter/material.dart';

/// Sistem Desain Libris v4.0 — Warm Editorial & Literary Print UI
/// Dirancang dengan prinsip Anti-AI-Slop (design-taste-frontend & ui-ux-pro-max):
/// - Palet warna buku cetak & arsip literasi (Warm Book Paper, Deep Charcoal Ink,
///   Bookbinding Terracotta, Library Olive, dan Antique Brass).
/// - Permukaan datar (flat tonal surfaces) dengan garis pemisah tipis (1px hairline rules)
///   menggantikan kotak berbingkai tebal yang repetitif.
/// - Kontras tipografi tegas antara Display Serif (Georgia), teks tubuh humanis,
///   dan metadata katalog bergaya indeks cetak.
class LibrisTheme {
  LibrisTheme._();

  // ==================== PALET WARNA WARM EDITORIAL & PRINT ====================
  /// Warm Unbleached Book Paper (#F6F3EC — latar kertas utama)
  static const Color backgroundPaper = Color(0xFFF6F3EC);

  /// Warm Vellum / Tonal Linen (#EDE8DF — satu tingkat lebih gelap dari kertas utama)
  static const Color skyCanvas = Color(0xFFEDE8DF);

  /// Crisp Archival Page (#FCFBF8 — permukaan kartu / halaman baca)
  static const Color surfaceCard = Color(0xFFFCFBF8);

  /// Tonal Sand / Muted Stone (#EAE3D5 — latar chip pasif & blok kutipan)
  static const Color primarySkyLight = Color(0xFFEAE3D5);
  static const Color surfaceSand = Color(0xFFEAE3D5);

  /// Bookbinding Terracotta / Burnt Sienna (#A64B2A — aksen utama < 5% piksel layar)
  static const Color primarySky = Color(0xFFA64B2A);
  static const Color accentTerracotta = Color(0xFFA64B2A);

  /// Deep Library Olive / Cloth Spine (#3D4F42 — aksen sekunder & klasifikasi subjek)
  static const Color primarySkyDark = Color(0xFF3D4F42);
  static const Color secondarySage = Color(0xFF3D4F42);

  /// Warm Ochre / Raw Umber Tint (#C89D54 — sorotan sekunder)
  static const Color accentCyan = Color(0xFFC89D54);

  /// Deep Espresso Ink / Monograph Cover (#1C1917 — latar malam/monograf & header gelap)
  static const Color deepStoryNight = Color(0xFF1C1917);

  /// Primary Editorial Charcoal Ink (#161514 — teks utama kontras tinggi)
  static const Color primaryInk = Color(0xFF161514);

  /// Warm Terracotta / RustBookmark (#B8502B — penanda bacaan & aksi utama)
  static const Color sunsetOrange = Color(0xFFB8502B);
  static const Color sunsetOrangeSoft = Color(0xFFF3E5DC);

  /// Antique Brass / Reading Lamp Glow (#C68B2C — bintang rating & lampu baca hangat)
  static const Color accentGold = Color(0xFFC68B2C);
  static const Color warmAmberLamp = Color(0xFFE5A93C);

  /// Botanical Library Sage (#4A6B53 — aksen organik & subjek sains/psikologi)
  static const Color botanicalSage = Color(0xFF4A6B53);
  static const Color botanicalSageSoft = Color(0xFFE3ECE5);

  /// Soft Parchment & Muted Burgundy (#EFECE6 & #8C3B32)
  static const Color softLavender = Color(0xFFEFECE6);
  static const Color storyBerry = Color(0xFF8C3B32);

  /// Secondary & Muted Editorial Text (#57534E & #78716C — Warm Stone Grey)
  static const Color textSecondary = Color(0xFF57534E);
  static const Color textMuted = Color(0xFF78716C);

  /// Archival Hairline Rule (#DDD6C7 — garis pembatas tipis 1px ala buku cetak)
  static const Color borderCrisp = Color(0xFFDDD6C7);

  // ==================== DEKORASI PERMUKAAN EDITORIAL (ANTI-SLOP) ====================
  /// Kartu permukaan tenang dengan radius moderat (8-12px) dan garis 1px halus
  static BoxDecoration flatCardDecoration({
    Color color = surfaceCard,
    Color borderColor = borderCrisp,
    double borderRadius = 10.0,
    double borderWidth = 1.0,
  }) {
    return BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: borderColor,
        width: borderWidth,
      ),
    );
  }

  /// Panel tonal tanpa garis tepi (1 tone step off paper)
  static BoxDecoration tonalPanelDecoration({
    Color color = skyCanvas,
    double borderRadius = 10.0,
  }) {
    return BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(borderRadius),
    );
  }

  /// Label indeks / tag editorial dengan sudut tegas (4px) ala katalog perpustakaan
  static BoxDecoration flatBadgeDecoration({
    Color backgroundColor = primarySkyLight,
    Color borderColor = borderCrisp,
    double borderRadius = 4.0,
  }) {
    return BoxDecoration(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: borderColor,
        width: 0.8,
      ),
    );
  }

  // ==================== KONFIGURASI TEMA FLUTTER ====================
  static ThemeData get lightEditorialTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: backgroundPaper,
      colorScheme: const ColorScheme.light(
        primary: primaryInk,
        onPrimary: surfaceCard,
        secondary: accentTerracotta,
        onSecondary: Colors.white,
        surface: surfaceCard,
        onSurface: primaryInk,
        outline: borderCrisp,
      ),
      splashFactory: InkSparkle.splashFactory,
      dividerTheme: const DividerThemeData(
        color: borderCrisp,
        thickness: 1,
        space: 1,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: backgroundPaper,
        foregroundColor: primaryInk,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: 'Georgia',
          fontSize: 21,
          fontWeight: FontWeight.w700,
          color: primaryInk,
          letterSpacing: -0.4,
        ),
      ),
      cardTheme: CardThemeData(
        color: surfaceCard,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: borderCrisp, width: 1.0),
        ),
      ),
      // Navigasi bawah tenang (Navigation recedes — active item in near-black ink)
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: backgroundPaper,
        elevation: 0,
        indicatorColor: primarySkyLight,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
              color: primaryInk,
              letterSpacing: 0.1,
            );
          }
          return const TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w500,
            color: textMuted,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(
              color: primaryInk,
              size: 21,
            );
          }
          return const IconThemeData(
            color: textMuted,
            size: 21,
          );
        }),
      ),
      textTheme: const TextTheme(
        displaySmall: TextStyle(
          fontFamily: 'Georgia',
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: primaryInk,
          height: 1.15,
          letterSpacing: -0.5,
        ),
        headlineMedium: TextStyle(
          fontFamily: 'Georgia',
          fontSize: 21,
          fontWeight: FontWeight.w700,
          color: primaryInk,
          height: 1.2,
          letterSpacing: -0.3,
        ),
        titleLarge: TextStyle(
          fontFamily: 'Georgia',
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: primaryInk,
          height: 1.28,
        ),
        titleMedium: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: primaryInk,
          height: 1.35,
        ),
        bodyLarge: TextStyle(
          fontSize: 14.5,
          fontWeight: FontWeight.w400,
          color: primaryInk,
          height: 1.65,
        ),
        bodyMedium: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w400,
          color: textSecondary,
          height: 1.5,
        ),
        labelLarge: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          color: primaryInk,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}
