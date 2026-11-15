import 'dart:math' as math;

import 'package:flutter_scene/scene.dart';
import 'package:vector_math/vector_math.dart' as vm;

/// Orbit camera around the player (third person, 360 degrees).
class GameCamera {
  double yaw = 0;
  double pitch = 0.22;
  double distance = 9;

  static const double minPitch = 0.02;
  static const double maxPitch = 1.2;
  static const double minDistance = 4;
  static const double maxDistance = 20;
  static const double targetHeight = 2.4;
  static const double followSmoothing = 0.3;

  double _followX = double.nan;
  double _followY = 0;
  double _followZ = 0;

  void rotate(double dx, double dy, {double sensitivity = 0.0055}) {
    yaw -= dx * sensitivity;
    pitch = (pitch + dy * sensitivity).clamp(minPitch, maxPitch);
  }

  void zoom(double amount) {
    distance = (distance + amount).clamp(minDistance, maxDistance);
  }

  PerspectiveCamera build({
    required double playerX,
    required double playerY,
    required double playerZ,
  }) {
    if (_followX.isNaN) {
      _followX = playerX;
      _followY = playerY;
      _followZ = playerZ;
    }

    _followX += (playerX - _followX) * followSmoothing;
    _followY += (playerY - _followY) * followSmoothing;
    _followZ += (playerZ - _followZ) * followSmoothing;

    final lookY = targetHeight + _followY * 0.6;
    final flat = math.cos(pitch) * distance;

    return PerspectiveCamera(
      position: vm.Vector3(
        _followX + math.sin(yaw) * flat,
        lookY + math.sin(pitch) * distance,
        _followZ + math.cos(yaw) * flat,
      ),
      target: vm.Vector3(_followX, lookY, _followZ),
      fovNear: 0.1,
      fovFar: 400,
    );
  }
}