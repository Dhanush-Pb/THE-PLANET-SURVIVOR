// TODO: Implement the player entity.
import 'dart:math' as math;

import 'package:flutter_scene/scene.dart';
import 'package:vector_math/vector_math.dart' as vm;

import 'player_animation.dart';

class GamePlayer {
  static const String modelPath = 'assets/models/player/Teen.glb';

  Node? node;
  PlayerAnimation? animation;

  double x = 0;
  double z = 5;

  bool get isLoaded => node != null;

  Future<void> load() async {
    final model = await loadScene(modelPath);

    model.scale = vm.Vector3.all(1);
    model.position = vm.Vector3(x, 0, z);

    node = model;
    animation = PlayerAnimation(model);

    print('Player loaded.');
    print('Available animations: ${animation!.animationNames}');

    animation!.playIdle();
  }

  void move(double dx, double dz) {
    if (node == null) return;

    x += dx;
    z += dz;

    x = x.clamp(-12.0, 12.0);
    z = z.clamp(-35.0, 35.0);

    node!.position = vm.Vector3(x, 0, z);

    if (dx != 0 || dz != 0) {
final angle = math.atan2(dx, dz);
      node!.rotation = vm.Quaternion.axisAngle(
        vm.Vector3(0, 1, 0),
        angle,
      );
    }
  }

  void setPosition(double newX, double newZ) {
    x = newX;
    z = newZ;

    if (node != null) {
      node!.position = vm.Vector3(x, 0, z);
    }
  }
}