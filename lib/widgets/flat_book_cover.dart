import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/book_volume.dart';
import '../theme/libris_theme.dart';

/// Widget Sampul Buku Editorial Cetak (Hardbound Monograph & Penguin Classics Style)
/// Menghilangkan kesan "AI slop card" dengan proporsi buku fisik asli:
/// - Lekukan engsel jilid buku (bookbinding spine crease) di sisi kiri
/// - Bingkai tipografi serif dan nomor edisi cetak ketika luring (offline fallback)
/// - Memuat sampul asli OpenLibrary/Google Books jika perangkat daring
class FlatBookCover extends StatelessWidget {
  final BookVolume book;
  final double width;
  final double height;
  final double borderRadius;
  final bool showCategoryBadge;

  const FlatBookCover({
    super.key,
    required this.book,
    this.width = 114,
    this.height = 166,
    this.borderRadius = 6,
    this.showCategoryBadge = false,
  });

  static Color _parseEditorialCoverColor(String hex, String category) {
    final cleaned = hex.replaceAll('#', '').trim().toUpperCase();
    // Map warna sampul agar selaras dengan estetika kertas & jilid kain buku klasik
    switch (cleaned) {
      case '2A5C4D':
        return const Color(0xFF28463B); // Deep Forest Cloth
      case 'D96B43':
        return const Color(0xFF9E472A); // Terracotta Cloth
      case '1E3A5F':
        return const Color(0xFF23364C); // Prussian Ink Blue
      case '3D348B':
        return const Color(0xFF3A3248); // Aubergine Monograph
      case '1B4965':
        return const Color(0xFF25444E); // Slate Petrol
    }
    if (cleaned.length == 6) {
      final intVal = int.tryParse('FF$cleaned', radix: 16);
      if (intVal != null) {
        final raw = Color(intVal);
        // Redam saturasi berlebih dengan mencampur sedikit tinta arang hangat
        return Color.lerp(raw, const Color(0xFF1F1B18), 0.22)!;
      }
    }
    return LibrisTheme.primarySkyDark;
  }

  @override
  Widget build(BuildContext context) {
    final primaryCoverColor = _parseEditorialCoverColor(
      book.readingState.coverHex,
      book.volumeInfo.primaryCategory,
    );
    final effectiveRadius = borderRadius > 10 ? 6.0 : borderRadius;

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: primaryCoverColor,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(2),
          bottomLeft: const Radius.circular(2),
          topRight: Radius.circular(effectiveRadius),
          bottomRight: Radius.circular(effectiveRadius),
        ),
        border: Border.all(
          color: Colors.black.withValues(alpha: 0.18),
          width: 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF161514).withValues(alpha: 0.14),
            blurRadius: 8,
            offset: const Offset(3, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Sampul Monograf Cetak (Fallback & Base Layer)
          _EditorialMonographCoverArt(
            book: book,
            primaryColor: primaryCoverColor,
          ),

          // 2. Gambar Sampul Buku dari URL jika perangkat online
          if (book.volumeInfo.imageLinks.thumbnail.isNotEmpty)
            Image.network(
              book.volumeInfo.imageLinks.thumbnail,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return const SizedBox.shrink();
              },
            ),

