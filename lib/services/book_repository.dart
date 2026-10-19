import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import '../models/book_volume.dart';
import 'libris_database_service.dart';

/// Repositori Data Buku Libris
/// Mendukung sinkronisasi hybrid:
/// 1. Berkas JSON lokal (assets/data/books_volumes.json) sebagai seed dasar.
/// 2. Google Books API v1 (REST endpoint) melalui asynchronous programming.
/// 3. Basis data SQLite lokal (libris_catalog.db) untuk persistensi offline & sinkronisasi data.
class BookRepository {
  final http.Client? _httpClient;
  final LibrisDatabaseService _dbService;

  BookRepository({
    http.Client? client,
    LibrisDatabaseService? dbService,
  })  : _httpClient = client,
        _dbService = dbService ?? LibrisDatabaseService.instance;

  static const String localJsonAssetPath = 'assets/data/books_volumes.json';

  /// Endpoint resmi Google Books API v1
  static const String googleBooksBaseUrl =
      'https://www.googleapis.com/books/v1/volumes';

  /// Daftar kategori subjek buku yang tersedia pada aplikasi Libris
  static const List<String> categories = [
    'Semua',
    'Computer Science',
    'Psychology',
    'Self-Growth',
    'Fiction',
  ];

  static const List<String> supportedCategories = categories;

  /// Membentuk URL endpoint Google Books API berdasarkan subjek/kategori
  static String buildGoogleBooksCategoryEndpoint(
    String category, {
    int maxResults = 20,
    int startIndex = 0,
  }) {
    final query = category == 'Semua' ? 'subject:computer+science' : 'subject:$category';
    final encodedSubject = Uri.encodeQueryComponent(query);
    return '$googleBooksBaseUrl?q=$encodedSubject&startIndex=$startIndex&maxResults=$maxResults&printType=books';
  }

  /// Membentuk URL endpoint Google Books API untuk pencarian kata kunci
  static String buildGoogleBooksSearchEndpoint(
    String query, {
    int maxResults = 20,
  }) {
    final encodedQuery = Uri.encodeQueryComponent(query);
    return '$googleBooksBaseUrl?q=$encodedQuery&maxResults=$maxResults&printType=books';
  }

  /// Memuat dan mem-parsing daftar buku dari berkas JSON lokal
  Future<List<BookVolume>> loadBooksFromLocalJson() async {
    final String jsonString = await rootBundle.loadString(localJsonAssetPath);
    final Map<String, dynamic> decodedMap =
        json.decode(jsonString) as Map<String, dynamic>;
    final BookVolumeResponse response = BookVolumeResponse.fromJson(decodedMap);
    return response.items;
  }

  Future<List<BookVolume>> loadLocalVolumes() => loadBooksFromLocalJson();

  /// Memuat katalog utama dengan persistensi SQLite:
  /// 1. Melakukan seeding dari berkas JSON lokal jika SQLite kosong.
  /// 2. Mengembalikan semua buku dari SQLite.
  Future<List<BookVolume>> loadCatalogWithDatabase() async {
    final localSeedBooks = await loadBooksFromLocalJson();
    await _dbService.seedInitialBooksIfEmpty(localSeedBooks);
    final booksFromDb = await _dbService.getAllBooks();
    if (booksFromDb.isNotEmpty) {
      return booksFromDb;
    }
    return localSeedBooks;
  }

  /// Mengambil buku lebih banyak dari Google Books API v1 secara asynchronous,
  /// mem-parsing hasilnya, dan menyimpannya secara otomatis ke database SQLite.
  Future<List<BookVolume>> fetchGoogleBooksByCategory(
    String category, {
    int maxResults = 20,
    int startIndex = 0,
  }) async {
    final endpoint = buildGoogleBooksCategoryEndpoint(
      category,
      maxResults: maxResults,
      startIndex: startIndex,
    );

    try {
      final client = _httpClient ?? http.Client();
      final response = await client
          .get(
            Uri.parse(endpoint),
            headers: {'Accept': 'application/json'},
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data =
            json.decode(response.body) as Map<String, dynamic>;
        final rawItems = data['items'] as List<dynamic>? ?? const [];

        final effectiveCategory = category == 'Semua' ? 'Computer Science' : category;

        final fetchedBooks = rawItems
            .map(
              (item) => BookVolume.fromGoogleApiJson(
                item as Map<String, dynamic>,
                fallbackCategory: effectiveCategory,
              ),
            )
            .where((b) => b.volumeInfo.title.trim().isNotEmpty)
            .toList();

        if (fetchedBooks.isNotEmpty) {
          // Sinkronisasi & simpan ke database SQLite
          await _dbService.upsertBooks(fetchedBooks, source: 'google_api');
        }

        // Ambil data terbaru dari SQLite agar state konsisten
        final allFromDb = await _dbService.getAllBooks();
        return allFromDb;
      } else {
        debugPrint(
          'Google Books API HTTP error: ${response.statusCode} - ${response.body}',
        );
        return await _dbService.getAllBooks();
      }
    } catch (e) {
      debugPrint('Google Books API fetch failed (offline/error): $e');
      // Jika jaringan gagal/offline, tetap kembalikan data yang ada di database SQLite
      return await _dbService.getAllBooks();
    }
  }

  /// Mengambil kumpulan buku dari berbagai kategori subjek secara bersamaan (parallel asynchronous)
  /// untuk memperkaya katalog buku secara signifikan (40-60+ buku tersimpan).
  Future<List<BookVolume>> fetchMultiCategoryGoogleBooks({
    int booksPerCategory = 10,
  }) async {
    final targetCategories = [
      'Computer Science',
      'Psychology',
      'Self-Growth',
      'Fiction',
    ];

    try {
      final futures = targetCategories.map((cat) {
        return fetchGoogleBooksByCategory(cat, maxResults: booksPerCategory);
      });
      await Future.wait(futures);
    } catch (e) {
      debugPrint('MultiCategory fetch error: $e');
    }

    return await _dbService.getAllBooks();
  }

  /// Mencari buku dari Google Books API v1 berdasarkan kata kunci pencarian
  Future<List<BookVolume>> searchGoogleBooksOnline(
    String query, {
    int maxResults = 20,
  }) async {
    if (query.trim().isEmpty) {
      return await _dbService.getAllBooks();
    }

    final endpoint = buildGoogleBooksSearchEndpoint(query, maxResults: maxResults);
    try {
      final client = _httpClient ?? http.Client();
      final response = await client
          .get(
            Uri.parse(endpoint),
            headers: {'Accept': 'application/json'},
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data =
            json.decode(response.body) as Map<String, dynamic>;
        final rawItems = data['items'] as List<dynamic>? ?? const [];

        final fetchedBooks = rawItems
            .map(
              (item) => BookVolume.fromGoogleApiJson(
                item as Map<String, dynamic>,
                fallbackCategory: 'General',
              ),
            )
            .where((b) => b.volumeInfo.title.trim().isNotEmpty)
            .toList();

        if (fetchedBooks.isNotEmpty) {
          await _dbService.upsertBooks(fetchedBooks, source: 'google_api');
        }
        return await _dbService.getAllBooks();
      }
    } catch (e) {
      debugPrint('Online search failed: $e');
    }

    return await _dbService.getAllBooks();
  }
}
