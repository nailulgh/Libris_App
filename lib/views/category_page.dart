import 'package:flutter/material.dart';
import '../models/book_volume.dart';
import '../services/book_repository.dart';
import '../services/libris_database_service.dart';
import '../theme/libris_theme.dart';
import '../widgets/flat_book_cover.dart';
import '../widgets/flat_character_illustrations.dart';
import 'detail_page.dart';

/// Halaman 2: Kategori Subjek (CategoryPage) — Archival Subject Classification UI
/// Direfaktor mengikuti prinsip Anti-AI-Slop (design-taste-frontend & ui-ux-pro-max):
/// - Menghilangkan pill berlapis (pill-inside-pill) pada tab filter subjek.
/// - Menampilkan Grid Katalog Buku dengan tumpuan kertas tonal (tanpa bingkai biru tebal).
/// - Menyediakan peralihan tampilan Grid Folio dan Daftar Indeks (Ledger List).
class CategoryPage extends StatefulWidget {
  final List<BookVolume> allBooks;
  final String initialCategory;
  final Set<String> savedBookIds;
  final ValueChanged<String> onToggleSave;

  const CategoryPage({
    super.key,
    required this.allBooks,
    required this.initialCategory,
    required this.savedBookIds,
    required this.onToggleSave,
  });

  @override
  State<CategoryPage> createState() => _CategoryPageState();
}

