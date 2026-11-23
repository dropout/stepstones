import 'package:donate/donate.dart';
import 'package:get_it/get_it.dart';

import 'package:core/core.dart';
import 'package:auth/auth.dart';
import 'package:home/home.dart';
import 'package:profile/profile.dart';
import 'package:stats/stats.dart';
import 'package:session/session.dart';
import 'package:timer/timer.dart';
import 'package:chanting/chanting.dart';
import 'package:social/social.dart';
// Demo recording: uncomment with the call below; never commit enabled.
// import 'package:social/testing.dart';


extension AppDependencyInjection on GetIt {

  Future<void> registerDependencies() async {
    await registerCoreDependencies();
    registerAuthModuleDependencies();
    registerProfileModuleDependencies();
    
    registerSocialModuleDependencies();
    registerSessionModuleDependencies();
    registerStatsModuleDependencies();
    registerTimerModuleDependencies();
    registerChantingModuleDependencies();
    registerHomeModuleDependencies();
    registerDonateModuleDependencies();

    // Demo recording: fake presence list with portrait photos.
    // await useFakePresenceForRecording();
  }

}
