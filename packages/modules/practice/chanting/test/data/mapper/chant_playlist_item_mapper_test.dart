import 'package:chanting/src/data/mapper/chant_playlist_item_mapper.dart';
import 'package:chanting/src/public/model/chant_playlist_item.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('preserves every playlist item field across the domain boundary', () {
    const item = ChantPlaylistItem(
      id: 'item-2',
      chantId: 'chant-1',
      name: 'Chant',
      blurHash: 'cover',
      order: 4,
      duration: Duration(seconds: 23),
    );

    final entity = item.toDomain();
    expect(entity.id, item.id);
    expect(entity.chantId, item.chantId);
    expect(entity.name, item.name);
    expect(entity.blurHash, item.blurHash);
    expect(entity.order, item.order);
    expect(entity.duration, item.duration);
    expect(entity.toApi(), item);
  });
}
