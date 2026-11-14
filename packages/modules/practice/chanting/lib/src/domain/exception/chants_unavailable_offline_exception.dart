/// Thrown when chants can't be prepared because the device is offline.
class ChantsUnavailableOfflineException implements Exception {
  const ChantsUnavailableOfflineException();

  @override
  String toString() => 'Chants are not available offline.';
}
