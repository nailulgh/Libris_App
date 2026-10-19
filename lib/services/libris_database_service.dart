import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../models/book_volume.dart';

/// Layanan Manajemen Basis Data SQLite Lokal Libris
/// Bertanggung jawab menyimpan, menyinkronkan katalog buku, bookmark koleksi,
/// dan progres bacaan aktif sehingga data persisten saat aplikasi dibuka kembali atau direfresh.
class LibrisDatabaseService {
  LibrisDatabaseService._internal();
  static final LibrisDatabaseService instance = LibrisDatabaseService._internal();

  static const String _dbFileName = 'libris_catalog.db';
  static const int _dbVersion = 1;

  Database? _db;
  bool _isFfiInitialized = false;

  // Fallback in-memory map jika platform tidak mendukung SQLite (misal Web murni)
  final Map<String, BookVolume> _memoryBooks = {};
  final Map<String, String> _memoryMeta = {};
  File? _mirrorFile;

  Future<File?> _getMirrorFile() async {
    if (_mirrorFile != null) return _mirrorFile;
    try {
      final databasesPath = await getDatabasesPath();
      final dir = Directory(databasesPath);
      if (!dir.existsSync()) {
        dir.createSync(recursive: true);
      }
      _mirrorFile = File(p.join(databasesPath, 'libris_state_mirror.json'));
      return _mirrorFile;
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>> _loadMirrorData() async {
    try {
      final file = await _getMirrorFile();
      if (file != null && file.existsSync()) {
        final content = await file.readAsString();
        if (content.isNotEmpty) {
          return jsonDecode(content) as Map<String, dynamic>;
        }
      }
    } catch (_) {}
    return {};
  }

  Future<void> _saveMirrorData({
    Set<String>? savedIds,
    Map<String, int>? readingPages,
    String? activeId,
  }) async {
    try {
      final file = await _getMirrorFile();
      if (file == null) return;
      final current = await _loadMirrorData();
      if (savedIds != null) {
        current['saved_ids'] = savedIds.toList();
      }
      if (readingPages != null) {
        final existingPages = (current['pages'] as Map<String, dynamic>?) ?? {};
        readingPages.forEach((k, v) => existingPages[k] = v);
        current['pages'] = existingPages;
      }
      if (activeId != null) {
        current['active_reading_book_id'] = activeId;
      }
      await file.writeAsString(jsonEncode(current), flush: true);
    } catch (_) {}
  }

  Future<Database?> _getDatabase() async {
    if (kIsWeb) {
      return null;
    }

    if (_db != null && _db!.isOpen) {
      return _db;
    }

    try {
      // Inisialisasi FFI untuk desktop Windows/Linux dan pengujian flutter test
      if (!_isFfiInitialized && (Platform.isWindows || Platform.isLinux)) {
        sqfliteFfiInit();
        databaseFactory = databaseFactoryFfi;
        _isFfiInitialized = true;
      }

      final databasesPath = await getDatabasesPath();
      final dbPath = p.join(databasesPath, _dbFileName);

      _db = await openDatabase(
        dbPath,
        version: _dbVersion,
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE books (
              id TEXT PRIMARY KEY,
              title TEXT,
              category TEXT,
              volume_json TEXT NOT NULL,
              is_bookmarked INTEGER DEFAULT 0,
              current_page INTEGER DEFAULT 0,
              last_read_at INTEGER DEFAULT 0,
              source TEXT DEFAULT 'local'
            )
          ''');

          await db.execute('''
            CREATE TABLE app_meta (
              meta_key TEXT PRIMARY KEY,
              meta_value TEXT NOT NULL
            )
          ''');
        },
      );
      return _db;
    } catch (e) {
      debugPrint('LibrisDatabaseService: Menggunakan in-memory fallback ($e)');
      return null;
    }
  }

  /// Melakukan inisialisasi awal database dari berkas seed lokal jika tabel masih kosong
  Future<void> seedInitialBooksIfEmpty(List<BookVolume> seedBooks) async {
    final mirror = await _loadMirrorData();
    final mirrorSaved = mirror['saved_ids'] != null
        ? Set<String>.from(mirror['saved_ids'] as List)
        : null;

    final db = await _getDatabase();
    if (db == null) {
      if (_memoryBooks.isEmpty) {
        for (final b in seedBooks) {
          final isSaved = mirrorSaved != null ? mirrorSaved.contains(b.id) : b.readingState.isBookmarked;
          _memoryBooks[b.id] = b.copyWith(
            readingState: b.readingState.copyWith(isBookmarked: isSaved),
          );
        }
        if (seedBooks.isNotEmpty) {
          _memoryMeta['active_reading_book_id'] = mirror['active_reading_book_id'] as String? ?? seedBooks.first.id;
        }
        if (mirrorSaved == null) {
          final initialSaved = seedBooks.where((b) => b.readingState.isBookmarked).map((b) => b.id).toSet();
          await _saveMirrorData(savedIds: initialSaved);
        }
      }
      return;
    }

    final countResult = await db.rawQuery('SELECT COUNT(*) as cnt FROM books');
    final count = Sqflite.firstIntValue(countResult) ?? 0;

    if (count == 0 && seedBooks.isNotEmpty) {
      final initialSaved = mirrorSaved ??
          seedBooks
              .where((b) => b.readingState.isBookmarked)
              .map((b) => b.id)
              .toSet();

      final batch = db.batch();
      for (final book in seedBooks) {
        final isBookmarked = initialSaved.contains(book.id);
        batch.insert(
          'books',
          {
            'id': book.id,
            'title': book.volumeInfo.title,
            'category': book.volumeInfo.primaryCategory,
            'volume_json': jsonEncode(book.copyWith(
              readingState: book.readingState.copyWith(isBookmarked: isBookmarked),
            ).toJson()),
            'is_bookmarked': isBookmarked ? 1 : 0,
            'current_page': book.readingState.currentPage,
            'last_read_at': book.readingState.lastReadAt,
            'source': 'local',
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      final activeId = mirror['active_reading_book_id'] as String? ??
          seedBooks
              .firstWhere(
                (b) => b.readingState.currentPage > 0,
                orElse: () => seedBooks.first,
              )
              .id;

      batch.insert(
        'app_meta',
        {
          'meta_key': 'active_reading_book_id',
          'meta_value': activeId,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      await batch.commit(noResult: true);
      if (mirrorSaved == null) {
        await _saveMirrorData(savedIds: initialSaved, activeId: activeId);
      }
    }
  }

  /// Mengambil semua buku dari database lokal
  Future<List<BookVolume>> getAllBooks() async {
    final mirror = await _loadMirrorData();
    final mirrorSaved = mirror['saved_ids'] != null
        ? Set<String>.from(mirror['saved_ids'] as List)
        : null;
    final mirrorPages = mirror['pages'] != null
        ? Map<String, int>.from(mirror['pages'] as Map)
        : null;

    final db = await _getDatabase();
    if (db == null) {
      final list = _memoryBooks.values.toList();
      return list.map((b) {
        bool bookmarked = b.readingState.isBookmarked;
        int page = b.readingState.currentPage;
        if (mirrorSaved != null) {
          bookmarked = mirrorSaved.contains(b.id);
        }
        if (mirrorPages != null && mirrorPages.containsKey(b.id)) {
          page = mirrorPages[b.id]!;
        }
        return b.copyWith(
          readingState: b.readingState.copyWith(
            isBookmarked: bookmarked,
            currentPage: page,
          ),
        );
      }).toList();
    }

    final maps = await db.query('books', orderBy: 'title ASC');
    final List<BookVolume> results = [];

    for (final row in maps) {
      try {
        final id = row['id'] as String;
        final jsonStr = row['volume_json'] as String;
        final decoded = jsonDecode(jsonStr) as Map<String, dynamic>;
        final baseBook = BookVolume.fromJson(decoded);

        // Pertahankan status persisten dari kolom SQLite / mirror
        bool isBookmarked = (row['is_bookmarked'] as int? ?? 0) == 1;
        int currentPage = row['current_page'] as int? ?? 0;
        final lastReadAt = row['last_read_at'] as int? ?? 0;

        if (mirrorSaved != null) {
          isBookmarked = mirrorSaved.contains(id);
        }
        if (mirrorPages != null && mirrorPages.containsKey(id)) {
          currentPage = mirrorPages[id]!;
        }

        final book = baseBook.copyWith(
          readingState: baseBook.readingState.copyWith(
            isBookmarked: isBookmarked,
            currentPage: currentPage,
            lastReadAt: lastReadAt,
          ),
        );
        results.add(book);
      } catch (err) {
        debugPrint('Error parsing book from db: $err');
      }
    }
    return results;
  }

  /// Upsert kumpulan buku (misal dari Google Books API).
  /// Mempertahankan bookmark & progres bacaan pengguna yang sudah ada sebelumnya.
  Future<void> upsertBooks(
    List<BookVolume> books, {
    String source = 'google_api',
  }) async {
    final mirror = await _loadMirrorData();
    final mirrorSaved = mirror['saved_ids'] != null
        ? Set<String>.from(mirror['saved_ids'] as List)
        : null;

    final db = await _getDatabase();
    if (db == null) {
      for (final book in books) {
        bool bookmarked = book.readingState.isBookmarked;
        int page = book.readingState.currentPage;
        int lastRead = book.readingState.lastReadAt;

        if (_memoryBooks.containsKey(book.id)) {
          final existing = _memoryBooks[book.id]!;
          bookmarked = existing.readingState.isBookmarked;
          page = existing.readingState.currentPage;
          lastRead = existing.readingState.lastReadAt;
        }
        if (mirrorSaved != null) {
          bookmarked = mirrorSaved.contains(book.id);
        }

        _memoryBooks[book.id] = book.copyWith(
          readingState: book.readingState.copyWith(
            isBookmarked: bookmarked,
            currentPage: page,
            lastReadAt: lastRead,
          ),
        );
      }
      return;
    }

    for (final book in books) {
      // Cek apakah buku sudah ada
      final existing = await db.query(
        'books',
        columns: ['is_bookmarked', 'current_page', 'last_read_at'],
        where: 'id = ?',
        whereArgs: [book.id],
        limit: 1,
      );

      bool bookmarked = book.readingState.isBookmarked;
      int page = book.readingState.currentPage;
      int lastRead = book.readingState.lastReadAt;

      if (existing.isNotEmpty) {
        bookmarked = (existing.first['is_bookmarked'] as int? ?? 0) == 1;
        page = existing.first['current_page'] as int? ?? page;
        lastRead = existing.first['last_read_at'] as int? ?? lastRead;
      }
      if (mirrorSaved != null) {
        bookmarked = mirrorSaved.contains(book.id);
      }

      final mergedBook = book.copyWith(
        readingState: book.readingState.copyWith(
          isBookmarked: bookmarked,
          currentPage: page,
          lastReadAt: lastRead,
        ),
      );

      await db.insert(
        'books',
        {
          'id': mergedBook.id,
          'title': mergedBook.volumeInfo.title,
          'category': mergedBook.volumeInfo.primaryCategory,
          'volume_json': jsonEncode(mergedBook.toJson()),
          'is_bookmarked': bookmarked ? 1 : 0,
          'current_page': page,
          'last_read_at': lastRead,
          'source': source,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  /// Mengambil semua ID buku yang dibookmark
  Future<Set<String>> getBookmarkedBookIds() async {
    final books = await getAllBooks();
    return books
        .where((b) => b.readingState.isBookmarked)
        .map((b) => b.id)
        .toSet();
  }

  /// Mengambil ID bookmark dari mirror secara cepat (tanpa membuka DB)
  Future<Set<String>?> getPersistedBookmarkedIds() async {
    final mirror = await _loadMirrorData();
    if (mirror['saved_ids'] != null) {
      return Set<String>.from(mirror['saved_ids'] as List);
    }
    return null;
  }

  /// Mengubah status bookmark suatu buku
  Future<void> setBookmark(String bookId, bool isBookmarked) async {
    // 1. Perbarui in-memory
    if (_memoryBooks.containsKey(bookId)) {
      final b = _memoryBooks[bookId]!;
      _memoryBooks[bookId] = b.copyWith(
        readingState: b.readingState.copyWith(isBookmarked: isBookmarked),
      );
    }

    // 2. Perbarui SQLite jika ada
    final db = await _getDatabase();
    if (db != null) {
      await db.update(
        'books',
        {'is_bookmarked': isBookmarked ? 1 : 0},
        where: 'id = ?',
        whereArgs: [bookId],
      );
    }

    // 3. Simpan ke mirror file secara persisten
    final currentMirror = await _loadMirrorData();
    final savedSet = currentMirror['saved_ids'] != null
        ? Set<String>.from(currentMirror['saved_ids'] as List)
        : <String>{};
    if (isBookmarked) {
      savedSet.add(bookId);
    } else {
      savedSet.remove(bookId);
    }
    await _saveMirrorData(savedIds: savedSet);
  }

  /// Memperbarui progres bacaan (halaman terkini) dan menjadikannya bacaan terkini
  Future<void> updateReadingProgress(String bookId, int currentPage) async {
    final nowTimestamp = DateTime.now().millisecondsSinceEpoch;
    await _saveMirrorData(
      readingPages: {bookId: currentPage},
      activeId: bookId,
    );

    final db = await _getDatabase();
    if (db == null) {
      if (_memoryBooks.containsKey(bookId)) {
        final b = _memoryBooks[bookId]!;
        _memoryBooks[bookId] = b.copyWith(
          readingState: b.readingState.copyWith(
            currentPage: currentPage,
            lastReadAt: nowTimestamp,
          ),
        );
      }
      _memoryMeta['active_reading_book_id'] = bookId;
      return;
    }

    await db.update(
      'books',
      {
        'current_page': currentPage,
        'last_read_at': nowTimestamp,
      },
      where: 'id = ?',
      whereArgs: [bookId],
    );

    await setActiveReadingBookId(bookId);
  }

  /// Mengatur ID buku yang aktif sedang dibaca pada hero section
  Future<void> setActiveReadingBookId(String bookId) async {
    await _saveMirrorData(activeId: bookId);

    final db = await _getDatabase();
    if (db == null) {
      _memoryMeta['active_reading_book_id'] = bookId;
      return;
    }

    await db.insert(
      'app_meta',
      {
        'meta_key': 'active_reading_book_id',
        'meta_value': bookId,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Mengambil ID buku aktif yang tersimpan
  Future<String?> getActiveReadingBookId() async {
    final db = await _getDatabase();
    if (db == null) {
      return _memoryMeta['active_reading_book_id'];
    }

    final res = await db.query(
      'app_meta',
      where: 'meta_key = ?',
      whereArgs: ['active_reading_book_id'],
      limit: 1,
    );
    if (res.isNotEmpty) {
      return res.first['meta_value'] as String?;
    }
    return null;
  }

  /// Menentukan buku yang aktif ditampilkan pada Hero Section:
  /// 1. Berdasarkan `active_reading_book_id` di database.
  /// 2. Jika tidak ada, cari buku dengan `last_read_at` tertinggi (> 0).
  /// 3. Jika tidak ada, cari buku dengan `currentPage` > 0.
  /// 4. Fallback ke buku pertama.
  Future<BookVolume?> resolveActiveReadingBook(List<BookVolume> books) async {
    if (books.isEmpty) return null;

    final activeId = await getActiveReadingBookId();
    if (activeId != null && activeId.isNotEmpty) {
      final found = books.where((b) => b.id == activeId).toList();
      if (found.isNotEmpty) return found.first;
    }

    // Urutkan berdasarkan waktu terakhir dibaca
    final sortedByLastRead = List<BookVolume>.from(books)
      ..sort((a, b) => b.readingState.lastReadAt.compareTo(a.readingState.lastReadAt));
    if (sortedByLastRead.first.readingState.lastReadAt > 0) {
      return sortedByLastRead.first;
    }

    // Cari dengan progres > 0
    final readingBooks = books.where((b) => b.readingState.currentPage > 0).toList();
    if (readingBooks.isNotEmpty) {
      return readingBooks.first;
    }

    return books.first;
  }
}
