import 'package:chant_schema/chant_schema.dart';

export 'package:chant_schema/chant_schema.dart' show ChantAssetType;

/// What the admin app needs to pick and upload each chant file.
extension ChantAssetUpload on ChantAssetType {
  List<String> get extensions => switch (this) {
    .audio => const ['mp3'],
    .lyrics => const ['ass'],
    .cover => const ['jpg', 'jpeg'],
  };

  String get contentType => switch (this) {
    .audio => 'audio/mpeg',
    .lyrics => 'text/plain',
    .cover => 'image/jpeg',
  };
}
