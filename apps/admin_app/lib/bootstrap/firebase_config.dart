import 'package:firebase_provider/firebase_provider.dart';

import 'admin_flavor.dart';

class MissingFirebaseConfigException implements Exception {
  const MissingFirebaseConfigException(this.flavor);

  final AdminFlavor flavor;

  @override
  String toString() =>
      'Missing Firebase config for the ${flavor.name} flavor. '
      'Run with --dart-define-from-file=config/${flavor.name}.json (see config/example.json).';
}

/// Resolves Firebase options from --dart-define values, so no native config file is bundled.
class AdminFirebaseConfig {
  static const _apiKey = String.fromEnvironment('FIREBASE_API_KEY');
  static const _appId = String.fromEnvironment('FIREBASE_APP_ID');
  static const _messagingSenderId = String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID');
  static const _projectId = String.fromEnvironment('FIREBASE_PROJECT_ID');
  static const _storageBucket = String.fromEnvironment('FIREBASE_STORAGE_BUCKET');

  // The emulators accept any well-formed values; a demo project never reaches real services.
  static const _emulatorOptions = FirebaseOptions(
    apiKey: 'AIzaSyDemoKeyForLocalEmulatorUseOnly000',
    appId: '1:000000000000:ios:0000000000000000000000',
    messagingSenderId: '000000000000',
    projectId: 'demo-stepstones',
    storageBucket: 'demo-stepstones.firebasestorage.app',
  );

  static FirebaseOptions resolve(AdminFlavor flavor) {
    final hasConfig = [_apiKey, _appId, _messagingSenderId, _projectId].every((value) => value.isNotEmpty);
    if (hasConfig) {
      return const FirebaseOptions(
        apiKey: _apiKey,
        appId: _appId,
        messagingSenderId: _messagingSenderId,
        projectId: _projectId,
        storageBucket: _storageBucket == '' ? null : _storageBucket,
      );
    }
    if (flavor.usesEmulator) {
      return _emulatorOptions;
    }
    throw MissingFirebaseConfigException(flavor);
  }
}
