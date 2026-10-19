import 'package:flutter_test/flutter_test.dart';
import 'package:libris_app/services/book_repository.dart';
import 'package:libris_app/services/libris_database_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Simulate unbookmark and reload catalog', () async {
    final repo = BookRepository();
    final db = LibrisDatabaseService.instance;

    // 1. First load
    final books1 = await repo.loadCatalogWithDatabase();
    final cleanArch1 = books1.firstWhere((b) => b.id == 'gb_cs_01');
    expect(cleanArch1.id, 'gb_cs_01');

    // 2. Unbookmark gb_cs_01
    await db.setBookmark('gb_cs_01', false);

    // 3. Check directly from db
    final booksFromDb = await db.getAllBooks();
    final cleanArchDb = booksFromDb.firstWhere((b) => b.id == 'gb_cs_01');
    expect(cleanArchDb.readingState.isBookmarked, isFalse);

    // 4. Reload via repository (simulating app restart)
    final booksReloaded = await repo.loadCatalogWithDatabase();
    final cleanArchReloaded = booksReloaded.firstWhere((b) => b.id == 'gb_cs_01');
    expect(cleanArchReloaded.readingState.isBookmarked, isFalse);
  });
}
