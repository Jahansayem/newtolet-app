class SupabaseConstants {
  SupabaseConstants._();

  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://ohzpdfuijcajoyyrofzp.supabase.co',
  );

  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im9oenBkZnVpamNham95eXJvZnpwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTg1MjIyNTIsImV4cCI6MjA3NDA5ODI1Mn0.sFFSxfwJ_qSqB6gO8yTAuh8PpUJeIo1bVoNxzjNrLxg',
  );
}
