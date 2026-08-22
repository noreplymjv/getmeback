import 'package:flutter_test/flutter_test.dart';
import 'package:getmeback/models/prop_sprite_catalog.dart';
import 'package:getmeback/models/prop_state.dart';

void main() {
  test('catalog assigns materials for common prop ids', () {
    expect(PropSpriteCatalog.materialFor('glass'), PropMaterial.glass);
    expect(PropSpriteCatalog.materialFor('plate'), PropMaterial.ceramic);
    expect(PropSpriteCatalog.materialFor('chair'), PropMaterial.wood);
    expect(PropSpriteCatalog.materialFor('blender'), PropMaterial.metal);
    expect(PropSpriteCatalog.materialFor('sofa'), PropMaterial.fabric);
  });

  test('catalog layout values are sane', () {
    expect(PropSpriteCatalog.sizeNormFor('glass'), inInclusiveRange(0.05, 0.2));
    expect(PropSpriteCatalog.aspectRatioFor('plate'), lessThan(1.0));
    expect(PropSpriteCatalog.zIndexFor('table'), 0);
  });
}
