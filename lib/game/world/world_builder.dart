import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter_scene/scene.dart';
import 'package:vector_math/vector_math.dart' as vm;

import '../physics/collision.dart';

/// Shared shapes and colors. Created once, reused by every object.
class _Kit {
  _Kit()
      : trunk = CylinderGeometry(bottomRadius: 0.3, topRadius: 0.2, height: 1.6),
        pineBig =
            CylinderGeometry(bottomRadius: 1.4, topRadius: 0.05, height: 2.4),
        pineSmall =
            CylinderGeometry(bottomRadius: 1.0, topRadius: 0.05, height: 2.0),
        cone = CylinderGeometry(bottomRadius: 1, topRadius: 0.04, height: 1),
        disc = CylinderGeometry(bottomRadius: 1, topRadius: 1, height: 1),
        ball = SphereGeometry(radius: 0.5),
        groundSlab = CuboidGeometry(vm.Vector3(220, 0.2, 220)),
        pathSlab = CuboidGeometry(vm.Vector3(3.8, 0.06, 4.2)),
        grass = WorldBuilder._mat(0.22, 0.52, 0.14),
        patchLight = WorldBuilder._mat(0.32, 0.62, 0.18),
        patchDark = WorldBuilder._mat(0.14, 0.40, 0.11),
        dirt = WorldBuilder._mat(0.58, 0.42, 0.24),
        sand = WorldBuilder._mat(0.85, 0.76, 0.50),
        water = WorldBuilder._mat(0.10, 0.48, 0.80, roughness: 0.2),
        lily = WorldBuilder._mat(0.15, 0.55, 0.20),
        bark = WorldBuilder._mat(0.36, 0.23, 0.12),
        pineA = WorldBuilder._mat(0.06, 0.36, 0.16),
        pineB = WorldBuilder._mat(0.10, 0.46, 0.20),
        autumn = [
          WorldBuilder._mat(0.96, 0.50, 0.10), // orange
          WorldBuilder._mat(0.82, 0.20, 0.12), // red
          WorldBuilder._mat(0.96, 0.78, 0.15), // yellow
          WorldBuilder._mat(0.55, 0.76, 0.16), // lime
          WorldBuilder._mat(0.95, 0.55, 0.70), // pink blossom
        ],
        bushes = [
          WorldBuilder._mat(0.12, 0.38, 0.12),
          WorldBuilder._mat(0.18, 0.46, 0.14),
          WorldBuilder._mat(0.26, 0.52, 0.16),
        ],
        stone = WorldBuilder._mat(0.52, 0.52, 0.55),
        stoneDark = WorldBuilder._mat(0.38, 0.38, 0.42),
        flowers = [
          WorldBuilder._mat(0.95, 0.15, 0.15),
          WorldBuilder._mat(0.98, 0.82, 0.15),
          WorldBuilder._mat(0.98, 0.98, 0.95),
          WorldBuilder._mat(0.65, 0.25, 0.88),
          WorldBuilder._mat(0.98, 0.50, 0.75),
        ],
        mushCap = WorldBuilder._mat(0.88, 0.12, 0.12),
        mushStem = WorldBuilder._mat(0.96, 0.94, 0.86),
        mountain = WorldBuilder._mat(0.40, 0.50, 0.66),
        snow = WorldBuilder._mat(0.96, 0.98, 1.0),
        hills = [
          WorldBuilder._mat(0.28, 0.56, 0.30),
          WorldBuilder._mat(0.34, 0.54, 0.34),
        ];

  final MeshGeometry trunk;
  final MeshGeometry pineBig;
  final MeshGeometry pineSmall;
  final MeshGeometry cone;
  final MeshGeometry disc;
  final MeshGeometry ball;
  final MeshGeometry groundSlab;
  final MeshGeometry pathSlab;

