import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart' show rootBundle;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Verify all 5 illustration PNG assets can be loaded from asset bundle', () async {
    const assets = [
      'lib/assets/story_immersion.png',
      'lib/assets/story_curated_index.png',
      'lib/assets/story_literary_journal.png',
      'lib/assets/hero_cozy_reader.png',
      'lib/assets/hero_category_explorer.png',
    ];

    for (final asset in assets) {
      final byteData = await rootBundle.load(asset);
      expect(byteData.lengthInBytes, greaterThan(1000));
      // Verify PNG magic header: 0x89, 0x50, 0x4E, 0x47
      final header = byteData.buffer.asUint8List(0, 4);
      expect(header[0], 0x89);
      expect(header[1], 0x50);
      expect(header[2], 0x4E);
      expect(header[3], 0x47);
    }
  });

  testWidgets('Verify Image.asset renders 5 illustrations without crashing', (tester) async {
    const assets = [
      'lib/assets/story_immersion.png',
      'lib/assets/story_curated_index.png',
      'lib/assets/story_literary_journal.png',
      'lib/assets/hero_cozy_reader.png',
      'lib/assets/hero_category_explorer.png',
    ];

    for (final asset in assets) {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Image.asset(asset),
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(Image), findsOneWidget);
    }
  });
}
