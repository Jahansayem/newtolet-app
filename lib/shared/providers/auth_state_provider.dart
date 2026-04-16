import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// A [StreamProvider] that emits the latest [AuthState] whenever the Supabase
/// authentication state changes (sign-in, sign-out, token refresh, etc.).
///
/// Usage:
/// ```dart
/// final authAsync = ref.watch(authStateProvider);
/// authAsync.when(
///   data: (authState) => ...,
///   loading: () => ...,
///   error: (e, st) => ...,
/// );
/// ```
final authStateProvider = StreamProvider<AuthState>((ref) {
  final client = Supabase.instance.client;
  return client.auth.onAuthStateChange;
});
