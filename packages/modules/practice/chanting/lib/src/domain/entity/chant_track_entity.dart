import 'package:freezed_annotation/freezed_annotation.dart';

part 'chant_track_entity.freezed.dart';

@freezed
sealed class ChantTrackEntity with _$ChantTrackEntity {
  const factory ChantTrackEntity({required String id, required String title, Duration? duration}) = _ChantTrackEntity;
}
