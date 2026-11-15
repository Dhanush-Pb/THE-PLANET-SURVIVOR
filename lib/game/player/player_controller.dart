import 'dart:async';
import 'dart:math' as math;

import '../camera/game_camera.dart';
import 'player.dart';

class PlayerController {
  PlayerController(this.player, this.camera);

  final GamePlayer player;
  final GameCamera camera;

  Timer? _timer;

  double _horizontal = 0; // -1 left, +1 right
  double _vertical = 0; // +1 forward, -1 back

  bool _sprinting = false;
  bool? _animationRunning; // remembers the current animation

  bool get sprinting => _sprinting;

  set sprinting(bool value) {
    if (_sprinting == value) return;

    _sprinting = value;

    if (_isMoving) {
      _setAnimation();
    }
  }

  bool get _isMoving => _horizontal != 0 || _vertical != 0;

  double get speed => _sprinting ? 0.12 : 0.065;

  void _setAnimation() {
    if (_animationRunning == _sprinting) return;
    _animationRunning = _sprinting;
    player.playMovementAnimation(running: _sprinting);
  }

  /// horizontal: -1 left, +1 right. vertical: +1 forward, -1 back.
  void startMove(double horizontal, double vertical) {
    _horizontal = horizontal;
    _vertical = vertical;

    if (!_isMoving) return;

    _setAnimation();

    if (_timer != null) return;

    _timer = Timer.periodic(
      const Duration(milliseconds: 33),
      (_) => _update(),
    );
  }

  void _update() {
    if (!_isMoving) return;

    final length = math.sqrt(
      _horizontal * _horizontal + _vertical * _vertical,
    );

    if (length == 0) return;

    final h = _horizontal / length;
    final v = _vertical / length;

    // Direction the camera looks at, on the ground.
    final yaw = camera.yaw;
    final forwardX = -math.sin(yaw);
    final forwardZ = -math.cos(yaw);

    // Camera's right side.
    final rightX = -forwardZ;
    final rightZ = forwardX;

    player.move(
      (rightX * h + forwardX * v) * speed,
      (rightZ * h + forwardZ * v) * speed,
    );
  }

  void stopMove() {
    _horizontal = 0;
    _vertical = 0;

    _timer?.cancel();
    _timer = null;

    if (_animationRunning != null) {
      _animationRunning = null;
      player.playIdleAnimation();
    }
  }

  void dispose() {
    stopMove();
  }
}