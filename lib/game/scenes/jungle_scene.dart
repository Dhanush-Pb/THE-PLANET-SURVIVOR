// TODO: Implement the jungle scene.

import 'package:flutter_scene/scene.dart';

import '../gltf_asset_loader.dart';

class JungleEnvironment {
  JungleEnvironment._();

  static Future<void> loadInto(Scene scene) async {
    // Load the main ground.
    final ground = await GltfAssetLoader.load('Floor_UnevenBrick');

    scene.add(ground);
  }
}
