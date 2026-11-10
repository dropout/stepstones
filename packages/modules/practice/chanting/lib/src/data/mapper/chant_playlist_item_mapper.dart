import 'package:chanting/src/domain/entity/chant_playlist_item_entity.dart';
import 'package:chanting/src/public/model/chant_playlist_item.dart';

extension ChantPlaylistItemMapper on ChantPlaylistItem {
  ChantPlaylistItemEntity toDomain() => ChantPlaylistItemEntity(
    id: id,
    chantId: chantId,
    name: name,
    blurHash: blurHash,
    order: order,
    duration: duration,
  );
}

extension ChantPlaylistItemEntityMapper on ChantPlaylistItemEntity {
  ChantPlaylistItem toApi() =>
      ChantPlaylistItem(id: id, chantId: chantId, name: name, blurHash: blurHash, order: order, duration: duration);
}
