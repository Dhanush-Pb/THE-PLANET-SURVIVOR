
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter_scene/scene.dart';
import 'package:vector_math/vector_math.dart' as vm;

import '../physics/collision.dart';
import '../systems/jump_system.dart';
import '../world/world_builder.dart';
import 'player_animation.dart';

class GamePlayer {
  static const String modelPath = 'assets/models/player/Teen.glb';

  static const double facingOffset = math.pi;
  static const double turnSpeed = 0.22;
  static const double bodyRadius = 0.6;

  Node? node;
  PlayerAnimation? animation;

  final JumpSystem _jump = JumpSystem();

  double x = 0;
  double z = 5;

  double _yaw = 0;
  double _lastAppliedYaw = double.nan;

  double get y => _jump.y;
  bool get grounded => _jump.grounded;
  bool get isLoaded => node != null;

  Future<void> load() async {
    final model = await loadScene(modelPath);

    model.scale = vm.Vector3.all(2);
    model.position = vm.Vector3(x, 0, z);

    node = model;
    animation = PlayerAnimation(model);

    debugPrint('Available animations: ${animation!.animationNames}');

    animation!.playIdle();
  }

  void move(
    double dx,
    double dz, {
    double? faceYaw,
  }) {
    final n = node;
    if (n == null) return;

    x += dx;
    z += dz;

    final pushed = Collision.pushOut(
      x,
      z,
      bodyRadius,
      WorldBuilder.obstacles,
    );

    x = pushed.$1;
    z = pushed.$2;

    final limit = WorldBuilder.halfExtent;
    x = x.clamp(-limit, limit);
    z = z.clamp(-limit, limit);

    n.position = vm.Vector3(x, y, z);

    if (dx != 0 || dz != 0) {
      _turnToward(
        faceYaw ?? (math.atan2(dx, dz) + facingOffset),
      );
    }
  }

  bool jump() {
    if (!_jump.jump()) return false;

    animation?.playJumpStart();
    return true;
  }

  bool update(double dt) {
    final landed = _jump.update(dt);
    node?.position = vm.Vector3(x, y, z);
    return landed;
  }

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

    node!.rotation = vm.Quaternion.axisAngle(
      vm.Vector3(0, 1, 0),
      _yaw,
    );
  }

  void playMovementAnimation({required bool running}) {
    if (running) {
      animation?.playRun();
    } else {
      animation?.playWalk();
    }
  }

  void playIdleAnimation() {
    animation?.playIdle();
  }

  void playStrafeLeftAnimation() {
    animation?.playLeft();
  }

  void playStrafeRightAnimation() {
    animation?.playRight();
  }

  void playCrouchIdleAnimation() {
    animation?.playCrouchIdle();
  }

  void playCrouchWalkAnimation() {
    animation?.playCrouchWalk();
  }

  void playJumpAirAnimation() {
    animation?.playJumpAir();
  }

  void playJumpLandAnimation() {
    animation?.playJumpLand();
  }

  void playRollAnimation() {
    animation?.playRoll();
  }

  void setPosition(double newX, double newZ) {
    x = newX;
    z = newZ;
    node?.position = vm.Vector3(x, y, z);
  }
}
