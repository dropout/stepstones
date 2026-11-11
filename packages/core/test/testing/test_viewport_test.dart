import 'package:core/testing.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('sets the default logical viewport and resets it at teardown', (tester) async {
    final originalSize = tester.view.physicalSize;
    final originalRatio = tester.view.devicePixelRatio;
    addTearDown(() {
      expect(tester.view.physicalSize, originalSize);
      expect(tester.view.devicePixelRatio, originalRatio);
    });

    setTestViewport(tester);
    await tester.pumpWidget(const SizedBox.expand());

    expect(tester.getSize(find.byType(SizedBox)), const Size(390, 844));
    expect(tester.view.devicePixelRatio, 1);
  });

  testWidgets('supports a custom logical size and pixel ratio', (tester) async {
    setTestViewport(tester, logicalSize: const Size(320, 640), devicePixelRatio: 2);
    await tester.pumpWidget(const SizedBox.expand());

    expect(tester.getSize(find.byType(SizedBox)), const Size(320, 640));
    expect(tester.view.physicalSize, const Size(640, 1280));
    expect(tester.view.devicePixelRatio, 2);
  });

  testWidgets('rejects invalid viewport dimensions and pixel ratios', (tester) async {
    expect(() => setTestViewport(tester, logicalSize: Size.zero), throwsArgumentError);
    expect(() => setTestViewport(tester, devicePixelRatio: double.infinity), throwsArgumentError);
  });
}
