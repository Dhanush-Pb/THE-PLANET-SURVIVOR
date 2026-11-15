import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_scene/scene.dart';
import 'package:jungle_advanture/game/scenes/jungle_scene.dart';

import '../../game/camera/game_camera.dart';
import '../../game/player/player.dart';
import '../../game/player/player_controller.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  final Scene _scene = Scene();

  final GamePlayer _player = GamePlayer();
  final GameCamera _camera = GameCamera();

  // Created in initState, because it needs _player and _camera.
  late final PlayerController _controller;

  final FocusNode _focus = FocusNode();

  bool _ready = false;
  bool _loadingFailed = false;
  bool _sprinting = false;

  String _error = '';

  final int _health = 100;

  @override
  void initState() {
    super.initState();
    _controller = PlayerController(_player, _camera);
    _initializeGame();
  }

  Future<void> _initializeGame() async {
    try {
      await Scene.initializeStaticResources();

      await JungleEnvironment.loadInto(_scene);

      await _player.load();
      _scene.add(_player.node!);

      if (!mounted) return;

      setState(() {
        _ready = true;
      });
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

  // ------------------------------------------------------------------
  // Keyboard (web / desktop): WASD or arrows, Shift to run
  // ------------------------------------------------------------------
  static final Set<LogicalKeyboardKey> _moveKeys = {
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
  };

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (!_moveKeys.contains(event.logicalKey)) {
      return KeyEventResult.ignored;
    }

    // Ignore auto-repeat so the animation does not restart.
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

    final h = (right ? 1.0 : 0.0) - (left ? 1.0 : 0.0);
    final v = (forward ? 1.0 : 0.0) - (back ? 1.0 : 0.0);

    if (h == 0 && v == 0) {
      _controller.stopMove();
    } else {
      _controller.startMove(h, v);
    }

    return KeyEventResult.handled;
  }

  // ------------------------------------------------------------------
  // UI
  // ------------------------------------------------------------------
  Widget _directionButton(
    IconData icon,
    double horizontal,
    double vertical,
  ) {
    return GestureDetector(
      onTapDown: (_) => _controller.startMove(horizontal, vertical),
      onTapUp: (_) => _controller.stopMove(),
      onTapCancel: _controller.stopMove,
      child: Container(
        width: 58,
        height: 58,
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.65),
          border: Border.all(color: Colors.white54),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: 30,
        ),
      ),
    );
  }

  Widget _movementControls() {
    return Positioned(
      left: 20,
      bottom: 20,
      child: Column(
        children: [
          _directionButton(Icons.keyboard_arrow_up, 0, 1),
          Row(
            children: [
              _directionButton(Icons.keyboard_arrow_left, -1, 0),
              const SizedBox(width: 66),
              _directionButton(Icons.keyboard_arrow_right, 1, 0),
            ],
          ),
          _directionButton(Icons.keyboard_arrow_down, 0, -1),
        ],
      ),
    );
  }

  Widget _gameHud() {
    return Positioned(
      top: 18,
      left: 20,
      right: 20,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'THE WILD STEP',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
          Row(
            children: [
              const Icon(Icons.favorite, color: Colors.red),
              const SizedBox(width: 8),
              Text(
                '$_health / 100',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 20),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _sprinting = !_sprinting;
                    _controller.sprinting = _sprinting;
                  });
                },
                child: Text(_sprinting ? 'RUN ON' : 'RUN'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _hint() {
    return const Positioned(
      bottom: 14,
      left: 0,
      right: 0,
      child: IgnorePointer(
        child: Center(
          child: Text(
            'Drag to look  •  Scroll to zoom  •  WASD to move  •  Shift to run',
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
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
          child: CircularProgressIndicator(
            color: Colors.greenAccent,
          ),
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
            Positioned.fill(
              child: Listener(
                onPointerDown: (_) => _focus.requestFocus(),
                // Mouse drag or finger drag turns the camera.
                onPointerMove: (event) {
                  _camera.rotate(event.delta.dx, event.delta.dy);
                },
                // Mouse wheel zooms.
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
                      playerZ: _player.z,
                    );
                  },
                ),
              ),
            ),
            _gameHud(),
            _movementControls(),
            if (kIsWeb) _hint(),
          ],
        ),
      ),
    );
  }
}