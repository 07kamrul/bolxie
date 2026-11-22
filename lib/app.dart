import 'package:bloxie/core/services/service_locator.dart';
import 'package:bloxie/core/theme/app_theme.dart';
import 'package:bloxie/core/theme/skins.dart';
import 'package:bloxie/features/daily_reward/bloc/daily_reward_cubit.dart';
import 'package:bloxie/features/home/home_screen.dart';
import 'package:bloxie/features/settings/bloc/settings_cubit.dart';
import 'package:bloxie/features/shop/bloc/shop_cubit.dart';
import 'package:bloxie/features/stats/bloc/stats_cubit.dart';
import 'package:bloxie/features/wallet/bloc/purchase_cubit.dart';
import 'package:bloxie/features/wallet/bloc/wallet_cubit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

class BloxieApp extends StatelessWidget {
  const BloxieApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: sl<SettingsCubit>()),
        BlocProvider.value(value: sl<WalletCubit>()),
        BlocProvider.value(value: sl<PurchaseCubit>()),
        BlocProvider.value(value: sl<ShopCubit>()),
        BlocProvider.value(value: sl<DailyRewardCubit>()),
        BlocProvider.value(value: sl<StatsCubit>()),
      ],
      child: BlocBuilder<ShopCubit, ShopState>(
        buildWhen: (a, b) => a.selectedId != b.selectedId,
        builder: (context, shop) {
          final skin = Skins.byId(shop.selectedId);
          return MaterialApp(
            title: 'Bloxie',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.of(skin),
            home: const HomeScreen(),
          );
        },
      ),
    );
  }
}
