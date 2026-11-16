import 'dart:async';
import 'dart:math' as math;

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
import '../../game/systems/game_rules.dart';
import '../../game/world/world_builder.dart';
import '../widgets/game_controls.dart';
import '../widgets/joystick.dart';

enum _Phase { playing, won, lost }

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen>
    with SingleTickerProviderStateMixin {
  static int _activeScreens = 0;

  /// How much the camera moves per pixel of pinch. Raise it for faster zoom.
  static const double _pinchZoomSpeed = 0.04;

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
  bool _crouching = false;

  String _error = '';

  // Fingers (or mouse) on the look area, used for turning and pinch zoom.
  final Map<int, Offset> _lookPointers = {};
  double _lastPinchDistance = 0;

  // Health, finish and game state.
  _Phase _phase = _Phase.playing;

  double _healthValue = GameRules.maxHealth;

  final ValueNotifier<int> _healthShown =
      ValueNotifier<int>(GameRules.maxHealth.round());

  final ValueNotifier<int> _finishDistance = ValueNotifier<int>(0);
  final ValueNotifier<String> _toast = ValueNotifier<String>('');

  Timer? _toastTimer;

  double _visibilityTimer = 0;

  @override
  void initState() {
    super.initState();

    _activeScreens++;

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

      _coins.onHealthPickup = _onHealthPickup;

      _coins.build(
        _scene,
        WorldBuilder.coinSpots,
        healthSpots: GameRules.healthSpots(),
      );

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

  void _onHealthPickup() {
    _healthValue = math.min(
      GameRules.maxHealth,
      _healthValue + GameRules.healthCoinHeal,
    );

    _syncHealth();
    _showToast('+${GameRules.healthCoinHeal.round()} health');
  }

  void _syncHealth() {
    final shown = _healthValue.ceil();

    if (_healthShown.value != shown) {
      _healthShown.value = shown;
    }
  }

  void _showToast(String text) {
    _toast.value = text;

    _toastTimer?.cancel();

    _toastTimer = Timer(const Duration(milliseconds: 1400), () {
      _toast.value = '';
    });
  }

  void _endGame(_Phase phase) {
    if (!mounted || _phase != _Phase.playing) return;

    _controller.stopMove();

    setState(() => _phase = phase);
  }

  void _restart() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const GameScreen()),
    );
  }

  void _onTick(Duration elapsed) {
    final t = elapsed.inMicroseconds / 1000000.0;

    final dt = (t - _lastTime).clamp(0.0, 0.1).toDouble();
    _lastTime = t;

    _controller.update(dt);
    _skyTime.value = t;

    // Show / hide world chunks around the player.
    _visibilityTimer += dt;

    if (_visibilityTimer >= 0.25) {
      _visibilityTimer = 0;

      WorldBuilder.updateVisibility(
        _player.x,
        _player.z,
      );
    }

    if (_phase != _Phase.playing) return;

    _coins.healthFull = _healthValue >= GameRules.maxHealth;

    _coins.update(
      t,
      _player.x,
      _player.y,
      _player.z,
    );

    // Health slowly drains.
    _healthValue = math.max(
      0,
      _healthValue - GameRules.drainPerSecond * dt,
    );

    _syncHealth();

    if (_healthValue <= 0) {
      _endGame(_Phase.lost);
      return;
    }

    // Distance to the finish area.
    final fx = _player.x - GameRules.finishX;
    final fz = _player.z - GameRules.finishZ;

    final dist = math.sqrt(fx * fx + fz * fz);

    final meters = math.max(
      0,
      (dist - GameRules.finishRadius).round(),
    );

    if (_finishDistance.value != meters) {
      _finishDistance.value = meters;
    }

    if (dist <= GameRules.finishRadius) {
      _endGame(_Phase.won);
    }
  }

  // ------------------------------------------------------------------
  // Look area: one finger turns the camera, two fingers pinch to zoom.
  // ------------------------------------------------------------------

  double _currentPinchDistance() {
    final points = _lookPointers.values.take(2).toList();
    return (points[0] - points[1]).distance;
  }

  void _onLookDown(PointerDownEvent event) {
    _focus.requestFocus();

    _lookPointers[event.pointer] = event.position;

    // Remember the starting distance so the first move does not jump.
    _lastPinchDistance =
        _lookPointers.length >= 2 ? _currentPinchDistance() : 0;
  }

  void _onLookMove(PointerMoveEvent event) {
    if (!_lookPointers.containsKey(event.pointer)) return;

    _lookPointers[event.pointer] = event.position;

    if (_lookPointers.length >= 2) {
      // Pinch: fingers moving apart zoom in, together zoom out.
      final distance = _currentPinchDistance();

      if (_lastPinchDistance > 0) {
        _camera.zoom((_lastPinchDistance - distance) * _pinchZoomSpeed);
      }

      _lastPinchDistance = distance;
      return;
    }

    // One finger (or mouse drag): turn the camera.
    _camera.rotate(event.delta.dx, event.delta.dy);
  }

  void _onLookEnd(PointerEvent event) {
    _lookPointers.remove(event.pointer);
    _lastPinchDistance = 0;
  }

  // ------------------------------------------------------------------
  // Keyboard: WASD / arrows, Space jump, Shift run, C crouch, Q dodge.
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
    LogicalKeyboardKey.keyC,
    LogicalKeyboardKey.keyQ,
  };

  void _toggleSprint() {
    if (_phase != _Phase.playing || _crouching) return;

    setState(() {
      _sprinting = !_sprinting;
      _controller.sprinting = _sprinting;
    });
  }

  void _toggleCrouch() {
    if (_phase != _Phase.playing) return;

    final next = !_crouching;

    _controller.crouching = next;

    setState(() {
      _crouching = _controller.crouching;
      _sprinting = _controller.sprinting;
    });
  }

  void _performDodge() {
    if (_phase != _Phase.playing) return;

    _controller.dodge();
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (!_gameKeys.contains(event.logicalKey)) {
      return KeyEventResult.ignored;
    }

    if (_phase != _Phase.playing) {
      return KeyEventResult.handled;
    }

    if (event.logicalKey == LogicalKeyboardKey.space) {
      if (event is KeyDownEvent) {
        _controller.jump();
      }

      return KeyEventResult.handled;
    }

    if (event.logicalKey == LogicalKeyboardKey.keyC) {
      if (event is KeyDownEvent) {
        _toggleCrouch();
      }

      return KeyEventResult.handled;
    }

    if (event.logicalKey == LogicalKeyboardKey.keyQ) {
      if (event is KeyDownEvent) {
        _performDodge();
      }

      return KeyEventResult.handled;
    }

    if (event is KeyRepeatEvent) {
      return KeyEventResult.handled;
    }

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
  // HUD.
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
              ValueListenableBuilder<int>(
                valueListenable: _healthShown,
                builder: (context, value, child) {
                  final low = value <= GameRules.lowHealth;

                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$value',
                        style: TextStyle(
                          color: low ? Colors.redAccent : Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 64,
                        height: 6,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(3),
                          child: LinearProgressIndicator(
                            value: (value / GameRules.maxHealth)
                                .clamp(0.0, 1.0)
                                .toDouble(),
                            backgroundColor: Colors.white24,
                            color:
                                low ? Colors.redAccent : Colors.greenAccent,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(width: 10),
            _chip(
              Icons.flag,
              Colors.cyanAccent,
              ValueListenableBuilder<int>(
                valueListenable: _finishDistance,
                builder: (context, value, child) => Text(
                  '$value m',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }

  Widget _chip(IconData icon, Color color, Widget child) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 8,
      ),
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

  // ------------------------------------------------------------------
  // Toast.
  // ------------------------------------------------------------------

  Widget _toastLayer() {
    return Positioned(
      top: 70,
      left: 0,
      right: 0,
      child: IgnorePointer(
        child: Center(
          child: ValueListenableBuilder<String>(
            valueListenable: _toast,
            builder: (context, text, child) {
              if (text.isEmpty) {
                return const SizedBox.shrink();
              }

              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.redAccent),
                ),
                child: Text(
                  text,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------------
  // Win / game over card.
  // ------------------------------------------------------------------

  Widget _endOverlay() {
    final won = _phase == _Phase.won;
    final color = won ? Colors.cyanAccent : Colors.redAccent;

    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(alpha: 0.65),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 36,
              vertical: 24,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFF101830),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color, width: 2),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  won ? Icons.emoji_events : Icons.heart_broken,
                  size: 52,
                  color: color,
                ),
                const SizedBox(height: 10),
                Text(
                  won ? 'You made it!' : 'Out of health',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Coins: ${_coins.collected.value} / ${_coins.total}',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                ),
                if (won)
                  Text(
                    'Health left: ${_healthShown.value}',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _restart,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Play again'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------------
  // Mobile controls.
  // ------------------------------------------------------------------

  Widget _controlsLayer() {
    final pad = MediaQuery.of(context).padding;

    return Stack(
      children: [
        // Joystick position
        Positioned(
          left: 30 + pad.left,
          bottom: 30 + pad.bottom,
          child: Joystick(
            size: 150,
            onChanged: (x, y) => _controller.setInput(x, y),
          ),
        ),

        // Sprint button position
        Positioned(
          right: 40,
          bottom: 195,
          child: ActionButton(
            icon: Icons.directions_run_rounded,
            size: 54,
            active: _sprinting,
            onDown: _toggleSprint,
          ),
        ),

        // Crouch button position
        Positioned(
          right: 130,
          bottom: 35,
          child: ActionButton(
            icon: Icons.airline_seat_recline_normal,
            size: 54,
            active: _crouching,
            onDown: _toggleCrouch,
          ),
        ),

        // Dodge button position
        Positioned(
          right: 40,
          bottom: 125,
          child: ActionButton(
            icon: Icons.rotate_right,
            size: 54,
            onDown: _performDodge,
          ),
        ),

        // Jump button position
        Positioned(
          right: 30,
          bottom: 30,
          child: ActionButton(
            icon: Icons.keyboard_double_arrow_up,
            size: 78,
            onDown: _controller.jump,
          ),
        ),
      ],
    );
  }

  Widget _hint() {
    return const Positioned(
      bottom: 10,
      left: 0,
      right: 0,
      child: IgnorePointer(
        child: Center(
          child: Text(
            'Drag to look • Scroll to zoom • WASD move • Space jump • Shift run • C crouch • Q dodge',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _activeScreens--;

    // Only reset screen settings when no other game screen is alive.
    if (_activeScreens <= 0) {
      SystemChrome.setPreferredOrientations(DeviceOrientation.values);
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }

    _toastTimer?.cancel();

    _ticker.dispose();
    _controller.dispose();
    _focus.dispose();

    _skyTime.dispose();
    _healthShown.dispose();
    _finishDistance.dispose();
    _toast.dispose();

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
      return Scaffold(
        backgroundColor: const Color(0xFF080E13),
        body: Stack(
          fit: StackFit.expand,
          children: [
            // Dark cinematic background.
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF101F27),
                    Color(0xFF080E13),
                    Color(0xFF030608),
                  ],
                ),
              ),
            ),

            // Loading content.
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 42),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.landscape_rounded,
                      size: 66,
                      color: Color(0xFF72D6C1),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'THE PLANET SURVIVOR',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 34,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 5,
                      ),
                    ),
                    const SizedBox(height: 9),
                    const Text(
                      'A MYSTERIOUS SURVIVAL ADVENTURE',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFF8CA9A8),
                        fontSize: 11,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 42),
                    const LinearProgressIndicator(
                      minHeight: 5,
                      backgroundColor: Color(0xFF26343A),
                      color: Color(0xFF72D6C1),
                    ),
                    const SizedBox(height: 15),
                    Text(
                      _loadingFailed
                          ? 'LOADING FAILED'
                          : 'PREPARING YOUR WORLD...',
                      style: const TextStyle(
                        color: Color(0xFFB7CBC7),
                        fontSize: 11,
                        letterSpacing: 2,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const Positioned(
              bottom: 24,
              left: 0,
              right: 0,
              child: Text(
                'EXPLORE • SURVIVE • DISCOVER',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white38,
                  fontSize: 10,
                  letterSpacing: 3,
                ),
              ),
            ),
          ],
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
            // Sky is painted behind the transparent 3D view.
            Positioned.fill(
              child: SkyBackground(
                camera: _camera,
                time: _skyTime,
              ),
            ),
            Positioned.fill(
              child: Listener(
                onPointerDown: _onLookDown,
                onPointerMove: _onLookMove,
                onPointerUp: _onLookEnd,
                onPointerCancel: _onLookEnd,
                // Mouse wheel zooms (web / desktop).
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
            _toastLayer(),
            _controlsLayer(),
            if (kIsWeb) _hint(),
            if (_phase != _Phase.playing) _endOverlay(),
          ],
        ),
      ),
    );
  }
}