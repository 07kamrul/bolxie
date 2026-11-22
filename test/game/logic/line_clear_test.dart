import 'package:bloxie/game/logic/board_state.dart';
import 'package:bloxie/game/logic/line_clear.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('finds nothing on an empty board', () {
    final result = LineClear.find(BoardState.empty());
    expect(result.lineCount, 0);
    expect(result.isEmpty, isTrue);
  });

  test('finds a full row', () {
    final board = BoardState.fromRows(['.', '.', 'XXXXXXXX']);
    final result = LineClear.find(board);
    expect(result.rows, [2]);
    expect(result.cols, isEmpty);
  });

  test('finds a full column', () {
    final board = BoardState.fromRows(List.filled(8, '...X....'));
    final result = LineClear.find(board);
    expect(result.cols, [3]);
    expect(result.rows, isEmpty);
  });

  test('a crossing row and column count as two lines and share a cell', () {
    final rows = List.filled(8, '...X....');
    rows[2] = 'XXXXXXXX';
    final result = LineClear.find(BoardState.fromRows(rows));
    expect(result.lineCount, 2);
    // 8 + 8 - 1 shared cell
    expect(result.cellIndices.length, 15);
  });

  test('apply clears cells and leaves others intact', () {
    final rows = List.filled(8, '.');
    rows[0] = 'XXXXXXXX';
    rows[1] = 'X.......';
    final board = BoardState.fromRows(rows);
    final cleared = LineClear.apply(board, LineClear.find(board));
    expect(cleared.filledCount, 1);
    expect(cleared.isFilled(1, 0), isTrue);
  });

  test('clears several lines at once', () {
    final board = BoardState.fromRows([
      'XXXXXXXX',
      'XXXXXXXX',
      'XXXXXXXX',
      '........',
      '........',
      '........',
      '........',
      '........',
    ]);
    final result = LineClear.find(board);
    expect(result.rows, [0, 1, 2]);
    expect(LineClear.apply(board, result).isEmpty, isTrue);
  });
}
