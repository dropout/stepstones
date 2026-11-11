import 'dart:ui' show Size;

// This test-only entry point uses core's flutter_test dev dependency.
// ignore: depend_on_referenced_packages
import 'package:flutter_test/flutter_test.dart';

/// Configures a widget test's viewport in logical pixels and resets it at teardown.
///
/// The default represents a portrait phone; use smaller sizes in separate
/// tests to verify layouts on constrained screens.
void setTestViewport(WidgetTester tester, {Size logicalSize = const Size(390, 844), double devicePixelRatio = 1}) {
  if (!logicalSize.width.isFinite ||
      !logicalSize.height.isFinite ||
      logicalSize.width <= 0 ||
      logicalSize.height <= 0 ||
      !devicePixelRatio.isFinite ||
      devicePixelRatio <= 0) {
    throw ArgumentError('Viewport dimensions and device pixel ratio must be finite and positive.');
  }

  tester.view.devicePixelRatio = devicePixelRatio;
  tester.view.physicalSize = logicalSize * devicePixelRatio;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}
