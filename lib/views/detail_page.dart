import 'package:flutter/material.dart';
import '../models/book_volume.dart';
import '../services/libris_database_service.dart';
import '../theme/libris_theme.dart';
import '../widgets/flat_character_illustrations.dart';

/// Halaman 3: Detail Buku (DetailPage) — Literary Monograph & Colophon UI
/// Direfaktor mengikuti prinsip Anti-AI-Slop (design-taste-frontend & ui-ux-pro-max):
/// - Mengganti deretan pill warna-warni neon (#EC4899, #60A5FA) dengan Label Indeks Katalog Arsip.
/// - Mengubah 4 kotak Bento Statistik berikon menjadi Pita Spesifikasi Tipografi
///   ("KPIs are type, not tiles" — dipisahkan garis vertikal 1px tanpa ikon dekoratif).
/// - Menampilkan Kolofon Buku, Biografi Penulis, dan Intisari Pokok (Key Takeaways) bernomor indeks.
class DetailPage extends StatefulWidget {
  final BookVolume book;
  final bool isSaved;
  final VoidCallback onToggleSave;

  const DetailPage({
    super.key,
    required this.book,
    required this.isSaved,
    required this.onToggleSave,
  });

  @override
  State<DetailPage> createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {
  late bool _saved;
  late int _currentPage;
  bool _isSynopsisExpanded = false;
  bool _isActiveReadingBook = false;

  @override
  void initState() {
    super.initState();
    _saved = widget.isSaved;
    _currentPage = widget.book.readingState.currentPage;
    _checkActiveBookStatus();
  }

  Future<void> _checkActiveBookStatus() async {
    final activeId = await LibrisDatabaseService.instance.getActiveReadingBookId();
    if (mounted) {
      setState(() {
        _isActiveReadingBook = (activeId == widget.book.id);
      });
    }
  }

  Future<void> _handleSave() async {
    final nextStatus = !_saved;
    setState(() {
      _saved = nextStatus;
    });
    await LibrisDatabaseService.instance.setBookmark(widget.book.id, nextStatus);
    widget.onToggleSave();
  }

  Future<void> _updateProgress(int newPage) async {
    final total = widget.book.volumeInfo.pageCount > 0
        ? widget.book.volumeInfo.pageCount
        : 100;
    final clamped = newPage.clamp(0, total);

    setState(() {
      _currentPage = clamped;
      _isActiveReadingBook = true;
    });

    await LibrisDatabaseService.instance.updateReadingProgress(
      widget.book.id,
      clamped,
    );
  }

  Future<void> _makeActiveBook() async {
    await LibrisDatabaseService.instance.setActiveReadingBookId(widget.book.id);
    setState(() {
      _isActiveReadingBook = true;
    });
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: LibrisTheme.primaryInk,
        behavior: SnackBarBehavior.floating,
        duration: Duration(milliseconds: 1000),
        content: Text(
          'Buku ini sekarang aktif di Meja Baca.',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  void _showPreviewReaderSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: LibrisTheme.backgroundPaper,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
      ),
      builder: (context) {
        final info = widget.book.volumeInfo;
        final state = widget.book.readingState;
        final excerptText = state.sampleExcerpt.isNotEmpty
            ? state.sampleExcerpt
            : '${info.description}\n\n'
                  'Bab Pembuka — Setiap karya penting dalam disiplin ${info.primaryCategory} '
                  'berangkat dari struktur pemikiran yang jernih. Melalui "${info.title}", '
                  '${info.primaryAuthor} menguraikan fondasi konseptual dan studi kasus '
                  'yang relevan bagi mahasiswa, akademisi, serta pembaca kritis.';

        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.80,
          minChildSize: 0.5,
          maxChildSize: 0.94,
          builder: (context, scrollController) {
            return ListView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(26, 16, 26, 28),
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 3.5,
                    decoration: BoxDecoration(
                      color: LibrisTheme.borderCrisp,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'LEMBAR EKSERP • BAB PEMBUKA',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: LibrisTheme.accentTerracotta,
                        letterSpacing: 1.1,
                      ),
                    ),
                    Text(
                      'Hal. 1 dari ${info.pageCount}',
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: LibrisTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Divider(color: LibrisTheme.primaryInk, height: 1, thickness: 1.2),
                const SizedBox(height: 16),
                Text(
                  info.title,
                  style: const TextStyle(
                    fontFamily: 'Georgia',
                    fontSize: 23,
                    fontWeight: FontWeight.w700,
                    color: LibrisTheme.primaryInk,
                    height: 1.18,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Oleh ${info.authorsLine} — ${info.publisher} (${info.publishedYear})',
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontStyle: FontStyle.italic,
                    color: LibrisTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: LibrisTheme.surfaceCard,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: LibrisTheme.borderCrisp,
                      width: 1.0,
                    ),
                  ),
                  child: Text(
                    excerptText,
                    style: const TextStyle(
                      fontFamily: 'Georgia',
                      fontSize: 15.5,
                      height: 1.82,
                      color: LibrisTheme.primaryInk,
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            _updateProgress(_currentPage + 15);
                          },
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(
                              color: LibrisTheme.borderCrisp,
                              width: 1.0,
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          child: const Text(
                            'Catat Bab Selesai (+15)',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: LibrisTheme.primaryInk,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton(
                          onPressed: () => Navigator.pop(context),
                          style: FilledButton.styleFrom(
                            backgroundColor: LibrisTheme.primaryInk,
                            foregroundColor: LibrisTheme.surfaceCard,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          child: const Text(
                            'Tutup Lembar Bacaan',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final info = widget.book.volumeInfo;
    final state = widget.book.readingState;

    return Scaffold(
      backgroundColor: LibrisTheme.backgroundPaper,
      appBar: AppBar(
        backgroundColor: LibrisTheme.deepStoryNight,
        foregroundColor: const Color(0xFFFCFBF8),
        title: const Text(
          'Detail Volume Buku',
          style: TextStyle(
            fontFamily: 'Georgia',
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xFFFCFBF8),
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(
            height: 1.0,
            color: const Color(0xFF332D27),
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Simpan ke Koleksi',
            onPressed: _handleSave,
            icon: Icon(
              _saved
                  ? Icons.bookmark_rounded
                  : Icons.bookmark_border_rounded,
              size: 20,
              color: _saved
                  ? const Color(0xFFD6A85A)
                  : const Color(0xFFFCFBF8),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 36),
        children: [
          // 1. HEADER MONOGRAF DARK ESPRESSO + EX-LIBRIS 3-CARD SHOWCASE
          Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
            decoration: const BoxDecoration(
              color: LibrisTheme.deepStoryNight,
              border: Border(
                bottom: BorderSide(color: LibrisTheme.borderCrisp, width: 1.0),
              ),
            ),
            child: Column(
              children: [
                Text(
                  info.primaryCategory.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFFD6A85A),
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  info.title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'Georgia',
                    fontSize: 21,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFFCFBF8),
                    height: 1.15,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Oleh ${info.authorsLine}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'Georgia',
                    fontSize: 12.5,
                    fontStyle: FontStyle.italic,
                    color: Color(0xFFD6D0C4),
                  ),
                ),
                const SizedBox(height: 8),

                // Fanned 3-Card Ex-Libris & Physical Book Cover
                AnimatedFannedStoryCards(book: widget.book),
                const SizedBox(height: 10),

                // Label Indeks Katalog Arsip (Menggantikan Pill Warna-Warni Neon)
                const Text(
                  'Tags & Metadata',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFFA8A29E),
                    letterSpacing: 0.9,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  alignment: WrapAlignment.center,
                  children: [
                    _buildArchivalIndexTag(
                      'SUBJEK: ${info.primaryCategory.toUpperCase()}',
                    ),
                    _buildArchivalIndexTag(
                      'RATING ${info.averageRating} / 5.0',
                    ),
                    _buildArchivalIndexTag(
                      '${info.pageCount} HALAMAN',
                    ),
                    _buildArchivalIndexTag(
                      'EDISI ${info.publishedYear}',
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '${info.publisher}   •   ISBN-13: ${info.isbn13}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFFA8A29E),
                  ),
                ),
              ],
            ),
          ),

          // 2. PITA SPESIFIKASI TIPOGRAFI (KPIs are type, not tiles — 1px Hairline Grid)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            decoration: const BoxDecoration(
              color: LibrisTheme.skyCanvas,
              border: Border(
                bottom: BorderSide(color: LibrisTheme.borderCrisp, width: 1.0),
              ),
            ),
            child: IntrinsicHeight(
              child: Row(
                children: [
                  Expanded(
                    child: _buildTypographicSpecCell(
                      label: 'RATING',
                      value: '${info.averageRating}',
                      sub: '${info.ratingsCount} ulasan',
                    ),
                  ),
                  const VerticalDivider(color: LibrisTheme.borderCrisp, width: 1, thickness: 1),
                  Expanded(
                    child: _buildTypographicSpecCell(
                      label: 'KETEBALAN',
                      value: '${info.pageCount}',
                      sub: 'Halaman',
                    ),
                  ),
                  const VerticalDivider(color: LibrisTheme.borderCrisp, width: 1, thickness: 1),
                  Expanded(
                    child: _buildTypographicSpecCell(
                      label: 'TAHUN TERBIT',
                      value: info.publishedYear,
                      sub: 'Edisi Cetak',
                    ),
                  ),
                  const VerticalDivider(color: LibrisTheme.borderCrisp, width: 1, thickness: 1),
                  Expanded(
                    child: _buildTypographicSpecCell(
                      label: 'BAHASA',
                      value: info.language,
                      sub: 'Standar ISO',
                    ),
                  ),
                ],
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 3. SINOPSIS & RINGKASAN ISI (Format Artikel Editorial — Tampil Langsung di Atas Lipatan)
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    const Text(
                      'TINJAUAN LITERATUR',
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        color: LibrisTheme.accentTerracotta,
                        letterSpacing: 1.1,
                      ),
                    ),
                    Text(
                      _currentPage > 0
                          ? 'Hal. $_currentPage/${info.pageCount} (${((_currentPage / (info.pageCount > 0 ? info.pageCount : 1)) * 100).round()}%)'
                          : '${info.pageCount} Halaman',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: LibrisTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  'Sinopsis & Ringkasan Isi',
                  style: TextStyle(
                    fontFamily: 'Georgia',
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: LibrisTheme.primaryInk,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  info.description,
                  maxLines: _isSynopsisExpanded ? 30 : 4,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Georgia',
                    fontSize: 14.5,
                    height: 1.72,
                    color: LibrisTheme.primaryInk,
                  ),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () => setState(
                    () => _isSynopsisExpanded = !_isSynopsisExpanded,
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _isSynopsisExpanded
                              ? 'Ringkas tampilan sinopsis'
                              : 'Baca sinopsis selengkapnya',
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: LibrisTheme.accentTerracotta,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          _isSynopsisExpanded
                              ? Icons.keyboard_arrow_up_rounded
                              : Icons.keyboard_arrow_down_rounded,
                          size: 18,
                          color: LibrisTheme.accentTerracotta,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                _buildReadingProgressPanel(info),
                const SizedBox(height: 24),

                // 5. INTISARI POKOK (KEY TAKEAWAYS) BERNOMOR INDEKS
                if (state.keyTakeaways.isNotEmpty) ...[
                  const Divider(color: LibrisTheme.borderCrisp, height: 1),
                  const SizedBox(height: 20),
                  const Text(
                    'INTISARI & GAGASAN UTAMA',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: LibrisTheme.primarySkyDark,
                      letterSpacing: 1.1,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...List.generate(state.keyTakeaways.length, (idx) {
                    final numStr = (idx + 1).toString().padLeft(2, '0');
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 26,
                            child: Text(
                              numStr,
                              style: const TextStyle(
                                fontFamily: 'Georgia',
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: LibrisTheme.accentTerracotta,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              state.keyTakeaways[idx],
                              style: const TextStyle(
                                fontSize: 13.5,
                                height: 1.55,
                                color: LibrisTheme.primaryInk,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],

                const SizedBox(height: 8),
                const Divider(color: LibrisTheme.borderCrisp, height: 1),
                const SizedBox(height: 20),

                // 6. KOLOFON & CATATAN PENULIS (Garis Samping Editorial Tanpa Kotak Ikon Bulat)
                Container(
                  padding: const EdgeInsets.only(left: 14, top: 2, bottom: 2),
                  decoration: const BoxDecoration(
                    border: Border(
                      left: BorderSide(
                        color: LibrisTheme.primaryInk,
                        width: 2.5,
                      ),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'TENTANG PENULIS — ${info.authorsLine.toUpperCase()}',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: LibrisTheme.textMuted,
                          letterSpacing: 0.9,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        state.authorBio.isNotEmpty
                            ? state.authorBio
                            : 'Penulis dan akademisi rujukan di bidang ${info.primaryCategory}.',
                        style: const TextStyle(
                          fontSize: 13,
                          height: 1.55,
                          color: LibrisTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Kolofon Katalog: Diterbitkan oleh ${info.publisher} (${info.publishedDate}) • ISBN-13 ${info.isbn13}',
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: LibrisTheme.primaryInk,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
        decoration: const BoxDecoration(
          color: LibrisTheme.backgroundPaper,
          border: Border(
            top: BorderSide(color: LibrisTheme.borderCrisp, width: 1.0),
          ),
        ),
        child: SafeArea(
          top: false,
          child: Row(
            children: [
              GestureDetector(
                onTap: _handleSave,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: _saved
                        ? LibrisTheme.sunsetOrangeSoft
                        : LibrisTheme.skyCanvas,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: _saved
                          ? LibrisTheme.accentTerracotta
                          : LibrisTheme.borderCrisp,
                      width: 1.0,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _saved
                            ? Icons.bookmark_rounded
                            : Icons.bookmark_border_rounded,
                        size: 19,
                        color: _saved
                            ? LibrisTheme.accentTerracotta
                            : LibrisTheme.primaryInk,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _saved ? 'Tersimpan' : 'Simpan',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: LibrisTheme.primaryInk,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: _showPreviewReaderSheet,
                  style: FilledButton.styleFrom(
                    backgroundColor: LibrisTheme.primaryInk,
                    foregroundColor: LibrisTheme.surfaceCard,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  icon: const Icon(Icons.menu_book_outlined, size: 18),
                  label: const Text(
                    'Baca Pratinjau Bab',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Label Indeks Arsip dengan sudut tegas (4px) — Menggantikan pill warna-warni AI slop
  Widget _buildArchivalIndexTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFF28231E),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: const Color(0xFF443C35),
          width: 0.8,
        ),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: Color(0xFFEDE8DF),
          letterSpacing: 0.6,
        ),
      ),
    );
  }

  /// Sel Spesifikasi Tipografi ("KPIs are type, not tiles")
  Widget _buildTypographicSpecCell({
    required String label,
    required String value,
    required String sub,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Column(
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 8.5,
              fontWeight: FontWeight.w800,
              color: LibrisTheme.textMuted,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'Georgia',
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: LibrisTheme.primaryInk,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            sub,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: LibrisTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  /// Panel Logika & Progres Membaca Persisten (SQLite)
  Widget _buildReadingProgressPanel(VolumeInfo info) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: LibrisTheme.surfaceCard,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: LibrisTheme.borderCrisp,
          width: 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 4,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _isActiveReadingBook
                        ? Icons.auto_stories
                        : Icons.menu_book_outlined,
                    size: 14,
                    color: LibrisTheme.accentTerracotta,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _isActiveReadingBook
                        ? 'SEDANG DIBACA • AKTIF'
                        : 'JURNAL BACAAN PRIBADI',
                    style: const TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
                      color: LibrisTheme.accentTerracotta,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
              Text(
                'Hal. $_currentPage / ${info.pageCount}',
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: LibrisTheme.primaryInk,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: info.pageCount > 0
                  ? (_currentPage / info.pageCount).clamp(0.0, 1.0)
                  : 0.0,
              minHeight: 4.0,
              backgroundColor: LibrisTheme.skyCanvas,
              valueColor: const AlwaysStoppedAnimation<Color>(
                LibrisTheme.accentTerracotta,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  OutlinedButton(
                    onPressed: _currentPage > 0
                        ? () => _updateProgress(_currentPage - 10)
                        : null,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(
                        color: LibrisTheme.borderCrisp,
                        width: 1.0,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      minimumSize: const Size(0, 32),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    child: const Text(
                      '-10 Hlm',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: LibrisTheme.primaryInk,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: _currentPage < info.pageCount
                        ? () => _updateProgress(_currentPage + 10)
                        : null,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(
                        color: LibrisTheme.borderCrisp,
                        width: 1.0,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      minimumSize: const Size(0, 32),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    child: const Text(
                      '+10 Hlm',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: LibrisTheme.primaryInk,
                      ),
                    ),
                  ),
                ],
              ),
              if (!_isActiveReadingBook)
                FilledButton.tonal(
                  onPressed: _makeActiveBook,
                  style: FilledButton.styleFrom(
                    backgroundColor: LibrisTheme.primaryInk,
                    foregroundColor: LibrisTheme.surfaceCard,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    minimumSize: const Size(0, 32),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  child: const Text(
                    'Jadikan Sedang Dibaca',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F0EC),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: const Color(0xFF28463B).withValues(alpha: 0.3),
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.check,
                        size: 12,
                        color: Color(0xFF28463B),
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Aktif di Beranda',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF28463B),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