  final PhysicallyBasedMaterial grass;
  final PhysicallyBasedMaterial patchLight;
  final PhysicallyBasedMaterial patchDark;
  final PhysicallyBasedMaterial dirt;
  final PhysicallyBasedMaterial sand;
  final PhysicallyBasedMaterial water;
  final PhysicallyBasedMaterial lily;
  final PhysicallyBasedMaterial bark;
  final PhysicallyBasedMaterial pineA;
  final PhysicallyBasedMaterial pineB;
  final List<PhysicallyBasedMaterial> autumn;
  final List<PhysicallyBasedMaterial> bushes;
  final PhysicallyBasedMaterial stone;
  final PhysicallyBasedMaterial stoneDark;
  final List<PhysicallyBasedMaterial> flowers;
  final PhysicallyBasedMaterial mushCap;
  final PhysicallyBasedMaterial mushStem;
  final PhysicallyBasedMaterial mountain;
  final PhysicallyBasedMaterial snow;
  final List<PhysicallyBasedMaterial> hills;
}

class WorldBuilder {
  WorldBuilder._();

  /// Walkable half-size (the park is 80 x 80).
  static const double halfExtent = 40;

  static const double startX = 0;
  static const double startZ = 5;

  // Lake
  static const double lakeX = -22;
  static const double lakeZ = -20;
  static const double lakeRadius = 5.5;
  static const double lakeKeepOut = 9;

  /// Things the player cannot walk through.
  static final List<CircleObstacle> obstacles = [];

  /// Where coins go (read by CoinSystem).
  static final List<vm.Vector3> coinSpots = [];

  // Amounts (web is lighter).
  static int get borderTrees => kIsWeb ? 14 : 22;
  static int get scatteredTrees => kIsWeb ? 18 : 36;
  static int get bushCount => kIsWeb ? 12 : 24;
  static int get rockCount => kIsWeb ? 8 : 14;
  static int get flowerCount => kIsWeb ? 14 : 30;
  static int get mushroomCount => kIsWeb ? 5 : 10;
  static int get patchCount => kIsWeb ? 10 : 22;
  static int get mountainCount => kIsWeb ? 10 : 14;
  static int get hillCount => kIsWeb ? 6 : 8;
  static int get coinRings => kIsWeb ? 2 : 3;

  /// Winding path: x for a given z. It passes through the start (0, 5).
  static double trailX(double z) => 6.0 * math.sin((z - startZ) * 0.09);

  static double _trailSlope(double z) =>
      6.0 * 0.09 * math.cos((z - startZ) * 0.09);

  static PhysicallyBasedMaterial _mat(
    double r,
    double g,
    double b, {
    double roughness = 0.9,
  }) {
    final m = PhysicallyBasedMaterial();
    m.baseColorFactor = vm.Vector4(r, g, b, 1);
    m.roughnessFactor = roughness;
    m.metallicFactor = 0;
    return m;
  }

  // ------------------------------------------------------------------
  // Entry point
  // ------------------------------------------------------------------
  static Future<void> loadInto(Scene scene) async {
    _applyLighting(scene);

    obstacles.clear();
    coinSpots.clear();

    final k = _Kit();
    final random = math.Random(5); // fixed seed: same park every run
    final placed = <vm.Vector2>[];

    scene.add(_part(k.groundSlab, k.grass, 0, -0.1, 0));

    _addMountains(scene, k, random);
    _addHills(scene, k, random);
    await Future<void>.delayed(Duration.zero);

    _addPatches(scene, k, random);
    _addTrail(scene, k);
    _addLake(scene, k, random);
    await Future<void>.delayed(Duration.zero);

    _addBorderTrees(scene, k, random);
    _addScatteredTrees(scene, k, random, placed);
    await Future<void>.delayed(Duration.zero);

    _addBushes(scene, k, random, placed);
    _addRocks(scene, k, random, placed);
    _addMushrooms(scene, k, random, placed);
    _addFlowers(scene, k, random, placed);
    await Future<void>.delayed(Duration.zero);

    _planCoins(random, placed);

    debugPrint('Park built. Obstacles: ${obstacles.length}, '
        'coins planned: ${coinSpots.length}');
  }

  /// Replaces the default studio lighting, which fails on some browsers.
  /// If this line shows a red error, delete the call and this method.
  static void _applyLighting(Scene scene) {
    scene.environment = EnvironmentMap.constantDiffuse(vm.Vector3.all(0.9));
  }

  // ------------------------------------------------------------------
  // Helpers
  // ------------------------------------------------------------------
  static Node _part(
    MeshGeometry geometry,
    PhysicallyBasedMaterial material,
    double x,
    double y,
    double z, {
    vm.Vector3? scale,
  }) {
    final node = Node(mesh: Mesh(geometry, material));
    node.position = vm.Vector3(x, y, z);
    if (scale != null) node.scale = scale;
    return node;
  }

