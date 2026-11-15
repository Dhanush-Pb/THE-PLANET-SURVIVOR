import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter_scene/scene.dart';
import 'package:vector_math/vector_math.dart' as vm;

/// Shared geometry and materials. Created once, reused by every object.
class _Kit {
  _Kit()
      : trunk = CylinderGeometry(bottomRadius: 0.3, topRadius: 0.2, height: 1.6),
        coneBig =
            CylinderGeometry(bottomRadius: 1.4, topRadius: 0.05, height: 2.4),
        coneSmall =
            CylinderGeometry(bottomRadius: 1.0, topRadius: 0.05, height: 2.0),
        pondShape =
            CylinderGeometry(bottomRadius: 4.5, topRadius: 4.5, height: 0.08),
        ball = SphereGeometry(radius: 0.5),
        groundSlab = CuboidGeometry(vm.Vector3(84, 0.2, 84)),
        pathSlab = CuboidGeometry(vm.Vector3(3.6, 0.06, 3.8)),
        grass = JungleEnvironment._mat(0.14, 0.36, 0.10),
        dirt = JungleEnvironment._mat(0.42, 0.30, 0.16),
        bark = JungleEnvironment._mat(0.30, 0.19, 0.10),
        leafA = JungleEnvironment._mat(0.10, 0.40, 0.14),
        leafB = JungleEnvironment._mat(0.14, 0.48, 0.18),
        bushGreen = JungleEnvironment._mat(0.12, 0.33, 0.12),
        stone = JungleEnvironment._mat(0.45, 0.45, 0.47),
        water = JungleEnvironment._mat(0.12, 0.35, 0.60, roughness: 0.2),
        flowers = [
          JungleEnvironment._mat(0.90, 0.15, 0.15),
          JungleEnvironment._mat(0.95, 0.80, 0.15),
          JungleEnvironment._mat(0.95, 0.95, 0.90),
          JungleEnvironment._mat(0.65, 0.25, 0.85),
        ];

  final MeshGeometry trunk;
  final MeshGeometry coneBig;
  final MeshGeometry coneSmall;
  final MeshGeometry pondShape;
  final MeshGeometry ball;
  final MeshGeometry groundSlab;
  final MeshGeometry pathSlab;

  final PhysicallyBasedMaterial grass;
  final PhysicallyBasedMaterial dirt;
  final PhysicallyBasedMaterial bark;
  final PhysicallyBasedMaterial leafA;
  final PhysicallyBasedMaterial leafB;
  final PhysicallyBasedMaterial bushGreen;
  final PhysicallyBasedMaterial stone;
  final PhysicallyBasedMaterial water;
  final List<PhysicallyBasedMaterial> flowers;
}

class JungleEnvironment {
  JungleEnvironment._();

  /// Walkable half-size. The player is clamped to this.
  static const double halfExtent = 27;

  static const double startX = 0;
  static const double startZ = 5;

  // Pond position and the keep-out distance around it.
  static const double pondX = -14;
  static const double pondZ = -12;
  static const double pondKeepOut = 6.5;

  // Amounts (web is lighter).
  static int get borderTreesPerSide => kIsWeb ? 6 : 8;
  static int get trailTrees => kIsWeb ? 8 : 12;
  static int get bushes => kIsWeb ? 12 : 20;
  static int get rocks => kIsWeb ? 6 : 10;
  static int get flowerCount => kIsWeb ? 12 : 24;

  /// Winding trail: x position of the trail for a given z.
  static double trailX(double z) => 4.0 * math.sin((z - startZ) * 0.15);

  static double _trailSlope(double z) =>
      4.0 * 0.15 * math.cos((z - startZ) * 0.15);

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

    final kit = _Kit();
    final random = math.Random(21); // fixed seed: same world every run
    final placed = <vm.Vector2>[];

    _addGround(scene, kit);
    _addTrail(scene, kit);
    _addPond(scene, kit);
    await Future<void>.delayed(Duration.zero);

    _addBorderTrees(scene, kit, random, placed);
    await Future<void>.delayed(Duration.zero);

    _addTrailTrees(scene, kit, random, placed);
    await Future<void>.delayed(Duration.zero);

    _addBushes(scene, kit, random, placed);
    _addRocks(scene, kit, random, placed);
    _addFlowers(scene, kit, random, placed);

