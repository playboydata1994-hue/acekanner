import '../../core/constants.dart';
import 'entitlement.dart';

/// Why a new scan cannot be saved right now.
enum ScanBlock {
  /// Licensing is set up in this build but nobody has signed in yet.
  signInRequired,

  /// No online check for 30 days (or the phone's clock was turned back).
  checkInRequired,

  /// The free scans are held by the account's other phone.
  leaseOnOtherPhone,

  /// All 100 lifetime free scans are used and Premium is not active.
  freeUsedUp,
}

/// The licensing picture at one moment, derived only from a verified
/// entitlement and this phone's scan ledger.
class LicenseStatus {
  const LicenseStatus({
    required this.configured,
    required this.entitlement,
    required this.unsyncedFree,
    required this.localFreeUsed,
    required this.now,
    this.clockTampered = false,
    this.email,
  });

  /// Licensing (sign-in, server, Play billing) is available in this build.
  final bool configured;
  final Entitlement? entitlement;

  /// Free scans recorded here and not yet reported to the server.
  final int unsyncedFree;

  /// All free scans recorded on this phone (used when [configured] is false).
  final int localFreeUsed;
  final DateTime now;

  /// The device clock is earlier than a time the app already trusted.
  final bool clockTampered;
  final String? email;

  bool get signedIn => entitlement != null;

  bool get offlineExpired =>
      entitlement != null && (clockTampered || !now.isBefore(entitlement!.offlineUntil));

  bool get premiumActive {
    final e = entitlement;
    if (!configured || e == null || !e.premiumPlan || e.premiumUntil == null) return false;
    return !offlineExpired && now.isBefore(e.premiumUntil!);
  }

  int get freeLimit => entitlement?.freeLimit ?? AppConstants.freeScanLimit;

  /// Free scans this phone can still use.
  int get freeRemaining {
    if (!configured) return (AppConstants.freeScanLimit - localFreeUsed).clamp(0, AppConstants.freeScanLimit);
    final e = entitlement;
    if (e == null) return 0;
    return (e.lease - unsyncedFree).clamp(0, e.freeLimit);
  }

  /// Free scans used by the account (server count plus not yet reported).
  int get freeUsed {
    if (!configured) return localFreeUsed;
    final e = entitlement;
    if (e == null) return 0;
    return (e.freeUsed + unsyncedFree).clamp(0, e.freeLimit);
  }

  /// When the next online check is required for scanning to continue.
  DateTime? get checkDueBy {
    final e = entitlement;
    if (e == null) return null;
    final until = e.offlineUntil;
    return premiumActive && e.premiumUntil!.isBefore(until) ? e.premiumUntil : until;
  }

  /// Warn from 7 days before the online check is due.
  bool get checkDueSoon {
    final due = entitlement?.offlineUntil;
    return due != null && !offlineExpired && due.difference(now) <= const Duration(days: 7);
  }

  /// Null when a new scan may be saved.
  ScanBlock? get block {
    if (!configured) return freeRemaining > 0 ? null : ScanBlock.freeUsedUp;
    final e = entitlement;
    if (e == null) return ScanBlock.signInRequired;
    if (premiumActive) return null;
    if (offlineExpired) return ScanBlock.checkInRequired;
    if (freeRemaining > 0) return null;
    if (e.lease == 0 && e.freeUsed < e.freeLimit) return ScanBlock.leaseOnOtherPhone;
    return ScanBlock.freeUsedUp;
  }

  /// The tier a new scan would be charged to, or null when blocked.
  String? get chargeTier => premiumActive ? 'premium' : (block == null ? 'free' : null);
}

/// Thrown when saving a new paper would exceed the plan.
class ScanLimitException implements Exception {
  const ScanLimitException(this.block);
  final ScanBlock block;

  String get message => scanBlockMessage(block);

  @override
  String toString() => message;
}

String scanBlockMessage(ScanBlock block) => switch (block) {
      ScanBlock.signInRequired =>
        'Sign in with Google once to start scanning. It needs the internet only this first time.',
      ScanBlock.checkInRequired =>
        'Connect to the internet so ACEkanner can confirm your plan, then scan again. '
            'Your saved papers and results stay available.',
      ScanBlock.leaseOnOtherPhone =>
        'Your free scans are in use on your other phone. Sign in again on this phone to move them here.',
      ScanBlock.freeUsedUp =>
        'You have used all ${AppConstants.freeScanLimit} free scans. Upgrade to Premium for unlimited scanning. '
            'Re-scanning a paper that was already saved is always free.',
    };
