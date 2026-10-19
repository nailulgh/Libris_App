import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/book_volume.dart';
import '../theme/libris_theme.dart';
import 'flat_book_cover.dart';

/// Kumpulan Ilustrasi Editorial & Karakter Literasi Interaktif (Warm Print Edition)
/// Direfaktor mengikuti prinsip Anti-AI-Slop (design-taste-frontend & ui-ux-pro-max):
/// - Mengganti gradasi biru langit & merah muda pastel dengan palet buku cetak hangat
///   (Deep Espresso #1C1917, Warm Vellum #EDE8DF, Bookbinding Terracotta #A64B2A,
///   Library Olive #4A6B53, dan Antique Brass #C68B2C).
/// - Menggunakan sampul buku asli pada bilah bacaan aktif (bukan ikon di dalam kotak biru).

// ============================================================================
// 1. HERO BERANDA: ARCHIVAL READING DESK & INTERACTIVE BRASS LAMP
// ============================================================================
class AnimatedCozyReaderHero extends StatefulWidget {
  final BookVolume activeBook;
  final VoidCallback onReadTap;
  final VoidCallback onStoryTourTap;
  final VoidCallback? onCycleActiveBook;
  final VoidCallback? onQuickAdvancePage;

  const AnimatedCozyReaderHero({
    super.key,
    required this.activeBook,
    required this.onReadTap,
    required this.onStoryTourTap,
    this.onCycleActiveBook,
    this.onQuickAdvancePage,
  });

  @override
  State<AnimatedCozyReaderHero> createState() => _AnimatedCozyReaderHeroState();
}

