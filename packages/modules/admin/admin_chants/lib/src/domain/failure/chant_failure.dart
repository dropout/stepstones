enum ChantFailureReason { emptyName, nameTooLong, invalidId, duplicateId, missingFile, emptyFile, unreadableAsset }

/// An expected, user-correctable problem with a chant upload or edit.
class ChantFailure implements Exception {
  const ChantFailure(this.reason);

  final ChantFailureReason reason;

  @override
  String toString() => 'ChantFailure(${reason.name})';
}
