import 'package:flutter/foundation.dart';

class AppConfig {
  /// Resolves the base URL of the application.
  /// Uses Uri.base.origin on web to automatically handle dynamic dev/prod ports and domains,
  /// and falls back to environment define on other platforms.
  static String get appUrl {
    if (kIsWeb) {
      return Uri.base.origin;
    }
    return const String.fromEnvironment(
      'APP_URL',
      defaultValue: 'http://localhost:3000',
    );
  }
}
