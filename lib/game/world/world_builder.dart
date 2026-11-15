import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter_scene/scene.dart';
import 'package:vector_math/vector_math.dart' as vm;

import '../physics/collision.dart';

/// Shared geometry + materials, created once per build.
class _Kit {
  // Unit shapes: scale them to the size you need.
  final box = CuboidGeometry(vm.Vector3(1, 1, 1));
  final sphere = SphereGeometry(radius: 0.5, segments: 20, rings: 14);
  final hill = SphereGeometry(radius: 0.5, segments: 28, rings: 14);
  final cyl = CylinderGeometry(
    bottomRadius: 0.5,
    topRadius: 0.5,
    height: 1,
    radialSegments: 24,
  );
  final disc = CylinderGeometry(
    bottomRadius: 1,
    topRadius: 1,
    height: 1,
    radialSegments: 56,
  );
  final cone = CylinderGeometry(
    bottomRadius: 1,
    topRadius: 0.05,
    height: 1,
    radialSegments: 14,
  );
  final ground = CuboidGeometry(vm.Vector3(260, 0.2, 260));

  // ---- terrain
  final groundMat = WorldBuilder._mat(0.34, 0.19, 0.15);
  final dust = WorldBuilder._mat(0.46, 0.30, 0.22);
  final rust = WorldBuilder._mat(0.25, 0.13, 0.11);
  final rockMat = WorldBuilder._mat(0.31, 0.23, 0.21, roughness: 0.85);
  final rockDark = WorldBuilder._mat(0.19, 0.14, 0.14, roughness: 0.85);
  final hillA = WorldBuilder._mat(0.27, 0.15, 0.13);
  final hillB = WorldBuilder._mat(0.20, 0.11, 0.12);
  final strata1 = WorldBuilder._mat(0.40, 0.21, 0.15);
  final strata2 = WorldBuilder._mat(0.31, 0.17, 0.13);
  final strata3 = WorldBuilder._mat(0.47, 0.28, 0.19);
  final sand = WorldBuilder._mat(0.52, 0.38, 0.27);

  // ---- roads / structures
  final road = WorldBuilder._mat(0.10, 0.10, 0.14, roughness: 0.6);
  final concrete = WorldBuilder._mat(0.56, 0.56, 0.61, roughness: 0.7);
  final concreteDark = WorldBuilder._mat(0.28, 0.29, 0.34, roughness: 0.7);
  final panel = WorldBuilder._mat(0.80, 0.82, 0.88, roughness: 0.45);
  final metal = WorldBuilder._mat(0.36, 0.39, 0.44, roughness: 0.4);
  final metalDark = WorldBuilder._mat(0.13, 0.14, 0.17, roughness: 0.5);
  final contRed = WorldBuilder._mat(0.55, 0.14, 0.12, roughness: 0.6);
  final contBlue = WorldBuilder._mat(0.12, 0.26, 0.52, roughness: 0.6);
  final contOrange = WorldBuilder._mat(0.72, 0.38, 0.10, roughness: 0.6);
  final contOlive = WorldBuilder._mat(0.30, 0.36, 0.20, roughness: 0.6);
  final wood = WorldBuilder._mat(0.40, 0.26, 0.14);
  final sandbag = WorldBuilder._mat(0.55, 0.46, 0.31);

  // ---- alien flora
  final trunk = WorldBuilder._mat(0.18, 0.12, 0.25);
  final canopyTeal = WorldBuilder._mat(0.05, 0.38, 0.40, roughness: 0.6);
  final canopyMagenta = WorldBuilder._mat(0.45, 0.12, 0.40, roughness: 0.6);
  final canopyViolet = WorldBuilder._mat(0.25, 0.15, 0.55, roughness: 0.6);

  // ---- glowing (unlit)
  final glowCyan = WorldBuilder._glow(0.12, 0.88, 0.98);
  final glowCyanDim = WorldBuilder._glow(0.05, 0.40, 0.50);
  final glowMagenta = WorldBuilder._glow(0.95, 0.22, 0.75);
  final glowViolet = WorldBuilder._glow(0.52, 0.32, 1.0);
  final glowWarm = WorldBuilder._glow(1.0, 0.78, 0.38);
  final glowWindow = WorldBuilder._glow(0.55, 0.90, 1.0);
  final glowWater = WorldBuilder._glow(0.05, 0.62, 0.80);
  final glowWaterLight = WorldBuilder._glow(0.12, 0.82, 0.92);
  final padCyan = WorldBuilder._glow(0.05, 0.16, 0.21);
  final padWarm = WorldBuilder._glow(0.24, 0.17, 0.10);
}

class WorldBuilder {
  WorldBuilder._();

  static const double halfExtent = 40;

  static const double startX = 0;
  static const double startZ = 5;

  // Glowing lake (kept so other code can still reference these).
  static const double poolX = -22;
  static const double poolZ = -20;
  static const double poolRadius = 5.5;
  static const double poolKeepOut = 9;

  static final List<CircleObstacle> obstacles = [];
  static final List<vm.Vector3> coinSpots = [];

  static int get hillCount => kIsWeb ? 18 : 28;
  static int get mesaCount => kIsWeb ? 5 : 8;
  static int get rockCount => kIsWeb ? 16 : 28;
  static int get treeCount => kIsWeb ? 12 : 22;
  static int get patchCount => kIsWeb ? 20 : 34;
  static int get sporeCount => kIsWeb ? 14 : 28;
  static int get coinRings => kIsWeb ? 2 : 3;