  static void _spin(Node node, math.Random random) {
    node.rotation = vm.Quaternion.axisAngle(
      vm.Vector3(0, 1, 0),
      random.nextDouble() * math.pi * 2,
    );
  }

  static Node _pine(_Kit k, double size, bool alt) {
    final g = Node();
    g.add(_part(k.trunk, k.bark, 0, 0.8, 0));
    g.add(_part(k.pineBig, alt ? k.pineB : k.pineA, 0, 2.5, 0));
    g.add(_part(k.pineSmall, alt ? k.pineA : k.pineB, 0, 3.7, 0));
    g.scale = vm.Vector3.all(size);
    return g;
  }

  static Node _roundTree(_Kit k, double size, PhysicallyBasedMaterial leaf) {
    final g = Node();
    g.add(_part(k.trunk, k.bark, 0, 0.8, 0));
    g.add(_part(k.ball, leaf, 0, 3.1, 0, scale: vm.Vector3(3.8, 3.2, 3.8)));
    g.scale = vm.Vector3.all(size);
    return g;
  }

  static Node _randomTree(_Kit k, math.Random random, double size) {
    if (random.nextDouble() < 0.5) {
      return _pine(k, size, random.nextBool());
    }
    return _roundTree(k, size, k.autumn[random.nextInt(k.autumn.length)]);
  }

  static bool _valid(
    List<vm.Vector2> placed,
    double x,
    double z, {
    required double gap,
    required double trailClear,
    double limit = 38,
  }) {
    if (x.abs() > limit || z.abs() > limit) return false;

    final sx = x - startX;
    final sz = z - startZ;
    if (sx * sx + sz * sz < 36) return false;

    final lx = x - lakeX;
    final lz = z - lakeZ;
    if (lx * lx + lz * lz < lakeKeepOut * lakeKeepOut) return false;

    if ((x - trailX(z)).abs() < trailClear) return false;

    for (final p in placed) {
      final dx = x - p.x;
      final dz = z - p.y;
      if (dx * dx + dz * dz < gap * gap) return false;
    }
    return true;
  }

  /// Finds a free spot, or null. [spread] keeps it near the trail.
  static vm.Vector2? _spot(
    math.Random random,
    List<vm.Vector2> placed, {
    required double gap,
    required double trailClear,
    double limit = 38,
  }) {
    for (var i = 0; i < 40; i++) {
      final x = (random.nextDouble() * 2 - 1) * limit;
      final z = (random.nextDouble() * 2 - 1) * limit;
      if (_valid(placed, x, z,
          gap: gap, trailClear: trailClear, limit: limit)) {
        return vm.Vector2(x, z);
      }
    }
    return null;
  }

  // ------------------------------------------------------------------
  // Far scenery: mountains and hills
  // ------------------------------------------------------------------
  static void _addMountains(Scene scene, _Kit k, math.Random random) {
    final n = mountainCount;

    for (var i = 0; i < n; i++) {
      final a = math.pi * 2 * i / n + random.nextDouble() * 0.2;
      final dist = 92 + random.nextDouble() * 10;
      final r = 20 + random.nextDouble() * 10;
      final h = 28 + random.nextDouble() * 22;
      final x = math.sin(a) * dist;
      final z = math.cos(a) * dist;

      scene.add(_part(k.cone, k.mountain, x, h / 2, z,
          scale: vm.Vector3(r, h, r)));

      // Snow cap on top.
      scene.add(_part(k.cone, k.snow, x, h * 0.65 + h * 0.175, z,
          scale: vm.Vector3(r * 0.35, h * 0.35, r * 0.35)));
    }
  }

  static void _addHills(Scene scene, _Kit k, math.Random random) {
    final n = hillCount;

    for (var i = 0; i < n; i++) {
      final a = math.pi * 2 * (i + 0.5) / n + random.nextDouble() * 0.2;
      final dist = 60 + random.nextDouble() * 8;
      final x = math.sin(a) * dist;
      final z = math.cos(a) * dist;

      scene.add(_part(
        k.ball,
        k.hills[i % k.hills.length],
        x,
        0,
        z,
        scale: vm.Vector3(
          28 + random.nextDouble() * 12,
          9 + random.nextDouble() * 6,
          24 + random.nextDouble() * 8,
        ),
      ));
    }
  }

