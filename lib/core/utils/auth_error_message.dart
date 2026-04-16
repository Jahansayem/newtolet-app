import 'package:supabase_flutter/supabase_flutter.dart';

import 'network_error.dart';

enum AuthAction { signIn, passwordReset }

String authErrorMessage(Object error, {required AuthAction action}) {
  final message = error.toString().toLowerCase();

  if (isLikelyNetworkError(error)) {
    switch (action) {
      case AuthAction.signIn:
        return 'Internet is required to sign in. After one successful login on this device, you can reopen the app offline.';
      case AuthAction.passwordReset:
        return 'Internet is required to send a password reset email.';
    }
  }

  if (error is AuthException) {
    if (message.contains('invalid login credentials')) {
      return 'Invalid email or password.';
    }

    if (message.contains('email not confirmed')) {
      return 'Please confirm your email before signing in.';
    }
  }

  switch (action) {
    case AuthAction.signIn:
      return 'Login failed. Please try again.';
    case AuthAction.passwordReset:
      return 'Failed to send reset email. Please check your email and try again.';
  }
}
