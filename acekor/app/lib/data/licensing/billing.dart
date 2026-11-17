import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/billing_client_wrappers.dart' show ReplacementMode;
import 'package:in_app_purchase_android/in_app_purchase_android.dart';

import '../../core/constants.dart';
import '../../domain/licensing/entitlement.dart';
import 'license_api.dart';
import 'license_service.dart';

/// Google Play Billing, behind an interface so the purchase flow can be tested.
abstract interface class BillingGateway {
  Stream<List<PurchaseDetails>> get purchaseStream;
  Future<bool> isAvailable();

  /// The yearly base plans of PRO and MAX (missing entries are not in Play yet).
  Future<Map<Tier, ProductDetails>> products();

  /// Opens Play's purchase sheet. [upgradeFrom] replaces an active PRO
  /// subscription (MAX upgrade, prorated, renewal date kept).
  Future<bool> buy(ProductDetails product, {required String accountRef, PurchaseDetails? upgradeFrom});

  /// The phone's active ACEkor subscriptions known to Play.
  Future<List<PurchaseDetails>> activePurchases({required String accountRef});
  Future<void> restore({required String accountRef});

  /// Tells Play the purchase was handled (the server already acknowledged it).
  Future<void> complete(PurchaseDetails purchase);
}

class PlayBillingGateway implements BillingGateway {
  final InAppPurchase _iap = InAppPurchase.instance;

  @override
  Stream<List<PurchaseDetails>> get purchaseStream => _iap.purchaseStream;

  @override
  Future<bool> isAvailable() => _iap.isAvailable();

  @override
  Future<Map<Tier, ProductDetails>> products() async {
    final res = await _iap.queryProductDetails({AppConstants.proProductId, AppConstants.maxProductId});
    ProductDetails? pick(String id) {
      final all = res.productDetails.where((p) => p.id == id).toList();
      for (final p in all) {
        if (p is GooglePlayProductDetails && p.subscriptionIndex != null) {
          final offer = p.productDetails.subscriptionOfferDetails![p.subscriptionIndex!];
          if (offer.basePlanId == AppConstants.basePlanId && offer.offerId == null) return p;
        }
      }
      return all.firstOrNull;
    }

    return {Tier.pro: ?pick(AppConstants.proProductId), Tier.max: ?pick(AppConstants.maxProductId)};
  }

  @override
  Future<bool> buy(ProductDetails product, {required String accountRef, PurchaseDetails? upgradeFrom}) {
    final param = upgradeFrom is GooglePlayPurchaseDetails
        ? GooglePlayPurchaseParam(
            productDetails: product,
            applicationUserName: accountRef,
            changeSubscriptionParam: ChangeSubscriptionParam(
              oldPurchaseDetails: upgradeFrom,
              replacementMode: ReplacementMode.chargeProratedPrice,
            ),
          )
        : PurchaseParam(productDetails: product, applicationUserName: accountRef);
    return _iap.buyNonConsumable(purchaseParam: param);
  }

  @override
  Future<List<PurchaseDetails>> activePurchases({required String accountRef}) async {
    final addition = _iap.getPlatformAddition<InAppPurchaseAndroidPlatformAddition>();
    final res = await addition.queryPastPurchases(applicationUserName: accountRef);
    return res.pastPurchases
        .where((p) => p.productID == AppConstants.proProductId || p.productID == AppConstants.maxProductId)
        .toList();
  }

  @override
  Future<void> restore({required String accountRef}) => _iap.restorePurchases(applicationUserName: accountRef);

  @override
  Future<void> complete(PurchaseDetails purchase) async {
    if (purchase.pendingCompletePurchase) await _iap.completePurchase(purchase);
  }
}

enum BillingPhase { idle, loading, purchasing, pending, verifying, success, error }

class BillingState {
  const BillingState({this.prices = const {}, this.phase = BillingPhase.idle, this.message});

  /// Play's localized prices, e.g. {pro: "₱399.00", max: "₱499.00"}.
  final Map<Tier, String> prices;
  final BillingPhase phase;
  final String? message;

  bool get busy => phase == BillingPhase.loading || phase == BillingPhase.purchasing || phase == BillingPhase.verifying;
  bool available(Tier t) => prices.containsKey(t);

  BillingState copyWith({Map<Tier, String>? prices, BillingPhase? phase, String? message, bool clearMessage = false}) =>
      BillingState(
        prices: prices ?? this.prices,
        phase: phase ?? this.phase,
        message: clearMessage ? null : (message ?? this.message),
      );
}

class BillingDeps {
  const BillingDeps({required this.gateway, required this.service, required this.accountId});

  /// Null when billing is not available in this build.
  final BillingGateway? gateway;
  final LicenseService service;

  /// The signed-in account's ID, or null.
  final String? Function() accountId;
}

/// Purchase flow. A purchase reported by Play is sent to the server, which
/// verifies it with Google; only a server-signed entitlement unlocks PRO or
/// MAX. Play is told the purchase is complete only after that, so a purchase
/// the server cannot confirm is redelivered (or refunded by Play).
class BillingController extends Notifier<BillingState> {
  BillingController(this._resolve);

  final BillingDeps Function(Ref ref) _resolve;
  late BillingDeps _deps;
  StreamSubscription<List<PurchaseDetails>>? _sub;
  Map<Tier, ProductDetails> _products = const {};
  bool _userRestore = false;

  BillingGateway? get _gateway => _deps.gateway;
  LicenseService get _service => _deps.service;

