import 'package:bloxie/core/theme/skins.dart';
import 'package:bloxie/features/shop/bloc/shop_cubit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

/// Scaffold with the active skin's background gradient.
class GradientScaffold extends StatelessWidget {
  const GradientScaffold({
    required this.body,
    super.key,
    this.appBar,
    this.safeArea = true,
  });

  final Widget body;
  final PreferredSizeWidget? appBar;
  final bool safeArea;

  @override
  Widget build(BuildContext context) {
    final skin = Skins.byId(
      context.select<ShopCubit, String>((c) => c.state.selectedId),
    );
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [skin.bgTop, skin.bgBottom],
        ),
      ),
      child: Scaffold(
        appBar: appBar,
        body: safeArea ? SafeArea(child: body) : body,
      ),
    );
  }
}
