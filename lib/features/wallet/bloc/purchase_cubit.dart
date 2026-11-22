import 'dart:async';

import 'package:bloxie/core/constants/iap_config.dart';
import 'package:bloxie/services/analytics/analytics_service.dart';
import 'package:bloxie/services/iap/iap_service.dart';
import 'package:bloxie/services/storage/prefs_repository.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class PurchaseState extends Equatable {
  const PurchaseState({
    required this.adsRemoved,
    this.isStoreAvailable = false,
    this.isBusy = false,
    this.price,
    this.message,
  });

  final bool adsRemoved;
  final bool isStoreAvailable;
  final bool isBusy;
  final String? price;

  /// One-shot user-facing status (shown in a snackbar then ignored).
  final String? message;

  PurchaseState copyWith({
    bool? adsRemoved,
    bool? isStoreAvailable,
    bool? isBusy,
    String? price,
    String? message,
  }) => PurchaseState(
    adsRemoved: adsRemoved ?? this.adsRemoved,
    isStoreAvailable: isStoreAvailable ?? this.isStoreAvailable,
    isBusy: isBusy ?? this.isBusy,
    price: price ?? this.price,
    message: message,
  );

  @override
  List<Object?> get props => [
    adsRemoved,
    isStoreAvailable,
    isBusy,
    price,
    message,
  ];
}

class PurchaseCubit extends Cubit<PurchaseState> {
  PurchaseCubit({
    required PrefsRepository prefs,
    required IapService iap,
    required AnalyticsService analytics,
  }) : _prefs = prefs,
       _iap = iap,
       _analytics = analytics,
       super(PurchaseState(adsRemoved: prefs.adsRemoved));

  final PrefsRepository _prefs;
  final IapService _iap;
  final AnalyticsService _analytics;
  StreamSubscription<IapEvent>? _sub;

  Future<void> init() async {
    _sub = _iap.events.listen(_onEvent);
    final ok = await _iap.init();
    emit(state.copyWith(isStoreAvailable: ok, price: _iap.removeAdsPrice));
  }

  Future<void> buyRemoveAds() async {
    if (state.adsRemoved || state.isBusy) return;
    emit(state.copyWith(isBusy: true));
    await _iap.buyRemoveAds();
  }

  Future<void> restore() async {
    if (state.isBusy) return;
    emit(state.copyWith(isBusy: true));
    await _iap.restore();
    // Restores with nothing to restore emit no event; release the busy flag.
    Timer(const Duration(seconds: 8), () {
      if (!isClosed && state.isBusy) {
        emit(state.copyWith(isBusy: false, message: 'No purchases to restore'));
      }
    });
  }

  Future<void> _onEvent(IapEvent e) async {
    switch (e.outcome) {
      case IapOutcome.purchased:
      case IapOutcome.restored:
        await _prefs.setAdsRemoved(true);
        if (e.outcome == IapOutcome.purchased) {
          unawaited(_analytics.iapPurchase(productId: IapConfig.removeAdsId));
        }
        emit(
          state.copyWith(
            adsRemoved: true,
            isBusy: false,
            message: e.outcome == IapOutcome.restored
                ? 'Purchase restored'
                : 'Ads removed. Thank you!',
          ),
        );
      case IapOutcome.pending:
        emit(state.copyWith(isBusy: true));
      case IapOutcome.canceled:
        emit(state.copyWith(isBusy: false));
      case IapOutcome.error:
        emit(
          state.copyWith(
            isBusy: false,
            message: e.message ?? 'Purchase failed',
          ),
        );
    }
  }

  @override
  Future<void> close() async {
    await _sub?.cancel();
    return super.close();
  }
}
