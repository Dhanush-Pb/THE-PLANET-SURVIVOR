
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_scene/scene.dart';
import 'package:vector_math/vector_math.dart' as vm;

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const WildStepApp());
}

class WildStepApp extends StatelessWidget {
  const WildStepApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: JungleGame(),
    );
  }
}

class JungleGame extends StatefulWidget {
  const JungleGame({super.key});

  @override
  State<JungleGame> createState() => _JungleGameState();
}

class _JungleGameState extends State<JungleGame> {
  final Scene scene = Scene();

  late Node playerModel;

  double playerX = 0;
  double playerZ = 5;

  double health = 100;
  double stamina = 100;

  bool ready = false;
  bool loadingFailed = false;
  bool sprinting = false;

  String errorMessage = '';

  Timer? movementTimer;

  double heldX = 0;
  double heldZ = 0;

  static const double walkSpeed = 0.16;
  static const double runSpeed = 0.30;

  UnlitMaterial material(double r, double g, double b) {
    return UnlitMaterial()
      ..baseColorFactor = vm.Vector4(r, g, b, 1);
  }

  Node createBox(
    double width,
    double height,
    double depth,
    double x,
    double y,
    double z,
    double r,
    double g,
    double b,
  ) {
    final node = Node(
      mesh: Mesh(
        CuboidGeometry(vm.Vector3(width, height, depth)),
        material(r, g, b),
      ),
    );

    node.position = vm.Vector3(x, y, z);
    scene.add(node);
    return node;
  }

  void createTree(double x, double z, double size) {
    // Tree trunk
    createBox(
      0.45 * size, 3.2 * size, 0.45 * size,
      x, 1.6 * size, z,
      0.25, 0.12, 0.05,
    );

    // Lower leaves
    createBox(
      2.8 * size, 1.5 * size, 2.8 * size,
      x, 3.1 * size, z,
      0.04, 0.22, 0.07,
    );

    // Upper leaves
    createBox(
      2.0 * size, 1.6 * size, 2.0 * size,
      x, 4.2 * size, z,
      0.08, 0.34, 0.09,
    );
  }

  void createWorld() {
    // Jungle ground
    createBox(
      60, 0.3, 75,
      0, -0.2, 0,
      0.13, 0.29, 0.10,
    );

    // Main jungle path
    createBox(
      5, 0.12, 75,
      0, 0.02, 0,
      0.46, 0.34, 0.19,
    );

    // Small path details
    for (int i = -30; i <= 30; i += 5) {
      createBox(
        1.5, 0.08, 2,
        0.3, 0.10, i.toDouble(),
        0.55, 0.42, 0.25,
      );
    }

    // Left side trees
    for (int i = 0; i < 16; i++) {
      final x = -7.0 - (i % 3) * 2.5;
      final z = -32.0 + i * 4.2;
      createTree(x, z, 0.9 + (i % 3) * 0.12);
    }

    // Right side trees
    for (int i = 0; i < 16; i++) {
      final x = 7.0 + (i % 3) * 2.5;
      final z = -32.0 + i * 4.2;
      createTree(x, z, 0.9 + (i % 2) * 0.15);
    }

    // Rocks
    for (int i = 0; i < 12; i++) {
      createBox(
        1.3 + (i % 2) * 0.6,
        0.8 + (i % 3) * 0.3,
        1.2,
        i.isEven ? -4.5 : 4.5,
        0.4,
        -25.0 + i * 4.5,
        0.25, 0.27, 0.23,
      );
    }
  }

  Future<void> initializeGame() async {
    try {
      await Scene.initializeStaticResources();

      createWorld();
playerModel = await loadScene(
  'assets/models/player/Teen.glb',
);

// Ara exports the character at 1.48 metres.
// Start with its original scale.
playerModel.scale = vm.Vector3(1, 1, 1);

playerModel.position = vm.Vector3(0, 0, 5);

scene.add(playerModel);

// Print every animation imported from the GLB.
debugPrint('===== CHARACTER ANIMATIONS =====');

for (final animation in playerModel.parsedAnimations) {
  debugPrint(
    '${animation.name} | ${animation.endTime.toStringAsFixed(2)} seconds',
  );
}

debugPrint('===== END ANIMATIONS =====');

// Play idle animation.
final idle = playerModel.findAnimationByName('Idle-loop');

if (idle != null) {
  final idleClip = playerModel.createAnimationClip(idle);
  idleClip.loop = true;
  idleClip.play();
} else {
  debugPrint('Idle-loop animation not found!');
}

      if (!mounted) return;

      setState(() {
        ready = true;
        loadingFailed = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        loadingFailed = true;
        errorMessage = e.toString();
      });
    }
  }

  @override
  void initState() {
    super.initState();

    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.immersiveSticky,
    );

