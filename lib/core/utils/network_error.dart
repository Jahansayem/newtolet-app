import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

/// Returns true when an exception likely came from missing connectivity.
bool isLikelyNetworkError(Object error) {
  if (error is SocketException || error is AuthRetryableFetchException) {
    return true;
  }

  final message = error.toString().toLowerCase();
  return message.contains('socketexception') ||
      message.contains('failed host lookup') ||
      message.contains('no address associated with hostname') ||
      message.contains('connection refused') ||
      message.contains('connection closed') ||
      message.contains('network is unreachable') ||
      message.contains('clientexception') ||
      message.contains('timed out');
}