  // ------------------------------------------------------------------
  // Ground details
  // ------------------------------------------------------------------
  static void _addPatches(Scene scene, _Kit k, math.Random random) {
    for (var i = 0; i < patchCount; i++) {
      final x = (random.nextDouble() * 2 - 1) * 55;
      final z = (random.nextDouble() * 2 - 1) * 55;
      final r = 2.5 + random.nextDouble() * 4;

      scene.add(_part(
        k.disc,
        i.isEven ? k.patchLight : k.patchDark,
        x,
        0.006 + i * 0.0004, // each patch a bit higher: no flicker
        z,
        scale: vm.Vector3(r, 0.01, r * (0.7 + random.nextDouble() * 0.5)),
      ));
    }
  }

  static void _addTrail(Scene scene, _Kit k) {
    for (var z = -44.0; z <= 44.0; z += 3.6) {
      final slab = _part(k.pathSlab, k.dirt, trailX(z), 0.03, z);
      slab.rotation = vm.Quaternion.axisAngle(
        vm.Vector3(0, 1, 0),
        math.atan2(_trailSlope(z), 1),
      );
      scene.add(slab);
    }
  }

  static void _addLake(Scene scene, _Kit k, math.Random random) {
    // Sand rim, then water on top.
    scene.add(_part(k.disc, k.sand, lakeX, 0.025, lakeZ,
        scale: vm.Vector3(lakeRadius + 1.2, 0.05, lakeRadius + 1.2)));
    scene.add(_part(k.disc, k.water, lakeX, 0.045, lakeZ,
        scale: vm.Vector3(lakeRadius, 0.08, lakeRadius)));

    for (var i = 0; i < 4; i++) {
      final a = random.nextDouble() * math.pi * 2;
      final d = random.nextDouble() * (lakeRadius - 1.5);
      scene.add(_part(k.disc, k.lily, lakeX + math.cos(a) * d, 0.095,
          lakeZ + math.sin(a) * d,
          scale: vm.Vector3(0.8, 0.02, 0.8)));
    }

    obstacles.add(const CircleObstacle(lakeX, lakeZ, lakeRadius));
  }

  // ------------------------------------------------------------------
  // Trees
  // ------------------------------------------------------------------
  static void _addBorderTrees(Scene scene, _Kit k, math.Random random) {
    const edge = 43.0;
    final perSide = (borderTrees / 4).ceil();

    for (var side = 0; side < 4; side++) {
      for (var i = 0; i < perSide; i++) {
        final t = -edge + (2 * edge) * (i + 0.5) / perSide;
        final jitter = (random.nextDouble() - 0.5) * 4;

        double x, z;
        switch (side) {
          case 0:
            x = t;
            z = -edge + jitter;
          case 1:
            x = t;
            z = edge + jitter;
          case 2:
            x = -edge + jitter;
            z = t;
          default:
            x = edge + jitter;
            z = t;
        }

        final tree = _randomTree(k, random, 1.3 + random.nextDouble() * 0.5);
        tree.position = vm.Vector3(x, 0, z);
        _spin(tree, random);
        scene.add(tree);
      }
    }
  }

  static void _addScatteredTrees(
    Scene scene,
    _Kit k,
    math.Random random,
    List<vm.Vector2> placed,
  ) {
    for (var i = 0; i < scatteredTrees; i++) {
      final s = _spot(random, placed, gap: 7, trailClear: 5);
      if (s == null) continue;

      final size = 0.9 + random.nextDouble() * 0.6;
      final tree = _randomTree(k, random, size);
      tree.position = vm.Vector3(s.x, 0, s.y);
      _spin(tree, random);
      scene.add(tree);

      placed.add(s);
      obstacles.add(CircleObstacle(s.x, s.y, 0.6 * size));
    }
  }

