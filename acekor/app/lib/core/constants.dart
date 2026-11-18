/// Product constants shared across features.
abstract final class AppConstants {
  static const String appName = 'ACEkor Grading Sheet';
  static const String applicationId = 'com.acekor.calculator';

  /// Google Play subscriptions (auto-renewing, base plan "yearly").
  static const String proProductId = 'acekor_pro_yearly';
  static const String maxProductId = 'acekor_max_yearly';
  static const String basePlanId = 'yearly';
  static const int proPricePhp = 399;
  static const int maxPricePhp = 499;

  static const int trialDays = 7;

  /// Paid features keep working offline this long after the last check.
  static const int offlineDays = 30;

  /// The licensing server's Edge Function.
  static const String licenseFunction = 'acekor-license';
}
