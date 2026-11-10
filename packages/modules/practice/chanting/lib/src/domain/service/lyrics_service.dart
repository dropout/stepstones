import 'package:chanting/src/domain/entity/lyrics_document_entity.dart';

abstract interface class LyricsService {
  Future<LyricsDocumentEntity> loadLyrics(String lyricsResourceUrl);
}
