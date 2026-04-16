import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../shared/data/auth_cache_service.dart';
import '../../../shared/providers/auth_cache_provider.dart';
import '../../../shared/providers/supabase_provider.dart';

/// Provides the [AuthRepository] instance through Riverpod.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  final authCache = ref.watch(authCacheServiceProvider);
  return AuthRepository(client, authCache);
});

/// Repository that wraps Supabase Auth operations.
///
/// All methods throw [AuthException] on failure, which callers
/// should handle for user-facing error messages.
class AuthRepository {
  AuthRepository(this._client, this._authCache);

  final SupabaseClient _client;
  final AuthCacheService _authCache;

  /// Creates a new account with email and password.
  ///
  /// [name] is stored in user metadata and used by the database
  /// `handle_new_user` trigger to populate the `users` table.
  ///
  /// [referralCode] is optional and passed as raw signup metadata.
  /// The database resolves the sponsor server-side so the tree
  /// placement rule stays authoritative in Supabase.
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String name,
    String? referralCode,
  }) async {
    final metadata = <String, dynamic>{'name': name};
    if (referralCode != null && referralCode.trim().isNotEmpty) {
      metadata['referral_code'] = referralCode.trim().toUpperCase();
    }

    final response = await _client.auth.signUp(
      email: email.trim(),
      password: password,
      data: metadata,
    );
    return response;
  }

  /// Signs in an existing user with email and password.
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    final response = await _client.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
    return response;
  }

  /// Signs out the current user and clears the local session.
  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } finally {
      await _authCache.clear();
    }
  }

  /// Sends a password-reset email to the given address.
  Future<void> resetPassword(String email) async {
    await _client.auth.resetPasswordForEmail(email.trim());
  }

  /// Returns the current session, or `null` if the user is not
  /// authenticated.
  Session? getCurrentSession() {
    return _client.auth.currentSession;
  }

  /// Returns the currently authenticated user, or `null`.
  User? getCurrentUser() {
    return _client.auth.currentUser;
  }
}
