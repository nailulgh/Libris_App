import 'package:flutter/material.dart';
import '../models/book_volume.dart';
import '../services/book_repository.dart';
import '../services/libris_database_service.dart';
import '../theme/libris_theme.dart';
import '../widgets/flat_book_cover.dart';
import '../widgets/flat_character_illustrations.dart';
import 'category_page.dart';
import 'detail_page.dart';
import 'onboarding_story_page.dart';

/// Halaman 1: Beranda (HomePage) — Warm Editorial & Literary Print UI
/// Direfaktor mengikuti panduan Anti-AI-Slop (design-taste-frontend & ui-ux-pro-max):
/// - Masthead bergaya majalah cetak tanpa kotak ikon warna-warni (no icons in tinted squares).
/// - Rak Buku Edisi Pilihan (Editorial Folio Shelf) menggantikan kartu biru mencolok.
/// - Daftar Katalog berformat Editorial Ledger dengan pemisah garis tipis 1px (hairline rules)
///   dan penomoran indeks tabular (01, 02, 03...) tanpa penumpukan border kartu.
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final BookRepository _repository = BookRepository();
  final TextEditingController _searchController = TextEditingController();

  List<BookVolume> _allBooks = [];
  BookVolume? _activeReadingBook;
  bool _isLoading = true;
  bool _isSyncingApi = false;
  String _selectedQuickCategory = 'Semua';
  String _searchQuery = '';
  int _bottomNavIndex = 0;
  bool _showMyBooksSegment = false;
  final Set<String> _savedBookIds = <String>{};

  @override
  void initState() {
    super.initState();
    _loadCatalog();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCatalog({bool showLoading = true}) async {
    // 1. Muat data lokal seketika agar render UI pertama instan tanpa jeda
    if (_allBooks.isEmpty) {
      try {
        final fastLocalBooks = await _repository.loadBooksFromLocalJson();
        final mirrorSaved = await LibrisDatabaseService.instance.getPersistedBookmarkedIds();
        if (mounted && _allBooks.isEmpty) {
          setState(() {
            _allBooks = fastLocalBooks;
            _activeReadingBook = fastLocalBooks.firstWhere(
              (b) => b.readingState.currentPage > 0,
              orElse: () => fastLocalBooks.first,
            );
            _savedBookIds.clear();
            if (mirrorSaved != null) {
              _savedBookIds.addAll(mirrorSaved);
            } else {
              for (final b in fastLocalBooks) {
                if (b.readingState.isBookmarked) {
                  _savedBookIds.add(b.id);
                }
              }
            }
            _isLoading = false;
          });
        }
      } catch (_) {}
    } else if (showLoading) {
      setState(() => _isLoading = true);
    }

    try {
      final books = await _repository.loadCatalogWithDatabase();
      final active = await LibrisDatabaseService.instance.resolveActiveReadingBook(books);
      final savedIds = books
          .where((b) => b.readingState.isBookmarked)
          .map((b) => b.id)
          .toSet();

      if (!mounted) return;
      setState(() {
        _allBooks = books;
        _activeReadingBook = active;
        _savedBookIds.clear();
        _savedBookIds.addAll(savedIds);
        _isLoading = false;
      });

      // Sinkronisasi ekspansi katalog Google Books API secara asynchronous di latar belakang
      if (books.length <= 16) {
        _backgroundExpandCatalog();
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _backgroundExpandCatalog() async {
    try {
      final expandedBooks = await _repository.fetchMultiCategoryGoogleBooks(booksPerCategory: 10);
      final savedIds = expandedBooks
          .where((b) => b.readingState.isBookmarked)
          .map((b) => b.id)
          .toSet();
      final active = await LibrisDatabaseService.instance.resolveActiveReadingBook(expandedBooks);

      if (!mounted) return;
      setState(() {
        _allBooks = expandedBooks;
        _activeReadingBook = active;
        _savedBookIds.clear();
        _savedBookIds.addAll(savedIds);
      });
    } catch (_) {}
  }

  Future<void> _toggleSaveBook(String bookId) async {
    final willBookmark = !_savedBookIds.contains(bookId);
    setState(() {
      if (willBookmark) {
        _savedBookIds.add(bookId);
      } else {
        _savedBookIds.remove(bookId);
      }
    });
    await LibrisDatabaseService.instance.setBookmark(bookId, willBookmark);

    final idx = _allBooks.indexWhere((b) => b.id == bookId);
    if (idx != -1) {
      _allBooks[idx] = _allBooks[idx].copyWith(
        readingState: _allBooks[idx].readingState.copyWith(
          isBookmarked: willBookmark,
        ),
      );
    }
  }

  Future<void> _cycleActiveBook() async {
    if (_allBooks.isEmpty) return;
    final currentId = _activeReadingBook?.id ?? _allBooks.first.id;
    final currentIndex = _allBooks.indexWhere((b) => b.id == currentId);
    final nextIndex = (currentIndex + 1) % _allBooks.length;
    final nextBook = _allBooks[nextIndex];

    await LibrisDatabaseService.instance.setActiveReadingBookId(nextBook.id);
    setState(() {
      _activeReadingBook = nextBook;
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: LibrisTheme.primaryInk,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(milliseconds: 900),
        content: Text(
          'Sedang dibaca: ${nextBook.volumeInfo.title}',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Future<void> _advanceActiveBookPage(BookVolume book) async {
    final total = book.volumeInfo.pageCount > 0 ? book.volumeInfo.pageCount : 100;
    final newPage = (book.readingState.currentPage + 10).clamp(0, total);
    await LibrisDatabaseService.instance.updateReadingProgress(book.id, newPage);
    final updatedBook = book.copyWith(
      readingState: book.readingState.copyWith(
        currentPage: newPage,
        lastReadAt: DateTime.now().millisecondsSinceEpoch,
      ),
    );
    setState(() {
      _activeReadingBook = updatedBook;
      final idx = _allBooks.indexWhere((b) => b.id == book.id);
      if (idx != -1) {
        _allBooks[idx] = updatedBook;
      }
    });
  }

  Future<void> _syncWithGoogleBooksApi() async {
    if (_isSyncingApi) return;
    setState(() => _isSyncingApi = true);
    try {
      final results = await _repository.fetchMultiCategoryGoogleBooks(booksPerCategory: 10);
      final active = await LibrisDatabaseService.instance.resolveActiveReadingBook(results);
      final savedIds = results
          .where((b) => b.readingState.isBookmarked)
          .map((b) => b.id)
          .toSet();

      if (!mounted) return;
      setState(() {
        _allBooks = results;
        _activeReadingBook = active;
        _savedBookIds.clear();
        _savedBookIds.addAll(savedIds);
        _isSyncingApi = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: LibrisTheme.primaryInk,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(milliseconds: 1400),
          content: Text(
            'Katalog diperbarui • ${_allBooks.length} buku tersedia',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSyncingApi = false);
    }
  }

  Future<void> _openCategoryPage(String initialCategory) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CategoryPage(
          allBooks: _allBooks,
          initialCategory: initialCategory,
          savedBookIds: _savedBookIds,
          onToggleSave: _toggleSaveBook,
        ),
      ),
    );
    await _loadCatalog(showLoading: false);
  }

  Future<void> _openDetailPage(BookVolume book) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DetailPage(
          book: book,
          isSaved: _savedBookIds.contains(book.id),
          onToggleSave: () => _toggleSaveBook(book.id),
        ),
      ),
    );
    await _loadCatalog(showLoading: false);
  }

  void _openStoryTour() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const OnboardingStoryPage(),
      ),
    );
  }

  List<BookVolume> get _filteredBooks {
    return _allBooks.where((book) {
      final matchesCategory =
          _selectedQuickCategory == 'Semua' ||
          book.volumeInfo.primaryCategory.toLowerCase() ==
              _selectedQuickCategory.toLowerCase();
      final q = _searchQuery.trim().toLowerCase();
      final matchesQuery =
          q.isEmpty ||
          book.volumeInfo.title.toLowerCase().contains(q) ||
          book.volumeInfo.primaryAuthor.toLowerCase().contains(q) ||
          book.volumeInfo.isbn13.toLowerCase().contains(q);
      return matchesCategory && matchesQuery;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LibrisTheme.backgroundPaper,
      appBar: _buildEditorialAppBar(),
      drawer: _buildEditorialDrawer(),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: LibrisTheme.primaryInk,
                strokeWidth: 2,
              ),
            )
          : (_bottomNavIndex == 2
                ? _buildSavedBooksView()
                : _buildDiscoveryBody()),
      bottomNavigationBar: _buildFlatBottomNav(),
    );
  }

  /// Masthead Editorial Bersih (Tanpa Ikon di Dalam Kotak Warna-Warni)
  PreferredSizeWidget _buildEditorialAppBar() {
    return AppBar(
      backgroundColor: LibrisTheme.backgroundPaper,
      titleSpacing: 4,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1.0),
        child: Container(
          height: 1.0,
          color: LibrisTheme.borderCrisp,
        ),
      ),
      title: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            const Text(
              'Libris.',
              style: TextStyle(
                fontFamily: 'Georgia',
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: LibrisTheme.primaryInk,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'LITERARY INDEX',
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
                color: LibrisTheme.textMuted.withValues(alpha: 0.9),
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
      ),
      actions: [
        IconButton(
          tooltip: 'Sinkronisasi Google Books API',
          onPressed: _isSyncingApi ? null : _syncWithGoogleBooksApi,
          icon: _isSyncingApi
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: LibrisTheme.primaryInk,
                  ),
                )
              : const Icon(
                  Icons.sync_rounded,
                  size: 20,
                  color: LibrisTheme.primaryInk,
                ),
        ),
        IconButton(
          tooltip: 'Story Onboarding',
          onPressed: _openStoryTour,
          icon: const Icon(
            Icons.menu_book_outlined,
            size: 20,
            color: LibrisTheme.primaryInk,
          ),
        ),
        IconButton(
          tooltip: 'Halaman Kategori Subjek',
          onPressed: () => _openCategoryPage(_selectedQuickCategory),
          icon: const Icon(
            Icons.grid_view_outlined,
            size: 20,
            color: LibrisTheme.primaryInk,
          ),
        ),
        const SizedBox(width: 6),
      ],
    );
  }

  Widget _buildEditorialDrawer() {
    return Drawer(
      backgroundColor: LibrisTheme.backgroundPaper,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: LibrisTheme.deepStoryNight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'EDISI KEPUSTAKAAN IV',
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFD6A85A),
                        letterSpacing: 1.2,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Libris Editorial',
                      style: TextStyle(
                        fontFamily: 'Georgia',
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFFCFBF8),
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Katalog Eksplorasi Buku, Monograf Akademik, dan Jurnal Bacaan Digital.',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFFD6D0C4),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'INDEKS NAVIGASI',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: LibrisTheme.textMuted,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              const Divider(color: LibrisTheme.borderCrisp, height: 1),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(
                  Icons.home_outlined,
                  color: LibrisTheme.primaryInk,
                  size: 20,
                ),
                title: const Text(
                  'Beranda Eksplorasi',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: LibrisTheme.primaryInk,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  setState(() => _bottomNavIndex = 0);
                },
              ),
              const Divider(color: LibrisTheme.borderCrisp, height: 1),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(
                  Icons.grid_view_outlined,
                  color: LibrisTheme.primaryInk,
                  size: 20,
                ),
                title: const Text(
                  'Halaman Kategori Subjek',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: LibrisTheme.primaryInk,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _openCategoryPage('Semua');
                },
              ),
              const Divider(color: LibrisTheme.borderCrisp, height: 1),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(
                  Icons.menu_book_outlined,
                  color: LibrisTheme.accentTerracotta,
                  size: 20,
                ),
                title: const Text(
                  'Story Tour (Pengantar Editorial)',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: LibrisTheme.primaryInk,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _openStoryTour();
                },
              ),
              const Divider(color: LibrisTheme.borderCrisp, height: 1),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(
                  Icons.bookmark_border_rounded,
                  color: LibrisTheme.primaryInk,
                  size: 20,
                ),
                title: Text(
                  'Koleksi Bacaan Tersimpan (${_savedBookIds.length})',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: LibrisTheme.primaryInk,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  setState(() => _bottomNavIndex = 2);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDiscoveryBody() {
    final activeReadingBook = _activeReadingBook ??
        (_allBooks.isNotEmpty ? _allBooks.first : null);

    if (activeReadingBook == null) {
      return const Center(
        child: Text(
          'Tidak ada buku yang ditemukan.',
          style: TextStyle(color: LibrisTheme.textSecondary),
        ),
      );
    }

    final trendingBooks = _allBooks
        .where((b) => b.readingState.isTrending)
        .toList();
    final filtered = _filteredBooks;
    final featuredDisplayBooks = _showMyBooksSegment
        ? _allBooks.where((b) => _savedBookIds.contains(b.id)).toList()
        : (trendingBooks.isNotEmpty ? trendingBooks : filtered);

    return RefreshIndicator(
      color: LibrisTheme.primaryInk,
      backgroundColor: LibrisTheme.surfaceCard,
      onRefresh: _syncWithGoogleBooksApi,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 36),
        children: [
          // 1. Kolom Pencarian Katalog (Permukaan Tonal Tenang)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
            decoration: BoxDecoration(
              color: LibrisTheme.skyCanvas,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: LibrisTheme.borderCrisp, width: 1.0),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.search_rounded,
                  color: LibrisTheme.textSecondary,
                  size: 19,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) => setState(() => _searchQuery = value),
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w500,
                      color: LibrisTheme.primaryInk,
                    ),
                    decoration: const InputDecoration(
                      hintText: 'Cari judul monograf, penulis, atau ISBN-13...',
                      hintStyle: TextStyle(
                        fontSize: 13,
                        color: LibrisTheme.textMuted,
                      ),
                      border: InputBorder.none,
                      isDense: true,
                    ),
                  ),
                ),
                if (_searchQuery.isNotEmpty)
                  GestureDetector(
                    onTap: () {
                      _searchController.clear();
                      setState(() => _searchQuery = '');
                    },
                    child: const Icon(
                      Icons.close_rounded,
                      size: 18,
                      color: LibrisTheme.primaryInk,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 2. HERO MEJA BACA EDITORIAL & LAMPU KUNINGAN INTERAKTIF (DINAMIS DARI SQLITE)
          if (_searchQuery.isEmpty) ...[
            AnimatedCozyReaderHero(
              activeBook: activeReadingBook,
              onReadTap: () => _openDetailPage(activeReadingBook),
              onStoryTourTap: _openStoryTour,
              onCycleActiveBook: _cycleActiveBook,
              onQuickAdvancePage: () => _advanceActiveBookPage(activeReadingBook),
            ),
            const SizedBox(height: 26),
          ],

        // 3. KLASIFIKASI SUBJEK & TAUTAN INDEKS KATEGORI
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            const Text(
              'Subjek & Disiplin',
              style: TextStyle(
                fontFamily: 'Georgia',
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: LibrisTheme.primaryInk,
                letterSpacing: -0.3,
              ),
            ),
            GestureDetector(
              onTap: () => _openCategoryPage(_selectedQuickCategory),
              child: const Row(
                children: [
                  Text(
                    'Indeks Subjek',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: LibrisTheme.accentTerracotta,
                    ),
                  ),
                  SizedBox(width: 2),
                  Icon(
                    Icons.arrow_forward_rounded,
                    size: 14,
                    color: LibrisTheme.accentTerracotta,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 34,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: BookRepository.supportedCategories.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final cat = BookRepository.supportedCategories[index];
              final isSelected = _selectedQuickCategory == cat;
              return GestureDetector(
                onTap: () => setState(() => _selectedQuickCategory = cat),
                onDoubleTap: () => _openCategoryPage(cat),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(horizontal: 13),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? LibrisTheme.primaryInk
                        : LibrisTheme.skyCanvas,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isSelected
                          ? LibrisTheme.primaryInk
                          : LibrisTheme.borderCrisp,
                      width: 1.0,
                    ),
                  ),
                  child: Text(
                    cat,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: isSelected
                          ? LibrisTheme.surfaceCard
                          : LibrisTheme.primaryInk,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 26),

        // 4. SEGMEN RAK PILIHAN EDITOR VS KOLEKSI SAYA (Garis Tab Editorial)
        Container(
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(color: LibrisTheme.borderCrisp, width: 1.0),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _showMyBooksSegment = false),
                  child: Container(
                    padding: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: !_showMyBooksSegment
                              ? LibrisTheme.primaryInk
                              : Colors.transparent,
                          width: 2.0,
                        ),
                      ),
                    ),
                    child: Text(
                      'ALL FEATURED',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: !_showMyBooksSegment
                            ? LibrisTheme.primaryInk
                            : LibrisTheme.textMuted,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _showMyBooksSegment = true),
                  child: Container(
                    padding: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: _showMyBooksSegment
                              ? LibrisTheme.primaryInk
                              : Colors.transparent,
                          width: 2.0,
                        ),
                      ),
                    ),
                    child: Text(
                      'MY BOOKS (${_savedBookIds.length})',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: _showMyBooksSegment
                            ? LibrisTheme.primaryInk
                            : LibrisTheme.textMuted,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        // 5. RAK FOLIO BUKU UNGGULAN (Tanpa Kotak Biru Mencolok)
        SizedBox(
          height: 256,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: featuredDisplayBooks.length,
            separatorBuilder: (_, _) => const SizedBox(width: 18),
            itemBuilder: (context, index) {
              final book = featuredDisplayBooks[index];
              return _buildEditorialFolioShelfItem(book, index);
            },
          ),
        ),
        const SizedBox(height: 28),

        // 6. DAFTAR KURASI BERFORMAT EDITORIAL LEDGER (1px Hairline Divider)
        Container(
          padding: const EdgeInsets.only(bottom: 10),
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(color: LibrisTheme.primaryInk, width: 1.2),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                _selectedQuickCategory == 'Semua'
                    ? 'Indeks Kurasi & Akademik'
                    : 'Katalog $_selectedQuickCategory',
                style: const TextStyle(
                  fontFamily: 'Georgia',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: LibrisTheme.primaryInk,
                  letterSpacing: -0.3,
                ),
              ),
              Text(
                '${filtered.length} VOLUME',
                style: const TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  color: LibrisTheme.textMuted,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
        ),
        ...List.generate(
          filtered.length,
          (index) => _buildCuratedEditorialLedgerRow(filtered[index], index),
        ),
      ],
    ),
  );
}

  /// Item Rak Folio Editorial — Sampul buku fisik sebagai fokus utama (Tanpa kotak biru)
  Widget _buildEditorialFolioShelfItem(BookVolume book, int index) {
    final progress = book.progressRatio.clamp(0.12, 1.0);
    final indexLabel = 'NO. ${(index + 1).toString().padLeft(2, '0')}';

    return GestureDetector(
      onTap: () => _openDetailPage(book),
      child: SizedBox(
        width: 136,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  indexLabel,
                  style: const TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    color: LibrisTheme.textMuted,
                    letterSpacing: 0.9,
                  ),
                ),
                Text(
                  '${book.progressPercent}%',
                  style: const TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    color: LibrisTheme.accentTerracotta,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Expanded(
              child: FlatBookCover(
                book: book,
                width: 136,
                height: double.infinity,
                borderRadius: 6,
                showCategoryBadge: true,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              book.volumeInfo.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'Georgia',
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: LibrisTheme.primaryInk,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              book.volumeInfo.primaryAuthor,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w400,
                color: LibrisTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 7),
            ClipRRect(
              borderRadius: BorderRadius.circular(1),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 2.5,
                backgroundColor: LibrisTheme.borderCrisp,
                valueColor: const AlwaysStoppedAnimation<Color>(
                  LibrisTheme.accentTerracotta,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Baris Katalog Bergaya Editorial Ledger (Dipisahkan Garis 1px, Tanpa Kartu Mengambang)
  Widget _buildCuratedEditorialLedgerRow(BookVolume book, int index) {
    final isSaved = _savedBookIds.contains(book.id);
    final rowNumber = (index + 1).toString().padLeft(2, '0');

    return GestureDetector(
      onTap: () => _openDetailPage(book),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(color: LibrisTheme.borderCrisp, width: 1.0),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Nomor Indeks Tabular
            SizedBox(
              width: 24,
              child: Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  rowNumber,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: LibrisTheme.textMuted,
                  ),
                ),
              ),
            ),
            // Sampul Buku Hardbound
            FlatBookCover(
              book: book,
              width: 66,
              height: 96,
              borderRadius: 5,
            ),
            const SizedBox(width: 14),
            // Kolom Informasi Bibliografi
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        book.volumeInfo.primaryCategory.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          color: LibrisTheme.primarySkyDark,
                          letterSpacing: 0.9,
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => _toggleSaveBook(book.id),
                        child: Icon(
                          isSaved
                              ? Icons.bookmark_rounded
                              : Icons.bookmark_border_rounded,
                          size: 19,
                          color: isSaved
                              ? LibrisTheme.accentTerracotta
                              : LibrisTheme.textMuted,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    book.volumeInfo.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Georgia',
                      fontSize: 15.5,
                      fontWeight: FontWeight.w700,
                      color: LibrisTheme.primaryInk,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${book.volumeInfo.primaryAuthor} • ${book.volumeInfo.publishedYear}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: LibrisTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        size: 14,
                        color: LibrisTheme.accentGold,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        '${book.volumeInfo.averageRating}',
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: LibrisTheme.primaryInk,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        width: 3,
                        height: 3,
                        decoration: const BoxDecoration(
                          color: LibrisTheme.textMuted,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        '${book.volumeInfo.pageCount} hlm',
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                          color: LibrisTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'ISBN ${book.volumeInfo.isbn13.substring(book.volumeInfo.isbn13.length - 4)}',
                        style: const TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          color: LibrisTheme.textMuted,
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

  Widget _buildSavedBooksView() {
    final savedBooks = _allBooks
        .where((b) => _savedBookIds.contains(b.id))
        .toList();

    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        const Text(
          'ARSIP PERSONAL',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            color: LibrisTheme.accentTerracotta,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Koleksi Bacaan Tersimpan',
          style: TextStyle(
            fontFamily: 'Georgia',
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: LibrisTheme.primaryInk,
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${savedBooks.length} volume monograf disimpan dalam daftar bacaan Anda',
          style: const TextStyle(
            fontSize: 13,
            color: LibrisTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 16),
        const Divider(color: LibrisTheme.primaryInk, thickness: 1.2, height: 1),
        if (savedBooks.isEmpty)
          Container(
            margin: const EdgeInsets.only(top: 20),
            padding: const EdgeInsets.all(28),
            decoration: LibrisTheme.tonalPanelDecoration(
              color: LibrisTheme.skyCanvas,
            ),
            child: const Column(
              children: [
                Icon(
                  Icons.bookmark_border_rounded,
                  size: 34,
                  color: LibrisTheme.textMuted,
                ),
                SizedBox(height: 10),
                Text(
                  'Belum ada monograf yang disimpan.',
                  style: TextStyle(
                    fontFamily: 'Georgia',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: LibrisTheme.primaryInk,
                  ),
                ),
              ],
            ),
          )
        else
          ...List.generate(
            savedBooks.length,
            (index) =>
                _buildCuratedEditorialLedgerRow(savedBooks[index], index),
          ),
      ],
    );
  }

  Widget _buildFlatBottomNav() {
    return Container(
      decoration: const BoxDecoration(
        color: LibrisTheme.backgroundPaper,
        border: Border(
          top: BorderSide(color: LibrisTheme.borderCrisp, width: 1.0),
        ),
      ),
      child: NavigationBar(
        height: 64,
        backgroundColor: LibrisTheme.backgroundPaper,
        elevation: 0,
        selectedIndex: _bottomNavIndex,
        onDestinationSelected: (index) {
          if (index == 1) {
            _openCategoryPage(_selectedQuickCategory);
          } else {
            setState(() => _bottomNavIndex = index);
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Beranda',
          ),
          NavigationDestination(
            icon: Icon(Icons.grid_view_outlined),
            selectedIcon: Icon(Icons.grid_view_rounded),
            label: 'Kategori Subjek',
          ),
          NavigationDestination(
            icon: Icon(Icons.bookmark_border_rounded),
            selectedIcon: Icon(Icons.bookmark_rounded),
            label: 'Koleksi Saya',
          ),
        ],
      ),
    );
  }
}