    initializeGame();
  }

  void startMoving(double dx, double dz) {
    if (!ready) return;

    heldX = dx;
    heldZ = dz;

    movementTimer ??= Timer.periodic(
      const Duration(milliseconds: 50),
      (_) => movePlayer(),
    );
  }

  void stopMoving() {
    heldX = 0;
    heldZ = 0;

    movementTimer?.cancel();
    movementTimer = null;
  }

  void movePlayer() {
    if (!ready || (heldX == 0 && heldZ == 0)) return;

    final isRunning = sprinting && stamina > 0;
    final speed = isRunning ? runSpeed : walkSpeed;

    setState(() {
      playerX = (playerX + heldX * speed).clamp(-12.0, 12.0);
      playerZ = (playerZ + heldZ * speed).clamp(-33.0, 33.0);

      playerModel.position = vm.Vector3(
        playerX,
        0,
        playerZ,
      );

      if (isRunning) {
        stamina = (stamina - 0.45).clamp(0.0, 100.0);
      }
    });
  }

  void restPlayer() {
    if (!ready) return;

    stopMoving();

    setState(() {
      stamina = (stamina + 25).clamp(0.0, 100.0);
      health = (health + 5).clamp(0.0, 100.0);
    });
  }

  Widget movementButton({
    required IconData icon,
    required double dx,
    required double dz,
  }) {
    return GestureDetector(
      onTapDown: (_) => startMoving(dx, dz),
      onTapUp: (_) => stopMoving(),
      onTapCancel: stopMoving,
      child: Container(
        width: 65,
        height: 65,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.55),
          border: Border.all(
            color: Colors.white54,
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: 34,
        ),
      ),
    );
  }

  Widget statusBar({
    required String label,
    required double value,
    required Color color,
  }) {
    return SizedBox(
      width: 145,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label ${value.toInt()}%',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 5),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: value / 100,
              minHeight: 9,
              backgroundColor: Colors.white24,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildControls() {
    return Positioned(
      left: 25,
      right: 25,
      bottom: 22,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Movement controls
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              movementButton(
                icon: Icons.keyboard_arrow_up,
                dx: 0,
                dz: -1,
              ),
              const SizedBox(height: 7),
              Row(
                children: [
                  movementButton(
                    icon: Icons.keyboard_arrow_left,
                    dx: -1,
                    dz: 0,
                  ),
                  const SizedBox(width: 7),
                  movementButton(
                    icon: Icons.keyboard_arrow_down,
                    dx: 0,
                    dz: 1,
                  ),
                  const SizedBox(width: 7),
                  movementButton(
                    icon: Icons.keyboard_arrow_right,
                    dx: 1,
                    dz: 0,
                  ),
                ],
              ),
            ],
          ),

          // Run and rest controls
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTapDown: (_) {
                  setState(() => sprinting = true);
                },
                onTapUp: (_) {
                  setState(() => sprinting = false);
                },
                onTapCancel: () {
                  setState(() => sprinting = false);
                },
                child: Container(
                  width: 75,
                  height: 65,
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.directions_run,
                        color: Colors.white,
                        size: 30,
                      ),
                      Text(
                        'RUN',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: restPlayer,
                child: Container(
                  width: 75,
                  height: 45,
                  decoration: BoxDecoration(
                    color: Colors.green.shade800,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Center(
                    child: Text(
                      'REST',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget buildHud() {
    return Positioned(
      left: 22,
      top: 18,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'THE WILD STEP',
            style: TextStyle(
              color: Colors.white,
              fontSize: 21,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
              shadows: [
                Shadow(
                  color: Colors.black,
                  blurRadius: 8,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          statusBar(
            label: 'HEALTH',
            value: health,
            color: Colors.redAccent,
          ),
          const SizedBox(height: 8),
          statusBar(
            label: 'STAMINA',
            value: stamina,
            color: Colors.lightGreenAccent,
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    movementTimer?.cancel();

    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.edgeToEdge,
    );

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (loadingFailed) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Unable to load the game model.\n\n$errorMessage',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ),
      );
    }

    if (!ready) {
      return const Scaffold(
        backgroundColor: Color(0xFF101B12),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                color: Colors.greenAccent,
              ),
              SizedBox(height: 18),
              Text(
                'LOADING THE WILD STEP...',
                style: TextStyle(
                  color: Colors.white,
                  letterSpacing: 2,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          // 3D game world and third-person camera
          Positioned.fill(
            child: SceneView(
              scene,
              cameraBuilder: (elapsed) {
                return PerspectiveCamera(
                  position: vm.Vector3(
                    playerX,
                    4.5,
                    playerZ + 8,
                  ),
                  target: vm.Vector3(
                    playerX,
                    1.2,
                    playerZ - 0.8,
                  ),
                );
              },
            ),
          ),

          // Game HUD
          buildHud(),

          // Movement and action controls
          buildControls(),
        ],
      ),
    );
  }
}
