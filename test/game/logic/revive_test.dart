import 'package:bloxie/game/logic/board_state.dart';
import 'package:bloxie/game/logic/placement.dart';
import 'package:bloxie/game/logic/revive.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fakes.dart';

void main() {
  test('apply clears exactly a 3x3 area', () {
    final full = BoardState.fromRows(List.filled(8, 'XXXXXXXX'));
    final next = Revive.apply(full, 2, 2);
    expect(next.filledCount, 64 - 9);
    expect(next.isFilled(2, 2), isFalse);
    expect(next.isFilled(4, 4), isFalse);
    expect(next.isFilled(5, 5), isTrue);
  });

  test('findArea prefers an area that lets a tray shape fit', () {
    final board = BoardState.fromRows(List.filled(8, 'XXXXXXXX'));
    final (r, c) = Revive.findArea(board, [sq3, null, null]);
    final cleared = Revive.apply(board, r, c);
    expect(Placement.anyFit(cleared, sq3), isTrue);
  });

  test('findArea stays inside the board', () {
    final board = BoardState.fromRows(List.filled(8, 'XXXXXXXX'));
    final (r, c) = Revive.findArea(board, [sq3, null, null]);
    expect(r, inInclusiveRange(0, 5));
    expect(c, inInclusiveRange(0, 5));
  });

  test('findArea with no fit still returns the densest area', () {
    final board = BoardState.fromRows([
      'XXX.....',
      'XXX.....',
      'XXX.....',
      '........',
      '........',
      '........',
      '........',
      '........',
    ]);
    final (r, c) = Revive.findArea(board, [null, null, null]);
    expect((r, c), (0, 0));
  });
}
