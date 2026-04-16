import 'package:flutter/widgets.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Initialises all third-party services required before the app starts.
///
/// Call this from `main()` before `runApp`.
Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables from the `.env` asset file.
  await dotenv.load(fileName: '.env');

  // Initialise Supabase with credentials from the environment.
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL'] ?? '',
    anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',
  );

  // Initialise Hive for local / offline storage.
  await Hive.initFlutter();
}