          // 3. Efek Fisik Punggung Jilid Buku (Book Spine Hinge & Crease)
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: 10,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Colors.black.withValues(alpha: 0.32),
                    Colors.white.withValues(alpha: 0.14),
                    Colors.black.withValues(alpha: 0.22),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.35, 0.75, 1.0],
                ),
              ),
            ),
          ),

          // 4. Label Bahasa / Edisi di Pojok Kanan Atas (Bila Diaktifkan)
          if (showCategoryBadge)
            Positioned(
              top: 7,
              right: 7,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFFCFBF8).withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(2),
                  border: Border.all(
                    color: Colors.black.withValues(alpha: 0.2),
                    width: 0.6,
                  ),
                ),
                child: Text(
                  book.volumeInfo.language,
                  style: const TextStyle(
                    fontSize: 8.5,
                    fontWeight: FontWeight.w800,
                    color: LibrisTheme.primaryInk,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _EditorialMonographCoverArt extends StatelessWidget {
  final BookVolume book;
  final Color primaryColor;

  const _EditorialMonographCoverArt({
    required this.book,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    final themeVariant = book.id.hashCode.abs() % 4;

    return CustomPaint(
      painter: _EditorialCoverMotifPainter(
        variant: themeVariant,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxHeight < 82 || constraints.maxWidth < 54) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(9, 6, 5, 6),
              child: Align(
                alignment: Alignment.bottomLeft,
                child: Text(
                  book.volumeInfo.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Georgia',
                    fontSize: 8.0,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFFCFBF8),
                    height: 1.1,
                  ),
                ),
              ),
            );
          }

          return Padding(
            padding: const EdgeInsets.fromLTRB(12, 9, 8, 9),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      book.volumeInfo.primaryCategory.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 7.0,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFFF6F3EC).withValues(alpha: 0.78),
                        letterSpacing: 0.9,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Container(
                      height: 0.8,
                      width: double.infinity,
                      color: const Color(0xFFF6F3EC).withValues(alpha: 0.28),
                    ),
                  ],
                ),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        book.volumeInfo.title,
                        maxLines: constraints.maxHeight < 115 ? 2 : 3,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Georgia',
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFFCFBF8),
                          height: 1.14,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        book.volumeInfo.primaryAuthor,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 8.5,
                          fontStyle: FontStyle.italic,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFFF6F3EC).withValues(alpha: 0.85),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _EditorialCoverMotifPainter extends CustomPainter {
  final int variant;

  const _EditorialCoverMotifPainter({
    required this.variant,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = const Color(0xFFF6F3EC).withValues(alpha: 0.16)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final warmGoldFill = Paint()
      ..color = const Color(0xFFD6A85A).withValues(alpha: 0.22);

    final cx = size.width * 0.56;
    final cy = size.height * 0.44;

    if (variant == 0) {
      // Motif 0: Geometri Bauhaus / Lingkaran Edisi Cetak
      canvas.drawCircle(Offset(cx, cy), size.width * 0.25, warmGoldFill);
      canvas.drawCircle(Offset(cx, cy), size.width * 0.31, linePaint);
      canvas.drawLine(
        Offset(14, cy),
        Offset(size.width - 10, cy),
        linePaint,
      );
    } else if (variant == 1) {
      // Motif 1: Lengkungan Arsitektur Klasik
      final archRect = Rect.fromCenter(
        center: Offset(cx, cy + 6),
        width: size.width * 0.46,
        height: size.height * 0.34,
      );
      canvas.drawRRect(
        RRect.fromRectAndCorners(
          archRect,
          topLeft: const Radius.circular(40),
          topRight: const Radius.circular(40),
        ),
        warmGoldFill,
      );
      canvas.drawRRect(
        RRect.fromRectAndCorners(
          archRect.inflate(4),
          topLeft: const Radius.circular(44),
          topRight: const Radius.circular(44),
        ),
        linePaint,
      );
    } else if (variant == 2) {
      // Motif 2: Orbit Kosmologi / Diagram Klasik
      canvas.drawCircle(Offset(cx, cy), size.width * 0.14, warmGoldFill);
      canvas.save();
      canvas.translate(cx, cy);
      canvas.rotate(-0.35);
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset.zero,
          width: size.width * 0.54,
          height: size.width * 0.18,
        ),
        linePaint,
      );
      canvas.restore();
    } else {
      // Motif 3: Matahari Terbit & Garis Horison
      canvas.drawArc(
        Rect.fromCircle(center: Offset(cx, cy + 10), radius: size.width * 0.23),
        math.pi,
        math.pi,
        true,
        warmGoldFill,
      );
      for (var i = 1; i <= 3; i++) {
        canvas.drawLine(
          Offset(18, cy + 10 + i * 4.0),
          Offset(size.width - 12, cy + 10 + i * 4.0),
          linePaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _EditorialCoverMotifPainter oldDelegate) {
    return oldDelegate.variant != variant;
  }
}
