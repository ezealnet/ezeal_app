class AuthConfig {
  /// Toggle email verification resend UI buttons and associated flows.
  /// Set via: --dart-define=AUTH_EMAIL_CONFIRMATION_ENABLED=false
  static const bool emailConfirmationEnabled = bool.fromEnvironment(
    'AUTH_EMAIL_CONFIRMATION_ENABLED',
    defaultValue: true,
  );

  /// Toggle Developer Quick Login tool grid on the sign in page.
  /// Set via: --dart-define=AUTH_SHOW_DEVELOPER_TOOLS=true
  static const bool showDeveloperTools = bool.fromEnvironment(
    'AUTH_SHOW_DEVELOPER_TOOLS',
    defaultValue: false,
  );
}
