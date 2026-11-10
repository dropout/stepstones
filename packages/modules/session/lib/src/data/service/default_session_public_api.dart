import '../mapper/session_mapper.dart';
import '../../domain/repository/session_repository.dart';
import '../../public/api/session_public_api.dart';
import '../../public/model/session.dart';

class DefaultSessionPublicApi({
  required final SessionRepository sessionRepository,
}) implements SessionPublicApi {  

  @override
  Future<void> saveSession(String profileId, Session session) async =>
    sessionRepository.create(profileId, session.toDomain());

}
