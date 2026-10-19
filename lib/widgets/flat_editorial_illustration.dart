import 'package:flutter/material.dart';
import '../models/book_volume.dart';
import '../theme/libris_theme.dart';

/// Kartu Hero Ilustrasi Flat 2D & Progres Bacaan (Continue Reading Card)
/// Mengadopsi estetika 2D Biru Langit (Sky Blue Flat UI) tanpa bayangan berat,
/// dengan garis tepi tegas dan ilustrasi vektor geometris 2D.
class FlatEditorialReadingBanner extends StatelessWidget {
  final BookVolume activeBook;
  final VoidCallback onContinueReading;

  const FlatEditorialReadingBanner({
    super.key,
    required this.activeBook,
    required this.onContinueReading,
  });

  @override
  Widget build(BuildContext context) {
    final progressPct = activeBook.progressPercent;
    final progressRatio = activeBook.progressRatio;

    return Container(
      decoration: LibrisTheme.flatCardDecoration(
        color: LibrisTheme.primarySkyLight,
        borderColor: LibrisTheme.primarySky,
        borderWidth: 1.5,
        borderRadius: 16,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14.5),
        child: Stack(
          children: [
            // Ilustrasi Vektor Flat 2D Biru Langit pada sisi kanan kartu
            Positioned(
              right: -6,
              bottom: -6,
              child: CustomPaint(
                size: const Size(150, 145),
                painter: _FlatReadingVectorPainter(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: LibrisTheme.primarySky,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.auto_stories_outlined,
                              size: 13,
                              color: Colors.white,
                            ),
                            SizedBox(width: 5),
                            Text(
                              'LANJUTKAN MEMBACA',
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: 0.6,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: LibrisTheme.surfaceCard,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: LibrisTheme.primarySky,
                            width: 1.2,
                          ),
                        ),
                        child: Text(
                          'Hal. ${activeBook.readingState.currentPage} / ${activeBook.volumeInfo.pageCount}',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: LibrisTheme.primarySkyDark,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 245),
                    child: Text(
                      activeBook.volumeInfo.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Georgia',
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                        color: LibrisTheme.primaryInk,
                        height: 1.2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Oleh ${activeBook.volumeInfo.primaryAuthor} • ${activeBook.volumeInfo.primaryCategory}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: LibrisTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Progres Bacaan',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: LibrisTheme.primaryInk,
                                  ),
                                ),
                                Text(
                                  '$progressPct%',
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w800,
                                    color: LibrisTheme.primarySkyDark,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Container(
                              height: 10,
                              decoration: BoxDecoration(
                                color: LibrisTheme.surfaceCard,
                                borderRadius: BorderRadius.circular(5),
                                border: Border.all(
                                  color: LibrisTheme.primarySky,
                                  width: 1.2,
                                ),
                              ),
                              child: FractionallySizedBox(
                                alignment: Alignment.centerLeft,
                                widthFactor: progressRatio,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: LibrisTheme.primarySky,
                                    borderRadius: BorderRadius.circular(3.5),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 14),
                      InkWell(
                        onTap: onContinueReading,
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: LibrisTheme.primarySky,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Lanjut Baca',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(width: 4),
                              Icon(
                                Icons.arrow_forward_rounded,
                                size: 15,
                                color: Colors.white,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FlatReadingVectorPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final strokePaint = Paint()
      ..color = LibrisTheme.primarySkyDark.withValues(alpha: 0.22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final skyFill = Paint()
      ..color = LibrisTheme.accentCyan.withValues(alpha: 0.25)
      ..style = PaintingStyle.fill;

    final primaryFill = Paint()
      ..color = LibrisTheme.primarySky.withValues(alpha: 0.18)
      ..style = PaintingStyle.fill;

    final whiteFill = Paint()
      ..color = Colors.white.withValues(alpha: 0.65)
      ..style = PaintingStyle.fill;

    // Lingkaran geometris flat 2D
    canvas.drawCircle(const Offset(108, 42), 26, whiteFill);
    canvas.drawCircle(const Offset(108, 42), 26, strokePaint);

    // Tumpukan 3 buku flat 2D di sudut kanan bawah
    final book1 = RRect.fromRectAndRadius(
      const Rect.fromLTWH(56, 78, 76, 16),
      const Radius.circular(4),
    );
    final book2 = RRect.fromRectAndRadius(
      const Rect.fromLTWH(46, 96, 86, 16),
      const Radius.circular(4),
    );
    final book3 = RRect.fromRectAndRadius(
      const Rect.fromLTWH(62, 60, 66, 16),
      const Radius.circular(4),
    );

    canvas.drawRRect(book3, skyFill);
    canvas.drawRRect(book3, strokePaint);

    canvas.drawRRect(book1, primaryFill);
    canvas.drawRRect(book1, strokePaint);

    canvas.drawRRect(book2, whiteFill);
    canvas.drawRRect(book2, strokePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
