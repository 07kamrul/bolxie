import 'package:bloxie/features/common/constrained_content.dart';
import 'package:bloxie/features/common/gradient_scaffold.dart';
import 'package:bloxie/features/stats/bloc/stats_cubit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      appBar: AppBar(title: const Text('Stats')),
      body: BlocBuilder<StatsCubit, StatsState>(
        builder: (context, s) => ConstrainedContent(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _StatCard(
                icon: Icons.sports_esports,
                label: 'Games played',
                value: '${s.gamesPlayed}',
              ),
              _StatCard(
                icon: Icons.emoji_events,
                label: 'Best score',
                value: '${s.bestScore}',
              ),
              _StatCard(
                icon: Icons.view_week_rounded,
                label: 'Lines cleared',
                value: '${s.totalLines}',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.black.withValues(alpha: 0.3),
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Icon(icon, size: 36),
            const SizedBox(width: 16),
            Expanded(child: Text(label, style: const TextStyle(fontSize: 18))),
            Text(
              value,
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
            ),
          ],
        ),
      ),
    );
  }
}
