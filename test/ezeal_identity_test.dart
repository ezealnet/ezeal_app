import 'package:flutter_test/flutter_test.dart';

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
  });
}
