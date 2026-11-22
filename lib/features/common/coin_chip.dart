import 'package:bloxie/features/wallet/bloc/wallet_cubit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

class CoinChip extends StatelessWidget {
  const CoinChip({super.key});

  @override
  Widget build(BuildContext context) {
    final coins = context.select<WalletCubit, int>((c) => c.state.coins);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.monetization_on, color: Color(0xFFFFD43B), size: 20),
          const SizedBox(width: 6),
          Text('$coins', style: const TextStyle(fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}
