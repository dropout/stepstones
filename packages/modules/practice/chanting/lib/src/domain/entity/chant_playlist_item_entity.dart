import 'package:freezed_annotation/freezed_annotation.dart';

part 'chant_playlist_item_entity.freezed.dart';

@freezed
sealed class ChantPlaylistItemEntity with _$ChantPlaylistItemEntity {
  const factory ChantPlaylistItemEntity({
    required String id,
    required String chantId,
    required String name,
    required String blurHash,
    required int order,
    required Duration duration,
  }) = _ChantPlaylistItemEntity;
}