  // Main road centre line.
  static double trailX(double z) => 6.0 * math.sin((z - startZ) * 0.09);

  static double _trailSlope(double z) =>
      6.0 * 0.09 * math.cos((z - startZ) * 0.09);

  // ---------------------------------------------------------------------
  // Materials / node helpers
  // ---------------------------------------------------------------------

  static PhysicallyBasedMaterial _mat(
    double r,
    double g,
    double b, {
    double roughness = 0.92,
  }) {
    final material = PhysicallyBasedMaterial();
    material.baseColorFactor = vm.Vector4(r, g, b, 1);
    material.roughnessFactor = roughness;
    material.metallicFactor = 0;
    return material;
  }

  static UnlitMaterial _glow(double r, double g, double b) {
    return UnlitMaterial()..baseColorFactor = vm.Vector4(r, g, b, 1);
  }

  static Node _n(
    MeshGeometry g,
    Material m,
    double x,
    double y,
    double z,
    double sx,
    double sy,
    double sz, {
    double yaw = 0,
    double tilt = 0,
    double roll = 0,
  }) {
    final node = Node(mesh: Mesh(g, m));
    node.position = vm.Vector3(x, y, z);
    node.scale = vm.Vector3(sx, sy, sz);
    if (yaw != 0 || tilt != 0 || roll != 0) {
      node.rotation = vm.Quaternion.axisAngle(vm.Vector3(0, 1, 0), yaw) *
          vm.Quaternion.axisAngle(vm.Vector3(1, 0, 0), tilt) *
          vm.Quaternion.axisAngle(vm.Vector3(0, 0, 1), roll);
    }
    return node;
  }

  /// Box sitting on [y] (base), sizes w x h x d.
  static void _box(
    Node p,
    _Kit k,
    Material m,
    double x,
    double y,
    double z,
    double w,
    double h,
    double d, {
    double yaw = 0,
  }) {
    p.add(_n(k.box, m, x, y + h / 2, z, w, h, d, yaw: yaw));
  }

  /// Upright cylinder standing on [y], diameter x height.
  static void _cyl(
    Node p,
    _Kit k,
    Material m,
    double x,
    double y,
    double z,
    double diameter,
    double h,
  ) {
    p.add(_n(k.cyl, m, x, y + h / 2, z, diameter, h, diameter));
  }

  /// Flat disc lying on the ground.
  static void _flat(
    Node p,
    _Kit k,
    Material m,
    double x,
    double y,
    double z,
    double rx,
    double rz, {
    double thickness = 0.02,
  }) {
    p.add(_n(k.disc, m, x, y, z, rx, thickness, rz));
  }

  static void _circle(double x, double z, double r) {
    obstacles.add(CircleObstacle(x, z, r));
  }

  /// Covers an axis-aligned rectangle with overlapping circles.
  static void _rectObstacle(double x, double z, double w, double d) {
    final r = math.min(w, d) / 2;
    final long = math.max(w, d);
    if (long <= r * 2.2) {
      _circle(x, z, math.max(r, long / 2));
      return;
    }
    final alongX = w >= d;
    final span = long / 2 - r;
    final n = ((span * 2) / (r * 1.1)).ceil().clamp(1, 40);
    for (var i = 0; i <= n; i++) {
      final t = -span + (2 * span) * i / n;
      _circle(alongX ? x + t : x, alongX ? z : z + t, r);
    }
  }

  static void _reserve(
    List<vm.Vector2> placed,
    double x,
    double z,
    double radius,
  ) {
    for (var dx = -radius; dx <= radius; dx += 3) {
      for (var dz = -radius; dz <= radius; dz += 3) {
        if (dx * dx + dz * dz <= radius * radius) {
          placed.add(vm.Vector2(x + dx, z + dz));
        }
      }
    }
  }

  static void _reserveLine(
    List<vm.Vector2> placed,
    double x1,
    double z1,
    double x2,
    double z2,
  ) {
    final len = math.sqrt((x2 - x1) * (x2 - x1) + (z2 - z1) * (z2 - z1));
    final n = (len / 3).ceil();
    for (var i = 0; i <= n; i++) {
      final t = i / n;
      placed.add(vm.Vector2(x1 + (x2 - x1) * t, z1 + (z2 - z1) * t));
    }
  }

  // ---------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------

  static Future<void> loadInto(Scene scene) async {
    obstacles.clear();
    coinSpots.clear();

    final k = _Kit();
    final random = math.Random(47);
    final placed = <vm.Vector2>[];
    final root = Node();
    scene.add(root);

    _applyLighting(scene);

    // Planet surface.
    root.add(_n(k.ground, k.groundMat, 0, -0.1, 0, 1, 1, 1));

    _addHorizon(root, k, random);
    _addGroundPatches(root, k, random);
    _addBoundaryMarkers(root, k);

    // Roads first, so props can avoid them.
    _addMainRoad(root, k);
    _branchRoad(root, k, placed, -12, 20, -12);
    _branchRoad(root, k, placed, 20, -22, 20);
    _branchRoad(root, k, placed, 26, 19, 26);
    _branchRoad(root, k, placed, -32, 8, -32);

    _addLake(root, k, random);

    // Points of interest.
    _addOutpost(root, k, placed);
    _addColony(root, k, placed);
    _addCargoYard(root, k, placed);
    _addRadarStation(root, k, placed);
    _addLandingPad(root, k, placed);

    await Future<void>.delayed(Duration.zero);

    _addCoverClusters(root, k, placed);
    _addBoulders(root, k, random, placed);

    await Future<void>.delayed(Duration.zero);

    _addAlienTrees(root, k, random, placed);
    _addSpores(root, k, random);

    _planCoins(random, placed);

    debugPrint(
      'Alien battleground created. '
      'Obstacles: ${obstacles.length}, coins: ${coinSpots.length}',
    );
  }

