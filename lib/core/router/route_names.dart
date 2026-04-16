/// Centralised route name constants used by [GoRouter] configuration.
class RouteNames {
  RouteNames._();

  // ---------------------------------------------------------------------------
  // Top-level routes
  // ---------------------------------------------------------------------------

  static const String splash = 'splash';
  static const String login = 'login';
  static const String register = 'register';
  static const String forgotPassword = 'forgotPassword';

  // ---------------------------------------------------------------------------
  // Shell / bottom-nav tabs
  // ---------------------------------------------------------------------------

  static const String home = 'home';
  static const String memberHub = 'memberHub';
  static const String myCenter = 'myCenter';

  // ---------------------------------------------------------------------------
  // Nested under Home
  // ---------------------------------------------------------------------------

  static const String propertyDetail = 'propertyDetail';
  static const String addListing = 'addListing';
  static const String myListings = 'myListings';

  // ---------------------------------------------------------------------------
  // Nested under Member Hub
  // ---------------------------------------------------------------------------

  static const String teamTree = 'teamTree';
  static const String invite = 'invite';
  static const String earnings = 'earnings';

  // ---------------------------------------------------------------------------
  // Nested under My Center
  // ---------------------------------------------------------------------------

  static const String settings = 'settings';
  static const String editProfile = 'editProfile';
  static const String upgradeAssistant = 'upgradeAssistant';
}
