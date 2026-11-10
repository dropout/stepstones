import '../model/session.dart';

abstract class SessionPublicApi {
  Future<void> saveSession(String profileId, Session session);
}
