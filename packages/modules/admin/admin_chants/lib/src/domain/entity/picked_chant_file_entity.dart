import 'package:freezed_annotation/freezed_annotation.dart';

part 'picked_chant_file_entity.freezed.dart';

@freezed
sealed class PickedChantFileEntity with _$PickedChantFileEntity {
  const factory PickedChantFileEntity({required String path, required String name}) = _PickedChantFileEntity;
}
