import '../../domain/entity/session_entity.dart';
import '../../public/model/session.dart';


extension SessionMapper on SessionEntity {
  Session toApi() {
    return Session(
      id: id,
      type: switch (type) {
        .timer => .timer,
        .chanting => .chanting,
      },
      startTime: startTime,
      endTime: endTime,
      duration: duration,
      completedChantIds: completedChantIds,
    );
  }
}

extension SessionEntityMapper on Session {
  SessionEntity toDomain() {
    return SessionEntity(
      id: id,
      type: switch (type) {
        .timer => .timer,
        .chanting => .chanting,
      },
      startTime: startTime,
      endTime: endTime,
      duration: duration,
      completedChantIds: completedChantIds,
    );
  }
}
