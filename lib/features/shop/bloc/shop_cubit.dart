import 'dart:async';

import 'package:bloxie/core/theme/skins.dart';
import 'package:bloxie/features/wallet/bloc/wallet_cubit.dart';
import 'package:bloxie/services/analytics/analytics_service.dart';
import 'package:bloxie/services/storage/prefs_repository.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ShopState extends Equatable {
  const ShopState({required this.selectedId, required this.unlocked});

  final String selectedId;
  final Set<String> unlocked;

  @override
  List<Object?> get props => [selectedId, unlocked.toList()..sort()];
}

enum ShopResult { selected, unlocked, insufficientCoins }

class ShopCubit extends Cubit<ShopState> {
  ShopCubit({
    required PrefsRepository prefs,
    required WalletCubit wallet,
    required AnalyticsService analytics,
  }) : _prefs = prefs,
       _wallet = wallet,
       _analytics = analytics,
       super(
         ShopState(
           selectedId: prefs.selectedSkin,
           unlocked: prefs.unlockedSkins,
         ),
       );

  final PrefsRepository _prefs;
  final WalletCubit _wallet;
  final AnalyticsService _analytics;

  /// Selects an owned skin, or buys then selects it if affordable.
  Future<ShopResult> selectOrBuy(String id) async {
    final skin = Skins.byId(id);
    var result = ShopResult.selected;
    var unlocked = state.unlocked;
    if (!unlocked.contains(skin.id)) {
      if (!await _wallet.spend(skin.price)) return ShopResult.insufficientCoins;
      unlocked = {...unlocked, skin.id};
      await _prefs.setUnlockedSkins(unlocked);
      result = ShopResult.unlocked;
    }
    emit(ShopState(selectedId: skin.id, unlocked: unlocked));
    await _prefs.setSelectedSkin(skin.id);
    unawaited(_analytics.themeChanged(themeId: skin.id));
    return result;
  }
}