  static void _applyLighting(Scene scene) {
    // Soft warm-neutral ambient. Raise/lower to brighten or darken the world.
    scene.environment =
        EnvironmentMap.constantDiffuse(vm.Vector3(0.95, 0.88, 0.95));
  }

  // ---------------------------------------------------------------------
  // Terrain & backdrop
  // ---------------------------------------------------------------------

  /// Smooth rolling hills, layered mesas and glowing landmark pylons ringing
  /// the playable area.
  static void _addHorizon(Node root, _Kit k, math.Random random) {
    // Rolling hills: big buried ellipsoids, only the smooth cap shows.
    for (var i = 0; i < hillCount; i++) {
      final angle = math.pi * 2 * i / hillCount + random.nextDouble() * 0.2;
      final dist = 56 + random.nextDouble() * 55;
      final w = 32 + random.nextDouble() * 42;
      final d = 26 + random.nextDouble() * 30;
      final h = 4 + random.nextDouble() * 11;

      final hill = _n(
        k.hill,
        i.isEven ? k.hillA : k.hillB,
        math.sin(angle) * dist,
        -h * 0.12,
        math.cos(angle) * dist,
        w,
        h * 2,
        d,
        yaw: random.nextDouble() * math.pi,
      );
      root.add(hill);
    }

    // Layered mesas on the far horizon.
    for (var i = 0; i < mesaCount; i++) {
      final angle = math.pi * 2 * i / mesaCount + random.nextDouble() * 0.4;
      final dist = 95 + random.nextDouble() * 35;
      final r = 11 + random.nextDouble() * 9;
      final h = 16 + random.nextDouble() * 16;
      final x = math.sin(angle) * dist;
      final z = math.cos(angle) * dist;

      final h1 = h * 0.45;
      final h2 = h * 0.30;
      final h3 = h * 0.25;
      root.add(_n(k.disc, k.strata1, x, h1 / 2, z, r * 1.05, h1, r * 0.85));
      root.add(_n(k.disc, k.strata2, x, h1 + h2 / 2, z, r * 0.92, h2, r * 0.75));
      root.add(_n(k.disc, k.strata3, x, h1 + h2 + h3 / 2, z, r * 0.84, h3, r * 0.68));
    }

    // Glowing landmark pylons: give each direction an identity.
    for (var i = 0; i < 8; i++) {
      final angle = math.pi * 2 * i / 8 + 0.2;
      final x = math.sin(angle) * 72;
      final z = math.cos(angle) * 72;
      final glow = i.isEven ? k.glowCyan : k.glowMagenta;
      root.add(_n(k.cone, k.metalDark, x, 14, z, 2.6, 28, 2.6));
      root.add(_n(k.sphere, glow, x, 28.6, z, 2.4, 2.4, 2.4));
    }
  }

  /// Large soft colour variation so the ground never looks flat.
  static void _addGroundPatches(Node root, _Kit k, math.Random random) {
    for (var i = 0; i < patchCount; i++) {
      final x = (random.nextDouble() * 2 - 1) * 62;
      final z = (random.nextDouble() * 2 - 1) * 62;
      final radius = 4 + random.nextDouble() * 8;

      final mat = switch (i % 3) {
        0 => k.dust,
        1 => k.rust,
        _ => k.sand,
      };

      root.add(_n(
        k.disc,
        mat,
        x,
        0.006 + i * 0.0003,
        z,
        radius,
        0.008,
        radius * (0.6 + random.nextDouble() * 0.6),
        yaw: random.nextDouble() * math.pi,
      ));
    }
  }

  /// Glowing pylons marking the edge of the play zone.
  static void _addBoundaryMarkers(Node root, _Kit k) {
    const e = 42.0;
    for (var t = -40.0; t <= 40.0; t += 10) {
      for (final p in [
        [t, e],
        [t, -e],
        [e, t],
        [-e, t],
      ]) {
        root.add(_n(k.cone, k.metalDark, p[0], 1.6, p[1], 0.7, 3.2, 0.7));
        root.add(_n(k.sphere, k.glowCyan, p[0], 3.3, p[1], 0.5, 0.5, 0.5));
        _flat(root, k, k.padCyan, p[0], 0.02, p[1], 1.6, 1.6);
      }
    }
  }

  // ---------------------------------------------------------------------
  // Roads
  // ---------------------------------------------------------------------

