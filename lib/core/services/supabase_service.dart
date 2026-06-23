import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static const String url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: '',
  );
  
  static const String anonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: '',
  );

  static Future<void> initialize() async {
    if (url.isEmpty || anonKey.isEmpty) {
      if (kDebugMode) {
        print(
          '⚠️ WARNING: Supabase credentials are not provided.\n'
          'Please run your app with:\n'
          'flutter run -d chrome --dart-define=SUPABASE_URL=https://otxnfklrtuiyukvfhlmt.supabase.co --dart-define=SUPABASE_ANON_KEY=your_supabase_anon_key\n'
          'Supabase features might fail or crash during runtime without these credentials.',
        );
      }
      return;
    }

    try {
      await Supabase.initialize(
        url: url,
        publishableKey: anonKey,
      );
      if (kDebugMode) {
        print('✅ Supabase initialized successfully!');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to initialize Supabase: $e');
      }
    }
  }

  static SupabaseClient get client => Supabase.instance.client;
}
