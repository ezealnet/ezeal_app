class AssessmentPricingService {
  static int calculateCartTotal(int itemCount) {
    if (itemCount <= 0) return 0;
    switch (itemCount) {
      case 1:
        return 299;
      case 2:
        return 499;
      case 3:
        return 699;
      case 4:
        return 899;
      case 5:
      default:
        return 999;
    }
  }

  static int calculateDiscount(int itemCount, List<int> basePrices) {
    final int baseSum = basePrices.fold(0, (sum, price) => sum + price);
    final int finalPrice = calculateCartTotal(itemCount);
    final int discount = baseSum - finalPrice;
    return discount > 0 ? discount : 0;
  }
}