  static void _addMainRoad(Node root, _Kit k) {
    const width = 6.4;
    var n = 0;
    for (var z = -46.0; z <= 46.0; z += 2.4) {
      final cx = trailX(z);
      final yaw = math.atan2(_trailSlope(z), 1);
      final nx = math.cos(yaw);
      final nz = -math.sin(yaw);

      root.add(_n(k.box, k.road, cx, 0.03, z, width, 0.05, 3.2, yaw: yaw));

      // glowing edge lines
      for (final side in const [-1.0, 1.0]) {
        root.add(_n(
          k.box,
          k.glowCyanDim,
          cx + nx * side * (width / 2 - 0.2),
          0.062,
          z + nz * side * (width / 2 - 0.2),
          0.1,
          0.02,
          1.6,
          yaw: yaw,
        ));
      }

      // dashed centre line
      if (n.isEven) {
        root.add(_n(k.box, k.concrete, cx, 0.062, z, 0.18, 0.02, 1.1, yaw: yaw));
      }

      // street lamps
      if (n % 6 == 0) {
        final side = (n ~/ 6).isEven ? 1.0 : -1.0;
        _lamp(root, k, cx + nx * side * (width / 2 + 1.2),
            z + nz * side * (width / 2 + 1.2));
      }
      n++;
    }
  }

  /// A straight side road from the main road at [zStart] to ([toX], [toZ]).
  static void _branchRoad(
    Node root,
    _Kit k,
    List<vm.Vector2> placed,
    double zStart,
    double toX,
    double toZ,
  ) {
    final fromX = trailX(zStart);
    final dx = toX - fromX;
    final dz = toZ - zStart;
    final len = math.sqrt(dx * dx + dz * dz);
    final yaw = math.atan2(dx, dz);
    const width = 4.2;

    final count = (len / 2.4).ceil();
    for (var i = 0; i <= count; i++) {
      final t = i / count;
      final x = fromX + dx * t;
      final z = zStart + dz * t;
      root.add(_n(k.box, k.road, x, 0.026, z, width, 0.05, 3.0, yaw: yaw));
      if (i.isEven) {
        root.add(_n(k.box, k.glowCyanDim, x, 0.056, z, 0.12, 0.02, 1.0, yaw: yaw));
      }
    }
    _reserveLine(placed, fromX, zStart, toX, toZ);
  }

  static void _lamp(Node root, _Kit k, double x, double z) {
    _cyl(root, k, k.metalDark, x, 0, z, 0.16, 4.2);
    root.add(_n(k.sphere, k.glowWarm, x, 4.35, z, 0.45, 0.35, 0.45));
    _flat(root, k, k.padWarm, x, 0.02, z, 2.4, 2.4);
  }

  // ---------------------------------------------------------------------
  // Lake
  // ---------------------------------------------------------------------

  static void _addLake(Node root, _Kit k, math.Random random) {
    _flat(root, k, k.sand, poolX, 0.02, poolZ, poolRadius + 2.6, poolRadius + 2.2);
    _flat(root, k, k.rust, poolX, 0.03, poolZ, poolRadius + 0.9, poolRadius + 0.7,
        thickness: 0.04);
    _flat(root, k, k.glowWater, poolX, 0.05, poolZ, poolRadius, poolRadius * 0.92,
        thickness: 0.04);
    _flat(root, k, k.glowWaterLight, poolX, 0.07, poolZ, poolRadius * 0.62,
        poolRadius * 0.55,
        thickness: 0.04);
    _flat(root, k, k.glowCyan, poolX, 0.09, poolZ, poolRadius * 0.2,
        poolRadius * 0.18,
        thickness: 0.04);

    // Shore rocks
    for (var i = 0; i < 7; i++) {
      final a = math.pi * 2 * i / 7 + random.nextDouble() * 0.3;
      final rr = poolRadius + 1.6 + random.nextDouble() * 0.8;
      final s = 0.8 + random.nextDouble() * 0.8;
      root.add(_n(
        k.sphere,
        i.isEven ? k.rockMat : k.rockDark,
        poolX + math.cos(a) * rr,
        0.28 * s,
        poolZ + math.sin(a) * rr,
        1.8 * s,
        1.0 * s,
        1.5 * s,
        yaw: random.nextDouble() * math.pi,
      ));
    }

    obstacles.add(const CircleObstacle(poolX, poolZ, poolRadius));
  }

  // ---------------------------------------------------------------------
  // Structure builders
  // ---------------------------------------------------------------------

  /// Sci-fi building: body, plinth, roof slab, glowing windows and roof gear.
  static void _building(
    Node root,
    _Kit k,
    double x,
    double z,
    double w,
    double d,
    double h, {
    Material? body,
  }) {
    final wall = body ?? k.concrete;

    _box(root, k, k.concreteDark, x, 0, z, w + 0.3, 0.35, d + 0.3);
    _box(root, k, wall, x, 0.35, z, w, h - 0.35, d);
    _box(root, k, k.metalDark, x, h, z, w + 0.5, 0.28, d + 0.5);

    // glowing windows on all four faces
    final wy = h * 0.55;
    root.add(_n(k.box, k.glowWindow, x, wy, z + d / 2 + 0.02, w * 0.65, 0.45, 0.05));
    root.add(_n(k.box, k.glowWindow, x, wy, z - d / 2 - 0.02, w * 0.65, 0.45, 0.05));
    root.add(_n(k.box, k.glowCyanDim, x + w / 2 + 0.02, wy, z, 0.05, 0.45, d * 0.65));
    root.add(_n(k.box, k.glowCyanDim, x - w / 2 - 0.02, wy, z, 0.05, 0.45, d * 0.65));

    // glowing roofline trim and door
    root.add(_n(k.box, k.glowCyan, x, h - 0.12, z + d / 2 + 0.03, w, 0.08, 0.05));
    _box(root, k, k.metalDark, x, 0.35, z + d / 2 + 0.02, 1.3, 2.1, 0.06);

    // roof equipment
    _box(root, k, k.metal, x - w * 0.22, h + 0.28, z - d * 0.15, w * 0.25, 0.7, d * 0.25);
    _cyl(root, k, k.metalDark, x + w * 0.25, h + 0.28, z + d * 0.1, 0.12, 2.2);
    root.add(_n(k.sphere, k.glowMagenta, x + w * 0.25, h + 2.55, z + d * 0.1,
        0.3, 0.3, 0.3));

    _rectObstacle(x, z, w + 0.2, d + 0.2);
  }

