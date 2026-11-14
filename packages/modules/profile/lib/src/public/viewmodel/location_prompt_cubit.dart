import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:core/core.dart';

/// Emits true while the post-session location prompt should be shown.
class LocationPromptCubit extends Cubit<bool> {
  final SharedPreferencesService preferences;

  LocationPromptCubit({required this.preferences}) : super(false);

  Future<void> load() async {
    final dismissed = await preferences.get<bool>(
      key: SharedPreferencesKey.locationPromptDismissed,
    );
    if (!isClosed) emit(dismissed != true);
  }

  Future<void> dismiss() async {
    emit(false);
    await preferences.set<bool>(
      key: SharedPreferencesKey.locationPromptDismissed,
      value: true,
    );
  }
}