class _AnimatedCozyReaderHeroState extends State<AnimatedCozyReaderHero>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _lampGlowing = true;
  int _quoteIndex = 0;

  static const List<String> _quotes = [
    '“A room without books is like a body without a soul.” — Cicero',
    '“Satu bab setiap hari membangun ketajaman berpikir yang bertahan lama.”',
    '“Ketuk lampu meja kuningan untuk meredupkan atau menyalakan ruang baca.”',
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3600),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleLampAndQuote() {
    setState(() {
      _lampGlowing = !_lampGlowing;
      _quoteIndex = (_quoteIndex + 1) % _quotes.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    final progress = widget.activeBook.progressRatio;
    final currentPage = widget.activeBook.readingState.currentPage;
    final totalPages = widget.activeBook.volumeInfo.pageCount;

    return Container(
      decoration: BoxDecoration(
        color: LibrisTheme.deepStoryNight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF38322C),
          width: 1.0,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Lukisan Ilustrasi Meja Baca Editorial + Lampu Kuningan Interaktif
          Positioned.fill(
            child: GestureDetector(
              onTap: _toggleLampAndQuote,
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, _) {
                  return CustomPaint(
                    painter: _CozyStackedBooksCharacterPainter(
                      phase: _controller.value * 2 * math.pi,
                      lampOn: _lampGlowing,
                    ),
                  );
                },
              ),
            ),
          ),

          // Karakter Ilustrasi Flat PNG
          Positioned(
            right: 0,
            top: 14,
            bottom: 74,
            width: 175,
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, _) {
                  final floatY = math.sin(_controller.value * 2 * math.pi) * 3.0;
                  return Transform.translate(
                    offset: Offset(0, floatY),
                    child: Image.asset(
                      'lib/assets/hero_cozy_reader.png',
                      fit: BoxFit.contain,
                      alignment: Alignment.bottomRight,
                      errorBuilder: (context, error, stackTrace) =>
                          const SizedBox.shrink(),
                    ),
                  );
                },
              ),
            ),
          ),

          // Konten Editorial di Atas Hero
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Baris Atas: Indeks Edisi / Story Tour & Sakelar Lampu Kuningan
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: widget.onStoryTourTap,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2C2622),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: const Color(0xFF4A423B),
                            width: 0.8,
                          ),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.menu_book_outlined,
                              size: 12,
                              color: Color(0xFFE5A93C),
                            ),
                            SizedBox(width: 5),
                            Text(
                              'STORY TOUR',
                              style: TextStyle(
                                fontSize: 9.0,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFFF6F3EC),
                                letterSpacing: 0.9,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: _toggleLampAndQuote,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _lampGlowing
                              ? const Color(0xFF3A2E1E)
                              : const Color(0xFF292420),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: _lampGlowing
                                ? LibrisTheme.warmAmberLamp.withValues(alpha: 0.65)
                                : const Color(0xFF4A423B),
                            width: 0.8,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _lampGlowing
                                  ? Icons.light_mode_rounded
                                  : Icons.lightbulb_outline_rounded,
                              size: 12,
                              color: _lampGlowing
                                  ? LibrisTheme.warmAmberLamp
                                  : const Color(0xFFA8A29E),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              _lampGlowing ? 'Lamp: ON' : 'Lamp: OFF',
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.4,
                                color: _lampGlowing
                                    ? const Color(0xFFFDE68A)
                                    : const Color(0xFFA8A29E),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Tajuk Utama Editorial
                SizedBox(
                  width: 220,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'JURNAL LITERASI • EDISI IV',
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFD6A85A),
                          letterSpacing: 1.4,
                        ),
                      ),
                      const SizedBox(height: 5),
                      const Text(
                        'Magic of Reading',
                        style: TextStyle(
                          fontFamily: 'Georgia',
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFFCFBF8),
                          height: 1.12,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 8),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: Text(
                          _quotes[_quoteIndex],
                          key: ValueKey(_quoteIndex),
                          style: const TextStyle(
                            fontFamily: 'Georgia',
                            fontSize: 11.5,
                            fontStyle: FontStyle.italic,
                            color: Color(0xFFD6D0C4),
                            height: 1.45,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 78),

                // Lembar Bacaan Aktif (Menggunakan Sampul Buku Fisik Asli, Bukan Kotak Ikon Biru)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: LibrisTheme.surfaceCard,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: LibrisTheme.borderCrisp,
                      width: 1.0,
                    ),
                  ),
                  child: Row(
                    children: [
                      FlatBookCover(
                        book: widget.activeBook,
                        width: 40,
                        height: 56,
                        borderRadius: 4,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    'SEDANG DIBACA',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 9.0,
                                      fontWeight: FontWeight.w800,
                                      color: LibrisTheme.accentTerracotta,
                                      letterSpacing: 0.6,
                                    ),
                                  ),
                                ),
                                if (widget.onCycleActiveBook != null) ...[
                                  const SizedBox(width: 3),
                                  GestureDetector(
                                    onTap: widget.onCycleActiveBook,
                                    child: const Icon(
                                      Icons.swap_horiz_rounded,
                                      size: 14,
                                      color: LibrisTheme.accentTerracotta,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 3),
                            Text(
                              widget.activeBook.volumeInfo.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontFamily: 'Georgia',
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: LibrisTheme.primaryInk,
                              ),
                            ),
                            const SizedBox(height: 5),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(2),
                              child: LinearProgressIndicator(
                                value: progress.clamp(0.0, 1.0),
                                minHeight: 3.5,
                                backgroundColor: LibrisTheme.primarySkyLight,
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                  LibrisTheme.accentTerracotta,
                                ),
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'Hal. $currentPage/$totalPages • ${(progress * 100).round()}%',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w600,
                                color: LibrisTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          FilledButton(
                            onPressed: widget.onReadTap,
                            style: FilledButton.styleFrom(
                              backgroundColor: LibrisTheme.primaryInk,
                              foregroundColor: LibrisTheme.surfaceCard,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              minimumSize: const Size(0, 28),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(5),
                              ),
                            ),
                            child: const Text(
                              'Baca',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ),
                          if (widget.onQuickAdvancePage != null && currentPage < totalPages) ...[
                            const SizedBox(height: 4),
                            GestureDetector(
                              onTap: widget.onQuickAdvancePage,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2.5,
                                ),
                                decoration: BoxDecoration(
                                  color: LibrisTheme.skyCanvas,
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: LibrisTheme.borderCrisp,
                                    width: 0.8,
                                  ),
                                ),
                                child: const Text(
                                  '+10 Hlm',
                                  style: TextStyle(
                                    fontSize: 9.0,
                                    fontWeight: FontWeight.w700,
                                    color: LibrisTheme.primaryInk,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CozyStackedBooksCharacterPainter extends CustomPainter {
  final double phase;
  final bool lampOn;

  const _CozyStackedBooksCharacterPainter({
    required this.phase,
    required this.lampOn,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final floatY = math.sin(phase) * 3.0;
    final swayX = math.cos(phase) * 2.5;

    // 1. Bidang Lengkung Kertas Arsip Gelap di Latar Bawah
    final wavePaint1 = Paint()
      ..color = const Color(0xFF28231E)
      ..style = PaintingStyle.fill;
    final wavePath1 = Path()
      ..moveTo(0, size.height * 0.58)
      ..quadraticBezierTo(
        size.width * 0.35,
        size.height * 0.46 + floatY,
        size.width * 0.68,
        size.height * 0.56,
      )
      ..quadraticBezierTo(
        size.width * 0.88,
        size.height * 0.62 - floatY,
        size.width,
        size.height * 0.50,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(wavePath1, wavePaint1);

    // 2. Titik Debu Cahaya / Bintang Halus Hangat
    final starPaint = Paint()
      ..color = const Color(0xFFD6A85A).withValues(alpha: 0.35 + 0.25 * math.sin(phase))
      ..style = PaintingStyle.fill;
    final starPositions = [
      Offset(size.width * 0.56, size.height * 0.14),
      Offset(size.width * 0.68, size.height * 0.10),
      Offset(size.width * 0.88, size.height * 0.18),
      Offset(size.width * 0.50, size.height * 0.28),
    ];
    for (final pos in starPositions) {
      canvas.drawCircle(pos, 1.8, starPaint);
    }

    // 3. Dedaunan Botani Olive Redup di Belakang Karakter
    final leafPaintDark = Paint()
      ..color = const Color(0xFF33473B).withValues(alpha: 0.65)
      ..style = PaintingStyle.fill;
    final leafPaintBright = Paint()
      ..color = const Color(0xFF4A6B53).withValues(alpha: 0.65)
      ..style = PaintingStyle.fill;

    final cx = size.width * 0.77;
    final baseBooksY = size.height * 0.64;

    _drawOrganicLeaf(
      canvas,
      Offset(cx - 48 + swayX, baseBooksY - 46),
      Offset(cx - 80 + swayX, baseBooksY - 94),
      16,
      leafPaintDark,
    );
    _drawOrganicLeaf(
      canvas,
      Offset(cx + 42 - swayX, baseBooksY - 48),
      Offset(cx + 76 - swayX, baseBooksY - 96),
      16,
      leafPaintBright,
    );

    // 4. Aura & Berkas Cahaya Hangat Lampu Baca Interaktif
    if (lampOn) {
      final glowPaint = Paint()
        ..color = const Color(0xFFFDE68A).withValues(alpha: 0.22 + 0.08 * math.sin(phase))
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 24);
      canvas.drawCircle(Offset(cx - 52, baseBooksY - 96), 46, glowPaint);

      final conePaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFFF5D08A).withValues(alpha: 0.25 + 0.06 * math.sin(phase)),
            const Color(0xFFF5D08A).withValues(alpha: 0.01),
          ],
        ).createShader(
          Rect.fromLTWH(cx - 56, baseBooksY - 92, 120, 105),
        );
      final conePath = Path()
        ..moveTo(cx - 50, baseBooksY - 90)
        ..lineTo(cx + 62, baseBooksY - 32)
        ..lineTo(cx - 30, baseBooksY + 8)
        ..close();
      canvas.drawPath(conePath, conePaint);
    }

    // 5. Bayangan Lembut Latar Belakang Buku
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.35)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx + 8, baseBooksY + 14),
        width: 130,
        height: 14,
      ),
      shadowPaint,
    );
  }

  void _drawOrganicLeaf(
    Canvas canvas,
    Offset start,
    Offset tip,
    double bulge,
    Paint paint,
  ) {
    final mid = Offset((start.dx + tip.dx) / 2, (start.dy + tip.dy) / 2);
    final path = Path()
      ..moveTo(start.dx, start.dy)
      ..quadraticBezierTo(mid.dx - bulge, mid.dy - bulge, tip.dx, tip.dy)
      ..quadraticBezierTo(mid.dx + bulge, mid.dy + bulge, start.dx, start.dy)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _CozyStackedBooksCharacterPainter oldDelegate) {
    return oldDelegate.phase != phase || oldDelegate.lampOn != lampOn;
  }
}