class _CategoryPageState extends State<CategoryPage> {
  late String _selectedCategory;
  late List<BookVolume> _currentBooks;
  String _sortBy = 'Rating Tertinggi';
  bool _isGridView = true;
  bool _isFetchingFromApi = false;

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.initialCategory;
    _currentBooks = List.from(widget.allBooks);
  }

  Future<void> _fetchCategoryFromGoogleBooks() async {
    if (_isFetchingFromApi) return;
    setState(() => _isFetchingFromApi = true);
    try {
      final updatedBooks = await BookRepository().fetchGoogleBooksByCategory(
        _selectedCategory == 'Semua' ? 'Computer Science' : _selectedCategory,
        maxResults: 15,
      );
      if (!mounted) return;
      setState(() {
        _currentBooks = updatedBooks;
        _isFetchingFromApi = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: LibrisTheme.primaryInk,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(milliseconds: 1200),
          content: Text(
            'Koleksi subjek "$_selectedCategory" diperbarui (${updatedBooks.length} buku tersedia)',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _isFetchingFromApi = false);
    }
  }

  List<BookVolume> get _filteredAndSortedBooks {
    final filtered = _currentBooks.where((book) {
      if (_selectedCategory == 'Semua') return true;
      return book.volumeInfo.primaryCategory.toLowerCase() ==
          _selectedCategory.toLowerCase();
    }).toList();

    if (_sortBy == 'Rating Tertinggi') {
      filtered.sort(
        (a, b) =>
            b.volumeInfo.averageRating.compareTo(a.volumeInfo.averageRating),
      );
    } else if (_sortBy == 'Tahun Terbaru') {
      filtered.sort(
        (a, b) =>
            b.volumeInfo.publishedDate.compareTo(a.volumeInfo.publishedDate),
      );
    } else if (_sortBy == 'Judul (A-Z)') {
      filtered.sort(
        (a, b) => a.volumeInfo.title.compareTo(b.volumeInfo.title),
      );
    }
    return filtered;
  }

  int _countForCategory(String category) {
    if (category == 'Semua') return _currentBooks.length;
    return _currentBooks
        .where(
          (b) =>
              b.volumeInfo.primaryCategory.toLowerCase() ==
              category.toLowerCase(),
        )
        .length;
  }

  Future<void> _openDetail(BookVolume book) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DetailPage(
          book: book,
          isSaved: widget.savedBookIds.contains(book.id),
          onToggleSave: () {
            widget.onToggleSave(book.id);
            setState(() {});
          },
        ),
      ),
    );
    final updated = await LibrisDatabaseService.instance.getAllBooks();
    if (mounted && updated.isNotEmpty) {
      setState(() {
        _currentBooks = updated;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final books = _filteredAndSortedBooks;

    return Scaffold(
      backgroundColor: LibrisTheme.backgroundPaper,
      appBar: AppBar(
        backgroundColor: LibrisTheme.backgroundPaper,
        title: const Text('Kategori Subjek Buku'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(
            height: 1.0,
            color: LibrisTheme.borderCrisp,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Sinkronisasi Google Books API',
            onPressed: _isFetchingFromApi ? null : _fetchCategoryFromGoogleBooks,
            icon: _isFetchingFromApi
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: LibrisTheme.primaryInk,
                    ),
                  )
                : const Icon(
                    Icons.cloud_download_outlined,
                    size: 20,
                    color: LibrisTheme.primaryInk,
                  ),
          ),
          IconButton(
            tooltip: _isGridView ? 'Tampilan Indeks Baris' : 'Tampilan Rak Grid',
            onPressed: () => setState(() => _isGridView = !_isGridView),
            icon: Icon(
              _isGridView
                  ? Icons.view_agenda_outlined
                  : Icons.grid_view_outlined,
              size: 20,
              color: LibrisTheme.primaryInk,
            ),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. HEADER KLASIFIKASI SUBJEK DEWEY & ILUSTRASI EDITORIAL
          AnimatedCategoryWaveCharacterHeader(
            selectedCategory: _selectedCategory,
            volumeCount: books.length,
          ),

          // 2. BARISAN FILTER SUBJEK (Tanpa Pill-in-Pill Berwarna Mencolok)
          SizedBox(
            height: 40,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 3),
              scrollDirection: Axis.horizontal,
              itemCount: BookRepository.supportedCategories.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final cat = BookRepository.supportedCategories[index];
                final isSelected = _selectedCategory == cat;
                final count = _countForCategory(cat);
                return GestureDetector(
                  onTap: () => setState(() => _selectedCategory = cat),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(horizontal: 13),
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
                    child: Row(
                      children: [
                        Text(
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
                        const SizedBox(width: 6),
                        Text(
                          '[$count]',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color: isSelected
                                ? const Color(0xFFD6A85A)
                                : LibrisTheme.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // 3. BARIS JUMLAH VOLUME & PENGURUTAN (Garis 1px Editorial)
          Container(
            margin: const EdgeInsets.fromLTRB(18, 10, 18, 4),
            padding: const EdgeInsets.only(bottom: 8),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: LibrisTheme.borderCrisp, width: 1.0),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'MENAMPILKAN ${books.length} VOLUME BUKU',
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    color: LibrisTheme.textSecondary,
                    letterSpacing: 0.8,
                  ),
                ),
                PopupMenuButton<String>(
                  initialValue: _sortBy,
                  onSelected: (val) => setState(() => _sortBy = val),
                  itemBuilder: (context) => const [
                    PopupMenuItem(
                      value: 'Rating Tertinggi',
                      child: Text('Rating Tertinggi'),
                    ),
                    PopupMenuItem(
                      value: 'Tahun Terbaru',
                      child: Text('Tahun Terbaru'),
                    ),
                    PopupMenuItem(
                      value: 'Judul (A-Z)',
                      child: Text('Judul (A-Z)'),
                    ),
                  ],
                  child: Row(
                    children: [
                      const Icon(
                        Icons.sort_rounded,
                        size: 15,
                        color: LibrisTheme.primaryInk,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        _sortBy,
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: LibrisTheme.primaryInk,
                        ),
                      ),
                      const SizedBox(width: 2),
                      const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 16,
                        color: LibrisTheme.textMuted,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 4. GRID FOLIO / DAFTAR LEDGER BUKU
          Expanded(
            child: RefreshIndicator(
              color: LibrisTheme.primaryInk,
              backgroundColor: LibrisTheme.surfaceCard,
              onRefresh: _fetchCategoryFromGoogleBooks,
              child: _isGridView
                  ? GridView.builder(
                      padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 20,
                            crossAxisSpacing: 16,
                            childAspectRatio: 0.58,
                          ),
                      itemCount: books.length,
                      itemBuilder: (context, index) {
                        return _buildGridBookCard(books[index]);
                      },
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(18, 4, 18, 28),
                      itemCount: books.length,
                      itemBuilder: (context, index) {
                        return _buildListBookCard(books[index], index);
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }

  /// Sel Grid Folio — Sampul buku di atas bidang kertas tonal tanpa kotak berbingkai biru
  Widget _buildGridBookCard(BookVolume book) {
    final isSaved = widget.savedBookIds.contains(book.id);
    return GestureDetector(
      onTap: () => _openDetail(book),
      behavior: HitTestBehavior.opaque,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: BoxDecoration(
                color: LibrisTheme.skyCanvas,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: LibrisTheme.borderCrisp,
                  width: 0.8,
                ),
              ),
              child: Center(
                child: FlatBookCover(
                  book: book,
                  width: double.infinity,
                  height: double.infinity,
                  borderRadius: 5,
                  showCategoryBadge: true,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text(
                  book.volumeInfo.primaryCategory.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 9.0,
                    fontWeight: FontWeight.w800,
                    color: LibrisTheme.primarySkyDark,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () {
                  widget.onToggleSave(book.id);
                  setState(() {});
                },
                child: Icon(
                  isSaved
                      ? Icons.bookmark_rounded
                      : Icons.bookmark_border_rounded,
                  size: 17,
                  color: isSaved
                      ? LibrisTheme.accentTerracotta
                      : LibrisTheme.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            book.volumeInfo.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'Georgia',
              fontSize: 14,
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
          const SizedBox(height: 5),
          Row(
            children: [
              const Icon(
                Icons.star_rounded,
                size: 13,
                color: LibrisTheme.accentGold,
              ),
              const SizedBox(width: 3),
              Text(
                '${book.volumeInfo.averageRating}',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: LibrisTheme.primaryInk,
                ),
              ),
              const Spacer(),
              Text(
                '${book.volumeInfo.pageCount} hlm',
                style: const TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w500,
                  color: LibrisTheme.textMuted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Baris Daftar Indeks (Ledger Row) dengan garis pemisah 1px
  Widget _buildListBookCard(BookVolume book, int index) {
    final isSaved = widget.savedBookIds.contains(book.id);
    final numLabel = (index + 1).toString().padLeft(2, '0');

    return GestureDetector(
      onTap: () => _openDetail(book),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(color: LibrisTheme.borderCrisp, width: 1.0),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 24,
              child: Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  numLabel,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: LibrisTheme.textMuted,
                  ),
                ),
              ),
            ),
            FlatBookCover(
              book: book,
              width: 64,
              height: 92,
              borderRadius: 5,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    book.volumeInfo.primaryCategory.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
                      color: LibrisTheme.primarySkyDark,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    book.volumeInfo.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Georgia',
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: LibrisTheme.primaryInk,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${book.volumeInfo.primaryAuthor} • ${book.volumeInfo.publishedYear} • ${book.volumeInfo.pageCount} hlm',
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: LibrisTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () {
                widget.onToggleSave(book.id);
                setState(() {});
              },
              icon: Icon(
                isSaved
                    ? Icons.bookmark_rounded
                    : Icons.bookmark_border_rounded,
                size: 20,
                color: isSaved
                    ? LibrisTheme.accentTerracotta
                    : LibrisTheme.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
