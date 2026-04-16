import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/auth_repository.dart';

/// Provides the [AuthNotifier] as an [AsyncNotifier] so UI widgets
/// can watch loading / error / success states for auth operations.
final authProvider = AsyncNotifierProvider<AuthNotifier, void>(
  AuthNotifier.new,
);

class AuthNotifier extends AsyncNotifier<void> {
  AuthRepository get _repository => ref.read(authRepositoryProvider);

  @override
  Future<void> build() async {
    ref.watch(authRepositoryProvider);
  }

  /// Creates a new account.
  ///
  /// Sets state to [AsyncLoading] while the request is in-flight and
  /// to [AsyncError] if the request fails.  On success the state is
  /// [AsyncData] with `void`.
  Future<void> signUp({
    required String email,
    required String password,
    required String name,
    String? referralCode,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await _repository.signUp(
        email: email,
        password: password,
        name: name,
        referralCode: referralCode,
      );
    });
  }

  /// Signs in with email and password.
  Future<void> signIn({required String email, required String password}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await _repository.signIn(email: email, password: password);
    });
  }

  /// Signs out the current user.
  Future<void> signOut() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await _repository.signOut();
    });
  }

  /// Sends a password-reset email.
  Future<void> resetPassword(String email) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await _repository.resetPassword(email);
    });
  }
}
