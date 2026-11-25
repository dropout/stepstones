/// Failures thrown by [AuthPublicApi], modelled by how callers react to them.
sealed class AuthPublicFailure implements Exception {
  final String message;

  /// The internal error this failure was mapped from, kept for diagnostics.
  final Object? cause;

  const AuthPublicFailure(this.message, {this.cause});

  @override
  String toString() => '$runtimeType: $message';
}

/// The user dismissed the sign-in or reauthentication prompt.
final class AuthPublicSignInCancelled extends AuthPublicFailure {
  const AuthPublicSignInCancelled(super.message, {super.cause});
}

/// The user reauthenticated with a different account than the signed-in one.
final class AuthPublicReauthenticationUserMismatch extends AuthPublicFailure {
  const AuthPublicReauthenticationUserMismatch(super.message, {super.cause});
}

/// Any other failure; inspect [cause] for details.
final class AuthPublicUnknownFailure extends AuthPublicFailure {
  const AuthPublicUnknownFailure(super.message, {super.cause});
}
