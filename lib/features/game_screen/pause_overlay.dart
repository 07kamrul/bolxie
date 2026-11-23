import 'package:bloxie/features/common/constrained_content.dart';
import 'package:bloxie/features/settings/bloc/settings_cubit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

class PauseOverlay extends StatelessWidget {
  const PauseOverlay({
    required this.onResume,
    required this.onRestart,
    required this.onHome,
    super.key,
  });

  final VoidCallback onResume;
  final VoidCallback onRestart;
  final VoidCallback onHome;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black.withValues(alpha: 0.7),
      child: ScrollableCenter(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'PAUSED',
              style: TextStyle(fontSize: 40, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 24),
            FilledButton(onPressed: onResume, child: const Text('RESUME')),
            const SizedBox(height: 12),
            FilledButton.tonal(
              onPressed: onRestart,
              child: const Text('RESTART'),
            ),
            const SizedBox(height: 12),
            FilledButton.tonal(onPressed: onHome, child: const Text('HOME')),
            const SizedBox(height: 24),
            BlocBuilder<SettingsCubit, SettingsState>(
              builder: (context, s) => Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton.filledTonal(
                    onPressed: () =>
                        context.read<SettingsCubit>().toggleSound(),
                    icon: Icon(s.soundOn ? Icons.volume_up : Icons.volume_off),
                    tooltip: 'Sound',
                  ),
                  const SizedBox(width: 16),
                  IconButton.filledTonal(
                    onPressed: () =>
                        context.read<SettingsCubit>().toggleHaptics(),
                    icon: Icon(
                      s.hapticsOn ? Icons.vibration : Icons.mobile_off,
                    ),
                    tooltip: 'Haptics',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
