import 'dart:math' as math;

import 'package:flutter_scene/scene.dart';
import 'package:vector_math/vector_math.dart' as vm;

/// Orbit camera around the player (third person, 360 degrees).
class GameCamera {
  /// Horizontal angle around the player, in radians.
  double yaw = 0;

  /// Height angle of the camera above the player, in radians.
  double pitch = 0.45;

  /// Distance from the player.
  double distance = 10;

  static const double minPitch = 0.08;
  static const double maxPitch = 1.3;
  static const double minDistance = 4;
  static const double maxDistance = 20;

  /// Height of the point the camera looks at (about the player's head).
  static const double targetHeight = 2.4;

  /// How fast the camera follows the player (0.1 slow, 1 instant).
  static const double followSmoothing = 0.3;

  double _followX = double.nan;
  double _followZ = 0;

  /// Call this when the user drags. Dragging right turns the view right,
  /// dragging up looks up.
  void rotate(double dx, double dy, {double sensitivity = 0.0055}) {
    yaw -= dx * sensitivity;
    pitch = (pitch + dy * sensitivity).clamp(minPitch, maxPitch);
  }

  void zoom(double amount) {
    distance = (distance + amount).clamp(minDistance, maxDistance);
  }

  PerspectiveCamera build({required double playerX, required double playerZ}) {
    if (_followX.isNaN) {
      _followX = playerX;
      _followZ = playerZ;
    }

    _followX += (playerX - _followX) * followSmoothing;
    _followZ += (playerZ - _followZ) * followSmoothing;

    final flat = math.cos(pitch) * distance;

    final target = vm.Vector3(_followX, targetHeight, _followZ);

    final position = vm.Vector3(
      _followX + math.sin(yaw) * flat,
      targetHeight + math.sin(pitch) * distance,
      _followZ + math.cos(yaw) * flat,
    );

    return PerspectiveCamera(
      position: position,
      target: target,
      fovNear: 0.1,
      fovFar: 300,
    );
  }
}
