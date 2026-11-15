// TODO: Implement the game camera.
import 'package:flutter_scene/scene.dart';
import 'package:vector_math/vector_math.dart' as vm;

class GameCamera {
  PerspectiveCamera build({
    required double playerX,
    required double playerZ,
  }) {
    return PerspectiveCamera(
      position: vm.Vector3(
        playerX,
        4.5,
        playerZ - 8,
      ),
      target: vm.Vector3(
        playerX,
        1.2,
        playerZ + 0.8,
      ),
    );
  }
}