import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../models/subscription.dart';
import '../services/subscription_hive_service.dart';
import '../services/billing_service.dart';

class SubscriptionUiState {
  final bool loading;
  final String? error;
  final ProductDetails? product;
  final Subscription? localSub;

  const SubscriptionUiState({
    required this.loading,
    this.error,
    this.product,
    this.localSub,
  });
  //final bool kForcePremiumForDebug = true;

  bool get isPremium =>  localSub != null && localSub!.isActive;
}

final subscriptionUiProvider =
StateNotifierProvider<SubscriptionUiNotifier, SubscriptionUiState>(
      (ref) => SubscriptionUiNotifier()..init(),
);

class SubscriptionUiNotifier extends StateNotifier<SubscriptionUiState> {
  SubscriptionUiNotifier()
      : super(const SubscriptionUiState(loading: true));

  final _billing = BillingService.instance;

  Future<void> init() async {
    try {
      // Load local subscription first
      final local = SubscriptionHiveService.getSubscription();
      state = SubscriptionUiState(loading: true, localSub: local);

      final available = await _billing.isAvailable();
      if (!available) {
        state = SubscriptionUiState(
          loading: false,
          localSub: local,
          error: 'Billing not available on this device.',
        );
        return;
      }

      final productsResp = await _billing.fetchProducts();
      if (productsResp.error != null) {
        state = SubscriptionUiState(
          loading: false,
          localSub: local,
          error: productsResp.error!.message,
        );
        return;
      }

      final product = productsResp.productDetails.isNotEmpty
          ? productsResp.productDetails.first
          : null;

      _billing.listenPurchases(
        onPurchase: _handlePurchase,
        onError: (e) {
          state = SubscriptionUiState(
            loading: false,
            localSub: state.localSub,
            product: state.product,
            error: e.toString(),
          );
        },
      );

      state = SubscriptionUiState(
        loading: false,
        localSub: local,
        product: product,
      );
    } catch (e) {
      state = SubscriptionUiState(loading: false, error: e.toString());
    }
  }

  Future<void> buyPremium() async {
    final product = state.product;
    if (product == null) {
      state = SubscriptionUiState(
        loading: false,
        localSub: state.localSub,
        error: 'Product not found. Did you publish the subscription in Play Console?',
      );
      return;
    }

    state = SubscriptionUiState(
      loading: true,
      localSub: state.localSub,
      product: state.product,
    );

    await _billing.buy(product);

    // Purchase result comes via stream
  }

  Future<void> restore() async {
    state = SubscriptionUiState(
      loading: true,
      localSub: state.localSub,
      product: state.product,
    );
    await _billing.restore();
    state = SubscriptionUiState(
      loading: false,
      localSub: state.localSub,
      product: state.product,
    );
  }

  Future<void> _handlePurchase(PurchaseDetails p) async {
    // You should verify purchase (server) in production.
    // For MVP: treat purchased/restored status as premium entitlement.
    if (p.status == PurchaseStatus.purchased ||
        p.status == PurchaseStatus.restored) {
      final now = DateTime.now();

      // Entitlement duration is tricky with base plans.
      // For MVP, you can set a short "active" window and rely on restore on next launch,
      // OR better: store purchase + use server verification later.
      final local = Subscription(
        type: SubscriptionType.yearly, // temporary; see note below
        startDate: now,
        endDate: DateTime(now.year + 1, now.month, now.day),
      );

      await SubscriptionHiveService.saveSubscription(local);
      state = SubscriptionUiState(
        loading: false,
        localSub: local,
        product: state.product,
      );
    } else if (p.status == PurchaseStatus.error) {
      state = SubscriptionUiState(
        loading: false,
        localSub: state.localSub,
        product: state.product,
        error: p.error?.message ?? 'Purchase failed.',
      );
    }

    await _billing.completeIfNeeded(p);
  }

  @override
  void dispose() {
    _billing.dispose();
    super.dispose();
  }
}
