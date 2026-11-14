import 'package:flutter_test/flutter_test.dart';

import 'package:admin_presence/src/data/mapper/admin_presence_mapper.dart';

void main() {
  test('maps a document written by the mobile app', () {
    final entry = adminPresenceFromFirestore('profile-1', {
      'id': 'profile-1',
      'profile': {'id': 'profile-1', 'firstName': 'Anna', 'lastName': 'Kovacs', 'photoBlurhash': 'abc'},
      'startedAt': 1700000000000,
      'location': {
        'name': 'Budapest',
        'latLng': {'latitude': 47.49, 'longitude': 19.04},
        'geoHash': 'u2mw1q8x',
      },
    });

    expect(entry.profileId, 'profile-1');
    expect(entry.displayName, 'Anna Kovacs');
    expect(entry.startedAt, DateTime.fromMillisecondsSinceEpoch(1700000000000));
    expect(entry.locationName, 'Budapest');
  });

  test('tolerates missing profile, location and start time', () {
    final entry = adminPresenceFromFirestore('profile-2', {'profile': 'broken', 'location': null});

    expect(entry.displayName, 'profile-2');
    expect(entry.startedAt, DateTime.fromMillisecondsSinceEpoch(0));
    expect(entry.locationName, isNull);
  });

  test('treats a blank location name as not shared', () {
    final entry = adminPresenceFromFirestore('profile-3', {
      'startedAt': 1700000000000.0,
      'location': {'name': '  '},
    });

    expect(entry.locationName, isNull);
    expect(entry.startedAt, DateTime.fromMillisecondsSinceEpoch(1700000000000));
  });
}
