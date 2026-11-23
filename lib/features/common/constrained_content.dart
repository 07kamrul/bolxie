import 'package:material_ui/material_ui.dart';

/// Centres [child] and caps its width so screens stay readable on tablets,
/// desktop windows and landscape phones.
class ConstrainedContent extends StatelessWidget {
  const ConstrainedContent({
    required this.child,
    super.key,
    this.maxWidth = 560,
  });

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.topCenter,
    child: ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: child,
    ),
  );
}

/// Vertically centres [child] when there is room and scrolls when there is
/// not (short landscape screens, large text scale).
class ScrollableCenter extends StatelessWidget {
  const ScrollableCenter({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: constraints.maxHeight - 32),
        child: Center(child: child),
      ),
    ),
  );
}
