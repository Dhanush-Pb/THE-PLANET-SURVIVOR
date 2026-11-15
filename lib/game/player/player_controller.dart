import 'dart:math' as math;

import '../camera/game_camera.dart';
import 'player.dart';

class PlayerController {
  PlayerController(this.player, this.camera);

  final GamePlayer player;
  final GameCamera camera;

  static const double walkSpeed = 4.2; // units per second
  static const double runSpeed = 8.5;

  double _horizontal = 0; // right is +1
  double _vertical = 0; // forward is +1

  bool _sprinting = false;
  bool? _animationRunning;

  bool get sprinting => _sprinting;

  set sprinting(bool value) {
    if (_sprinting == value) return;
    _sprinting = value;
    if (_isMoving) _setAnimation();
  }

  bool get _isMoving => _horizontal != 0 || _vertical != 0;

  void _setAnimation() {
    if (!player.grounded) return; // jump animation stays in the air
    if (_animationRunning == _sprinting) return;
    _animationRunning = _sprinting;
    player.playMovementAnimation(running: _sprinting);
  }

  /// Joystick or keyboard input. Both values from -1 to 1.
  void setInput(double horizontal, double vertical) {
    final wasMoving = _isMoving;

    _horizontal = horizontal;
    _vertical = vertical;

    if (_isMoving) {
      _setAnimation();
    } else if (wasMoving) {
      _animationRunning = null;
      if (player.grounded) player.playIdleAnimation();
    }
  }

  void stopMove() => setInput(0, 0);

  void jump() {
    player.jump();
  }

  /// Call once per frame.
  void update(double dt) {
    if (_isMoving) {
      final length = math.sqrt(
        _horizontal * _horizontal + _vertical * _vertical,
      );

      final strength = math.min(length, 1.0);
      final h = _horizontal / length;
      final v = _vertical / length;

      // Directions relative to where the camera looks.
      final forwardX = -math.sin(camera.yaw);
      final forwardZ = -math.cos(camera.yaw);
      final rightX = -forwardZ;
      final rightZ = forwardX;

      final speed = (_sprinting ? runSpeed : walkSpeed) * strength * dt;

      player.move(
        (rightX * h + forwardX * v) * speed,
        (rightZ * h + forwardZ * v) * speed,
      );
    }

    final landed = player.update(dt);

    if (landed) {
      _animationRunning = null;
      if (_isMoving) {
        _setAnimation();
      } else {
        player.playIdleAnimation();
      }
    }
  }

  void dispose() {
    stopMove();
  }
}