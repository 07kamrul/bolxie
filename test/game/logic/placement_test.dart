import 'package:bloxie/game/logic/board_state.dart';
import 'package:bloxie/game/logic/placement.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fakes.dart';

void main() {
  group('Placement.canPlace', () {
    test('accepts a shape on an empty board', () {
      expect(Placement.canPlace(BoardState.empty(), sq3, 0, 0), isTrue);
    });

    test('rejects a shape that overflows the right edge', () {
      expect(Placement.canPlace(BoardState.empty(), h3, 0, 6), isFalse);
    });

    test('rejects a shape that overflows the bottom edge', () {
      expect(Placement.canPlace(BoardState.empty(), v3, 6, 0), isFalse);
    });

    test('rejects negative origins', () {
      expect(Placement.canPlace(BoardState.empty(), single, -1, 0), isFalse);
      expect(Placement.canPlace(BoardState.empty(), single, 0, -1), isFalse);
    });

    test('rejects overlap with filled cells', () {
      final board = Placement.place(BoardState.empty(), single, 3, 3, 1);
      expect(Placement.canPlace(board, h2, 3, 2), isFalse);
      expect(Placement.canPlace(board, h2, 3, 4), isTrue);
    });

    test('respects non-rectangular shapes', () {
      final board = Placement.place(BoardState.empty(), single, 0, 1, 1);
      // L occupies (0,0),(1,0),(2,0),(2,1): (0,1) is free for it.
      expect(Placement.canPlace(board, lShape, 0, 0), isTrue);
    });
  });

  group('Placement.place', () {
    test('returns a new board and leaves the original untouched', () {
      final original = BoardState.empty();
      final next = Placement.place(original, h2, 2, 2, 3);
      expect(original.isEmpty, isTrue);
      expect(next.filledCount, 2);
      expect(next.at(2, 2), 3);
      expect(next.at(2, 3), 3);
    });
  });

  group('Placement.anyFit / isGameOver', () {
    test('anyFit is true on an empty board', () {
      expect(Placement.anyFit(BoardState.empty(), sq3), isTrue);
    });

    test('anyFit is false when no 2x2 hole exists', () {
      final board = BoardState.fromRows([
        'X.X.X.X.',
        '.X.X.X.X',
        'X.X.X.X.',
        '.X.X.X.X',
        'X.X.X.X.',
        '.X.X.X.X',
        'X.X.X.X.',
        '.X.X.X.X',
      ]);
      expect(Placement.anyFit(board, sq2), isFalse);
      expect(Placement.anyFit(board, single), isTrue);
    });

    test('isGameOver is false while any tray shape fits', () {
      final board = BoardState.fromRows([
        'XXXXXXXX',
        'XXXXXXXX',
        'XXXXXXXX',
        'XXXXXXXX',
        'XXXXXXXX',
        'XXXXXXXX',
        'XXXXXXXX',
        'XXXXXXX.',
      ]);
      expect(Placement.isGameOver(board, [sq2, null, single]), isFalse);
    });

    test('isGameOver is true when no remaining shape fits', () {
      final board = BoardState.fromRows([
        'XXXXXXXX',
        'XXXXXXXX',
        'XXXXXXXX',
        'XXXXXXXX',
        'XXXXXXXX',
        'XXXXXXXX',
        'XXXXXXXX',
        'XXXXXXX.',
      ]);
      expect(Placement.isGameOver(board, [sq2, h2, null]), isTrue);
    });

    test('isGameOver is false for an empty tray (refill pending)', () {
      expect(
        Placement.isGameOver(BoardState.empty(), [null, null, null]),
        isFalse,
      );
    });
  });

  group('Placement.snap', () {
    test('returns the exact cell when valid', () {
      final spot = Placement.snap(BoardState.empty(), sq2, 3, 3);
      expect(spot, (3, 3));
    });

    test('snaps to the nearest valid neighbour', () {
      final board = Placement.place(BoardState.empty(), single, 3, 3, 1);
      final spot = Placement.snap(board, single, 3, 3);
      expect(spot, isNotNull);
      expect(Placement.canPlace(board, single, spot!.$1, spot.$2), isTrue);
    });

    test('returns null when nothing is valid within the radius', () {
      final board = BoardState.fromRows([
        'XXXXXXXX',
        'XXXXXXXX',
        'XXXXXXXX',
        'XXXXXXXX',
        'XXXXXXXX',
        'XXXXXXXX',
        'XXXXXXXX',
        'XXXXXXX.',
      ]);
      expect(Placement.snap(board, single, 1, 1), isNull);
    });
  });
}
