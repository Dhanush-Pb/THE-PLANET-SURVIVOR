
import 'package:flutter/services.dart';
import 'package:flutter_scene/scene.dart';

class GltfAssetLoader {
  static const String assetDirectory = 'assets/environments/glTF/';

  static Future<Node> load(String modelName) async {
    final gltfData = await rootBundle.load(
      '$assetDirectory$modelName.gltf',
    );

    return Node.fromGltfBytes(
      gltfData.buffer.asUint8List(
        gltfData.offsetInBytes,
        gltfData.lengthInBytes,
      ),
      resolveUri: (uri) async {
        final relativePath = Uri.decodeComponent(Uri.parse(uri).path);
        final resource = await rootBundle.load(
          '$assetDirectory$relativePath',
        );

        return resource.buffer.asUint8List(
          resource.offsetInBytes,
          resource.lengthInBytes,
        );
      },
      onWarning: (warning) {
        print('GLTF warning: $warning');
      },
    );
  }
}
