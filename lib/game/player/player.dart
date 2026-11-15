import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter_scene/scene.dart';
import 'package:vector_math/vector_math.dart' as vm;

import '../scenes/jungle_scene.dart';
import 'player_animation.dart';

class GamePlayer {
  static const String modelPath = 'assets/models/player/Teen.glb';

  /// Imported models face -z, so the character is turned by 180 degrees.
  /// If it still walks with its back or side first, try:
  ///   0, math.pi / 2, or -math.pi / 2
  static const double facingOffset = math.pi;

  /// How fast the character turns (0.1 slow, 0.4 fast).
  static const double turnSpeed = 0.22;

  Node? node;
  PlayerAnimation? animation;

  double x = 0;
  double z = 5;

  double _yaw = 0;
  double _lastAppliedYaw = double.nan;

  bool get isLoaded => node != null;

  Future<void> load() async {
    final model = await loadScene(modelPath);

    model.scale = vm.Vector3.all(2);
    model.position = vm.Vector3(x, 0, z);

    node = model;
    animation = PlayerAnimation(model);

    debugPrint('Available animations: ${animation!.animationNames}');

    animation!.play('Idle-loop');
  }

  void move(double dx, double dz) {
    final n = node;
    if (n == null) return;

    x += dx;
    z += dz;

    final limit = JungleEnvironment.halfExtent;
    x = x.clamp(-limit, limit);
    z = z.clamp(-limit, limit);

    n.position = vm.Vector3(x, 0, z);

    if (dx != 0 || dz != 0) {
      _turnToward(math.atan2(dx, dz) + facingOffset);
    }
  }

  /// Turns smoothly along the shortest way, so the character always
  /// faces where it is going instead of walking backwards.
  void _turnToward(double target) {
    var diff = target - _yaw;

    while (diff > math.pi) {
      diff -= math.pi * 2;
    }
    while (diff < -math.pi) {
      diff += math.pi * 2;
    }

    if (diff.abs() < 0.01) {
      _yaw = target;
    } else {
      _yaw += diff * turnSpeed;
    }

    if (_yaw == _lastAppliedYaw) return;
    _lastAppliedYaw = _yaw;

    node!.rotation = vm.Quaternion.axisAngle(vm.Vector3(0, 1, 0), _yaw);
  }

  void playMovementAnimation({required bool running}) {
    animation?.play(running ? 'Run-loop' : 'Walk-loop');
  }

  void playIdleAnimation() {
    animation?.play('Idle-loop');
  }

  void setPosition(double newX, double newZ) {
    x = newX;
    z = newZ;

    node?.position = vm.Vector3(x, 0, z);
  }
}