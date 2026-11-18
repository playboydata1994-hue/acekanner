import '../categories.dart';
import 'entitlement.dart';

/// Why paid features are locked right now.
enum PlanBlock {
  /// No trial started and no subscription.
  noPlan,

  /// The trial has ended and there is no subscription.
  trialEnded,

  /// The subscription has ended.
  expired,

  /// No online check for 30 days, or the phone's clock was turned back.
  checkInRequired,

  /// The feature needs MAX; the instructor has PRO.
  needsMax,
}

/// The plan picture at one moment, derived only from a verified entitlement
/// (or, in test builds without licensing, the phone-only trial).
class PlanStatus {
  const PlanStatus({
    required this.configured,
    required this.now,
    this.entitlement,
    this.localTrialStarted,
    this.signedIn = false,
    this.email,
  });

  static const Duration trialLength = Duration(days: 7);

  /// Play renews while the phone may be offline: paid features stay unlocked
  /// this long after the paid-through date when auto-renew was on.
  static const Duration renewalGrace = Duration(days: 7);

  /// The phone's clock may lag the last verification by this much.
  static const Duration clockTolerance = Duration(hours: 24);

  /// Licensing (sign-in, server, Play billing) is compiled into this build.
  final bool configured;
  final DateTime now;
  final Entitlement? entitlement;

  /// Test builds only: when the phone-only trial started.
  final DateTime? localTrialStarted;
  final bool signedIn;
  final String? email;

  bool get clockTampered => entitlement != null && now.isBefore(entitlement!.verifiedAt.subtract(clockTolerance));

  bool get offlineExpired => entitlement != null && !now.isBefore(entitlement!.offlineUntil);

  bool get needsCheckIn => configured && entitlement != null && (clockTampered || offlineExpired);

  DateTime? get trialStarted => configured ? entitlement?.trialStarted : localTrialStarted;

  DateTime? get trialEnds {
    if (!configured) return localTrialStarted?.add(trialLength);
    return entitlement?.trialUntil;
  }

  bool get trialUsed => trialStarted != null;

  bool get trialActive {
    final end = trialEnds;
    if (end == null || !now.isBefore(end)) return false;
    if (!configured) return true;
    return !needsCheckIn;
  }

  /// Whole days left in the trial, counting a started day (6.2 days → 7).
  int get trialDaysLeft {
    final end = trialEnds;
    if (end == null || !now.isBefore(end)) return 0;
    final hours = end.difference(now).inMinutes / 60;
    return (hours / 24).ceil();
  }

  Tier get paidTier => entitlement?.paid ?? Tier.none;
  DateTime? get paidUntil => entitlement?.paidUntil;
  bool get autoRenew => entitlement?.autoRenew ?? false;

  /// The paid plan is usable now (verified and inside the offline policy).
  bool get paidActive {
    final e = entitlement;
    if (!configured || e == null || e.paid == Tier.none || e.paidUntil == null) return false;
    if (needsCheckIn) return false;
    final until = e.autoRenew ? e.paidUntil!.add(renewalGrace) : e.paidUntil!;
    return now.isBefore(until);
  }

  /// The effective plan now: the trial unlocks everything (MAX).
  Tier get tier {
    if (trialActive) return Tier.max;
    if (paidActive) return paidTier;
    return Tier.none;
  }

  bool get isTrialOnly => trialActive && !paidActive;

  /// Saving scores of this kind is allowed now.
  bool canSave(CategoryKind kind) => block(kind) == null;

  /// Null when [kind] may be saved; otherwise the reason it is locked.
  PlanBlock? block(CategoryKind kind) {
    final t = tier;
    if (t == Tier.max) return null;
    if (t == Tier.pro) return kind.needsMax ? PlanBlock.needsMax : null;
    if (needsCheckIn) return PlanBlock.checkInRequired;
    if (paidTier != Tier.none) return PlanBlock.expired;
    if (trialUsed) return PlanBlock.trialEnded;
    return PlanBlock.noPlan;
  }

  /// MAX-only analytics and examination features.
  bool get hasMax => tier == Tier.max;
}