    debugPrint('Jungle built from code. Objects placed: ${placed.length}');
  }

  /// Replaces the default "studio" lighting, which fails on many
  /// browsers ("Framebuffer incomplete"). If this line shows a red error
  /// in your editor, delete the call to _applyLighting and this method.
  static void _applyLighting(Scene scene) {
    scene.environment = EnvironmentMap.constantDiffuse(vm.Vector3.all(0.9));
  }

  // ------------------------------------------------------------------
  // Small helpers
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

  static Node _tree(_Kit k, double size, bool alt) {
    final group = Node();
    group.add(_part(k.trunk, k.bark, 0, 0.8, 0));
    group.add(_part(k.coneBig, alt ? k.leafB : k.leafA, 0, 2.5, 0));
    group.add(_part(k.coneSmall, alt ? k.leafA : k.leafB, 0, 3.7, 0));
    group.scale = vm.Vector3.all(size);
    return group;
  }

  static void _spin(Node node, math.Random random) {
    node.rotation = vm.Quaternion.axisAngle(
      vm.Vector3(0, 1, 0),
      random.nextDouble() * math.pi * 2,
    );
  }

  /// Checks a spot: inside the map, away from start, pond and trail,
  /// and not too close to anything already placed.
  static bool _valid(
    List<vm.Vector2> placed,
    double x,
    double z, {
    required double gap,
    required double trailClear,
    double limit = 26,
  }) {
    if (x.abs() > limit || z.abs() > limit) return false;

    final sx = x - startX;
    final sz = z - startZ;
    if (sx * sx + sz * sz < 36) return false;

    final px = x - pondX;
    final pz = z - pondZ;
    if (px * px + pz * pz < pondKeepOut * pondKeepOut) return false;

    if ((x - trailX(z)).abs() < trailClear) return false;

    for (final p in placed) {
      final dx = x - p.x;
      final dz = z - p.y;
      if (dx * dx + dz * dz < gap * gap) return false;
    }
    return true;
  }

  // ------------------------------------------------------------------
  // Ground, trail, pond
  // ------------------------------------------------------------------
  static void _addGround(Scene scene, _Kit k) {
    scene.add(_part(k.groundSlab, k.grass, 0, -0.1, 0));
  }

  static void _addTrail(Scene scene, _Kit k) {
    for (var z = -30.0; z <= 30.0; z += 3.0) {
      final slab = _part(k.pathSlab, k.dirt, trailX(z), 0.03, z);
      slab.rotation = vm.Quaternion.axisAngle(
        vm.Vector3(0, 1, 0),
        math.atan2(_trailSlope(z), 1),
      );
      scene.add(slab);
    }
  }

  static void _addPond(Scene scene, _Kit k) {
    scene.add(_part(k.pondShape, k.water, pondX, 0.04, pondZ));
  }

  // ------------------------------------------------------------------
  // Trees
  // ------------------------------------------------------------------
  static void _addBorderTrees(
    Scene scene,
    _Kit k,
    math.Random random,
    List<vm.Vector2> placed,
  ) {
    const edge = 29.0;
    final n = borderTreesPerSide;

    for (var side = 0; side < 4; side++) {
      for (var i = 0; i < n; i++) {
        final t = -edge + (2 * edge) * (i + 0.5) / n;
        final jitter = (random.nextDouble() - 0.5) * 3;

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

        final tree = _tree(k, 1.2 + random.nextDouble() * 0.5, random.nextBool());
        tree.position = vm.Vector3(x, 0, z);
        _spin(tree, random);
        scene.add(tree);
        placed.add(vm.Vector2(x, z));
      }
    }
  }

  static void _addTrailTrees(
    Scene scene,
    _Kit k,
    math.Random random,
    List<vm.Vector2> placed,
  ) {
    var count = 0;
    var tries = 0;

    while (count < trailTrees && tries < 300) {
      tries++;
      final z = (random.nextDouble() * 2 - 1) * 24;
      final side = random.nextBool() ? 1.0 : -1.0;
      final x = trailX(z) + side * (5.5 + random.nextDouble() * 6);

      if (!_valid(placed, x, z, gap: 6, trailClear: 5, limit: 24)) continue;

      final tree = _tree(k, 0.9 + random.nextDouble() * 0.5, random.nextBool());
      tree.position = vm.Vector3(x, 0, z);
      _spin(tree, random);
      scene.add(tree);
      placed.add(vm.Vector2(x, z));
      count++;
    }
  }

  // ------------------------------------------------------------------
  // Bushes, rocks, flowers
  // ------------------------------------------------------------------
  static void _addBushes(
    Scene scene,
    _Kit k,
    math.Random random,
    List<vm.Vector2> placed,
  ) {
    var count = 0;
    var tries = 0;

    while (count < bushes && tries < 300) {
      tries++;
      final z = (random.nextDouble() * 2 - 1) * 25;
      final side = random.nextBool() ? 1.0 : -1.0;
      final x = trailX(z) + side * (3.2 + random.nextDouble() * 9);

      if (!_valid(placed, x, z, gap: 2.8, trailClear: 3)) continue;

      final s = 0.8 + random.nextDouble() * 0.7;
      scene.add(_part(
        k.ball,
        k.bushGreen,
        x,
        0.3 * s,
        z,
        scale: vm.Vector3(1.5 * s, 0.9 * s, 1.5 * s),
      ));
      placed.add(vm.Vector2(x, z));
      count++;
    }
  }

  static void _addRocks(
    Scene scene,
    _Kit k,
    math.Random random,
    List<vm.Vector2> placed,
  ) {
    var count = 0;
    var tries = 0;

    while (count < rocks && tries < 300) {
      tries++;
      final z = (random.nextDouble() * 2 - 1) * 25;
      final side = random.nextBool() ? 1.0 : -1.0;
      final x = trailX(z) + side * (3.2 + random.nextDouble() * 10);

      if (!_valid(placed, x, z, gap: 3, trailClear: 2.8)) continue;

      final s = 0.8 + random.nextDouble() * 1.0;
      final rock = _part(
        k.ball,
        k.stone,
        x,
        0.22 * s,
        z,
        scale: vm.Vector3(1.6 * s, 0.9 * s, 1.2 * s),
      );
      _spin(rock, random);
      scene.add(rock);
      placed.add(vm.Vector2(x, z));
      count++;
    }
  }

  static void _addFlowers(
    Scene scene,
    _Kit k,
    math.Random random,
    List<vm.Vector2> placed,
  ) {
    var count = 0;
    var tries = 0;

    while (count < flowerCount && tries < 400) {
      tries++;
      final z = (random.nextDouble() * 2 - 1) * 25;
      final side = random.nextBool() ? 1.0 : -1.0;
      final x = trailX(z) + side * (2.8 + random.nextDouble() * 6);

      if (!_valid(placed, x, z, gap: 1.4, trailClear: 2.6)) continue;

      scene.add(_part(
        k.ball,
        k.flowers[random.nextInt(k.flowers.length)],
        x,
        0.15,
        z,
        scale: vm.Vector3.all(0.32),
      ));
      placed.add(vm.Vector2(x, z));
      count++;
    }
  }
}