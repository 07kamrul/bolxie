import 'package:bloxie/core/theme/game_skin.dart';
import 'package:material_ui/material_ui.dart';

class ThemeCard extends StatelessWidget {
  const ThemeCard({
    required this.skin,
    required this.isSelected,
    required this.isUnlocked,
    required this.onTap,
    super.key,
  });

  final GameSkin skin;
  final bool isSelected;
  final bool isUnlocked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [skin.bgTop, skin.bgBottom]),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? skin.accent : Colors.white12,
            width: isSelected ? 3 : 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    skin.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      for (final c in skin.palette.take(5))
                        Container(
                          width: 26,
                          height: 26,
                          margin: const EdgeInsets.only(right: 6),
                          decoration: BoxDecoration(
                            color: c,
                            borderRadius: BorderRadius.circular(7),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            _Status(skin: skin, isSelected: isSelected, isUnlocked: isUnlocked),
          ],
        ),
      ),
    );
  }
}

class _Status extends StatelessWidget {
  const _Status({
    required this.skin,
    required this.isSelected,
    required this.isUnlocked,
  });

  final GameSkin skin;
  final bool isSelected;
  final bool isUnlocked;

  @override
  Widget build(BuildContext context) {
    if (isSelected) {
      return const Chip(
        label: Text('Selected'),
        avatar: Icon(Icons.check, size: 18),
      );
    }
    if (isUnlocked) return const Chip(label: Text('Select'));
    return Chip(
      avatar: const Icon(
        Icons.monetization_on,
        color: Color(0xFFFFD43B),
        size: 18,
      ),
      label: Text('${skin.price}'),
    );
  }
}