  /// Smooth habitat dome.
  static void _dome(Node root, _Kit k, double x, double z, double r) {
    _flat(root, k, k.padCyan, x, 0.02, z, r * 1.45, r * 1.45);
    root.add(_n(k.sphere, k.panel, x, 0, z, r * 2, r * 1.5, r * 2));
    // glowing band
    root.add(_n(k.disc, k.glowWindow, x, r * 0.26, z, r * 0.93, 0.07, r * 0.93));
    // entrance
    _box(root, k, k.metalDark, x, 0, z + r * 0.88, r * 0.55, r * 0.5, r * 0.4);
    root.add(_n(k.box, k.glowCyan, x, r * 0.28, z + r * 1.09, r * 0.35, 0.08, 0.04));
    // roof beacon
    root.add(_n(k.sphere, k.glowMagenta, x, r * 0.78, z, 0.3, 0.3, 0.3));
    _circle(x, z, r * 0.98);
  }

  static void _tower(Node root, _Kit k, double x, double z) {
    for (final sx in const [-1.1, 1.1]) {
      for (final sz in const [-1.1, 1.1]) {
        _box(root, k, k.metal, x + sx, 0, z + sz, 0.22, 5.2, 0.22);
      }
    }
    // cross braces
    _box(root, k, k.metalDark, x, 2.0, z + 1.1, 2.2, 0.14, 0.14);
    _box(root, k, k.metalDark, x, 2.0, z - 1.1, 2.2, 0.14, 0.14);
    _box(root, k, k.metalDark, x + 1.1, 3.4, z, 0.14, 0.14, 2.2);
    _box(root, k, k.metalDark, x - 1.1, 3.4, z, 0.14, 0.14, 2.2);
    // platform, cabin, roof
    _box(root, k, k.concreteDark, x, 5.2, z, 3.2, 0.25, 3.2);
    _box(root, k, k.concrete, x, 5.45, z, 2.4, 1.5, 2.4);
    root.add(_n(k.box, k.glowWindow, x, 6.2, z + 1.22, 2.0, 0.5, 0.05));
    _box(root, k, k.metalDark, x, 6.95, z, 3.0, 0.22, 3.0);
    _cyl(root, k, k.metalDark, x, 7.17, z, 0.1, 1.6);
    root.add(_n(k.sphere, k.glowCyan, x, 8.85, z, 0.35, 0.35, 0.35));
    _circle(x, z, 1.7);
  }

  /// Wall segment between two points with a glowing cap.
  static void _wall(
    Node root,
    _Kit k,
    double x1,
    double z1,
    double x2,
    double z2, {
    double h = 2.4,
    double t = 0.7,
  }) {
    final dx = x2 - x1;
    final dz = z2 - z1;
    final len = math.sqrt(dx * dx + dz * dz);
    final yaw = math.atan2(dx, dz);
    final cx = (x1 + x2) / 2;
    final cz = (z1 + z2) / 2;

    root.add(_n(k.box, k.concrete, cx, h / 2, cz, t, h, len, yaw: yaw));
    root.add(_n(k.box, k.metalDark, cx, h + 0.08, cz, t + 0.2, 0.16, len, yaw: yaw));
    root.add(_n(k.box, k.glowCyanDim, cx, h * 0.62, cz, t + 0.04, 0.1, len * 0.96,
        yaw: yaw));

    final n = (len / 1.1).ceil();
    for (var i = 0; i <= n; i++) {
      final f = i / n;
      _circle(x1 + dx * f, z1 + dz * f, t * 0.9);
    }
  }

  static void _crates(Node root, _Kit k, double x, double z) {
    _box(root, k, k.wood, x, 0, z, 1.5, 1.5, 1.5, yaw: 0.2);
    _box(root, k, k.wood, x + 1.6, 0, z + 0.3, 1.3, 1.3, 1.3, yaw: -0.1);
    _box(root, k, k.contOlive, x + 0.5, 1.5, z + 0.1, 1.2, 1.1, 1.2, yaw: 0.5);
    root.add(_n(k.box, k.glowWarm, x + 0.5, 2.62, z + 0.1, 0.3, 0.04, 0.3));
    _circle(x + 0.7, z + 0.1, 1.5);
  }

  static void _container(
    Node root,
    _Kit k,
    Material m,
    double x,
    double z, {
    bool alongX = true,
    bool stacked = false,
    Material? topMat,
  }) {
    final w = alongX ? 6.0 : 2.4;
    final d = alongX ? 2.4 : 6.0;
    _box(root, k, m, x, 0, z, w, 2.6, d);
    // ribs
    for (var i = -2; i <= 2; i++) {
      if (alongX) {
        _box(root, k, k.metalDark, x + i * 1.1, 0, z + d / 2 + 0.01, 0.12, 2.6, 0.05);
        _box(root, k, k.metalDark, x + i * 1.1, 0, z - d / 2 - 0.01, 0.12, 2.6, 0.05);
      } else {
        _box(root, k, k.metalDark, x + w / 2 + 0.01, 0, z + i * 1.1, 0.05, 2.6, 0.12);
        _box(root, k, k.metalDark, x - w / 2 - 0.01, 0, z + i * 1.1, 0.05, 2.6, 0.12);
      }
    }
    if (stacked) {
      _box(root, k, topMat ?? k.contBlue, x, 2.6, z, w, 2.6, d);
    }
    _rectObstacle(x, z, w, d);
  }

