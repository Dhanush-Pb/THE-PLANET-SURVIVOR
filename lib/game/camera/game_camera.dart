import 'dart:math' as math;

import 'package:flutter_scene/scene.dart';
import 'package:vector_math/vector_math.dart' as vm;

/// Orbit camera around the player: full 360 degrees horizontally, and a wide
/// vertical range (look up at the sky, look straight down from above).
class GameCamera {
  double yaw = 0;
  double pitch = 0.22;
  double distance = 9;

  /// Drag direction. If a direction still feels wrong, flip it here:
  ///  - dragging right shows the LEFT side  -> change invertHorizontal
  ///  - dragging up looks the wrong way     -> change invertVertical
  static const bool invertHorizontal = true;
  static const bool invertVertical = false;

  /// Highest angle: almost directly above the player (top-down view).
  static const double maxPitch = 1.45;

  /// Lowest angle: looking up at the sky from near ground level.
  /// The real lower limit is also restricted so the camera never goes
  /// underground (see _minPitch).
  static const double minPitchFloor = -1.0;

  /// The camera never goes lower than this height above the ground.
  static const double minCameraHeight = 0.6;

  static const double minDistance = 3;
  static const double maxDistance = 24;
  static const double targetHeight = 2.4;
  static const double followSmoothing = 0.3;

  static const double _tau = math.pi * 2;

  double _followX = double.nan;
  double _followY = 0;
  double _followZ = 0;
  double _lookY = targetHeight;

  /// Lowest pitch allowed right now so the camera stays above the ground.
  double get _minPitch {
    final s = ((minCameraHeight - _lookY) / distance).clamp(-1.0, 1.0);
    return math.max(math.asin(s), minPitchFloor);
  }

  void rotate(double dx, double dy, {double sensitivity = 0.0055}) {
    final h = invertHorizontal ? 1.0 : -1.0;
    final v = invertVertical ? -1.0 : 1.0;

    // Wrapped to 0..2pi so it can spin endlessly in either direction.
    yaw = (yaw + h * dx * sensitivity) % _tau;
    pitch = (pitch + v * dy * sensitivity).clamp(_minPitch, maxPitch).toDouble();
  }

  void zoom(double amount) {
    distance = (distance + amount).clamp(minDistance, maxDistance).toDouble();
    pitch = pitch.clamp(_minPitch, maxPitch).toDouble();
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

    _lookY = targetHeight + _followY * 0.6;

    // Keep pitch valid (e.g. after the player jumps or zoom changes).
    // The sky reads this same value, so it always matches the view.
    pitch = pitch.clamp(_minPitch, maxPitch).toDouble();

    final flat = math.cos(pitch) * distance;

    return PerspectiveCamera(
      position: vm.Vector3(
        _followX + math.sin(yaw) * flat,
        _lookY + math.sin(pitch) * distance,
        _followZ + math.cos(yaw) * flat,
      ),
      target: vm.Vector3(_followX, _lookY, _followZ),
      fovNear: 0.1,
      fovFar: 400,
    );
  }
}