// General
class SignInFailure implements Exception {}

// Google
class SignInWithGoogleFailure implements Exception {
  final String msg;
  const SignInWithGoogleFailure(this.msg);
  @override
  String toString() => 'SignInWithGoogleFailure: $msg';
}

// Apple
class SignInWithAppleFailure implements Exception {
  final String msg;
  const SignInWithAppleFailure(this.msg);
  @override
  String toString() => 'SignInWithAppleFailure: $msg';
}

// Email and Password
class SignInWithEmailAndPasswordFailure implements Exception {
  final String msg;
  const SignInWithEmailAndPasswordFailure(this.msg);
  @override
  String toString() => 'SignInWithEmailAndPasswordFailure: $msg';
}

// Reauthentication
class ReauthenticationFailure implements Exception {
  final String msg;
  const ReauthenticationFailure(this.msg);
  @override
  String toString() => 'ReauthenticationFailure: $msg';
}

/// The user reauthenticated with a different account than the signed-in one.
class ReauthenticationUserMismatch implements Exception {
  final String msg;
  const ReauthenticationUserMismatch(this.msg);
  @override
  String toString() => 'ReauthenticationUserMismatch: $msg';
}

// Specific exception to handle case when user cancels
// the signin process
class SignInCancelled implements Exception {
  final String msg;
  const SignInCancelled(this.msg);
  @override
  String toString() => 'SignInWithAppleFailure: $msg';
}
