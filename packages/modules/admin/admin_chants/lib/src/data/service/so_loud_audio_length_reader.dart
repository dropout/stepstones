import 'dart:typed_data';

import 'package:flutter_soloud/flutter_soloud.dart';

/// Reads the length with the same decoder the mobile app plays chants with.
Future<Duration> readAudioLengthWithSoLoud(Uint8List audioBytes) async {
  final soLoud = SoLoud.instance;
  if (!soLoud.isInitialized) {
    await soLoud.init();
  }
  final source = await soLoud.loadMem('chant-length-probe.mp3', audioBytes);
  try {
    return soLoud.getLength(source);
  } finally {
    await soLoud.disposeSource(source);
  }
}
