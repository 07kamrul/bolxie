import 'package:bloxie/features/common/constrained_content.dart';
import 'package:material_ui/material_ui.dart';

/// First-run coach: three short steps, shown once.
class TutorialOverlay extends StatefulWidget {
  const TutorialOverlay({required this.onDone, super.key});

  final VoidCallback onDone;

  @override
  State<TutorialOverlay> createState() => _TutorialOverlayState();
}

class _TutorialOverlayState extends State<TutorialOverlay> {
  static const _steps = <(IconData, String, String)>[
    (
      Icons.touch_app_rounded,
      'Drag a piece',
      'Pick a piece from the tray and drag it onto the board.',
    ),
    (
      Icons.view_week_rounded,
      'Complete lines',
      'Fill a full row or column to clear it and score points.',
    ),
    (
      Icons.local_fire_department_rounded,
      'Build combos',
      'Clear lines on back-to-back moves for bigger combos.',
    ),
  ];

  int _index = 0;

  void _next() {
    if (_index == _steps.length - 1) {
      widget.onDone();
    } else {
      setState(() => _index++);
    }
  }

  @override
  Widget build(BuildContext context) {
    final (icon, title, body) = _steps[_index];
    final isLast = _index == _steps.length - 1;
    return ColoredBox(
      color: Colors.black.withValues(alpha: 0.82),
      child: ScrollableCenter(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Semantics(
            liveRegion: true,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 72),
                const SizedBox(height: 16),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  body,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16, color: Colors.white70),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (var i = 0; i < _steps.length; i++)
                      Container(
                        width: 8,
                        height: 8,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: i == _index ? Colors.white : Colors.white24,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _next,
                  child: Text(isLast ? "LET'S PLAY" : 'NEXT'),
                ),
                if (!isLast)
                  TextButton(
                    onPressed: widget.onDone,
                    child: const Text('SKIP'),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
