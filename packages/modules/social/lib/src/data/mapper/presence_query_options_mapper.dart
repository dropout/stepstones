import 'package:core/core.dart';
import 'package:social/src/domain/entity/presence_query_options_entity.dart';

/// Builds query options so the public layer never touches the entity.
PresenceQueryOptionsEntity toPresenceQueryOptions({
  required Duration windowSize,
  required int limit,
  required double rangeInKm,
  String? ownProfileId,
  String? lastDocumentId,
  Location? location,
}) => PresenceQueryOptionsEntity(
  windowSize: windowSize,
  limit: limit,
  ownProfileId: ownProfileId,
  lastDocumentId: lastDocumentId,
  location: location,
  rangeInKm: rangeInKm,
);
