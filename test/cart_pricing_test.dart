import 'package:flutter_test/flutter_test.dart';
import 'package:ezeal/features/cart/domain/assessment_pricing_service.dart';

void main() {
  group('AssessmentPricingService Tests', () {
    test('calculateCartTotal for different counts', () {
      expect(AssessmentPricingService.calculateCartTotal(0), 0);
      expect(AssessmentPricingService.calculateCartTotal(1), 299);
      expect(AssessmentPricingService.calculateCartTotal(2), 499);
      expect(AssessmentPricingService.calculateCartTotal(3), 699);
      expect(AssessmentPricingService.calculateCartTotal(4), 899);
      expect(AssessmentPricingService.calculateCartTotal(5), 999);
      expect(AssessmentPricingService.calculateCartTotal(6), 999);
    });

    test('calculateDiscount calculates discount correctly', () {
      expect(AssessmentPricingService.calculateDiscount(1, [299]), 0);
      expect(AssessmentPricingService.calculateDiscount(3, [299, 299, 299]), 198);
      expect(AssessmentPricingService.calculateDiscount(5, [299, 299, 299, 299, 299]), 496);
    });
  });
}