  static void _rover(Node root, _Kit k, double x, double z) {
    _box(root, k, k.metal, x, 0.5, z, 2.2, 0.7, 3.6);
    root.add(_n(k.sphere, k.panel, x, 1.25, z - 0.2, 1.7, 1.1, 1.9));
    root.add(_n(k.box, k.glowWindow, x, 1.35, z + 0.65, 1.1, 0.35, 0.05));
    for (final sx in const [-1.25, 1.25]) {
      for (final sz in const [-1.2, 1.2]) {
        root.add(_n(k.cyl, k.metalDark, x + sx, 0.48, z + sz, 0.95, 0.5, 0.95,
            roll: math.pi / 2));
      }
    }
    root.add(_n(k.sphere, k.glowWarm, x - 0.7, 0.85, z + 1.85, 0.3, 0.2, 0.2));
    root.add(_n(k.sphere, k.glowWarm, x + 0.7, 0.85, z + 1.85, 0.3, 0.2, 0.2));
    _rectObstacle(x, z, 2.5, 3.8);
  }

  static void _sandbags(
    Node root,
    _Kit k,
    double x,
    double z,
    double len, {
    bool alongX = true,
  }) {
    final n = (len / 1.0).floor();
    for (var i = 0; i < n; i++) {
      final off = (i - (n - 1) / 2) * 1.0;
      final bx = alongX ? x + off : x;
      final bz = alongX ? z : z + off;
      root.add(_n(k.sphere, k.sandbag, bx, 0.28, bz, alongX ? 1.15 : 0.8,
          0.6, alongX ? 0.8 : 1.15));
      if (i.isEven) {
        root.add(_n(k.sphere, k.sandbag, bx, 0.78, bz, alongX ? 1.05 : 0.75,
            0.55, alongX ? 0.75 : 1.05));
      }
    }
    _rectObstacle(x, z, alongX ? len : 0.9, alongX ? 0.9 : len);
  }

  static void _jersey(Node root, _Kit k, double x, double z, {bool alongX = true}) {
    final w = alongX ? 3.2 : 0.9;
    final d = alongX ? 0.9 : 3.2;
    _box(root, k, k.concrete, x, 0, z, w, 1.1, d);
    root.add(_n(k.box, k.glowWarm, x, 1.12, z, alongX ? 2.8 : 0.1, 0.04,
        alongX ? 0.1 : 2.8));
    _rectObstacle(x, z, w, d);
  }

  // ---------------------------------------------------------------------
  // Points of interest
  // ---------------------------------------------------------------------

  /// Walled military outpost on the east side.
  static void _addOutpost(Node root, _Kit k, List<vm.Vector2> placed) {
    const x0 = 19.0, x1 = 33.0, z0 = -19.0, z1 = -5.0;

    _flat(root, k, k.concreteDark, 26, 0.02, -12, 7.6, 7.6);

    _wall(root, k, x0, z0, x1, z0); // north
    _wall(root, k, x0, z1, x1, z1); // south
    _wall(root, k, x1, z0, x1, z1); // east
    _wall(root, k, x0, z0, x0, -14.6); // west, gate gap in the middle
    _wall(root, k, x0, -9.4, x0, z1);

    _building(root, k, 24, -15, 6, 4, 3.2);
    _building(root, k, 30, -8.8, 5, 4.6, 3.8, body: k.panel);
    _tower(root, k, 30.6, -16.4);
    _crates(root, k, 21.5, -8.2);
    _rover(root, k, 25.5, -9.5);
    _lamp(root, k, 22, -12);
    _lamp(root, k, 28.5, -12.8);

    _sandbags(root, k, 16.5, -15.5, 4, alongX: false);
    _sandbags(root, k, 16.5, -8.5, 4, alongX: false);

    _reserve(placed, 26, -12, 11);
  }

  /// Habitat-dome colony on the west side.
  static void _addColony(Node root, _Kit k, List<vm.Vector2> placed) {
    _flat(root, k, k.concreteDark, -27, 0.02, 20, 6, 6);

    _dome(root, k, -27, 20, 3.4);
    _dome(root, k, -35, 17, 2.2);
    _dome(root, k, -34, 25, 2.2);
    _dome(root, k, -20, 27, 1.9);
    _dome(root, k, -20, 13, 1.9);
    _dome(root, k, -28, 30, 1.8);

    _lamp(root, k, -24, 16.5);
    _lamp(root, k, -24, 23.5);
    _crates(root, k, -32, 12.5);
    _rover(root, k, -23, 31);
    _sandbags(root, k, -15.5, 20, 3, alongX: false);

    _reserve(placed, -27, 20, 12);
  }

