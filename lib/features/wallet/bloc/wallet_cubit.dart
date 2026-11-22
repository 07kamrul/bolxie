import 'package:bloxie/services/storage/prefs_repository.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class WalletState extends Equatable {
  const WalletState({required this.coins});

  final int coins;

  @override
  List<Object?> get props => [coins];
}

class WalletCubit extends Cubit<WalletState> {
  WalletCubit(this._prefs) : super(WalletState(coins: _prefs.coins));

  final PrefsRepository _prefs;

  Future<void> addCoins(int amount) async {
    if (amount <= 0) return;
    final next = state.coins + amount;
    emit(WalletState(coins: next));
    await _prefs.setCoins(next);
  }

  /// Deducts [amount] if affordable. Returns whether it succeeded.
  Future<bool> spend(int amount) async {
    if (amount < 0 || amount > state.coins) return false;
    final next = state.coins - amount;
    emit(WalletState(coins: next));
    await _prefs.setCoins(next);
    return true;
  }
}
