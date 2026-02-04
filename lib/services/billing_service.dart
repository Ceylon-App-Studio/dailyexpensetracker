import 'dart:async';
import 'package:in_app_purchase/in_app_purchase.dart';

class BillingService {
  BillingService._();
  static final BillingService instance = BillingService._();

  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _sub;

  // Your Play Console subscription product id
  static const String premiumSubId = 'dailybudgeto_premium';

  Future<bool> isAvailable() => _iap.isAvailable();

  Future<ProductDetailsResponse> fetchProducts() async {
    return _iap.queryProductDetails({premiumSubId});
  }

  void listenPurchases({
    required void Function(PurchaseDetails purchase) onPurchase,
    required void Function(Object error) onError,
  }) {
    _sub?.cancel();
    _sub = _iap.purchaseStream.listen(
          (purchases) {
        for (final p in purchases) {
          onPurchase(p);
        }
      },
      onError: onError,
    );
  }

  Future<void> buy(ProductDetails product) async {
    final purchaseParam = PurchaseParam(productDetails: product);
    // Subscriptions use buyNonConsumable in this plugin API.
    await _iap.buyNonConsumable(purchaseParam: purchaseParam);
  }

  Future<void> restore() => _iap.restorePurchases();

  Future<void> completeIfNeeded(PurchaseDetails p) async {
    if (p.pendingCompletePurchase) {
      await _iap.completePurchase(p);
    }
  }

  Future<void> dispose() async {
    await _sub?.cancel();
    _sub = null;
  }
}