  /// Warehouse + container yard in the south-east.
  static void _addCargoYard(Node root, _Kit k, List<vm.Vector2> placed) {
    _flat(root, k, k.concreteDark, 28, 0.02, 25, 10, 9);

    _building(root, k, 31, 31, 12, 7, 5, body: k.concrete);

    _container(root, k, k.contRed, 22, 20, stacked: true, topMat: k.contBlue);
    _container(root, k, k.contOrange, 22, 24);
    _container(root, k, k.contBlue, 30, 20, alongX: false);
    _container(root, k, k.contOlive, 35, 22, alongX: false, stacked: true,
        topMat: k.contRed);

    _crates(root, k, 21, 28.5);
    _rover(root, k, 27, 25);
    _lamp(root, k, 20, 26);
    _lamp(root, k, 33.5, 27);
    _jersey(root, k, 18, 22);

    _reserve(placed, 28, 25, 12);
  }

  /// Dish + control hut.
  static void _addRadarStation(Node root, _Kit k, List<vm.Vector2> placed) {
    _flat(root, k, k.concreteDark, -30, 0.02, -5, 6, 6);

    _building(root, k, -30, -3, 4.2, 4, 2.6, body: k.panel);

    // dish
    _cyl(root, k, k.metal, -31, 0, -9, 0.7, 3.2);
    root.add(_n(k.sphere, k.panel, -31, 3.8, -9, 3.8, 0.7, 3.8, tilt: -0.75));
    root.add(_n(k.sphere, k.glowCyan, -31, 4.4, -9.9, 0.32, 0.32, 0.32));
    _circle(-31, -9, 0.9);

    _lamp(root, k, -34, -6);
    _lamp(root, k, -26.5, -6.5);

    _reserve(placed, -30, -5, 8);
  }

  /// Glowing helipad with a parked dropship.
  static void _addLandingPad(Node root, _Kit k, List<vm.Vector2> placed) {
    const px = 14.0, pz = -32.0;

    _flat(root, k, k.glowCyan, px, 0.035, pz, 6.5, 6.5);
    _flat(root, k, k.concreteDark, px, 0.045, pz, 6.2, 6.2);
    _flat(root, k, k.glowCyanDim, px, 0.055, pz, 4.2, 4.2);
    _flat(root, k, k.concreteDark, px, 0.065, pz, 4.0, 4.0);

    // "H" marking
    root.add(_n(k.box, k.glowWarm, px - 1, 0.08, pz, 0.35, 0.02, 3.0));
    root.add(_n(k.box, k.glowWarm, px + 1, 0.08, pz, 0.35, 0.02, 3.0));
    root.add(_n(k.box, k.glowWarm, px, 0.08, pz, 2.0, 0.02, 0.35));

    // dropship parked beside the pad
    const sx = 23.0, sz = -33.0;
    root.add(_n(k.sphere, k.panel, sx, 1.5, sz, 3.6, 2.0, 7.4));
    root.add(_n(k.sphere, k.glowWindow, sx, 1.9, sz + 2.5, 1.5, 0.8, 1.9));
    for (final side in const [-1.0, 1.0]) {
      _box(root, k, k.metal, sx + side * 2.9, 1.1, sz - 0.4, 4.0, 0.2, 2.4);
      root.add(_n(k.sphere, k.glowCyan, sx + side * 4.2, 1.2, sz - 1.0, 0.8, 0.8, 0.8));
      _box(root, k, k.metalDark, sx + side * 1.2, 0, sz + 0.5, 0.3, 0.9, 0.3);
      _box(root, k, k.metalDark, sx + side * 1.2, 0, sz - 1.8, 0.3, 0.9, 0.3);
    }
    _flat(root, k, k.padCyan, sx, 0.02, sz, 5, 6.5);
    _circle(sx, sz + 1.9, 2.0);
    _circle(sx, sz - 1.9, 2.0);

    _lamp(root, k, 8.5, -37);
    _lamp(root, k, 19.5, -28);

    _reserve(placed, px, pz, 8);
    _reserve(placed, sx, sz, 6);
  }

  /// Mid-field firefight cover: barriers, sandbags and crates.
  static void _addCoverClusters(Node root, _Kit k, List<vm.Vector2> placed) {
    const spots = [
      [12.0, 9.0],
      [-13.0, 3.0],
      [15.0, -1.5],
      [-14.0, -12.0],
      [-12.0, 10.0],
      [13.0, 16.0],
      [-12.0, -3.0],
      [12.0, -22.0],
    ];

    for (var i = 0; i < spots.length; i++) {
      final x = spots[i][0];
      final z = spots[i][1];

      switch (i % 3) {
        case 0:
          _jersey(root, k, x - 1.8, z);
          _jersey(root, k, x + 1.8, z + 1.6, alongX: false);
          _crates(root, k, x - 0.5, z - 2.4);
        case 1:
          _sandbags(root, k, x, z, 4);
          _sandbags(root, k, x + 2.4, z + 1.8, 3, alongX: false);
        default:
          _jersey(root, k, x, z);
          _sandbags(root, k, x, z + 2.2, 3);
          _lamp(root, k, x + 2.6, z - 1.5);
      }
      _reserve(placed, x, z, 4);
    }
  }

  // ---------------------------------------------------------------------
  // Natural props
  // ---------------------------------------------------------------------

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

    final px = x - poolX;
    final pz = z - poolZ;
    if (px * px + pz * pz < poolKeepOut * poolKeepOut) return false;

    if ((x - trailX(z)).abs() < trailClear) return false;

