import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

Future<void> loadBrandFonts() async {
  final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
  final available = manifest.listAssets().toSet();
  for (final font in const {
    'Plus Jakarta Sans': 'assets/fonts/PlusJakartaSans.ttf',
    'JetBrains Mono': 'assets/fonts/JetBrainsMono.ttf',
  }.entries) {
    if (!available.contains(font.value)) {
      if (kDebugMode) {
        debugPrint(
          'Bundled font missing: ${font.value}. Run bash tool/prepare-fonts.sh.',
        );
      }
      continue;
    }
    final loader = FontLoader(font.key)..addFont(rootBundle.load(font.value));
    await loader.load();
  }
}
