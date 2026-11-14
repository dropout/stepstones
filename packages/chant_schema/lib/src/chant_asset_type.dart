/// Firestore collection that holds the chant catalog.
const chantsCollection = 'chants';

/// The three files of a chant.
enum ChantAssetType {
  audio('chant.mp3'),
  lyrics('chant.ass'),
  cover('cover.jpg');

  const ChantAssetType(this.fileName);

  final String fileName;

  /// Storage path of this file for the chant with [chantId].
  String storagePath(String chantId) => '/$chantsCollection/$chantId/$fileName';

  /// Names of this file's fields inside a chant document's `metaData` map.
  String get versionField => '${name}Version';
  String get sha256Field => '${name}Sha256';
  String get bytesField => '${name}Bytes';
}
