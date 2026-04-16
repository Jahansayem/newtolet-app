import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/auth_cache_service.dart';

final authCacheServiceProvider = Provider<AuthCacheService>((ref) {
  return AuthCacheService();
});
