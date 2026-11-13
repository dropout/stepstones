import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:admin_access/src/domain/enum/admin_access_status.dart';

part 'admin_access_entity.freezed.dart';

@freezed
sealed class AdminAccessEntity with _$AdminAccessEntity {
  const factory AdminAccessEntity({required AdminAccessStatus status, String? userId, String? email}) =
      _AdminAccessEntity;
}
