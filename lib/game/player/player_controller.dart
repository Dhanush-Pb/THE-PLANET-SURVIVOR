// TODO: Implement player input and control.
import 'dart:async';
import 'dart:math' as math;

import 'player.dart';

class PlayerController {
  PlayerController(this.player);

  final GamePlayer player;

  Timer? _timer;

  double _horizontal = 0;
  double _vertical = 0;

  bool sprinting = false;

  double get speed => sprinting ? 0.12 : 0.065;

  void startMove(double horizontal, double vertical) {
    _horizontal = horizontal;
    _vertical = vertical;

    if (_timer != null) return;

    _timer = Timer.periodic(
      const Duration(milliseconds: 33),
      (_) => _update(),
    );
  }

  void _update() {
    if (_horizontal == 0 && _vertical == 0) return;

    final length = math.sqrt(
      _horizontal * _horizontal + _vertical * _vertical,
    );

    if (length == 0) return;

    player.move(
      (_horizontal / length) * speed,
      (_vertical / length) * speed,
    );
  }

  void stopMove() {
    _horizontal = 0;
    _vertical = 0;

    _timer?.cancel();
    _timer = null;
  }

  void dispose() {
    stopMove();
  }
}