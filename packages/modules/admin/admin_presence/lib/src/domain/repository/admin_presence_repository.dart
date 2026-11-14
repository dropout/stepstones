import 'package:admin_presence/src/domain/entity/admin_presence_entity.dart';

abstract interface class AdminPresenceRepository {
  /// Emits the practice starts at or after [since], newest first, capped at [limit].
  Stream<List<AdminPresenceEntity>> watchPresence({required DateTime since, required int limit});
}
