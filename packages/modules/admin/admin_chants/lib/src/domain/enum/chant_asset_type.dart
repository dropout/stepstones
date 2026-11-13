/// The three files of a chant; names and paths must match what the mobile app downloads.
enum ChantAssetType {
  audio(fileName: 'chant.mp3', extensions: ['mp3'], contentType: 'audio/mpeg'),
  lyrics(fileName: 'chant.ass', extensions: ['ass'], contentType: 'text/plain'),
  cover(fileName: 'cover.jpg', extensions: ['jpg', 'jpeg'], contentType: 'image/jpeg');

  const ChantAssetType({required this.fileName, required this.extensions, required this.contentType});

  final String fileName;
  final List<String> extensions;
  final String contentType;

  String storagePath(String chantId) => 'chants/$chantId/$fileName';
}
