import 'package:bloxie/features/common/brand_logo.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  testWidgets('renders the logo asset at the requested size', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: BrandLogo(size: 96))),
    );

    final image = tester.widget<Image>(find.byType(Image));
    expect(image.image, isA<AssetImage>());
    expect((image.image as AssetImage).assetName, brandLogoAsset);
    expect(image.width, 96);
    expect(image.height, 96);
  });

  testWidgets('is excluded from semantics because it is decorative', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: BrandLogo(size: 96))),
    );

    final image = tester.widget<Image>(find.byType(Image));
    expect(image.excludeFromSemantics, isTrue);
  });
}
