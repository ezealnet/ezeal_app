class AuthConfig {
  /// Toggle email verification resend UI buttons and associated flows.
  /// Set via: --dart-define=AUTH_EMAIL_CONFIRMATION_ENABLED=false
  static const bool emailConfirmationEnabled = bool.fromEnvironment(
    'AUTH_EMAIL_CONFIRMATION_ENABLED',
    defaultValue: true,
  );
}
