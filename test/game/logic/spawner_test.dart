import 'dart:math';

import 'package:bloxie/game/logic/board_state.dart';
import 'package:bloxie/game/logic/placement.dart';
import 'package:bloxie/game/logic/spawner.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('offers three shapes', () {
    final tray = Spawner(random: Random(1)).nextTray(BoardState.empty());
    expect(tray.length, 3);
    expect(tray.every((s) => s != null), isTrue);
  });

  test('is repeatable with a fixed seed', () {
    final a = Spawner(random: Random(7)).nextTray(BoardState.empty());
    final b = Spawner(random: Random(7)).nextTray(BoardState.empty());
    expect(a.map((s) => s!.id), b.map((s) => s!.id));
  });

  test('always includes a placeable shape when one exists (crowded board)', () {
    // Only a single 1x1 hole: every tray must contain the single block.
    final board = BoardState.fromRows([
      'XXXXXXXX',
      'XXXXXXXX',
      'XXXXXXXX',
      'XXXX.XXX',
      'XXXXXXXX',
      'XXXXXXXX',
      'XXXXXXXX',
      'XXXXXXX.',
    ]);
    for (var seed = 0; seed < 200; seed++) {
      final tray = Spawner(random: Random(seed)).nextTray(board);
      expect(
        tray.any((s) => Placement.anyFit(board, s!)),
        isTrue,
        reason: 'seed $seed produced an unplayable tray',
      );
    }
  });

  test('falls back gracefully when nothing can fit at all', () {
    final board = BoardState.fromRows(List.filled(8, 'XXXXXXXX'));
    final tray = Spawner(random: Random(3)).nextTray(board);
    expect(tray.length, 3);
  });
}
