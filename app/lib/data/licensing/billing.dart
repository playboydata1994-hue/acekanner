import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';

import '../../core/constants.dart';
import 'license_api.dart';
import 'license_service.dart';

/// Google Play Billing, behind an interface so the purchase flow can be tested.
abstract interface class BillingGateway {
  Stream<List<PurchaseDetails>> get purchaseStream;
  Future<bool> isAvailable();

  /// The yearly base plan of the Premium subscription, or null if Play has none.
  Future<ProductDetails?> premiumProduct();

  /// Opens Play's purchase sheet. [accountRef] ties the purchase to the account.
  Future<bool> buy(ProductDetails product, {required String accountRef});
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
  Future<ProductDetails?> premiumProduct() async {
    final res = await _iap.queryProductDetails({AppConstants.premiumProductId});
    final all = res.productDetails.where((p) => p.id == AppConstants.premiumProductId).toList();
    for (final p in all) {
      if (p is GooglePlayProductDetails && p.subscriptionIndex != null) {
        final offer = p.productDetails.subscriptionOfferDetails![p.subscriptionIndex!];
        if (offer.basePlanId == AppConstants.premiumBasePlanId && offer.offerId == null) return p;
      }
    }
    return all.isEmpty ? null : all.first;
  }

  @override
  Future<bool> buy(ProductDetails product, {required String accountRef}) =>
      _iap.buyNonConsumable(purchaseParam: PurchaseParam(productDetails: product, applicationUserName: accountRef));

  @override
  Future<void> restore({required String accountRef}) => _iap.restorePurchases(applicationUserName: accountRef);

  @override
  Future<void> complete(PurchaseDetails purchase) async {
    if (purchase.pendingCompletePurchase) await _iap.completePurchase(purchase);
  }
}

enum BillingPhase { idle, loading, purchasing, pending, verifying, success, error }

class BillingState {
  const BillingState({this.available = false, this.price, this.phase = BillingPhase.idle, this.message});

  final bool available;

  /// Play's localized price, e.g. "₱399.00".
  final String? price;
  final BillingPhase phase;
  final String? message;

  bool get busy => phase == BillingPhase.loading || phase == BillingPhase.purchasing || phase == BillingPhase.verifying;

  BillingState copyWith({bool? available, String? price, BillingPhase? phase, String? message, bool clearMessage = false}) =>
      BillingState(
        available: available ?? this.available,
        price: price ?? this.price,
        phase: phase ?? this.phase,
        message: clearMessage ? null : (message ?? this.message),
      );
}

/// Purchase flow. A purchase reported by Play is sent to the server, which
/// verifies it with Google; only a server-signed Premium entitlement unlocks
/// scanning. Play is told the purchase is complete only after that. A
/// purchase the server refuses is never completed (Play refunds it).
class BillingDeps {
  const BillingDeps({required this.gateway, required this.service, required this.accountId});

  /// Null when billing is not available in this build.
  final BillingGateway? gateway;
  final LicenseService service;

  /// The signed-in account's ID, or null.
  final String? Function() accountId;
}

class BillingController extends Notifier<BillingState> {
  BillingController(this._resolve);

  final BillingDeps Function(Ref ref) _resolve;
  late BillingDeps _deps;
  StreamSubscription<List<PurchaseDetails>>? _sub;
  ProductDetails? _product;
  bool _userRestore = false;

  BillingGateway? get _gateway => _deps.gateway;
  LicenseService get _service => _deps.service;
  String? _accountId() => _deps.accountId();

  @override
  BillingState build() {
    _deps = _resolve(ref);
    final gateway = _gateway;
    if (gateway == null) return const BillingState();
    _sub = gateway.purchaseStream.listen(handle, onError: (_) {});
    ref.onDispose(() => _sub?.cancel());
    return const BillingState();
  }

  /// Loads the product and price from Play.
  Future<void> load() async {
    final gateway = _gateway;
    if (gateway == null) return;
    state = state.copyWith(phase: BillingPhase.loading, clearMessage: true);
    try {
      if (!await gateway.isAvailable()) {
        state = const BillingState(message: 'Google Play is not available on this phone.');
        return;
      }
      _product = await gateway.premiumProduct();
      state = BillingState(
        available: _product != null,
        price: _product?.price,
        message: _product == null ? 'Premium is not available in Google Play yet.' : null,
      );
    } catch (_) {
      state = const BillingState(message: 'Could not reach Google Play. Check your connection.');
    }
  }

  Future<void> buy() async {
    final gateway = _gateway;
    final account = _accountId();
    if (gateway == null || account == null) return;
    if (_product == null) await load();
    final product = _product;
    if (product == null) return;
    state = state.copyWith(phase: BillingPhase.purchasing, clearMessage: true);
    try {
      final started = await gateway.buy(product, accountRef: LicenseService.playAccountRef(account));
      if (!started) state = state.copyWith(phase: BillingPhase.idle, message: 'Google Play could not start the purchase.');
    } catch (_) {
      state = state.copyWith(phase: BillingPhase.error, message: 'Google Play could not start the purchase.');
    }
  }

  /// [userInitiated] shows "no subscription found" when nothing is restored.
  Future<void> restore({bool userInitiated = true}) async {
    final gateway = _gateway;
    final account = _accountId();
    if (gateway == null || account == null) return;
    _userRestore = userInitiated;
    if (userInitiated) state = state.copyWith(phase: BillingPhase.verifying, clearMessage: true);
    try {
      await gateway.restore(accountRef: LicenseService.playAccountRef(account));
      // Restored purchases arrive on the purchase stream; nothing owned = no event.
      await Future<void>.delayed(const Duration(seconds: 3));
      if (_userRestore && state.phase == BillingPhase.verifying) {
        state = state.copyWith(phase: BillingPhase.idle, message: 'No active Premium subscription was found for this Google account.');
      }
    } catch (_) {
      if (userInitiated) state = state.copyWith(phase: BillingPhase.error, message: 'Could not reach Google Play.');
    } finally {
      _userRestore = false;
    }
  }

  Future<void> handle(List<PurchaseDetails> purchases) async {
    for (final p in purchases) {
      if (p.productID != AppConstants.premiumProductId) continue;
      switch (p.status) {
        case PurchaseStatus.pending:
          state = state.copyWith(
            phase: BillingPhase.pending,
            message: 'Payment pending. Premium starts as soon as Google Play confirms your payment.',
          );
        case PurchaseStatus.canceled:
          state = state.copyWith(phase: BillingPhase.idle, clearMessage: true);
        case PurchaseStatus.error:
          state = state.copyWith(phase: BillingPhase.error, message: 'The purchase did not complete. You were not charged.');
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          await _verify(p);
      }
    }
  }

  Future<void> _verify(PurchaseDetails p) async {
    state = state.copyWith(phase: BillingPhase.verifying, message: 'Confirming your purchase with Google Play…');
    try {
      final outcome = await _service.verifyPurchase(p.verificationData.serverVerificationData);
      switch (outcome) {
        case PurchaseOutcome.granted:
          await _gateway?.complete(p);
          state = state.copyWith(phase: BillingPhase.success, message: 'Premium is active. Thank you!');
        case PurchaseOutcome.pending:
          state = state.copyWith(
            phase: BillingPhase.pending,
            message: 'Payment pending. Premium starts as soon as Google Play confirms your payment.',
          );
        case PurchaseOutcome.notGranted:
          state = state.copyWith(phase: BillingPhase.idle, message: 'This subscription is no longer active.');
      }
    } on LicenseApiException catch (e) {
      // Not completed: Play delivers it again (and refunds it if never confirmed).
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
