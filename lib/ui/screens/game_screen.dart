// TODO: Implement the game screen.
import 'package:flutter/material.dart';
import 'package:flutter_scene/scene.dart';

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

  late final PlayerController _controller = PlayerController(_player);
  final GameCamera _camera = GameCamera();

  bool _ready = false;
  bool _loadingFailed = false;
  bool _sprinting = false;
  String _error = '';

  int _health = 100;

  @override
  void initState() {
    super.initState();
    _initializeGame();
  }

  Future<void> _initializeGame() async {
    try {
      await Scene.initializeStaticResources();

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

  Widget _directionButton(
    IconData icon,
    double horizontal,
    double vertical,
  ) {
    return GestureDetector(
      onTapDown: (_) {
        _controller.startMove(horizontal, vertical);
      },
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

  @override
  void dispose() {
    _controller.dispose();
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
      body: Stack(
        children: [
          Positioned.fill(
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
          _gameHud(),
          _movementControls(),
        ],
      ),
    );
  }
}