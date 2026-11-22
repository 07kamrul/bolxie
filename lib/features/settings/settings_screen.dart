import 'package:bloxie/features/common/gradient_scaffold.dart';
import 'package:bloxie/features/common/snack.dart';
import 'package:bloxie/features/settings/bloc/settings_cubit.dart';
import 'package:bloxie/features/wallet/bloc/purchase_cubit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: BlocListener<PurchaseCubit, PurchaseState>(
        listenWhen: (a, b) => b.message != null && a.message != b.message,
        listener: (context, s) => showSnack(context, s.message!),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            BlocBuilder<SettingsCubit, SettingsState>(
              builder: (context, s) => Column(
                children: [
                  SwitchListTile(
                    title: const Text('Sound'),
                    secondary: const Icon(Icons.volume_up),
                    value: s.soundOn,
                    onChanged: (_) =>
                        context.read<SettingsCubit>().toggleSound(),
                  ),
                  SwitchListTile(
                    title: const Text('Haptics'),
                    secondary: const Icon(Icons.vibration),
                    value: s.hapticsOn,
                    onChanged: (_) =>
                        context.read<SettingsCubit>().toggleHaptics(),
                  ),
                ],
              ),
            ),
            const Divider(height: 32),
            BlocBuilder<PurchaseCubit, PurchaseState>(
              builder: (context, s) => Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.block),
                    title: const Text('Remove Ads'),
                    subtitle: Text(
                      s.adsRemoved
                          ? 'Purchased. Thank you!'
                          : s.isStoreAvailable
                          ? 'One-time purchase'
                          : 'Store unavailable',
                    ),
                    trailing: s.adsRemoved
                        ? const Icon(
                            Icons.check_circle,
                            color: Colors.greenAccent,
                          )
                        : FilledButton(
                            style: FilledButton.styleFrom(
                              minimumSize: const Size(96, 44),
                            ),
                            onPressed: s.isStoreAvailable && !s.isBusy
                                ? () => context
                                      .read<PurchaseCubit>()
                                      .buyRemoveAds()
                                : null,
                            child: Text(s.price ?? 'Buy'),
                          ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.restore),
                    title: const Text('Restore purchases'),
                    enabled: s.isStoreAvailable && !s.isBusy,
                    onTap: () => context.read<PurchaseCubit>().restore(),
                  ),
                  if (s.isBusy) const LinearProgressIndicator(),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Center(
              child: Text(
                'Bloxie 1.0.0',
                style: TextStyle(color: Colors.white54),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