// ============================================================================
// 2. HEADER KATEGORI SUBJEK: ARCHIVAL CLASSIFICATION HEADER
// ============================================================================
class AnimatedCategoryWaveCharacterHeader extends StatefulWidget {
  final String selectedCategory;
  final int volumeCount;

  const AnimatedCategoryWaveCharacterHeader({
    super.key,
    required this.selectedCategory,
    required this.volumeCount,
  });

  @override
  State<AnimatedCategoryWaveCharacterHeader> createState() =>
      _AnimatedCategoryWaveCharacterHeaderState();
}

class _AnimatedCategoryWaveCharacterHeaderState
    extends State<AnimatedCategoryWaveCharacterHeader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color _accentForCategory(String cat) {
    switch (cat) {
      case 'Computer Science':
        return const Color(0xFF28463B); // Deep Forest Cloth
      case 'Psychology':
        return const Color(0xFF8C3B32); // Muted Burgundy
      case 'Self-Growth':
        return LibrisTheme.botanicalSage;
      case 'Fiction':
        return LibrisTheme.accentTerracotta;
      default:
        return LibrisTheme.primaryInk;
    }
  }

  String _deweyCodeForCategory(String cat) {
    switch (cat) {
      case 'Computer Science':
        return 'INDEKS 004 • ILMU KOMPUTER';
      case 'Psychology':
        return 'INDEKS 150 • PSIKOLOGI KOGNITIF';
      case 'Self-Growth':
        return 'INDEKS 158 • PENGEMBANGAN DIRI';
      case 'Fiction':
        return 'INDEKS 800 • SASTRA & FIKSI';
      default:
        return 'INDEKS 000–899 • SEMUA DISIPLIN';
    }
  }

  String _subtitleForCategory(String cat) {
    switch (cat) {
      case 'Computer Science':
        return 'Arsitektur perangkat lunak, sistem terdistribusi & rekayasa kode.';
      case 'Psychology':
        return 'Eksplorasi kognisi manusia, perilaku, dan pengambilan keputusan.';
      case 'Self-Growth':
        return 'Kebiasaan atomik, fokus mendalam, dan produktivitas bermakna.';
      case 'Fiction':
        return 'Imajinasi dunia paralel, perjalanan waktu, dan narasi sastra.';
      default:
        return 'Jelajahi seluruh koleksi monograf dan literatur lintas disiplin ilmu.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = _accentForCategory(widget.selectedCategory);

    return Container(
      height: 148,
      margin: const EdgeInsets.fromLTRB(18, 8, 18, 8),
      decoration: BoxDecoration(
        color: LibrisTheme.skyCanvas,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: LibrisTheme.borderCrisp, width: 1.0),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                return CustomPaint(
                  painter: _WaveExplorerCharacterPainter(
                    phase: _controller.value * 2 * math.pi,
                    accentColor: accent,
                  ),
                );
              },
            ),
          ),

          // Karakter Flat Explorer PNG
          Positioned(
            right: 2,
            top: 6,
            bottom: 6,
            width: 135,
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, _) {
                  final floatY = math.sin(_controller.value * 2 * math.pi) * 2.5;
                  return Transform.translate(
                    offset: Offset(0, floatY),
                    child: Image.asset(
                      'lib/assets/hero_category_explorer.png',
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) =>
                          const SizedBox.shrink(),
                    ),
                  );
                },
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 124, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${_deweyCodeForCategory(widget.selectedCategory)} (${widget.volumeCount} VOL)',
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    color: accent,
                    letterSpacing: 0.9,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  widget.selectedCategory == 'Semua'
                      ? 'Katalog Subjek Utama'
                      : widget.selectedCategory,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Georgia',
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: LibrisTheme.primaryInk,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  _subtitleForCategory(widget.selectedCategory),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: LibrisTheme.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WaveExplorerCharacterPainter extends CustomPainter {
  final double phase;
  final Color accentColor;

  const _WaveExplorerCharacterPainter({
    required this.phase,
    required this.accentColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final floatY = math.sin(phase) * 2.5;

    // 1. Bidang Kertas Berlapis (Warm Vellum Waves)
    final waveBack = Path()
      ..moveTo(0, size.height * 0.72)
      ..quadraticBezierTo(
        size.width * 0.34,
        size.height * 0.56 + floatY,
        size.width * 0.66,
        size.height * 0.70,
      )
      ..quadraticBezierTo(
        size.width * 0.86,
        size.height * 0.78 - floatY,
        size.width,
        size.height * 0.56,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(
      waveBack,
      Paint()..color = const Color(0xFFE2DBD0),
    );

    final waveFront = Path()
      ..moveTo(0, size.height * 0.85)
      ..quadraticBezierTo(
        size.width * 0.40,
        size.height * 0.72 - floatY,
        size.width * 0.75,
        size.height * 0.82,
      )
      ..quadraticBezierTo(
        size.width * 0.90,
        size.height * 0.88,
        size.width,
        size.height * 0.72,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(
      waveFront,
      Paint()..color = accentColor.withValues(alpha: 0.14),
    );

    // 2. Diagram Astrolab / Lingkaran Katalog di Latar Kanan
    final px = size.width - 92;
    final py = size.height * 0.40 + floatY * 0.4;
    canvas.drawCircle(
      Offset(px, py),
      16,
      Paint()..color = const Color(0xFFE5DEC9),
    );
    canvas.save();
    canvas.translate(px, py);
    canvas.rotate(-0.35);
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: 50, height: 13),
      Paint()
        ..color = accentColor.withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
    canvas.restore();

    // 3. Bayangan Halus Horizon di Kaki Gelombang
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width - 50, size.height * 0.88),
        width: 100,
        height: 12,
      ),
      Paint()..color = Colors.black.withValues(alpha: 0.22),
    );
  }

  @override
  bool shouldRepaint(covariant _WaveExplorerCharacterPainter oldDelegate) {
    return oldDelegate.phase != phase ||
        oldDelegate.accentColor != accentColor;
  }
}

