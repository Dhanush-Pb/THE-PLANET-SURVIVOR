import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_scene/scene.dart';
import 'package:jungle_advanture/ui/widgets/sky_baground.dart';

import '../../game/camera/game_camera.dart';
import '../../game/player/player.dart';
import '../../game/player/player_controller.dart';
import '../../game/systems/coin_system.dart';
import '../../game/world/world_builder.dart';
import '../widgets/game_controls.dart';
import '../widgets/joystick.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen>
    with SingleTickerProviderStateMixin {
  final Scene _scene = Scene();

  final GamePlayer _player = GamePlayer();
  final GameCamera _camera = GameCamera();
  final CoinSystem _coins = CoinSystem();
  final ValueNotifier<double> _skyTime = ValueNotifier<double>(0);
  final FocusNode _focus = FocusNode();

  late final PlayerController _controller;
  late final Ticker _ticker;

  double _lastTime = 0;

  bool _ready = false;
  bool _loadingFailed = false;
  bool _sprinting = false;

  /// true: joystick on the right, buttons on the left.
  bool _movementOnRight = true;

  String _error = '';
  final int _health = 100;

  @override
  void initState() {
    super.initState();

    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    _controller = PlayerController(_player, _camera);
    _ticker = createTicker(_onTick);

    _initializeGame();
  }

  Future<void> _initializeGame() async {
    try {
      await Scene.initializeStaticResources();

      await WorldBuilder.loadInto(_scene);
      _coins.build(_scene, WorldBuilder.coinSpots);

      await _player.load();
      _scene.add(_player.node!);

      if (!mounted) return;

      setState(() => _ready = true);
      _ticker.start();
    } catch (error, stackTrace) {
      debugPrint('Game initialization error: $error');
      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) return;

      setState(() {
        _loadingFailed = true;
        _error = error.toString();
      });
    }
  }

  void _onTick(Duration elapsed) {
    final t = elapsed.inMicroseconds / 1000000.0;
    final dt = (t - _lastTime).clamp(0.0, 0.1).toDouble();
    _lastTime = t;

    _controller.update(dt);
    _coins.update(t, _player.x, _player.y, _player.z);
    _skyTime.value = t;
  }

  // ------------------------------------------------------------------
  // Keyboard: WASD / arrows, Space jump, Shift run
  // ------------------------------------------------------------------
  static final Set<LogicalKeyboardKey> _gameKeys = {
    LogicalKeyboardKey.keyW,
    LogicalKeyboardKey.keyA,
    LogicalKeyboardKey.keyS,
    LogicalKeyboardKey.keyD,
    LogicalKeyboardKey.arrowUp,
    LogicalKeyboardKey.arrowDown,
    LogicalKeyboardKey.arrowLeft,
    LogicalKeyboardKey.arrowRight,
    LogicalKeyboardKey.shiftLeft,
    LogicalKeyboardKey.shiftRight,
    LogicalKeyboardKey.space,
  };

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (!_gameKeys.contains(event.logicalKey)) {
      return KeyEventResult.ignored;
    }

    if (event.logicalKey == LogicalKeyboardKey.space) {
      if (event is KeyDownEvent) _controller.jump();
      return KeyEventResult.handled;
    }

    if (event is KeyRepeatEvent) return KeyEventResult.handled;

    final keys = HardwareKeyboard.instance;
    bool down(LogicalKeyboardKey key) => keys.isLogicalKeyPressed(key);

    final forward =
        down(LogicalKeyboardKey.keyW) || down(LogicalKeyboardKey.arrowUp);
    final back =
        down(LogicalKeyboardKey.keyS) || down(LogicalKeyboardKey.arrowDown);
    final left =
        down(LogicalKeyboardKey.keyA) || down(LogicalKeyboardKey.arrowLeft);
    final right =
        down(LogicalKeyboardKey.keyD) || down(LogicalKeyboardKey.arrowRight);
    final shift = down(LogicalKeyboardKey.shiftLeft) ||
        down(LogicalKeyboardKey.shiftRight);

    _controller.sprinting = _sprinting || shift;

    _controller.setInput(
      (right ? 1.0 : 0.0) - (left ? 1.0 : 0.0),
      (forward ? 1.0 : 0.0) - (back ? 1.0 : 0.0),
    );

    return KeyEventResult.handled;
  }

  // ------------------------------------------------------------------
  // UI
  // ------------------------------------------------------------------
  Widget _hud() {
    return Positioned(
      top: 14,
      left: 20,
      right: 20,
      child: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _chip(
              Icons.monetization_on,
              Colors.amber,
              ValueListenableBuilder<int>(
                valueListenable: _coins.collected,
                builder: (context, value, child) => Text(
                  '$value / ${_coins.total}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            _chip(
              Icons.favorite,
              Colors.redAccent,
              Text(
                '$_health',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: () => setState(() => _movementOnRight = !_movementOnRight),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.45),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white54),
                ),
                child: const Icon(Icons.swap_horiz, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(IconData icon, Color color, Widget child) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 6),
          child,
        ],
      ),
    );
  }

  Widget _controlsLayer() {
    final pad = MediaQuery.of(context).padding;
    final onRight = _movementOnRight;

    final stick = Positioned(
      bottom: 24 + pad.bottom,
      left: onRight ? null : 28 + pad.left,
      right: onRight ? 28 + pad.right : null,
      child: Joystick(
        size: 150,
        onChanged: (x, y) => _controller.setInput(x, y),
      ),
    );

    final buttons = Positioned(
      bottom: 24 + pad.bottom,
      left: onRight ? 28 + pad.left : null,
      right: onRight ? null : 28 + pad.right,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          ActionButton(
            icon: Icons.directions_run,
            size: 58,
            active: _sprinting,
            onDown: () {
              setState(() {
                _sprinting = !_sprinting;
                _controller.sprinting = _sprinting;
              });
            },
          ),
          const SizedBox(width: 18),
          ActionButton(
            icon: Icons.keyboard_double_arrow_up,
            size: 84,
            onDown: _controller.jump,
          ),
        ],
      ),
    );

    return Stack(children: [stick, buttons]);
  }

  Widget _hint() {
    return const Positioned(
      bottom: 10,
      left: 0,
      right: 0,
      child: IgnorePointer(
        child: Center(
          child: Text(
            'Drag to look  •  Scroll to zoom  •  WASD move  •  Space jump  •  Shift run',
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    _ticker.dispose();
    _controller.dispose();
    _focus.dispose();
    _skyTime.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingFailed) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Unable to load the game.\n\n$_error',
              style: const TextStyle(color: Colors.white),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    if (!_ready) {
      return const Scaffold(
        backgroundColor: Color(0xFF101810),
        body: Center(
          child: CircularProgressIndicator(color: Colors.greenAccent),
        ),
      );
    }

    return Scaffold(
      body: Focus(
        focusNode: _focus,
        autofocus: true,
        onKeyEvent: _onKey,
        child: Stack(
          children: [
            // Sky is painted behind the 3D view (the 3D view is transparent).
            Positioned.fill(
              child: SkyBackground(camera: _camera, time: _skyTime),
            ),
            Positioned.fill(
              child: Listener(
                onPointerDown: (_) => _focus.requestFocus(),
                onPointerMove: (event) {
                  _camera.rotate(event.delta.dx, event.delta.dy);
                },
                onPointerSignal: (event) {
                  if (event is PointerScrollEvent) {
                    _camera.zoom(event.scrollDelta.dy * 0.01);
                  }
                },
                child: SceneView(
                  _scene,
                  cameraBuilder: (elapsed) {
                    return _camera.build(
                      playerX: _player.x,
                      playerY: _player.y,
                      playerZ: _player.z,
                    );
                  },
                ),
              ),
            ),
            _hud(),
            _controlsLayer(),
            if (kIsWeb) _hint(),
          ],
        ),
      ),
    );
  }
}