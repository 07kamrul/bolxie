import 'package:bloxie/features/game_screen/game_over_overlay.dart';
import 'package:bloxie/features/game_screen/tutorial_overlay.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const sizes = [
    Size(320, 480),
    Size(390, 844),
    Size(844, 340),
    Size(1024, 768),
  ];

  for (final size in sizes) {
    testWidgets('game over overlay has no overflow at $size', (tester) async {
      tester.view
        ..physicalSize = size
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GameOverOverlay(
              score: 123456,
              bestScore: 200000,
              isNewBest: false,
              coinsEarned: 12,
              canRevive: true,
              isBusy: false,
              onRevive: () {},
              onPlayAgain: () {},
              onHome: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('123456'), findsOneWidget);
    });

    testWidgets('tutorial steps through and finishes at $size', (tester) async {
      tester.view
        ..physicalSize = size
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      var done = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: TutorialOverlay(onDone: () => done = true)),
        ),
      );
      for (var i = 0; i < 2; i++) {
        await tester.ensureVisible(find.text('NEXT'));
        await tester.tap(find.text('NEXT'));
        await tester.pump();
      }
      await tester.ensureVisible(find.text("LET'S PLAY"));
      await tester.tap(find.text("LET'S PLAY"));
      expect(tester.takeException(), isNull);
      expect(done, isTrue);
    });
  }
}
