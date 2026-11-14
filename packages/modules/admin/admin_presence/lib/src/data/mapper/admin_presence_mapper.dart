import 'package:admin_presence/src/domain/entity/admin_presence_entity.dart';

/// Maps a `presence/{profileId}` document; tolerant of missing fields so a malformed entry stays visible.
AdminPresenceEntity adminPresenceFromFirestore(String documentId, Map<String, dynamic> data) {
  final profile = _map(data['profile']);
  final startedAt = data['startedAt'];
  return AdminPresenceEntity(
    profileId: documentId,
    firstName: _string(profile['firstName']) ?? '',
    lastName: _string(profile['lastName']) ?? '',
    startedAt: DateTime.fromMillisecondsSinceEpoch(startedAt is num ? startedAt.toInt() : 0),
    locationName: _string(_map(data['location'])['name']),
  );
}

Map<dynamic, dynamic> _map(Object? value) => value is Map ? value : const {};

String? _string(Object? value) => value is String && value.trim().isNotEmpty ? value.trim() : null;
