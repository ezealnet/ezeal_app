import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Forgot Password Email Local Validation Tests', () {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );

    String? validateForgotPasswordEmail(String email) {
      final trimmed = email.trim();
      if (trimmed.isEmpty) {
        return 'Please enter a valid email address.';
      }
      if (!emailRegex.hasMatch(trimmed)) {
        return 'Please enter a valid email address.';
      }
      return null;
    }

    test('Empty email is invalid and returns the custom message', () {
      expect(
        validateForgotPasswordEmail(''),
        'Please enter a valid email address.',
      );
      expect(
        validateForgotPasswordEmail('   '),
        'Please enter a valid email address.',
      );
    });

    test('Malformed email is invalid and returns the custom message', () {
      expect(
        validateForgotPasswordEmail('invalidemail'),
        'Please enter a valid email address.',
      );
      expect(
        validateForgotPasswordEmail('invalid@'),
        'Please enter a valid email address.',
      );
      expect(
        validateForgotPasswordEmail('invalid@domain'),
        'Please enter a valid email address.',
      );
      expect(
        validateForgotPasswordEmail('@domain.com'),
        'Please enter a valid email address.',
      );
    });

    test('Well-formed email returns null (no error)', () {
      expect(validateForgotPasswordEmail('user@example.com'), isNull);
      expect(validateForgotPasswordEmail('user.name+tag@domain.co.in'), isNull);
      expect(validateForgotPasswordEmail('   trimmed@example.com   '), isNull);
    });
  });
}