  static bool _ours(String id) => id == AppConstants.proProductId || id == AppConstants.maxProductId;

  @override
  BillingState build() {
    _deps = _resolve(ref);
    final gateway = _gateway;
    if (gateway == null) return const BillingState();
    _sub = gateway.purchaseStream.listen(handle, onError: (_) {});
    ref.onDispose(() => _sub?.cancel());
    return const BillingState();
  }

  /// Loads products and prices from Play.
  Future<void> load() async {
    final gateway = _gateway;
    if (gateway == null) return;
    state = state.copyWith(phase: BillingPhase.loading, clearMessage: true);
    try {
      if (!await gateway.isAvailable()) {
        state = const BillingState(message: 'Google Play is not available on this phone.');
        return;
      }
      _products = await gateway.products();
      state = BillingState(
        prices: {for (final e in _products.entries) e.key: e.value.price},
        message: _products.isEmpty ? 'PRO and MAX are not available in Google Play yet.' : null,
      );
    } catch (_) {
      state = const BillingState(message: 'Could not reach Google Play. Check your connection.');
    }
  }

  /// Buys [tier]. When the instructor has PRO and buys MAX, the PRO
  /// subscription is replaced (upgrade, prorated).
  Future<void> buy(Tier tier) async {
    final gateway = _gateway;
    final account = _deps.accountId();
    if (gateway == null || account == null || tier == Tier.none) return;
    if (_products.isEmpty) await load();
    final product = _products[tier];
    if (product == null) return;
    state = state.copyWith(phase: BillingPhase.purchasing, clearMessage: true);
    final ref = LicenseService.playAccountRef(account);
    try {
      PurchaseDetails? upgradeFrom;
      if (tier == Tier.max) {
        final active = await gateway.activePurchases(accountRef: ref);
        upgradeFrom = active.where((p) => p.productID == AppConstants.proProductId).firstOrNull;
      }
      final started = await gateway.buy(product, accountRef: ref, upgradeFrom: upgradeFrom);
      if (!started) {
        state = state.copyWith(phase: BillingPhase.idle, message: 'Google Play could not start the purchase.');
      }
    } catch (_) {
      state = state.copyWith(phase: BillingPhase.error, message: 'Google Play could not start the purchase.');
    }
  }

  /// [userInitiated] shows "no subscription found" when nothing is restored.
  Future<void> restore({bool userInitiated = true}) async {
    final gateway = _gateway;
    final account = _deps.accountId();
    if (gateway == null || account == null) return;
    _userRestore = userInitiated;
    if (userInitiated) state = state.copyWith(phase: BillingPhase.verifying, clearMessage: true);
    try {
      await gateway.restore(accountRef: LicenseService.playAccountRef(account));
      // Restored purchases arrive on the purchase stream; nothing owned = no event.
      await Future<void>.delayed(const Duration(seconds: 3));
      if (_userRestore && state.phase == BillingPhase.verifying) {
        state = state.copyWith(
          phase: BillingPhase.idle,
          message: 'No active ACEkor subscription was found for this Google account.',
        );
      }
    } catch (_) {
      if (userInitiated) state = state.copyWith(phase: BillingPhase.error, message: 'Could not reach Google Play.');
    } finally {
      _userRestore = false;
    }
  }

  Future<void> handle(List<PurchaseDetails> purchases) async {
    for (final p in purchases) {
      if (!_ours(p.productID)) continue;
      switch (p.status) {
        case PurchaseStatus.pending:
          state = state.copyWith(
            phase: BillingPhase.pending,
            message: 'Payment pending. Your plan starts as soon as Google Play confirms your payment.',
          );
        case PurchaseStatus.canceled:
          state = state.copyWith(phase: BillingPhase.idle, clearMessage: true);
        case PurchaseStatus.error:
          state = state.copyWith(
            phase: BillingPhase.error,
            message: 'The purchase did not complete. You were not charged.',
          );
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          await _verify(p);
      }
    }
  }

  Future<void> _verify(PurchaseDetails p) async {
    state = state.copyWith(phase: BillingPhase.verifying, message: 'Confirming your purchase with Google Play…');
    try {
      final outcome = await _service.verifyPurchase(p.verificationData.serverVerificationData, p.productID);
      switch (outcome) {
        case PurchaseOutcome.granted:
          await _gateway?.complete(p);
          final plan = p.productID == AppConstants.maxProductId ? 'MAX' : 'PRO';
          state = state.copyWith(phase: BillingPhase.success, message: '$plan is active. Thank you!');
        case PurchaseOutcome.pending:
          state = state.copyWith(
            phase: BillingPhase.pending,
            message: 'Payment pending. Your plan starts as soon as Google Play confirms your payment.',
          );
        case PurchaseOutcome.notGranted:
          // An old, replaced or expired purchase: nothing to unlock.
          await _gateway?.complete(p);
          if (state.phase == BillingPhase.verifying) {
            state = state.copyWith(phase: BillingPhase.idle, message: 'This subscription is no longer active.');
          }
      }
    } on LicenseApiException catch (e) {
      state = state.copyWith(
        phase: BillingPhase.error,
        message: e.offline
            ? 'Your purchase is safe, but it could not be confirmed yet. Connect to the internet and tap "Restore purchase".'
            : e.message,
      );
    } catch (_) {
      state = state.copyWith(
        phase: BillingPhase.error,
        message: 'Your purchase could not be confirmed yet. Tap "Restore purchase" to try again.',
      );
    }
  }
}
