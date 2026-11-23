import 'dart:ui';

import 'package:bloxie/game/game_layout.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const sizes = <String, Size>{
    'small phone': Size(320, 480),
    'phone': Size(390, 700),
    'tall phone': Size(412, 800),
    'tablet portrait': Size(768, 950),
    'phone landscape': Size(800, 340),
    'tablet landscape': Size(1024, 700),
    'desktop': Size(1280, 720),
    'fold': Size(280, 640),
  };

  for (final e in sizes.entries) {
    group('${e.key} ${e.value}', () {
      final l = GameLayout(e.value.width, e.value.height);
      final bounds = Rect.fromLTWH(0, 0, e.value.width, e.value.height);
      final board = Rect.fromLTWH(
        l.boardLeft,
        l.boardTop,
        l.boardSize,
        l.boardSize,
      );

      test('board fits inside the area', () {
        expect(l.boardSize, greaterThan(0));
        expect(bounds.contains(board.topLeft), isTrue);
        expect(board.right, lessThanOrEqualTo(e.value.width + 0.001));
        expect(board.bottom, lessThanOrEqualTo(e.value.height + 0.001));
      });

      test('slots stay inside the area and do not overlap the board', () {
        for (var i = 0; i < 3; i++) {
          final r = l.slotRect(i);
          expect(r.left, greaterThanOrEqualTo(-0.001));
          expect(r.right, lessThanOrEqualTo(e.value.width + 0.001));
          expect(r.bottom, lessThanOrEqualTo(e.value.height + 0.001));
          expect(r.overlaps(board), isFalse, reason: 'slot $i overlaps board');
        }
      });

      test('slots do not overlap each other', () {
        for (var i = 0; i < 2; i++) {
          final a = l.slotRect(i);
          final b = l.slotRect(i + 1);
          expect(
            a.intersect(b).isEmpty ||
                a.intersect(b).width <= 0.001 ||
                a.intersect(b).height <= 0.001,
            isTrue,
          );
        }
      });

      test('every hit area is at least 48px', () {
        for (var i = 0; i < 3; i++) {
          final r = l.slotHitRect(i, 0);
          expect(r.width, greaterThanOrEqualTo(48));
          expect(r.height, greaterThanOrEqualTo(48));
        }
      });
    });
  }

  test('portrait vs wide mode choice', () {
    expect(GameLayout(390, 800).isWide, isFalse);
    expect(GameLayout(1024, 700).isWide, isTrue);
  });

  test('board is capped on huge screens', () {
    expect(
      GameLayout(2000, 3000).boardSize,
      lessThanOrEqualTo(GameLayout.maxBoardSize),
    );
  });

  test('zero size does not throw or produce NaN', () {
    final l = GameLayout(0, 0);
    expect(l.boardSize, 0);
    expect(l.trayScale, 0);
    expect(l.unit.isNaN, isFalse);
  });
}
