import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/home/presentation/screens/property_detail_screen.dart';
import '../../features/listing/presentation/screens/add_listing_screen.dart';
import '../../features/listing/presentation/screens/my_listings_screen.dart';
import '../../features/mlm/presentation/screens/invite_screen.dart';
import '../../features/mlm/presentation/screens/member_hub_screen.dart';
import '../../features/mlm/presentation/screens/team_tree_screen.dart';
import '../../features/mlm/presentation/screens/upgrade_assistant_screen.dart';
import '../../features/profile/presentation/screens/earnings_screen.dart';
import '../../features/profile/presentation/screens/edit_profile_screen.dart';
import '../../features/profile/presentation/screens/my_center_screen.dart';
import '../../features/profile/presentation/screens/settings_screen.dart';
import '../../shared/widgets/app_scaffold.dart';
import 'route_names.dart';

// ---------------------------------------------------------------------------
// Navigator keys for StatefulShellRoute branches
// ---------------------------------------------------------------------------

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _homeNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'home');
final _memberNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'member');
final _myCenterNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'myCenter');

// ---------------------------------------------------------------------------
// Router
// ---------------------------------------------------------------------------

final GoRouter appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/splash',
  debugLogDiagnostics: false,
  redirect: _authGuard,
  routes: [
    // -- Splash ---------------------------------------------------------------
    GoRoute(
      path: '/splash',
      name: RouteNames.splash,
      builder: (context, state) => const SplashScreen(),
    ),

    // -- Auth -----------------------------------------------------------------
    GoRoute(
      path: '/login',
      name: RouteNames.login,
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/register',
      name: RouteNames.register,
      builder: (context, state) => const RegisterScreen(),
    ),
    GoRoute(
      path: '/forgot-password',
      name: RouteNames.forgotPassword,
      builder: (context, state) => const ForgotPasswordScreen(),
    ),

    // -- Main shell with bottom navigation ------------------------------------
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return AppScaffold(navigationShell: navigationShell);
      },
      branches: [
        // Tab 0 -- Home
        StatefulShellBranch(
          navigatorKey: _homeNavigatorKey,
          routes: [
            GoRoute(
              path: '/home',
              name: RouteNames.home,
              builder: (context, state) => const HomeScreen(),
              routes: [
                GoRoute(
                  path: 'property/:id',
                  name: RouteNames.propertyDetail,
                  builder: (context, state) {
                    final id = state.pathParameters['id'] ?? '';
                    return PropertyDetailScreen(propertyId: id);
                  },
                ),
                GoRoute(
                  path: 'add-listing',
                  name: RouteNames.addListing,
                  builder: (context, state) => const AddListingScreen(),
                ),
                GoRoute(
                  path: 'my-listings',
                  name: RouteNames.myListings,
                  builder: (context, state) => const MyListingsScreen(),
                ),
              ],
            ),
          ],
        ),

        // Tab 1 -- Member Hub
        StatefulShellBranch(
          navigatorKey: _memberNavigatorKey,
          routes: [
            GoRoute(
              path: '/member',
              name: RouteNames.memberHub,
              builder: (context, state) => const MemberHubScreen(),
              routes: [
                GoRoute(
                  path: 'team-tree',
                  name: RouteNames.teamTree,
                  builder: (context, state) => const TeamTreeScreen(),
                ),
                GoRoute(
                  path: 'invite',
                  name: RouteNames.invite,
                  builder: (context, state) => const InviteScreen(),
                ),
                GoRoute(
                  path: 'earnings',
                  name: RouteNames.earnings,
                  builder: (context, state) => const EarningsScreen(),
                ),
              ],
            ),
          ],
        ),

        // Tab 2 -- My Center
        StatefulShellBranch(
          navigatorKey: _myCenterNavigatorKey,
          routes: [
            GoRoute(
              path: '/my-center',
              name: RouteNames.myCenter,
              builder: (context, state) => const MyCenterScreen(),
              routes: [
                GoRoute(
                  path: 'settings',
                  name: RouteNames.settings,
                  builder: (context, state) => const SettingsScreen(),
                ),
                GoRoute(
                  path: 'edit-profile',
                  name: RouteNames.editProfile,
                  builder: (context, state) => const EditProfileScreen(),
                ),
                GoRoute(
                  path: 'upgrade-assistant',
                  name: RouteNames.upgradeAssistant,
                  builder: (context, state) => const UpgradeAssistantScreen(),
                ),
              ],
            ),
          ],
        ),
      ],
    ),
  ],
);

// ---------------------------------------------------------------------------
// Auth guard
// ---------------------------------------------------------------------------

/// Redirects unauthenticated users to login and authenticated users away from
/// auth screens.
String? _authGuard(BuildContext context, GoRouterState state) {
  final session = Supabase.instance.client.auth.currentSession;
  final isAuthenticated = session != null;
  final currentPath = state.matchedLocation;

  // Paths that do not require authentication.
  const publicPaths = ['/splash', '/login', '/register', '/forgot-password'];
  final isPublicRoute = publicPaths.contains(currentPath);

  // If user is not authenticated and trying to access a protected route,
  // redirect to login.
  if (!isAuthenticated && !isPublicRoute) {
    return '/login';
  }

  // If user is authenticated and visiting an auth screen, send them home.
  if (isAuthenticated &&
      (currentPath == '/login' || currentPath == '/register')) {
    return '/home';
  }

  // No redirect needed.
  return null;
}