    for (final point in placed) {
      final dx = x - point.x;
      final dz = z - point.y;
      if (dx * dx + dz * dz < gap * gap) return false;
    }
    return true;
  }

  static vm.Vector2? _spot(
    math.Random random,
    List<vm.Vector2> placed, {
    required double gap,
    required double trailClear,
    double limit = 38,
  }) {
    for (var i = 0; i < 120; i++) {
      final x = (random.nextDouble() * 2 - 1) * limit;
      final z = (random.nextDouble() * 2 - 1) * limit;
      if (_valid(placed, x, z,
          gap: gap, trailClear: trailClear, limit: limit)) {
        return vm.Vector2(x, z);
      }
    }
    return null;
  }

  /// Smooth boulders, often in small groups.
  static void _addBoulders(
    Node root,
    _Kit k,
    math.Random random,
    List<vm.Vector2> placed,
  ) {
    for (var i = 0; i < rockCount; i++) {
      final spot = _spot(random, placed, gap: 4.5, trailClear: 4.5);
      if (spot == null) continue;

      final size = 0.9 + random.nextDouble() * 1.6;

      root.add(_n(
        k.sphere,
        i.isEven ? k.rockMat : k.rockDark,
        spot.x,
        0.3 * size,
        spot.y,
        3.0 * size,
        1.6 * size,
        2.4 * size,
        yaw: random.nextDouble() * math.pi,
      ));
      root.add(_n(
        k.sphere,
        k.rockDark,
        spot.x + 1.5 * size,
        0.17 * size,
        spot.y + 0.7 * size,
        1.1 * size,
        0.7 * size,
        1.0 * size,
        yaw: random.nextDouble() * math.pi,
      ));

      placed.add(spot);
      _circle(spot.x, spot.y, 1.15 * size);
    }
  }

  /// Alien canopy trees: smooth layered canopies with a glowing underside.
  static void _addAlienTrees(
    Node root,
    _Kit k,
    math.Random random,
    List<vm.Vector2> placed,
  ) {
    for (var i = 0; i < treeCount; i++) {
      final spot = _spot(random, placed, gap: 4, trailClear: 4);
      if (spot == null) continue;

      final s = 0.8 + random.nextDouble() * 0.7;
      final canopy = switch (i % 3) {
        0 => k.canopyTeal,
        1 => k.canopyMagenta,
        _ => k.canopyViolet,
      };
      final glow = i % 3 == 1 ? k.glowMagenta : k.glowCyan;

      _cyl(root, k, k.trunk, spot.x, 0, spot.y, 0.55 * s, 3.5 * s);
      root.add(_n(k.sphere, canopy, spot.x, 3.7 * s, spot.y, 4.4 * s, 1.2 * s, 4.4 * s));
      root.add(_n(k.sphere, canopy, spot.x + 0.4 * s, 4.4 * s, spot.y - 0.3 * s,
          2.9 * s, 0.95 * s, 2.9 * s));

      // glowing fruit under the canopy
      for (var f = 0; f < 3; f++) {
        final a = f * math.pi * 2 / 3 + i;
        root.add(_n(
          k.sphere,
          glow,
          spot.x + math.cos(a) * 1.0 * s,
          3.15 * s,
          spot.y + math.sin(a) * 1.0 * s,
          0.3 * s,
          0.3 * s,
          0.3 * s,
        ));
      }
      _flat(root, k, i % 3 == 1 ? k.padWarm : k.padCyan, spot.x, 0.02, spot.y,
          2.6 * s, 2.6 * s);

      placed.add(spot);
      _circle(spot.x, spot.y, 0.6 * s);
    }
  }

  /// Floating glowing dust for atmosphere.
  static void _addSpores(Node root, _Kit k, math.Random random) {
    for (var i = 0; i < sporeCount; i++) {
      final x = (random.nextDouble() * 2 - 1) * 45;
      final z = (random.nextDouble() * 2 - 1) * 45;
      final y = 1.5 + random.nextDouble() * 6;
      final s = 0.08 + random.nextDouble() * 0.12;

      final mat = switch (i % 3) {
        0 => k.glowCyan,
        1 => k.glowViolet,
        _ => k.glowWarm,
      };

      root.add(_n(k.sphere, mat, x, y, z, s, s, s));
    }
  }

  // ---------------------------------------------------------------------
  // Coins (route unchanged: follows the main road)
  // ---------------------------------------------------------------------

  static void _planCoins(
    math.Random random,
    List<vm.Vector2> placed,
  ) {
    const arcStarts = [-32.0, -12.0, 12.0, 30.0];

    for (final start in arcStarts) {
      for (var i = 0; i < 7; i++) {
        final t = i / 6;
        final z = start + i * 1.1;

        coinSpots.add(vm.Vector3(
          trailX(z),
          1.0 + 2.0 * math.sin(math.pi * t),
          z,
        ));
      }
    }

    for (var z = -38.0; z <= 38.0; z += 2.5) {
      var insideArc = false;
      for (final start in arcStarts) {
        if (z >= start - 0.5 && z <= start + 7.1) insideArc = true;
      }
      if (insideArc) continue;

      coinSpots.add(vm.Vector3(trailX(z), 1.0, z));
    }

    for (var ring = 0; ring < coinRings; ring++) {
      final spot = _spot(
        random,
        placed,
        gap: 5,
        trailClear: 8,
        limit: 36,
      );
      if (spot == null) continue;

      for (var i = 0; i < 8; i++) {
        final angle = math.pi * 2 * i / 8;
        coinSpots.add(vm.Vector3(
          spot.x + math.cos(angle) * 2.4,
          1.3,
          spot.y + math.sin(angle) * 2.4,
        ));
      }
      placed.add(spot);
    }
  }
}