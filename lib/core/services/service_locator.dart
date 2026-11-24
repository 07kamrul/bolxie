import 'dart:io' show Platform;

import 'package:bloxie/features/daily_reward/bloc/daily_reward_cubit.dart';
import 'package:bloxie/features/levels/bloc/level_progress_cubit.dart';
import 'package:bloxie/features/settings/bloc/settings_cubit.dart';
import 'package:bloxie/features/shop/bloc/shop_cubit.dart';
import 'package:bloxie/features/stats/bloc/stats_cubit.dart';
import 'package:bloxie/features/wallet/bloc/purchase_cubit.dart';
import 'package:bloxie/features/wallet/bloc/wallet_cubit.dart';
import 'package:bloxie/services/ads/ad_service.dart';
import 'package:bloxie/services/analytics/analytics_service.dart';
import 'package:bloxie/services/audio/audio_service.dart';
import 'package:bloxie/services/audio/haptics_service.dart';
import 'package:bloxie/services/iap/iap_service.dart';
import 'package:bloxie/services/storage/prefs_repository.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

final GetIt sl = GetIt.instance;

bool get _isMobile => Platform.isAndroid || Platform.isIOS;

/// Wires up services and app-level cubits. Call once at startup.
Future<void> setupServices() async {
  final prefs = PrefsRepository(await SharedPreferences.getInstance());
  const AnalyticsService analytics = NoopAnalyticsService();

  final settings = SettingsCubit(prefs);
  final wallet = WalletCubit(prefs);
  final iap = _isMobile ? StoreIapService() : NoopIapService();
  final purchase = PurchaseCubit(prefs: prefs, iap: iap, analytics: analytics);

  sl
    ..registerSingleton<PrefsRepository>(prefs)
    ..registerSingleton<AnalyticsService>(analytics)
    ..registerSingleton<SettingsCubit>(settings)
    ..registerSingleton<WalletCubit>(wallet)
    ..registerSingleton<IapService>(iap)
    ..registerSingleton<PurchaseCubit>(purchase)
    ..registerSingleton<StatsCubit>(StatsCubit(prefs))
    ..registerSingleton<LevelProgressCubit>(LevelProgressCubit(prefs))
    ..registerSingleton<ShopCubit>(
      ShopCubit(prefs: prefs, wallet: wallet, analytics: analytics),
    )
    ..registerSingleton<DailyRewardCubit>(
      DailyRewardCubit(prefs: prefs, wallet: wallet, analytics: analytics),
    )
    ..registerSingleton<HapticsService>(
      HapticsService(isEnabled: () => settings.state.hapticsOn),
    )
    ..registerSingleton<AudioService>(
      AudioService(isEnabled: () => settings.state.soundOn),
    )
    ..registerSingleton<AdService>(
      _isMobile
          ? AdMobAdService(
              analytics: analytics,
              adsRemoved: () => purchase.state.adsRemoved,
            )
          : NoopAdService(),
    );
}

/// Slow, non-critical initialisation kicked off after the first frame.
Future<void> warmUpServices() async {
  await Future.wait([
    sl<AudioService>().preload(),
    sl<PurchaseCubit>().init(),
    sl<AdService>().init(),
  ]);
}
