import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:libris_app/main.dart';

void main() {
  testWidgets('Verify no overflow on small screen width (320px)', (tester) async {
    // Set small screen size (320 x 568)
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(const LibrisApp());
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump(const Duration(milliseconds: 600));

    // Verify HomePage renders without RenderFlex overflow
    expect(find.text('Libris.'), findsOneWidget);
    expect(find.text('Magic of Reading'), findsOneWidget);
    expect(find.text('Baca'), findsOneWidget);

    // Tap 'Baca' to navigate to DetailPage
    await tester.tap(find.text('Baca'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    // Verify DetailPage renders without overflow
    expect(find.text('Detail Volume Buku'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Sinopsis & Ringkasan Isi'), 100);
    expect(find.text('Sinopsis & Ringkasan Isi'), findsOneWidget);
  });
}
