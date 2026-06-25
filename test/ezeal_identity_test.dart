import 'package:flutter_test/flutter_test.dart';
import 'package:ezeal/features/ezeal_identity/presentation/controllers/ezeal_identity_providers.dart';

void main() {
  group('Ezeal ID Verification Gate Tests', () {
    test('Aadhaar number validation formats', () {
      bool validateAadhaar(String val) {
        final clean = val.replaceAll(RegExp(r'\s+'), '');
        return clean.length == 12 && int.tryParse(clean) != null;
      }

      expect(validateAadhaar('123456789012'), true);
      expect(validateAadhaar('1234 5678 9012'), true);
      expect(validateAadhaar('12345678901'), false);
      expect(validateAadhaar('1234567890123'), false);
      expect(validateAadhaar('12345678901a'), false);
    });

    test('OTP mock check', () {
      bool validateOtp(String val) => val.trim() == '123456';
      expect(validateOtp('123456'), true);
      expect(validateOtp('123457'), false);
    });

    test('Ezeal ID Sequence Padded formatting', () {
      String generateId(int count, int year) {
        final sequence = count + 1;
        final paddedSequence = sequence.toString().padLeft(6, '0');
        return 'EZL-$year-STU-$paddedSequence';
      }

      expect(generateId(0, 2026), 'EZL-2026-STU-000001');
      expect(generateId(4, 2026), 'EZL-2026-STU-000005');
      expect(generateId(99, 2026), 'EZL-2026-STU-000100');
    });

    test('Ezeal ID parseStudentSequence logic', () {
      expect(EzealIdentityController.parseStudentSequence('EZL-2026-STU-000001', 2026), 1);
      expect(EzealIdentityController.parseStudentSequence('EZL-2026-STU-000042', 2026), 42);
      expect(EzealIdentityController.parseStudentSequence('EZL-2026-STU-000100', 2026), 100);
      expect(EzealIdentityController.parseStudentSequence('EZL-2025-STU-000001', 2026), 0); // Year mismatch
      expect(EzealIdentityController.parseStudentSequence('EZL-2026-STU-abc', 2026), 0); // Non-digit sequence
      expect(EzealIdentityController.parseStudentSequence('EZL-2026-INS-000001', 2026), 0); // Prefix role mismatch
      expect(EzealIdentityController.parseStudentSequence('random-string', 2026), 0); // Completely malformed ID
    });
  });
}
