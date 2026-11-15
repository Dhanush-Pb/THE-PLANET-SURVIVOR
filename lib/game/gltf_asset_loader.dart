
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_scene/scene.dart';

class GltfAssetLoader {
  static const String assetDirectory = 'assets/environments/glTF/';

  static Future<Node> load(String modelName) async {
    final path = '$assetDirectory$modelName.gltf';

    debugPrint('Loading GLTF: $path');

    final gltfData = await rootBundle.load(path);

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
        debugPrint('GLTF warning: $warning');
      },
    );
  }
}
