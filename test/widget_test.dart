import 'package:flutter_test/flutter_test.dart';
import 'package:libris_app/main.dart';

void main() {
  testWidgets(
    'LibrisApp renders Storybook Character Hero, interactive motion, CategoryPage, DetailPage, and OnboardingStoryPage',
    (WidgetTester tester) async {
      await tester.pumpWidget(const LibrisApp());
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pump(const Duration(milliseconds: 600));

      // 1. Verifikasi Halaman Beranda & Hero Karakter ("Magic of Reading")
      expect(find.text('Libris.'), findsOneWidget);
      expect(find.text('Magic of Reading'), findsOneWidget);
      expect(find.text('GOOGLE BOOKS v1'), findsNothing);

      // Verifikasi interaksi Lampu Baca pada Hero Karakter
      expect(find.text('Lamp: ON'), findsOneWidget);
      await tester.tap(find.text('Lamp: ON'));
      await tester.pump(const Duration(milliseconds: 350));
      expect(find.text('Lamp: OFF'), findsOneWidget);

      // 2. Navigasi ke Halaman Kategori Subjek (CategoryPage) melalui NavigationBar
      await tester.tap(find.text('Kategori Subjek'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.text('Kategori Subjek Buku'), findsOneWidget);

      // Kembali ke Beranda
      await tester.pageBack();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      // 3. Navigasi ke Halaman Detail Buku (DetailPage dengan Fanned 3-Card Story Header)
      await tester.tap(find.text('Baca'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.text('Detail Volume Buku'), findsOneWidget);
      expect(find.text('Tags & Metadata'), findsOneWidget);
      expect(find.text('Sinopsis & Ringkasan Isi'), findsOneWidget);

      // Kembali ke Beranda lalu buka Story Tour (Onboarding Karakter)
      await tester.pageBack();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      await tester.tap(find.text('STORY TOUR'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.text('Immersion reading'), findsOneWidget);
    },
  );
}
