import 'package:auth/src/data/datasource/auth/exception.dart';
import 'package:auth/src/public/types/auth_public_failure.dart';

extension AuthPublicFailureMapper on Object {
  AuthPublicFailure toPublicFailure() => switch (this) {
    final AuthPublicFailure failure => failure,
    SignInCancelled(:final msg) => AuthPublicSignInCancelled(msg, cause: this),
    ReauthenticationUserMismatch(:final msg) =>
      AuthPublicReauthenticationUserMismatch(msg, cause: this),
    _ => AuthPublicUnknownFailure(toString(), cause: this),
  };
}
