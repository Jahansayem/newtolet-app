import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/utils/network_error.dart';
import '../data/auth_cache_service.dart';
import '../models/user_model.dart';
import 'auth_cache_provider.dart';
import 'auth_state_provider.dart';
import 'supabase_provider.dart';

/// Provides the current authenticated user's profile from the `users` table.
///
/// Automatically refetches when the Supabase auth state changes.
///
/// Usage:
/// ```dart
/// final userAsync = ref.watch(currentUserProvider);
/// userAsync.when(
///   data: (user) => Text(user?.name ?? 'Guest'),
///   loading: () => CircularProgressIndicator(),
///   error: (e, st) => Text('Error: $e'),
/// );
/// ```
final currentUserProvider =
    AsyncNotifierProvider<CurrentUserNotifier, UserModel?>(
      CurrentUserNotifier.new,
    );

class CurrentUserNotifier extends AsyncNotifier<UserModel?> {
  AuthCacheService get _authCache => ref.read(authCacheServiceProvider);
  SupabaseClient get _client => ref.read(supabaseClientProvider);

  @override
  Future<UserModel?> build() async {
    // Listen to auth state changes and refetch the user profile accordingly.
    ref.listen(authStateProvider, (previous, next) {
      next.whenData((authState) {
        switch (authState.event) {
          case AuthChangeEvent.signedIn:
          case AuthChangeEvent.userUpdated:
            final currentUser = state.valueOrNull;
            if (currentUser != null) {
              unawaited(_refreshInBackground(currentUser));
            } else {
              unawaited(refresh());
            }
            break;
          case AuthChangeEvent.signedOut:
            unawaited(_authCache.clear());
            state = const AsyncData(null);
            break;
          default:
            break;
        }
      });
    });

    return _loadCurrentUser();
  }

  Future<UserModel?> _loadCurrentUser() async {
    final session = _client.auth.currentSession;

    if (session == null) {
      return null;
    }

    final cachedUser = await _authCache.getCachedUser(userId: session.user.id);
    if (cachedUser != null) {
      unawaited(_refreshInBackground(cachedUser));
      return cachedUser;
    }

    return _fetchRemoteUser(session.user.id);
  }

  /// Fetches the current user's row from the `users` table.
  Future<UserModel?> _fetchRemoteUser(String userId) async {
    final response = await _client
        .from('users')
        .select()
        .eq('id', userId)
        .single();

    final user = UserModel.fromJson(response);
    await _authCache.saveCachedUser(user);
    return user;
  }

  Future<void> _refreshInBackground(UserModel cachedUser) async {
    final session = _client.auth.currentSession;
    if (session == null) {
      return;
    }

    final sessionUserId = session.user.id;

    try {
      final freshUser = await _fetchRemoteUser(sessionUserId);
      if (_client.auth.currentSession?.user.id != sessionUserId) {
        return;
      }
      state = AsyncData(freshUser);
    } catch (_) {
      if (_client.auth.currentSession?.user.id != sessionUserId) {
        return;
      }
      state = AsyncData(cachedUser);
    }
  }

  /// Manually triggers a re-fetch of the user profile.
  Future<void> refresh() async {
    final session = _client.auth.currentSession;
    if (session == null) {
      await _authCache.clear();
      state = const AsyncData(null);
      return;
    }

    final cachedUser = await _authCache.getCachedUser(userId: session.user.id);
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      try {
        return await _fetchRemoteUser(session.user.id);
      } catch (error) {
        if (cachedUser != null && isLikelyNetworkError(error)) {
          return cachedUser;
        }
        rethrow;
      }
    });
  }
}
