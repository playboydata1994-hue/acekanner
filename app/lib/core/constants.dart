/// Product constants shared across features.
abstract final class AppConstants {
  static const String appName = 'ACEkanner';
  static const String applicationId = 'com.acekanner.app';

  /// Lifetime successful (finalized) student-paper scans on the free plan.
  static const int freeScanLimit = 100;

  /// Google Play subscription product (Play IDs must be lower-case).
  static const String premiumProductId = 'acekanner_premium_yearly';
  static const String premiumBasePlanId = 'yearly-autorenew';
  static const int premiumPricePhp = 399;

  /// Premium keeps working offline for this many days after the last
  /// successful online verification.
  static const int offlineVerificationDays = 30;

  /// Supported answer-sheet templates.
  static const List<int> itemCounts = [50, 75, 100];
  static const List<String> choiceLabels = ['A', 'B', 'C', 'D', 'E'];
}
