import 'package:timer/src/domain/entity/timer_settings_entity.dart' as domain;

import '../../public/model/timer_settings.dart';


/// Maps between the module's public [api.TimerSettings] DTO and the domain model.
extension TimerSettingsToDomain on TimerSettings {
  domain.TimerSettingsEntity toDomain() {
    return domain.TimerSettingsEntity(
      warmup: warmup,
      duration: duration,
      intervalCount: intervalCount,
      intervalSound: intervalSound,
      startingSound: startingSound,
      endingSound: endingSound,
      lastUsed: lastUsed,
    );
  }
}

extension TimerSettingsToPublic on domain.TimerSettingsEntity {
  TimerSettings toApi() {
    return TimerSettings(
      warmup: warmup,
      duration: duration,
      intervalCount: intervalCount,
      intervalSound: intervalSound,
      startingSound: startingSound,
      endingSound: endingSound,
      lastUsed: lastUsed,
    );
  }
}
