import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';

import '../models/user_model.dart';

/// Persists the last authenticated user's profile for offline startup.
class AuthCacheService {
  static const String _boxName = 'auth_cache';
  static const String _cachedUserKey = 'cached_user';
  static const String _cachedUserIdKey = 'cached_user_id';
  static const String _cachedAtKey = 'cached_at';

  Future<Box<String>> _openBox() async {
    if (Hive.isBoxOpen(_boxName)) {
      return Hive.box<String>(_boxName);
    }

    return Hive.openBox<String>(_boxName);
  }

  Future<void> saveCachedUser(UserModel user) async {
    final box = await _openBox();
    await box.put(_cachedUserKey, jsonEncode(user.toJson()));
    await box.put(_cachedUserIdKey, user.id);
    await box.put(_cachedAtKey, DateTime.now().toIso8601String());
  }

  Future<UserModel?> getCachedUser({String? userId}) async {
    final box = await _openBox();
    final cachedUserId = box.get(_cachedUserIdKey);

    if (userId != null && cachedUserId != userId) {
      return null;
    }

    final rawUser = box.get(_cachedUserKey);
    if (rawUser == null || rawUser.isEmpty) {
      return null;
    }

    try {
      final decoded = jsonDecode(rawUser);
      if (decoded is! Map) {
        await clear();
        return null;
      }

      return UserModel.fromJson(Map<String, dynamic>.from(decoded));
    } catch (_) {
      await clear();
      return null;
    }
  }

  Future<void> clear() async {
    final box = await _openBox();
    await box.delete(_cachedUserKey);
    await box.delete(_cachedUserIdKey);
    await box.delete(_cachedAtKey);
  }
}
