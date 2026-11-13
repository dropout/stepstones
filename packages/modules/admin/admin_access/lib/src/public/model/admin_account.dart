import 'package:freezed_annotation/freezed_annotation.dart';

part 'admin_account.freezed.dart';

@freezed
sealed class AdminAccount with _$AdminAccount {
  const factory AdminAccount({required String userId, String? email}) = _AdminAccount;
}