  // ------------------------------------------------------------------
  // Small things
  // ------------------------------------------------------------------
  static void _addBushes(
    Scene scene,
    _Kit k,
    math.Random random,
    List<vm.Vector2> placed,
  ) {
    for (var i = 0; i < bushCount; i++) {
      final s = _spot(random, placed, gap: 3, trailClear: 3);
      if (s == null) continue;

      final size = 0.8 + random.nextDouble() * 0.7;
      scene.add(_part(
        k.ball,
        k.bushes[random.nextInt(k.bushes.length)],
        s.x,
        0.3 * size,
        s.y,
        scale: vm.Vector3(1.5 * size, 0.9 * size, 1.5 * size),
      ));

      placed.add(s);
      obstacles.add(CircleObstacle(s.x, s.y, 0.6 * size));
    }
  }

  static void _addRocks(
    Scene scene,
    _Kit k,
    math.Random random,
    List<vm.Vector2> placed,
  ) {
    for (var i = 0; i < rockCount; i++) {
      final s = _spot(random, placed, gap: 3.5, trailClear: 3);
      if (s == null) continue;

      final size = 0.8 + random.nextDouble() * 1.1;
      final rock = _part(
        k.ball,
        i.isEven ? k.stone : k.stoneDark,
        s.x,
        0.22 * size,
        s.y,
        scale: vm.Vector3(1.6 * size, 0.9 * size, 1.2 * size),
      );
      _spin(rock, random);
      scene.add(rock);

      placed.add(s);
      obstacles.add(CircleObstacle(s.x, s.y, 0.7 * size));
    }
  }

  static void _addMushrooms(
    Scene scene,
    _Kit k,
    math.Random random,
    List<vm.Vector2> placed,
  ) {
    for (var i = 0; i < mushroomCount; i++) {
      final s = _spot(random, placed, gap: 3, trailClear: 3);
      if (s == null) continue;

      final size = 0.9 + random.nextDouble() * 0.8;
      final g = Node();
      g.add(_part(k.disc, k.mushStem, 0, 0.25, 0,
          scale: vm.Vector3(0.14, 0.5, 0.14)));
      g.add(_part(k.ball, k.mushCap, 0, 0.55, 0,
          scale: vm.Vector3(0.8, 0.45, 0.8)));
      g.position = vm.Vector3(s.x, 0, s.y);
      g.scale = vm.Vector3.all(size);
      scene.add(g);

      placed.add(s);
    }
  }

  static void _addFlowers(
    Scene scene,
    _Kit k,
    math.Random random,
    List<vm.Vector2> placed,
  ) {
    for (var i = 0; i < flowerCount; i++) {
      final s = _spot(random, placed, gap: 1.6, trailClear: 2.6);
      if (s == null) continue;

      scene.add(_part(
        k.ball,
        k.flowers[random.nextInt(k.flowers.length)],
        s.x,
        0.15,
        s.y,
        scale: vm.Vector3.all(0.34),
      ));
      placed.add(s);
    }
  }

  // ------------------------------------------------------------------
  // Coins: a line along the path, arcs you must jump, and hidden rings
  // ------------------------------------------------------------------
  static void _planCoins(math.Random random, List<vm.Vector2> placed) {
    const arcStarts = [-32.0, -12.0, 12.0, 30.0];

    // Arcs (jump to collect the high ones).
    for (final zs in arcStarts) {
      for (var i = 0; i < 7; i++) {
        final t = i / 6;
        final z = zs + i * 1.1;
        coinSpots.add(vm.Vector3(
          trailX(z),
          1.0 + 2.0 * math.sin(math.pi * t),
          z,
        ));
      }
    }

    // Straight line along the path.
    for (var z = -38.0; z <= 38.0; z += 2.5) {
      var inArc = false;
      for (final zs in arcStarts) {
        if (z >= zs - 0.5 && z <= zs + 7.1) inArc = true;
      }
      if (inArc) continue;
      coinSpots.add(vm.Vector3(trailX(z), 1.0, z));
    }

    // Rings far from the path: a reason to explore the park.
    for (var r = 0; r < coinRings; r++) {
      final s = _spot(random, placed, gap: 5, trailClear: 8, limit: 36);
      if (s == null) continue;

      for (var i = 0; i < 8; i++) {
        final a = math.pi * 2 * i / 8;
        coinSpots.add(vm.Vector3(
          s.x + math.cos(a) * 2.4,
          1.3,
          s.y + math.sin(a) * 2.4,
        ));
      }
      placed.add(s);
    }
  }
}