// ============================================================================
// 3. DETAIL BUKU: EDITORIAL 3-CARD EX-LIBRIS & FOLIO SHOWCASE
// ============================================================================
class AnimatedFannedStoryCards extends StatefulWidget {
  final BookVolume book;

  const AnimatedFannedStoryCards({
    super.key,
    required this.book,
  });

  @override
  State<AnimatedFannedStoryCards> createState() =>
      _AnimatedFannedStoryCardsState();
}

class _AnimatedFannedStoryCardsState extends State<AnimatedFannedStoryCards>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  int _selectedCard = 1;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 196,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final floatY = math.sin(_controller.value * 2 * math.pi) * 2.5;

          return Stack(
            alignment: Alignment.center,
            children: [
              // KARTU KIRI MIRING: EX-LIBRIS PLATE I
              Transform.translate(
                offset: Offset(-86, 10 - floatY * 0.5),
                child: Transform.rotate(
                  angle: -0.14,
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedCard = 0),
                    child: _buildMiniIllustratedSceneCard(
                      width: 112,
                      height: 144,
                      bgColor: const Color(0xFFEDE8DF),
                      bottomBarColor: const Color(0xFF3D4F42),
                      sceneIndex: 0,
                      isFocused: _selectedCard == 0,
                    ),
                  ),
                ),
              ),

              // KARTU KANAN MIRING: EX-LIBRIS PLATE III
              Transform.translate(
                offset: Offset(86, 10 + floatY * 0.5),
                child: Transform.rotate(
                  angle: 0.14,
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedCard = 2),
                    child: _buildMiniIllustratedSceneCard(
                      width: 112,
                      height: 144,
                      bgColor: const Color(0xFFEAE3D5),
                      bottomBarColor: const Color(0xFF57534E),
                      sceneIndex: 2,
                      isFocused: _selectedCard == 2,
                    ),
                  ),
                ),
              ),

              // KARTU TENGAH UTAMA: SAMPUL BUKU ASLI (FISIK)
              Transform.translate(
                offset: Offset(0, floatY),
                child: GestureDetector(
                  onTap: () => setState(() => _selectedCard = 1),
                  child: FlatBookCover(
                    book: widget.book,
                    width: 122,
                    height: 174,
                    borderRadius: 6,
                    showCategoryBadge: true,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMiniIllustratedSceneCard({
    required double width,
    required double height,
    required Color bgColor,
    required Color bottomBarColor,
    required int sceneIndex,
    required bool isFocused,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 240),
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isFocused
              ? const Color(0xFFD6A85A)
              : const Color(0xFFDDD6C7).withValues(alpha: 0.7),
          width: isFocused ? 1.8 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.22),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Expanded(
            child: CustomPaint(
              size: Size.infinite,
              painter: _FannedCardScenePainter(sceneIndex: sceneIndex),
            ),
          ),
          Container(
            height: 22,
            width: double.infinity,
            color: bottomBarColor,
            alignment: Alignment.center,
            child: Text(
              sceneIndex == 0 ? 'EX-LIBRIS I' : 'CATATAN INTI',
              style: const TextStyle(
                fontSize: 8.0,
                fontWeight: FontWeight.w800,
                color: Color(0xFFFCFBF8),
                letterSpacing: 0.9,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FannedCardScenePainter extends CustomPainter {
  final int sceneIndex;

  const _FannedCardScenePainter({required this.sceneIndex});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    final rulePaint = Paint()
      ..color = const Color(0xFF78716C).withValues(alpha: 0.35)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    // Bingkai tipis Ex-Libris di dalam kartu
    canvas.drawRect(
      Rect.fromLTWH(8, 8, size.width - 16, size.height - 16),
      rulePaint,
    );

    if (sceneIndex == 0) {
      // Kartu Kiri: Ilustrasi Botani & Arsitektur Klasik
      canvas.drawArc(
        Rect.fromCircle(center: Offset(cx, cy + 16), radius: 24),
        math.pi,
        math.pi,
        true,
        Paint()..color = const Color(0xFF4A6B53).withValues(alpha: 0.35),
      );
      canvas.drawCircle(
        Offset(cx, cy - 8),
        10,
        Paint()..color = const Color(0xFFC68B2C).withValues(alpha: 0.65),
      );
      for (var i = -1; i <= 1; i++) {
        canvas.drawLine(
          Offset(20, cy + 24 + i * 5.0),
          Offset(size.width - 20, cy + 24 + i * 5.0),
          rulePaint,
        );
      }
    } else {
      // Kartu Kanan: Lembar Manuskrip & Stempel Lilin Terakota
      for (var i = 0; i < 5; i++) {
        final y = 24.0 + i * 11.0;
        final w = i == 4 ? size.width * 0.45 : size.width - 32;
        canvas.drawLine(
          Offset(16, y),
          Offset(16 + w, y),
          rulePaint,
        );
      }
      canvas.drawCircle(
        Offset(size.width - 26, size.height - 26),
        9,
        Paint()..color = LibrisTheme.accentTerracotta.withValues(alpha: 0.85),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _FannedCardScenePainter oldDelegate) {
    return oldDelegate.sceneIndex != sceneIndex;
  }
}
