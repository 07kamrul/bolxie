import 'dart:async';

import 'package:bloxie/core/constants/iap_config.dart';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

enum IapOutcome { purchased, restored, pending, canceled, error }

@immutable
class IapEvent {
  const IapEvent(this.outcome, {this.productId, this.message});

  final IapOutcome outcome;
  final String? productId;
  final String? message;
}

abstract interface class IapService {
  Stream<IapEvent> get events;
  Future<bool> init();
  bool get isAvailable;
  String? get removeAdsPrice;
  Future<void> buyRemoveAds();
  Future<void> restore();
  Future<void> dispose();
}

class StoreIapService implements IapService {
  StoreIapService({InAppPurchase? iap}) : _iap = iap ?? InAppPurchase.instance;

  final InAppPurchase _iap;
  final _events = StreamController<IapEvent>.broadcast();
  StreamSubscription<List<PurchaseDetails>>? _sub;
  ProductDetails? _removeAds;
  bool _available = false;

  @override
  Stream<IapEvent> get events => _events.stream;

  @override
  bool get isAvailable => _available && _removeAds != null;

  @override
  String? get removeAdsPrice => _removeAds?.price;

  @override
  Future<bool> init() async {
    try {
      _available = await _iap.isAvailable();
      if (!_available) return false;
      _sub = _iap.purchaseStream.listen(
        _onPurchases,
        onError: (Object e) =>
            _events.add(IapEvent(IapOutcome.error, message: '$e')),
      );
      final response = await _iap.queryProductDetails({IapConfig.removeAdsId});
      if (response.productDetails.isNotEmpty) {
        _removeAds = response.productDetails.first;
      }
      return isAvailable;
    } on Object catch (e) {
      debugPrint('iap init failed: $e');
      _available = false;
      return false;
    }
  }

  Future<void> _onPurchases(List<PurchaseDetails> purchases) async {
    for (final p in purchases) {
      switch (p.status) {
        case PurchaseStatus.pending:
          _events.add(IapEvent(IapOutcome.pending, productId: p.productID));
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          if (p.productID == IapConfig.removeAdsId) {
            _events.add(
              IapEvent(
                p.status == PurchaseStatus.restored
                    ? IapOutcome.restored
                    : IapOutcome.purchased,
                productId: p.productID,
              ),
            );
          }
        case PurchaseStatus.canceled:
          _events.add(IapEvent(IapOutcome.canceled, productId: p.productID));
        case PurchaseStatus.error:
          _events.add(
            IapEvent(
              IapOutcome.error,
              productId: p.productID,
              message: p.error?.message,
            ),
          );
      }
      if (p.pendingCompletePurchase) await _iap.completePurchase(p);
    }
  }

  @override
  Future<void> buyRemoveAds() async {
    final product = _removeAds;
    if (product == null) {
      _events.add(
        const IapEvent(IapOutcome.error, message: 'Store unavailable'),
      );
      return;
    }
    await _iap.buyNonConsumable(
      purchaseParam: PurchaseParam(productDetails: product),
    );
  }

  @override
  Future<void> restore() => _iap.restorePurchases();

  @override
  Future<void> dispose() async {
    await _sub?.cancel();
    await _events.close();
  }
}

/// Used when billing is unavailable.
class NoopIapService implements IapService {
  @override
  Stream<IapEvent> get events => const Stream.empty();
  @override
  Future<bool> init() async => false;
  @override
  bool get isAvailable => false;
  @override
  String? get removeAdsPrice => null;
  @override
  Future<void> buyRemoveAds() async {}
  @override
  Future<void> restore() async {}
  @override
  Future<void> dispose() async {}
}
