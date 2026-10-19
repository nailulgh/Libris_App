import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/libris_theme.dart';

/// Halaman Story Onboarding Interaktif 3 Slide — Warm Editorial Print Edition
/// Direfaktor mengikuti prinsip Anti-AI-Slop (design-taste-frontend & ui-ux-pro-max):
/// - Mengganti gelombang biru muda pastel dan merah muda neon dengan palet kertas arsip hangat
///   (Warm Vellum #EDE8DF, Library Olive #3D4F42, Terracotta #A64B2A, dan Antique Brass #C68B2C).
class OnboardingStoryPage extends StatefulWidget {
  const OnboardingStoryPage({super.key});

  @override
  State<OnboardingStoryPage> createState() => _OnboardingStoryPageState();
}

class _OnboardingStoryPageState extends State<OnboardingStoryPage>
    with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController();
  late final AnimationController _motionController;
  int _currentSlide = 0;

  static const List<_StorySlideData> _slides = [
    _StorySlideData(
      title: 'Immersion reading',
      subtitle: 'EDISI I • PILIH MONOGRAF',
      description:
          'Ruang baca tenang tanpa gangguan visual, dirancang untuk merawat konsentrasi dan apresiasi terhadap karya tulis.',
    ),
    _StorySlideData(
      title: 'Curated index',
      subtitle: 'EDISI II • EKSPLORASI SUBJEK',
      description:
          'Telusuri literatur ilmu komputer, psikologi kognitif, pengembangan diri, dan sastra melalui klasifikasi yang terstruktur.',
    ),
    _StorySlideData(
      title: 'Literary journal',
      subtitle: 'EDISI III • ARSIP PERSONAL',
      description:
          'Catat progres halaman, tandai buku pilihan, dan bangun perpustakaan intelektual pribadi Anda.',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _motionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3400),
    )..repeat();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _motionController.dispose();
    super.dispose();
  }

  void _nextOrFinish() {
    if (_currentSlide < _slides.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 360),
        curve: Curves.easeOutCubic,
      );
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LibrisTheme.backgroundPaper,
      appBar: AppBar(
        backgroundColor: LibrisTheme.backgroundPaper,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(
            height: 1.0,
            color: LibrisTheme.borderCrisp,
          ),
        ),
        title: const Text(
          'Libris Editorial',
          style: TextStyle(
            fontFamily: 'Georgia',
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _slides.length,
                onPageChanged: (idx) => setState(() => _currentSlide = idx),
                itemBuilder: (context, index) {
                  final slide = _slides[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Container(
                            width: double.infinity,
                            margin: const EdgeInsets.symmetric(vertical: 16),
                            decoration: BoxDecoration(
                              color: LibrisTheme.surfaceCard,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: LibrisTheme.borderCrisp,
                                width: 1.0,
                              ),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Positioned.fill(
                                  child: AnimatedBuilder(
                                    animation: _motionController,
                                    builder: (context, _) {
                                      return CustomPaint(
                                        painter: _OnboardingCharacterSlidePainter(
                                          slideIndex: index,
                                          phase: _motionController.value * 2 * math.pi,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(22),
                                  child: AnimatedBuilder(
                                    animation: _motionController,
                                    builder: (context, _) {
                                      final floatY = math.sin(_motionController.value * 2 * math.pi) * 3.5;
                                      final pngAsset = index == 0
                                          ? 'lib/assets/story_immersion.png'
                                          : (index == 1
                                              ? 'lib/assets/story_curated_index.png'
                                              : 'lib/assets/story_literary_journal.png');
                                      return Transform.translate(
                                        offset: Offset(0, floatY),
                                        child: Image.asset(
                                          pngAsset,
                                          fit: BoxFit.contain,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Garis Indikator Tipis Editorial
                        Row(
                          children: List.generate(_slides.length, (i) {
                            final active = i == _currentSlide;
                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 240),
                              margin: const EdgeInsets.only(right: 8),
                              width: active ? 36 : 12,
                              height: 3,
                              decoration: BoxDecoration(
                                color: active
                                    ? LibrisTheme.primaryInk
                                    : LibrisTheme.borderCrisp,
                                borderRadius: BorderRadius.circular(1),
                              ),
                            );
                          }),
                        ),
                        const SizedBox(height: 16),

                        Text(
                          slide.subtitle,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: LibrisTheme.accentTerracotta,
                            letterSpacing: 1.1,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          slide.title,
                          style: const TextStyle(
                            fontFamily: 'Georgia',
                            fontSize: 27,
                            fontWeight: FontWeight.w700,
                            color: LibrisTheme.primaryInk,
                            letterSpacing: -0.4,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          slide.description,
                          style: const TextStyle(
                            fontSize: 14,
                            color: LibrisTheme.textSecondary,
                            height: 1.6,
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Bilah Tombol Bawah
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'Lewati',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: LibrisTheme.textSecondary,
                      ),
                    ),
                  ),
                  FilledButton(
                    onPressed: _nextOrFinish,
                    style: FilledButton.styleFrom(
                      backgroundColor: LibrisTheme.primaryInk,
                      foregroundColor: LibrisTheme.surfaceCard,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 26,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    child: Text(
                      _currentSlide == _slides.length - 1
                          ? 'Mulai Membaca'
                          : 'Selanjutnya',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
                      ),
                    ),
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

class _StorySlideData {
  final String title;
  final String subtitle;
  final String description;

  const _StorySlideData({
    required this.title,
    required this.subtitle,
    required this.description,
  });
}

class _OnboardingCharacterSlidePainter extends CustomPainter {
  final int slideIndex;
  final double phase;

  const _OnboardingCharacterSlidePainter({
    required this.slideIndex,
    required this.phase,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final floatY = math.sin(phase) * 3.5;
    final cx = size.width / 2;
    final cy = size.height / 2;

    // 1. Halo Latar Belakang Hangat (Warm Archival Halo)
    final haloPaint = Paint()
      ..color = const Color(0xFFF7F3EB).withValues(alpha: 0.95);
    canvas.drawCircle(Offset(cx, cy + 12), size.width * 0.36, haloPaint);

    // 2. Latar Bidang Kertas Vellum Berlapis (Warm Vellum Rolling Waves)
    final wave1 = Path()
      ..moveTo(0, size.height * 0.68)
      ..quadraticBezierTo(
        size.width * 0.28,
        size.height * 0.58 + floatY * 0.6,
        size.width * 0.62,
        size.height * 0.68,
      )
      ..quadraticBezierTo(
        size.width * 0.85,
        size.height * 0.74 - floatY * 0.6,
        size.width,
        size.height * 0.62,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(
      wave1,
      Paint()..color = const Color(0xFFEDE8DF),
    );

    final wave2 = Path()
      ..moveTo(0, size.height * 0.80)
      ..quadraticBezierTo(
        size.width * 0.42,
        size.height * 0.72 - floatY * 0.4,
        size.width,
        size.height * 0.78,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(
      wave2,
      Paint()..color = const Color(0xFFE2DBD0),
    );
  }

  @override
  bool shouldRepaint(covariant _OnboardingCharacterSlidePainter oldDelegate) {
    return oldDelegate.slideIndex != slideIndex || oldDelegate.phase != phase;
  }
}
