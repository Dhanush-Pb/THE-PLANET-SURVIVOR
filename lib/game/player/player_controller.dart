
import 'dart:math' as math;

import '../camera/game_camera.dart';
import 'player.dart';

class PlayerController {
  PlayerController(this.player, this.camera);

  final GamePlayer player;
  final GameCamera camera;

  static const double walkSpeed = 4.2;
  static const double runSpeed = 8.5;
  static const double crouchSpeed = 2.2;

  double _horizontal = 0;
  double _vertical = 0;

  bool _sprinting = false;
  bool _crouching = false;

  bool _jumpActive = false;
  bool _jumpAirStarted = false;
  double _jumpElapsed = 0;

  double _landingTimer = 0;
  double _actionTimer = 0;

  bool get sprinting => _sprinting;
  bool get crouching => _crouching;

  set sprinting(bool value) {
    final next = value && !_crouching;
    if (_sprinting == next) return;

    _sprinting = next;
    _refreshMovementAnimation();
  }

  set crouching(bool value) {
    if (_crouching == value) return;
    if (!player.grounded || _jumpActive || _actionTimer > 0) return;

    _crouching = value;

    if (_crouching) {
      _sprinting = false;
    }

    _refreshMovementAnimation();
  }

  bool get _isMoving =>
      _horizontal.abs() > 0.01 || _vertical.abs() > 0.01;

  void _refreshMovementAnimation() {
    if (!player.grounded ||
        _jumpActive ||
        _landingTimer > 0 ||
        _actionTimer > 0) {
      return;
    }

    if (_crouching) {
      if (_isMoving) {
        player.playCrouchWalkAnimation();
      } else {
        player.playCrouchIdleAnimation();
      }
      return;
    }

    if (!_isMoving) {
      player.playIdleAnimation();
      return;
    }

    // Sideways-only movement uses strafe animations.
    // No backward-walk animation is used.
    if (_vertical.abs() < 0.01 && _horizontal.abs() > 0.01) {
      if (_horizontal < 0) {
        player.playStrafeLeftAnimation();
      } else {
        player.playStrafeRightAnimation();
      }
      return;
    }

    player.playMovementAnimation(running: _sprinting);
  }

  /// Joystick or keyboard input. Values are normally between -1 and 1.
  void setInput(double horizontal, double vertical) {
    final wasMoving = _isMoving;

    // Keep the existing joystick direction convention.
    _horizontal = -horizontal;
    _vertical = vertical;

    if (_isMoving || wasMoving) {
      _refreshMovementAnimation();
    }
  }

  void stopMove() {
    setInput(0, 0);
  }

  void jump() {
    if (_actionTimer > 0 || _landingTimer > 0) return;

    if (player.jump()) {
      _jumpActive = true;
      _jumpAirStarted = false;
      _jumpElapsed = 0;
    }
  }

  void dodge() {
    if (!player.grounded ||
        _jumpActive ||
        _landingTimer > 0 ||
        _actionTimer > 0 ||
        _crouching) {
      return;
    }

    player.playRollAnimation();
    _actionTimer = 0.75;
  }

  /// Call once per frame.
  void update(double dt) {
    // Keep existing camera-relative movement and collision behaviour.
    if (_isMoving && _actionTimer <= 0) {
      final length = math.sqrt(
        _horizontal * _horizontal + _vertical * _vertical,
      );

      if (length > 0) {
        final strength = math.min(length, 1.0);
        final h = _horizontal / length;
        final v = _vertical / length;

        final forwardX = -math.sin(camera.yaw);
        final forwardZ = -math.cos(camera.yaw);

        final rightX = -forwardZ;
        final rightZ = forwardX;

        final currentSpeed = _crouching
            ? crouchSpeed
            : (_sprinting ? runSpeed : walkSpeed);

        final speed = currentSpeed * strength * dt;

        final dx = (rightX * h + forwardX * v) * speed;
        final dz = (rightZ * h + forwardZ * v) * speed;

        // While strafing, keep the character facing forward.
        final double? faceYaw =
            _vertical.abs() < 0.01 && _horizontal.abs() > 0.01
                ? camera.yaw + math.pi
                : null;

        player.move(dx, dz, faceYaw: faceYaw);
      }
    }

    final landed = player.update(dt);

    // Jump start -> jump in air.
    if (_jumpActive && !player.grounded) {
      _jumpElapsed += dt;

      if (!_jumpAirStarted && _jumpElapsed >= 0.20) {
        _jumpAirStarted = true;
        player.playJumpAirAnimation();
      }
    }

    // Landing animation.
    if (landed) {
      _jumpActive = false;
      _jumpAirStarted = false;
      _landingTimer = 0.35;

      player.playJumpLandAnimation();
    }

    // Allow the landing animation to play before returning to movement.
    if (_landingTimer > 0) {
      _landingTimer -= dt;

      if (_landingTimer <= 0) {
        _landingTimer = 0;
        _refreshMovementAnimation();
      }
    }

    // Keep the roll animation from being immediately replaced.
    if (_actionTimer > 0) {
      _actionTimer -= dt;

      if (_actionTimer <= 0) {
        _actionTimer = 0;
        _refreshMovementAnimation();
      }
    }
  }

  void dispose() {
    stopMove();
  }
}
