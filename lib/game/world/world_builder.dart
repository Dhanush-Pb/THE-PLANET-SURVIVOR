import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter_scene/scene.dart';
import 'package:vector_math/vector_math.dart' as vm;

import '../physics/collision.dart';

class _Lake {
  const _Lake(this.x, this.z, this.r);

  final double x;
  final double z;
  final double r;
}

/// Spatial grid so "is this spot free?" stays fast in a big world.
class _Grid {
  static const double _cell = 12;
  final Map<int, List<vm.Vector2>> _cells = {};

  int _key(int ix, int iz) => (ix + 500) * 1024 + (iz + 500);

  void add(double x, double z) {
    final key = _key((x / _cell).floor(), (z / _cell).floor());
    (_cells[key] ??= []).add(vm.Vector2(x, z));
  }

  /// [gap] must be 12 or less.
  bool free(double x, double z, double gap) {
    final cx = (x / _cell).floor();
    final cz = (z / _cell).floor();
    final g2 = gap * gap;

    for (var ix = cx - 1; ix <= cx + 1; ix++) {
      for (var iz = cz - 1; iz <= cz + 1; iz++) {
        final list = _cells[_key(ix, iz)];
        if (list == null) continue;
        for (final p in list) {
          final dx = x - p.x;
          final dz = z - p.y;
          if (dx * dx + dz * dz < g2) return false;
        }
      }
    }
    return true;
  }
}

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
    radialSegments: 48,
  );
  final blob = CylinderGeometry(
    bottomRadius: 1,
    topRadius: 1,
    height: 1,
    radialSegments: 20,
  );
  final cone = CylinderGeometry(
    bottomRadius: 1,
    topRadius: 0.05,
    height: 1,
    radialSegments: 14,
  );
  final crystal = CylinderGeometry(
    bottomRadius: 1,
    topRadius: 0.04,
    height: 1,
    radialSegments: 6,
  );
  final ground = CuboidGeometry(vm.Vector3(800, 0.2, 800));

  // ---- terrain (Aurora Twilight palette)
  final groundMat = WorldBuilder._mat(0.14, 0.33, 0.37);
  final mossTeal = WorldBuilder._mat(0.21, 0.50, 0.48);
  final soilViolet = WorldBuilder._mat(0.30, 0.23, 0.47);
  final mossLime = WorldBuilder._mat(0.38, 0.60, 0.28);
  final sandLilac = WorldBuilder._mat(0.60, 0.54, 0.70);
  final rock = WorldBuilder._mat(0.31, 0.28, 0.48, roughness: 0.85);
  final rockDark = WorldBuilder._mat(0.19, 0.17, 0.33, roughness: 0.85);
  final strata1 = WorldBuilder._mat(0.36, 0.24, 0.52);
  final strata2 = WorldBuilder._mat(0.22, 0.30, 0.50);
  final strata3 = WorldBuilder._mat(0.50, 0.34, 0.58);

  // Far hills and mesas: each tier fades more into the horizon haze.
  final hillTiers = [
    WorldBuilder._hazed(0.20, 0.32, 0.46, 0.0),
    WorldBuilder._hazed(0.20, 0.32, 0.46, 0.3),
    WorldBuilder._hazed(0.20, 0.32, 0.46, 0.6),
    WorldBuilder._hazed(0.20, 0.32, 0.46, 0.85),
  ];
  final mesaLayers = [
    WorldBuilder._hazed(0.36, 0.24, 0.52, 0.5),
    WorldBuilder._hazed(0.22, 0.30, 0.50, 0.5),
    WorldBuilder._hazed(0.50, 0.34, 0.58, 0.5),
  ];

  // ---- road / structures
  final road = WorldBuilder._mat(0.11, 0.12, 0.19, roughness: 0.6);
  final concrete = WorldBuilder._mat(0.56, 0.58, 0.66, roughness: 0.7);
  final concreteDark = WorldBuilder._mat(0.26, 0.28, 0.36, roughness: 0.7);
  final panel = WorldBuilder._mat(0.80, 0.84, 0.92, roughness: 0.45);
  final metal = WorldBuilder._mat(0.36, 0.40, 0.48, roughness: 0.4);
  final metalDark = WorldBuilder._mat(0.12, 0.13, 0.19, roughness: 0.5);
  final contRed = WorldBuilder._mat(0.62, 0.16, 0.22, roughness: 0.6);
  final contBlue = WorldBuilder._mat(0.12, 0.30, 0.60, roughness: 0.6);
  final contOrange = WorldBuilder._mat(0.80, 0.42, 0.14, roughness: 0.6);
  final contOlive = WorldBuilder._mat(0.30, 0.40, 0.26, roughness: 0.6);
  final wood = WorldBuilder._mat(0.42, 0.28, 0.20);
  final sandbag = WorldBuilder._mat(0.60, 0.52, 0.42);

  // ---- shadows, crater, crash site, bones
  // Shadow is now a soft, light tone close to the ground colour.
  final shadow = WorldBuilder._mat(0.09, 0.22, 0.28);
  final scorch = WorldBuilder._mat(0.06, 0.05, 0.10);
  final scorchDark = WorldBuilder._mat(0.03, 0.03, 0.06);
  final rim = WorldBuilder._mat(0.46, 0.38, 0.60);
  final hullDark = WorldBuilder._mat(0.26, 0.28, 0.34, roughness: 0.5);
  final hullLight = WorldBuilder._mat(0.64, 0.66, 0.74, roughness: 0.5);
  final smoke = WorldBuilder._mat(0.20, 0.19, 0.27);
  final bone = WorldBuilder._mat(0.86, 0.82, 0.78, roughness: 0.7);

  // ---- alien flora
  final trunk = WorldBuilder._mat(0.20, 0.14, 0.30);
  final limb = WorldBuilder._mat(0.26, 0.19, 0.40, roughness: 0.6);
  final canopies = [
    WorldBuilder._mat(0.06, 0.45, 0.48, roughness: 0.6), // teal
    WorldBuilder._mat(0.55, 0.14, 0.50, roughness: 0.6), // magenta
    WorldBuilder._mat(0.30, 0.20, 0.65, roughness: 0.6), // violet
    WorldBuilder._mat(0.36, 0.62, 0.30, roughness: 0.6), // lime
  ];
  final shroomCapA = WorldBuilder._mat(0.62, 0.18, 0.52, roughness: 0.6);
  final shroomCapB = WorldBuilder._mat(0.18, 0.40, 0.66, roughness: 0.6);
  final shroomStem = WorldBuilder._mat(0.86, 0.80, 0.92, roughness: 0.6);
  final tuftA = WorldBuilder._mat(0.10, 0.55, 0.50, roughness: 0.6);
  final tuftB = WorldBuilder._mat(0.42, 0.66, 0.26, roughness: 0.6);
  final tuftC = WorldBuilder._mat(0.50, 0.28, 0.70, roughness: 0.6);

  // ---- glowing (unlit)
  final glowCyan = WorldBuilder._glow(0.12, 0.88, 0.98);
  final glowCyanDeep = WorldBuilder._glow(0.05, 0.55, 0.75);
  final glowCyanDim = WorldBuilder._glow(0.05, 0.40, 0.50);
  final glowMagenta = WorldBuilder._glow(0.95, 0.22, 0.75);
  final glowMagentaDeep = WorldBuilder._glow(0.65, 0.12, 0.50);
  final glowViolet = WorldBuilder._glow(0.52, 0.32, 1.0);
  final glowVioletDeep = WorldBuilder._glow(0.32, 0.20, 0.75);
  final glowLime = WorldBuilder._glow(0.62, 1.0, 0.36);
  final glowLimeDeep = WorldBuilder._glow(0.34, 0.70, 0.22);
  final glowWarm = WorldBuilder._glow(1.0, 0.78, 0.38);
  final glowWindow = WorldBuilder._glow(0.55, 0.90, 1.0);
  final glowWater = WorldBuilder._glow(0.05, 0.62, 0.80);
  final glowWaterLight = WorldBuilder._glow(0.12, 0.82, 0.92);
  final glowFire = WorldBuilder._glow(1.0, 0.42, 0.08);
  final glowFireCore = WorldBuilder._glow(1.0, 0.86, 0.38);
  final padCyan = WorldBuilder._glow(0.05, 0.17, 0.24);
  final padWarm = WorldBuilder._glow(0.26, 0.18, 0.14);
}

class WorldBuilder {
  WorldBuilder._();

  /// Walkable half-size: the world is 180 x 180.
  static const double halfExtent = 90;

  static const double startX = 0;
  static const double startZ = 5;

  static const List<_Lake> _lakes = [
    _Lake(-22, -20, 5.5),
    _Lake(-66, -4, 11),
    _Lake(58, 54, 9),
  ];

  static const double _padY = 0.045;

  // Horizon haze colour: far hills fade toward this.
  static const double _hazeR = 0.60;
  static const double _hazeG = 0.30;
  static const double _hazeB = 0.46;

  // Shadows fall away from the sun in the sky.
  static const double _shadowDx = -0.675;
  static const double _shadowDz = 0.737;
  static final double _shadowYaw = math.atan2(_shadowDx, _shadowDz);

  static final List<CircleObstacle> obstacles = [];
  static final List<vm.Vector3> coinSpots = [];

  // ---------------------------------------------------------------------
  // Quality knobs. Lower density / viewRadius if the game lags.
  // ---------------------------------------------------------------------
  static double get density => kIsWeb ? 0.7 : 0.9;
  static double get viewRadius => kIsWeb ? 58 : 70;

  static int _cnt(int base) => math.max(1, (base * density).round());

  /// Total coins placed in the world.
  static const int totalCoins = 110;

  static int get hillCount => _cnt(22);
  static int get footHillCount => _cnt(16);
  static int get mesaCount => _cnt(9);
  static int get patchCount => _cnt(110);
  static int get rockCount => _cnt(80);
  static int get spireCount => _cnt(16);
  static int get craterCount => _cnt(6);
  // Fewer trees than before: the new neuron trees have more parts each.
  static int get treeCount => _cnt(18);
  static int get giantShroomCount => _cnt(22);
  static int get shroomCount => _cnt(60);
  static int get crystalCount => _cnt(80);
  static int get tuftCount => _cnt(120);
  static int get shardCount => _cnt(14);
  static int get sporeCount => _cnt(60);
  static int get coverCount => _cnt(20);
  static int get coinRings => kIsWeb ? 3 : 5;

  // ---------------------------------------------------------------------
  // Road centre line (winding)
  // ---------------------------------------------------------------------
  static double trailX(double z) =>
      8.0 * math.sin((z - startZ) * 0.055) +
      3.0 * math.sin((z - startZ) * 0.17);

  static double _trailSlope(double z) =>
      8.0 * 0.055 * math.cos((z - startZ) * 0.055) +
      3.0 * 0.17 * math.cos((z - startZ) * 0.17);

  // ---------------------------------------------------------------------
  // Chunks: the world is split in squares that show / hide with distance.
  // ---------------------------------------------------------------------
  static const double _chunkSize = 32;
  static Node _root = Node();
  static final Map<int, Node> _chunks = {};
  static final Map<int, vm.Vector2> _chunkCenters = {};

  static Node _c(double x, double z) {
    final ix = (x / _chunkSize).floor();
    final iz = (z / _chunkSize).floor();
    final key = (ix + 100) * 1000 + (iz + 100);

    var node = _chunks[key];
    if (node == null) {
      node = Node();
      _root.add(node);
      _chunks[key] = node;
      _chunkCenters[key] = vm.Vector2(
        (ix + 0.5) * _chunkSize,
        (iz + 0.5) * _chunkSize,
      );
    }
    return node;
  }

  /// Call every frame with the player position. Far chunks are hidden.
  static void updateVisibility(double px, double pz) {
    final r = viewRadius + _chunkSize * 0.75;
    final r2 = r * r;

    _chunks.forEach((key, node) {
      final c = _chunkCenters[key]!;
      final dx = c.x - px;
      final dz = c.y - pz;
      final show = dx * dx + dz * dz < r2;
      if (node.visible != show) node.visible = show;
    });
  }

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

  static PhysicallyBasedMaterial _hazed(
    double r,
    double g,
    double b,
    double t,
  ) {
    return _mat(
      r + (_hazeR - r) * t,
      g + (_hazeG - g) * t,
      b + (_hazeB - b) * t,
    );
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

  /// A thin cylinder between two points (tree branches / dendrites).
  static void _limb(
    Node p,
    _Kit k,
    Material m,
    vm.Vector3 a,
    vm.Vector3 b,
    double thick,
  ) {
    final dx = b.x - a.x;
    final dy = b.y - a.y;
    final dz = b.z - a.z;
    final len = math.sqrt(dx * dx + dy * dy + dz * dz);
    if (len < 1e-5) return;

    final node = Node(mesh: Mesh(k.cyl, m));
    node.position =
        vm.Vector3((a.x + b.x) / 2, (a.y + b.y) / 2, (a.z + b.z) / 2);
    node.scale = vm.Vector3(thick, len, thick);

    // Rotate the cylinder's Y axis onto the direction vector.
    final ax = dz;
    final az = -dx;
    final axLen = math.sqrt(ax * ax + az * az);
    if (axLen > 1e-6) {
      final angle = math.acos((dy / len).clamp(-1.0, 1.0));
      node.rotation = vm.Quaternion.axisAngle(
        vm.Vector3(ax / axLen, 0, az / axLen),
        angle,
      );
    } else if (dy < 0) {
      node.rotation = vm.Quaternion.axisAngle(vm.Vector3(1, 0, 0), math.pi);
    }
    p.add(node);
  }

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

  /// Soft, light fake shadow. Smaller and shorter than before.
  static void _shadow(
    Node root,
    _Kit k,
    double x,
    double z,
    double rx,
    double rz,
    double height,
  ) {
    final sRx = rx * 0.7;
    final sRz = rz * 0.7;
    final len = sRz + height * 0.5;
    final shift = len - sRz;
    root.add(_n(
      k.blob,
      k.shadow,
      x + _shadowDx * shift,
      0.11,
      z + _shadowDz * shift,
      sRx,
      0.01,
      len,
      yaw: _shadowYaw,
    ));
  }

  static void _circle(double x, double z, double r) {
    obstacles.add(CircleObstacle(x, z, r));
  }

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

  static void _reserve(_Grid placed, double x, double z, double radius) {
    for (var dx = -radius; dx <= radius; dx += 3) {
      for (var dz = -radius; dz <= radius; dz += 3) {
        if (dx * dx + dz * dz <= radius * radius) {
          placed.add(x + dx, z + dz);
        }
      }
    }
  }

  static void _reserveLine(
    _Grid placed,
    double x1,
    double z1,
    double x2,
    double z2,
  ) {
    final len = math.sqrt((x2 - x1) * (x2 - x1) + (z2 - z1) * (z2 - z1));
    final n = (len / 3).ceil();
    for (var i = 0; i <= n; i++) {
      final t = i / n;
      placed.add(x1 + (x2 - x1) * t, z1 + (z2 - z1) * t);
    }
  }

  /// A random point outside the play square, between [minOut] and [maxOut].
  static vm.Vector2 _outside(math.Random random, double minOut, double maxOut) {
    final out = minOut + random.nextDouble() * (maxOut - minOut);
    final along = (random.nextDouble() * 2 - 1) * (maxOut + 10);
    switch (random.nextInt(4)) {
      case 0:
        return vm.Vector2(along, out);
      case 1:
        return vm.Vector2(along, -out);
      case 2:
        return vm.Vector2(out, along);
      default:
        return vm.Vector2(-out, along);
    }
  }

  // ---------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------
  static Future<void> loadInto(Scene scene) async {
    obstacles.clear();
    coinSpots.clear();
    _chunks.clear();
    _chunkCenters.clear();

    final k = _Kit();
    final random = math.Random(73);
    final placed = _Grid();

    _root = Node();
    scene.add(_root);

    _applyLighting(scene);

    // Planet surface (always visible).
    _root.add(_n(k.ground, k.groundMat, 0, -0.1, 0, 1, 1, 1));

    _addBackdrop(k, random);
    _addBoundary(k);
    _addGroundPatches(k, random);

    // Roads first, so props avoid them.
    _addMainRoad(k);
    _branchRoad(k, placed, -12, 20, -12); // outpost
    _branchRoad(k, placed, 20, -22, 20); // colony
    _branchRoad(k, placed, 26, 19, 26); // cargo yard
    _branchRoad(k, placed, -32, 8, -32); // landing pad
    _branchRoad(k, placed, -4, -26, -4); // radar
    _branchRoad(k, placed, -48, 56, -52); // portal ring
    _branchRoad(k, placed, 10, 66, 10); // mining camp
    _branchRoad(k, placed, 40, -50, 42); // crystal garden
    _branchRoad(k, placed, -70, -10, -72); // observatory

    _addLakes(k, random);

    // Points of interest.
    _addOutpost(k, placed);
    _addColony(k, placed);
    _addCargoYard(k, placed);
    _addRadarStation(k, placed);
    _addLandingPad(k, placed);
    _addCrashSite(k, placed);
    _addPortal(k, placed);
    _addMine(k, placed);
    _addObservatory(k, placed);
    _addBones(k, placed);

    await Future<void>.delayed(Duration.zero);

    _addCrystalGarden(k, random, placed);
    _addCover(k, random, placed);
    _addBoulders(k, random, placed);
    _addSpires(k, random, placed);
    _addCraters(k, random, placed);

    await Future<void>.delayed(Duration.zero);

    _addTrees(k, random, placed);
    _addGiantShrooms(k, random, placed);
    _addShrooms(k, random, placed);
    _addCrystals(k, random, placed);
    _addTufts(k, random, placed);
    _addShards(k, random);
    _addSpores(k, random);

    _planCoins(random, placed);

    updateVisibility(startX, startZ);

    debugPrint(
      'Alien world built. Chunks: ${_chunks.length}, '
      'obstacles: ${obstacles.length}, coins: ${coinSpots.length}',
    );
  }

  /// Cool twilight ambient. Raise the numbers to brighten the world.
  static void _applyLighting(Scene scene) {
    scene.environment =
        EnvironmentMap.constantDiffuse(vm.Vector3(0.85, 0.85, 1.0));
  }

  // ---------------------------------------------------------------------
  // Backdrop (always visible): hills, mesas, landmark pylons
  // ---------------------------------------------------------------------
  static void _addBackdrop(_Kit k, math.Random random) {
    // Far hills. The further away, the hazier.
    for (var i = 0; i < hillCount; i++) {
      final p = _outside(random, 110, 210);
      final t = ((math.max(p.x.abs(), p.y.abs()) - 110) / 100).clamp(0.0, 1.0);
      final tier = math.min(3, (t * 3.4).floor());

      final w = 40 + random.nextDouble() * 40;
      final d = 30 + random.nextDouble() * 30;
      final h = 8 + random.nextDouble() * 18;

      _root.add(_n(
        k.hill,
        k.hillTiers[tier],
        p.x,
        -h * 0.12,
        p.y,
        w,
        h * 2,
        d,
        yaw: random.nextDouble() * math.pi,
      ));
    }

    // Low foothills just outside the play area.
    for (var i = 0; i < footHillCount; i++) {
      final p = _outside(random, 100, 125);
      final w = 20 + random.nextDouble() * 16;
      final d = 14 + random.nextDouble() * 10;
      final h = 2.5 + random.nextDouble() * 3.5;

      _root.add(_n(
        k.hill,
        i.isEven ? k.mossTeal : k.soilViolet,
        p.x,
        -h * 0.15,
        p.y,
        w,
        h * 2,
        d,
        yaw: random.nextDouble() * math.pi,
      ));
    }

    // Layered mesas.
    for (var i = 0; i < mesaCount; i++) {
      final p = _outside(random, 190, 260);
      final r = 18 + random.nextDouble() * 14;
      final h = 26 + random.nextDouble() * 26;

      final h1 = h * 0.45;
      final h2 = h * 0.30;
      final h3 = h * 0.25;
      _root.add(_n(k.disc, k.mesaLayers[0], p.x, h1 / 2, p.y, r * 1.05, h1, r * 0.85));
      _root.add(_n(k.disc, k.mesaLayers[1], p.x, h1 + h2 / 2, p.y, r * 0.92, h2, r * 0.75));
      _root.add(_n(k.disc, k.mesaLayers[2], p.x, h1 + h2 + h3 / 2, p.y, r * 0.84, h3, r * 0.68));
    }

    // Glowing landmark pylons on the horizon.
    for (var i = 0; i < 8; i++) {
      final angle = math.pi * 2 * i / 8 + 0.2;
      final x = math.sin(angle) * 150;
      final z = math.cos(angle) * 150;
      final glow = i.isEven ? k.glowCyan : k.glowMagenta;
      _root.add(_n(k.cone, k.metalDark, x, 26, z, 4.0, 52, 4.0));
      _root.add(_n(k.sphere, glow, x, 53.5, z, 4.2, 4.2, 4.2));
    }
  }

  /// Glowing pylons marking the edge of the play area.
  static void _addBoundary(_Kit k) {
    const e = 94.0;
    for (var t = -90.0; t <= 90.0; t += 18) {
      for (final p in [
        [t, e],
        [t, -e],
        [e, t],
        [-e, t],
      ]) {
        final root = _c(p[0], p[1]);
        root.add(_n(k.cone, k.metalDark, p[0], 2.2, p[1], 0.9, 4.4, 0.9));
        root.add(_n(k.sphere, k.glowCyan, p[0], 4.6, p[1], 0.7, 0.7, 0.7));
      }
    }
  }

  /// Soft colour patches so the ground never looks flat.
  static void _addGroundPatches(_Kit k, math.Random random) {
    for (var i = 0; i < patchCount; i++) {
      final x = (random.nextDouble() * 2 - 1) * 130;
      final z = (random.nextDouble() * 2 - 1) * 130;
      final radius = 4 + random.nextDouble() * 9;

      final mat = switch (i % 4) {
        0 => k.mossTeal,
        1 => k.soilViolet,
        2 => k.mossLime,
        _ => k.sandLilac,
      };

      _c(x, z).add(_n(
        k.blob,
        mat,
        x,
        0.005 + (i % 16) * 0.0016,
        z,
        radius,
        0.008,
        radius * (0.6 + random.nextDouble() * 0.6),
        yaw: random.nextDouble() * math.pi,
      ));
    }
  }

  // ---------------------------------------------------------------------
  // Roads
  // ---------------------------------------------------------------------
  static void _addMainRoad(_Kit k) {
    const width = 4.4;
    var n = 0;

    for (var z = -100.0; z <= 100.0; z += 3.2) {
      final cx = trailX(z);
      final yaw = math.atan2(_trailSlope(z), 1);
      final nx = math.cos(yaw);
      final nz = -math.sin(yaw);
      final root = _c(cx, z);

      root.add(_n(k.box, k.road, cx, 0.033, z, width, 0.05, 3.9, yaw: yaw));

      // Glowing edge dashes.
      for (final side in const [-1.0, 1.0]) {
        root.add(_n(
          k.box,
          k.glowCyanDim,
          cx + nx * side * (width / 2 - 0.15),
          0.062,
          z + nz * side * (width / 2 - 0.15),
          0.1,
          0.02,
          2.9,
          yaw: yaw,
        ));
      }

      if (n % 7 == 0) {
        final side = (n ~/ 7).isEven ? 1.0 : -1.0;
        _lamp(root, k, cx + nx * side * (width / 2 + 1.1),
            z + nz * side * (width / 2 + 1.1));
      }
      n++;
    }
  }

  static void _branchRoad(
    _Kit k,
    _Grid placed,
    double zStart,
    double toX,
    double toZ,
  ) {
    final fromX = trailX(zStart);
    final dx = toX - fromX;
    final dz = toZ - zStart;
    final len = math.sqrt(dx * dx + dz * dz);
    final yaw = math.atan2(dx, dz);
    const width = 3.0;

    final count = (len / 3.2).ceil();
    for (var i = 0; i <= count; i++) {
      final t = i / count;
      final x = fromX + dx * t;
      final z = zStart + dz * t;
      final root = _c(x, z);

      root.add(_n(k.box, k.road, x, 0.029, z, width, 0.05, 3.7, yaw: yaw));
      if (i.isEven) {
        root.add(_n(k.box, k.glowCyanDim, x, 0.058, z, 0.1, 0.02, 1.4, yaw: yaw));
      }
    }
    _reserveLine(placed, fromX, zStart, toX, toZ);
  }

  static void _lamp(Node root, _Kit k, double x, double z) {
    _cyl(root, k, k.metalDark, x, 0, z, 0.16, 4.2);
    root.add(_n(k.sphere, k.glowWarm, x, 4.35, z, 0.45, 0.35, 0.45));
    _flat(root, k, k.padWarm, x, _padY, z, 2.4, 2.4);
    _shadow(root, k, x, z, 0.3, 0.3, 4.2);
  }

  // ---------------------------------------------------------------------
  // Lakes
  // ---------------------------------------------------------------------
  static void _addLakes(_Kit k, math.Random random) {
    for (final l in _lakes) {
      // Water layers are always visible (cheap), shore rocks are chunked.
      _flat(_root, k, k.sandLilac, l.x, 0.034, l.z, l.r + 2.6, l.r + 2.2);
      _flat(_root, k, k.soilViolet, l.x, 0.046, l.z, l.r + 0.9, l.r + 0.7,
          thickness: 0.04);
      _flat(_root, k, k.glowWater, l.x, 0.06, l.z, l.r, l.r * 0.92,
          thickness: 0.04);
      _flat(_root, k, k.glowWaterLight, l.x, 0.074, l.z, l.r * 0.62,
          l.r * 0.55,
          thickness: 0.04);
      _flat(_root, k, k.glowCyan, l.x, 0.088, l.z, l.r * 0.2, l.r * 0.18,
          thickness: 0.04);

      final n = (5 + l.r * 0.7).round();
      for (var i = 0; i < n; i++) {
        final a = math.pi * 2 * i / n + random.nextDouble() * 0.3;
        final rr = l.r + 1.6 + random.nextDouble() * 0.9;
        final s = 0.8 + random.nextDouble() * 0.9;
        final rx = l.x + math.cos(a) * rr;
        final rz = l.z + math.sin(a) * rr;
        final root = _c(rx, rz);

        root.add(_n(
          k.sphere,
          i.isEven ? k.rock : k.rockDark,
          rx,
          0.28 * s,
          rz,
          1.8 * s,
          1.0 * s,
          1.5 * s,
          yaw: random.nextDouble() * math.pi,
        ));
        _shadow(root, k, rx, rz, 0.9 * s, 0.8 * s, 1.0 * s);
      }

      obstacles.add(CircleObstacle(l.x, l.z, l.r));
    }
  }

  // ---------------------------------------------------------------------
  // Structure builders
  // ---------------------------------------------------------------------
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

    _shadow(root, k, x, z, w * 0.55, d * 0.5, h);

    _box(root, k, k.concreteDark, x, 0, z, w + 0.3, 0.35, d + 0.3);
    _box(root, k, wall, x, 0.35, z, w, h - 0.35, d);
    _box(root, k, k.metalDark, x, h, z, w + 0.5, 0.28, d + 0.5);

    final wy = h * 0.55;
    root.add(_n(k.box, k.glowWindow, x, wy, z + d / 2 + 0.02, w * 0.65, 0.45, 0.05));
    root.add(_n(k.box, k.glowWindow, x, wy, z - d / 2 - 0.02, w * 0.65, 0.45, 0.05));
    root.add(_n(k.box, k.glowCyanDim, x + w / 2 + 0.02, wy, z, 0.05, 0.45, d * 0.65));
    root.add(_n(k.box, k.glowCyanDim, x - w / 2 - 0.02, wy, z, 0.05, 0.45, d * 0.65));

    root.add(_n(k.box, k.glowCyan, x, h - 0.12, z + d / 2 + 0.03, w, 0.08, 0.05));
    _box(root, k, k.metalDark, x, 0.35, z + d / 2 + 0.02, 1.3, 2.1, 0.06);

    _box(root, k, k.metal, x - w * 0.22, h + 0.28, z - d * 0.15, w * 0.25, 0.7, d * 0.25);
    _cyl(root, k, k.metalDark, x + w * 0.25, h + 0.28, z + d * 0.1, 0.12, 2.2);
    root.add(_n(k.sphere, k.glowMagenta, x + w * 0.25, h + 2.55, z + d * 0.1,
        0.3, 0.3, 0.3));

    _rectObstacle(x, z, w + 0.2, d + 0.2);
  }

  static void _dome(Node root, _Kit k, double x, double z, double r) {
    _shadow(root, k, x, z, r * 0.95, r * 0.9, r * 1.5);
    _flat(root, k, k.padCyan, x, _padY, z, r * 1.45, r * 1.45);
    root.add(_n(k.sphere, k.panel, x, 0, z, r * 2, r * 1.5, r * 2));
    root.add(_n(k.disc, k.glowWindow, x, r * 0.26, z, r * 0.93, 0.07, r * 0.93));
    _box(root, k, k.metalDark, x, 0, z + r * 0.88, r * 0.55, r * 0.5, r * 0.4);
    root.add(_n(k.box, k.glowCyan, x, r * 0.28, z + r * 1.09, r * 0.35, 0.08, 0.04));
    root.add(_n(k.sphere, k.glowMagenta, x, r * 0.78, z, 0.3, 0.3, 0.3));
    _circle(x, z, r * 0.98);
  }

  static void _tower(Node root, _Kit k, double x, double z) {
    _shadow(root, k, x, z, 1.3, 1.3, 8);
    for (final sx in const [-1.1, 1.1]) {
      for (final sz in const [-1.1, 1.1]) {
        _box(root, k, k.metal, x + sx, 0, z + sz, 0.22, 5.2, 0.22);
      }
    }
    _box(root, k, k.metalDark, x, 2.0, z + 1.1, 2.2, 0.14, 0.14);
    _box(root, k, k.metalDark, x, 2.0, z - 1.1, 2.2, 0.14, 0.14);
    _box(root, k, k.metalDark, x + 1.1, 3.4, z, 0.14, 0.14, 2.2);
    _box(root, k, k.metalDark, x - 1.1, 3.4, z, 0.14, 0.14, 2.2);
    _box(root, k, k.concreteDark, x, 5.2, z, 3.2, 0.25, 3.2);
    _box(root, k, k.concrete, x, 5.45, z, 2.4, 1.5, 2.4);
    root.add(_n(k.box, k.glowWindow, x, 6.2, z + 1.22, 2.0, 0.5, 0.05));
    _box(root, k, k.metalDark, x, 6.95, z, 3.0, 0.22, 3.0);
    _cyl(root, k, k.metalDark, x, 7.17, z, 0.1, 1.6);
    root.add(_n(k.sphere, k.glowCyan, x, 8.85, z, 0.35, 0.35, 0.35));
    _circle(x, z, 1.7);
  }

  static void _dish(Node root, _Kit k, double x, double z, {double s = 1}) {
    _shadow(root, k, x, z, 1.9 * s, 1.9 * s, 4.5 * s);
    _cyl(root, k, k.metal, x, 0, z, 0.7 * s, 3.2 * s);
    root.add(_n(k.sphere, k.panel, x, 3.8 * s, z, 3.8 * s, 0.7 * s, 3.8 * s,
        tilt: -0.75));
    root.add(_n(k.sphere, k.glowCyan, x, 4.4 * s, z - 0.9 * s, 0.32 * s,
        0.32 * s, 0.32 * s));
    _circle(x, z, 0.9 * s);
  }

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
    _shadow(root, k, x + 0.8, z + 0.2, 1.4, 1.0, 2.6);
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

    _shadow(root, k, x, z, math.max(w, d) * 0.35, math.min(w, d) * 0.45,
        stacked ? 5.2 : 2.6);

    _box(root, k, m, x, 0, z, w, 2.6, d);
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
    _shadow(root, k, x, z, 1.3, 1.8, 2.0);
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
    _shadow(root, k, x, z, 1.1, 0.7, 1.1);
    _box(root, k, k.concrete, x, 0, z, w, 1.1, d);
    root.add(_n(k.box, k.glowWarm, x, 1.12, z, alongX ? 2.8 : 0.1, 0.04,
        alongX ? 0.1 : 2.8));
    _rectObstacle(x, z, w, d);
  }

  // ---------------------------------------------------------------------
  // Bases (each one lives in its own chunk)
  // ---------------------------------------------------------------------
  static void _addOutpost(_Kit k, _Grid placed) {
    final root = _c(26, -12);
    const x0 = 19.0, x1 = 33.0, z0 = -19.0, z1 = -5.0;

    _flat(root, k, k.concreteDark, 26, _padY, -12, 7.6, 7.6);

    _wall(root, k, x0, z0, x1, z0);
    _wall(root, k, x0, z1, x1, z1);
    _wall(root, k, x1, z0, x1, z1);
    _wall(root, k, x0, z0, x0, -14.6);
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

  static void _addColony(_Kit k, _Grid placed) {
    final root = _c(-27, 20);

    _flat(root, k, k.concreteDark, -27, _padY, 20, 6, 6);

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

  static void _addCargoYard(_Kit k, _Grid placed) {
    final root = _c(28, 25);

    _flat(root, k, k.concreteDark, 28, _padY, 25, 10, 9);

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

  static void _addRadarStation(_Kit k, _Grid placed) {
    final root = _c(-30, -5);

    _flat(root, k, k.concreteDark, -30, _padY, -5, 6, 6);
    _building(root, k, -30, -3, 4.2, 4, 2.6, body: k.panel);
    _dish(root, k, -31, -9);

    _lamp(root, k, -34, -6);
    _lamp(root, k, -26.5, -6.5);

    _reserve(placed, -30, -5, 8);
  }

  static void _addLandingPad(_Kit k, _Grid placed) {
    const px = 14.0, pz = -32.0;
    final root = _c(px, pz);

    _flat(root, k, k.glowCyan, px, 0.05, pz, 6.5, 6.5);
    _flat(root, k, k.concreteDark, px, 0.06, pz, 6.2, 6.2);
    _flat(root, k, k.glowCyanDim, px, 0.07, pz, 4.2, 4.2);
    _flat(root, k, k.concreteDark, px, 0.08, pz, 4.0, 4.0);

    root.add(_n(k.box, k.glowWarm, px - 1, 0.095, pz, 0.35, 0.02, 3.0));
    root.add(_n(k.box, k.glowWarm, px + 1, 0.095, pz, 0.35, 0.02, 3.0));
    root.add(_n(k.box, k.glowWarm, px, 0.095, pz, 2.0, 0.02, 0.35));

    const sx = 23.0, sz = -33.0;
    _shadow(root, k, sx, sz, 3.2, 3.6, 3.4);
    root.add(_n(k.sphere, k.panel, sx, 1.5, sz, 3.6, 2.0, 7.4));
    root.add(_n(k.sphere, k.glowWindow, sx, 1.9, sz + 2.5, 1.5, 0.8, 1.9));
    for (final side in const [-1.0, 1.0]) {
      _box(root, k, k.metal, sx + side * 2.9, 1.1, sz - 0.4, 4.0, 0.2, 2.4);
      root.add(_n(k.sphere, k.glowCyan, sx + side * 4.2, 1.2, sz - 1.0, 0.8, 0.8, 0.8));
      _box(root, k, k.metalDark, sx + side * 1.2, 0, sz + 0.5, 0.3, 0.9, 0.3);
      _box(root, k, k.metalDark, sx + side * 1.2, 0, sz - 1.8, 0.3, 0.9, 0.3);
    }
    _flat(root, k, k.padCyan, sx, _padY, sz, 5, 6.5);
    _circle(sx, sz + 1.9, 2.0);
    _circle(sx, sz - 1.9, 2.0);

    _lamp(root, k, 8.5, -37);
    _lamp(root, k, 19.5, -28);

    _reserve(placed, px, pz, 8);
    _reserve(placed, sx, sz, 6);
  }

  static void _addCrashSite(_Kit k, _Grid placed) {
    const cx = -11.0;
    const cz = -31.0;
    const yaw = -0.6;
    final cs = math.cos(yaw);
    final sn = math.sin(yaw);
    final random = math.Random(9);
    final root = _c(cx, cz);

    vm.Vector2 world(double lx, double lz) =>
        vm.Vector2(cx + lx * cs + lz * sn, cz - lx * sn + lz * cs);

    root.add(_n(k.blob, k.scorch, cx, 0.04, cz, 9, 0.01, 7.5, yaw: 0.4));
    root.add(_n(k.blob, k.scorchDark, cx + 1, 0.052, cz + 0.5, 5.5, 0.01, 4.5, yaw: 0.4));
    root.add(_n(k.blob, k.scorch, -6.5, 0.043, -36.5, 1.7, 0.01, 7.5,
        yaw: math.atan2(9, -11)));

    _shadow(root, k, cx, cz, 3.4, 3.6, 3.2);

    final hull = Node();
    hull.position = vm.Vector3(cx, 0, cz);
    hull.rotation = vm.Quaternion.axisAngle(vm.Vector3(0, 1, 0), yaw);
    root.add(hull);

    hull.add(_n(k.sphere, k.hullDark, 0, 1.5, 0, 5.2, 3.0, 9.0, tilt: 0.16, roll: 0.1));
    hull.add(_n(k.sphere, k.glowWindow, 0, 2.5, 3.5, 2.0, 1.0, 2.6));
    hull.add(_n(k.box, k.glowFireCore, 2.5, 1.7, -0.6, 0.1, 1.1, 2.2));
    hull.add(_n(k.box, k.hullLight, -5.2, 0.95, -1.0, 6.5, 0.35, 2.8,
        yaw: 0.3, roll: 0.25));
    hull.add(_n(k.cyl, k.metalDark, -3.5, 0.9, -4.5, 1.8, 4.0, 1.8, roll: math.pi / 2));
    hull.add(_n(k.disc, k.glowFire, -5.6, 0.9, -4.5, 0.8, 0.05, 0.8, roll: math.pi / 2));

    for (var i = 0; i < 8; i++) {
      final a = random.nextDouble() * math.pi * 2;
      final r = 6 + random.nextDouble() * 5;
      final px = cx + math.cos(a) * r;
      final pz = cz + math.sin(a) * r;

      root.add(_n(
        k.box,
        i.isEven ? k.hullLight : k.hullDark,
        px,
        0.15,
        pz,
        0.8 + random.nextDouble() * 1.4,
        0.14,
        0.6 + random.nextDouble() * 1.0,
        yaw: random.nextDouble() * math.pi,
        tilt: (random.nextDouble() - 0.5) * 0.4,
        roll: (random.nextDouble() - 0.5) * 0.4,
      ));
    }

    for (final lp in const [
      [1.8, -1.2],
      [-1.0, 2.2],
      [-3.8, -4.0],
    ]) {
      final p = world(lp[0], lp[1]);
      root.add(_n(k.cone, k.glowFire, p.x, 0.9, p.y, 0.8, 1.8, 0.8));
      root.add(_n(k.cone, k.glowFireCore, p.x, 0.65, p.y, 0.4, 1.2, 0.4));
    }

    for (var i = 0; i < 5; i++) {
      final s = 1.2 + i * 0.7;
      root.add(_n(
        k.sphere,
        k.smoke,
        cx + 0.4 + i * 0.5,
        4.0 + i * 1.7,
        cz + 0.3 + i * 0.2,
        s,
        s * 0.9,
        s,
      ));
    }

    for (final lz in const [-3.0, 0.0, 3.0]) {
      final p = world(0, lz);
      _circle(p.x, p.y, 2.4);
    }
    final engine = world(-3.5, -4.5);
    _circle(engine.x, engine.y, 1.3);
    final wing = world(-5.2, -1.0);
    _circle(wing.x, wing.y, 1.6);

    _reserve(placed, cx, cz, 9);
  }

  // ---------------------------------------------------------------------
  // New landmarks
  // ---------------------------------------------------------------------

  /// Ring of glowing pillars with an energy core and a beam to the sky.
  static void _addPortal(_Kit k, _Grid placed) {
    const cx = 62.0, cz = -55.0;
    final root = _c(cx, cz);

    _flat(root, k, k.concreteDark, cx, _padY, cz, 11, 11);
    _flat(root, k, k.glowCyanDim, cx, _padY + 0.012, cz, 9.6, 9.6);
    _flat(root, k, k.concreteDark, cx, _padY + 0.024, cz, 9.2, 9.2);

    const n = 14;
    for (var i = 0; i < n; i++) {
      final a = math.pi * 2 * i / n;
      final px = cx + math.cos(a) * 7;
      final pz = cz + math.sin(a) * 7;
      final h = 5.5 + (i.isEven ? 1.4 : 0.0);

      root.add(_n(k.box, k.metalDark, px, h / 2, pz, 1.1, h, 1.1, yaw: -a));
      root.add(_n(k.box, k.glowCyanDim, cx + math.cos(a) * 6.42, h * 0.5,
          cz + math.sin(a) * 6.42, 0.08, h * 0.8, 0.45, yaw: -a));
      root.add(_n(
        k.sphere,
        i.isEven ? k.glowMagenta : k.glowCyan,
        px,
        h + 0.5,
        pz,
        0.75,
        0.75,
        0.75,
      ));
      _circle(px, pz, 0.8);
    }

    _flat(root, k, k.glowViolet, cx, _padY + 0.04, cz, 5.8, 5.8);
    _flat(root, k, k.glowCyan, cx, _padY + 0.055, cz, 4.0, 4.0);
    _flat(root, k, k.glowMagenta, cx, _padY + 0.07, cz, 2.4, 2.4);
    _flat(root, k, k.glowWarm, cx, _padY + 0.085, cz, 1.0, 1.0);

    // Beam: a landmark you can see from far away.
    root.add(_n(k.cone, k.glowViolet, cx, 24, cz, 1.1, 48, 1.1));

    _reserve(placed, cx, cz, 13);
  }

  /// Drill rig, ore crystals and containers.
  static void _addMine(_Kit k, _Grid placed) {
    const cx = 72.0, cz = 10.0;
    final root = _c(cx, cz);
    final random = math.Random(31);

    _flat(root, k, k.concreteDark, cx, _padY, cz, 10, 9);

    _shadow(root, k, cx, cz, 2.2, 2.2, 11);
    for (final sx in const [-1.5, 1.5]) {
      for (final sz in const [-1.5, 1.5]) {
        _box(root, k, k.metal, cx + sx, 0, cz + sz, 0.3, 9, 0.3);
      }
    }
    for (final y in const [2.6, 5.4]) {
      _box(root, k, k.metalDark, cx, y, cz + 1.5, 3.3, 0.18, 0.18);
      _box(root, k, k.metalDark, cx, y, cz - 1.5, 3.3, 0.18, 0.18);
      _box(root, k, k.metalDark, cx + 1.5, y, cz, 0.18, 0.18, 3.3);
      _box(root, k, k.metalDark, cx - 1.5, y, cz, 0.18, 0.18, 3.3);
    }
    _cyl(root, k, k.metalDark, cx, 0, cz, 1.0, 11);
    _box(root, k, k.concreteDark, cx, 9, cz, 3.8, 0.3, 3.8);
    root.add(_n(k.sphere, k.glowFire, cx, 11.6, cz, 0.6, 0.6, 0.6));
    _circle(cx, cz, 2.2);

    _crystalCluster(root, k, random, cx - 5.5, cz + 4.5, 1.1, 1);
    _crystalCluster(root, k, random, cx + 5.5, cz - 5.0, 1.0, 0);
    _container(root, k, k.contOrange, cx - 6, cz - 6);
    _container(root, k, k.contOlive, cx + 7, cz + 6, alongX: false);
    _rover(root, k, cx, cz + 7.5);
    _lamp(root, k, cx - 8, cz + 1);
    _lamp(root, k, cx + 8, cz - 2);

    _reserve(placed, cx, cz, 13);
  }

  /// Big dome with two dishes.
  static void _addObservatory(_Kit k, _Grid placed) {
    const cx = -14.0, cz = -76.0;
    final root = _c(cx, cz);

    _flat(root, k, k.concreteDark, cx, _padY, cz, 12, 12);
    _dome(root, k, cx, cz, 6.0);
    _dish(root, k, cx + 10, cz + 3, s: 1.2);
    _dish(root, k, cx - 10, cz - 2, s: 1.0);

    for (var i = 0; i < 6; i++) {
      final a = math.pi * 2 * i / 6;
      _lamp(root, k, cx + math.cos(a) * 11, cz + math.sin(a) * 11);
    }
    _reserve(placed, cx, cz, 15);
  }

  /// Giant alien skeleton.
  static void _addBones(_Kit k, _Grid placed) {
    const cx = -66.0, cz = -62.0;
    final root = _c(cx, cz);

    _flat(root, k, k.sandLilac, cx, 0.034, cz + 2, 9, 14);
    _shadow(root, k, cx, cz, 4, 10, 6);

    for (var i = 0; i < 7; i++) {
      final z = cz - 8 + i * 2.7;
      final h = 6.4 - (i - 3).abs() * 0.6;

      root.add(_n(k.cone, k.bone, cx - 2.4, h / 2, z, 0.6, h, 0.6, roll: -0.32));
      root.add(_n(k.cone, k.bone, cx + 2.4, h / 2, z, 0.6, h, 0.6, roll: 0.32));
      _circle(cx - 2.4, z, 0.5);
      _circle(cx + 2.4, z, 0.5);
    }

    // Spine.
    root.add(_n(k.cyl, k.bone, cx, 0.8, cz + 0.4, 0.8, 19, 0.8, tilt: math.pi / 2));

    // Skull.
    const sz = cz + 12.0;
    root.add(_n(k.sphere, k.bone, cx, 1.7, sz, 4.2, 3.2, 4.8));
    root.add(_n(k.cone, k.bone, cx - 1.4, 3.6, sz - 0.6, 0.5, 2.2, 0.5, roll: 0.4));
    root.add(_n(k.cone, k.bone, cx + 1.4, 3.6, sz - 0.6, 0.5, 2.2, 0.5, roll: -0.4));
    root.add(_n(k.sphere, k.glowMagenta, cx - 0.9, 2.1, sz + 2.1, 0.55, 0.55, 0.3));
    root.add(_n(k.sphere, k.glowMagenta, cx + 0.9, 2.1, sz + 2.1, 0.55, 0.55, 0.3));
    _circle(cx, sz, 2.2);

    _reserve(placed, cx, cz + 3, 14);
  }

  // ---------------------------------------------------------------------
  // Crystals, shrooms and trees
  // ---------------------------------------------------------------------
  static void _crystalCluster(
    Node root,
    _Kit k,
    math.Random random,
    double x,
    double z,
    double size,
    int kind,
  ) {
    final bright = [k.glowCyan, k.glowMagenta, k.glowViolet, k.glowLime][kind % 4];
    final deep =
        [k.glowCyanDeep, k.glowMagentaDeep, k.glowVioletDeep, k.glowLimeDeep][kind % 4];

    root.add(_n(k.crystal, bright, x, 1.8 * size, z, 0.9 * size, 3.6 * size,
        0.9 * size,
        yaw: random.nextDouble() * math.pi,
        tilt: (random.nextDouble() - 0.5) * 0.3,
        roll: (random.nextDouble() - 0.5) * 0.3));
    root.add(_n(k.crystal, deep, x + 0.9 * size, 1.1 * size, z + 0.3 * size,
        0.65 * size, 2.2 * size, 0.65 * size,
        yaw: random.nextDouble() * math.pi, roll: -0.35));
    root.add(_n(k.crystal, deep, x - 0.7 * size, 0.8 * size, z - 0.5 * size,
        0.5 * size, 1.6 * size, 0.5 * size,
        yaw: random.nextDouble() * math.pi, tilt: 0.4));

    if (size > 1.2) {
      _flat(root, k, k.padCyan, x, _padY, z, 2.0 * size, 2.0 * size);
    }
    _circle(x, z, 0.8 * size);
  }

  static void _giantShroom(
    Node root,
    _Kit k,
    double x,
    double z,
    double s,
    bool blue,
  ) {
    final cap = blue ? k.shroomCapB : k.shroomCapA;
    final glow = blue ? k.glowCyan : k.glowMagenta;

    _shadow(root, k, x, z, 3.4 * s, 3.0 * s, 8 * s);

    _cyl(root, k, k.shroomStem, x, 0, z, 1.1 * s, 5.2 * s);
    root.add(_n(k.sphere, cap, x, 5.6 * s, z, 7 * s, 2.6 * s, 7 * s));
    for (var i = 0; i < 4; i++) {
      final a = math.pi * 2 * i / 4 + 0.4;
      root.add(_n(
        k.sphere,
        glow,
        x + math.cos(a) * 2.2 * s,
        6.2 * s,
        z + math.sin(a) * 2.2 * s,
        0.7 * s,
        0.35 * s,
        0.7 * s,
      ));
    }
    root.add(_n(k.sphere, blue ? k.glowCyan : k.glowWarm, x, 7.0 * s, z,
        0.5 * s, 0.5 * s, 0.5 * s));
    _circle(x, z, 0.8 * s);
  }

  // ---------------------------------------------------------------------
  // Random placement helpers
  // ---------------------------------------------------------------------
  static bool _valid(
    _Grid placed,
    double x,
    double z, {
    required double gap,
    required double trailClear,
    double limit = 86,
  }) {
    if (x.abs() > limit || z.abs() > limit) return false;

    final sx = x - startX;
    final sz = z - startZ;
    if (sx * sx + sz * sz < 36) return false;

    for (final l in _lakes) {
      final lx = x - l.x;
      final lz = z - l.z;
      final keep = l.r + 4;
      if (lx * lx + lz * lz < keep * keep) return false;
    }

    if ((x - trailX(z)).abs() < trailClear) return false;

    return placed.free(x, z, gap);
  }

  static vm.Vector2? _spot(
    math.Random random,
    _Grid placed, {
    required double gap,
    required double trailClear,
    double limit = 86,
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

  static void _addCover(_Kit k, math.Random random, _Grid placed) {
    for (var i = 0; i < coverCount; i++) {
      final s = _spot(random, placed, gap: 10, trailClear: 7);
      if (s == null) continue;

      final root = _c(s.x, s.y);
      final x = s.x;
      final z = s.y;

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

  static void _addCrystalGarden(_Kit k, math.Random random, _Grid placed) {
    const cx = -60.0, cz = 42.0;

    // Giant centre.
    final centre = _c(cx, cz);
    _flat(centre, k, k.padCyan, cx, _padY, cz, 16, 16);
    for (var i = 0; i < 5; i++) {
      final a = math.pi * 2 * i / 5;
      final h = 6 + (i % 3) * 1.8;
      final x = cx + math.cos(a) * 1.4;
      final z = cz + math.sin(a) * 1.4;

      _shadow(centre, k, x, z, 1.0, 1.0, h);
      centre.add(_n(
        k.crystal,
        [k.glowCyan, k.glowMagenta, k.glowViolet][i % 3],
        x,
        h / 2,
        z,
        1.5,
        h,
        1.5,
        yaw: a,
        tilt: math.sin(a) * 0.22,
        roll: -math.cos(a) * 0.22,
      ));
    }
    _circle(cx, cz, 2.8);

    // Ring of smaller clusters.
    for (var i = 0; i < 16; i++) {
      final a = math.pi * 2 * i / 16 + random.nextDouble() * 0.25;
      final r = 6 + random.nextDouble() * 9;
      final x = cx + math.cos(a) * r;
      final z = cz + math.sin(a) * r;
      _crystalCluster(_c(x, z), k, random, x, z, 0.9 + random.nextDouble() * 0.8, i);
    }
    _reserve(placed, cx, cz, 18);
  }

  static void _addBoulders(_Kit k, math.Random random, _Grid placed) {
    for (var i = 0; i < rockCount; i++) {
      final spot = _spot(random, placed, gap: 4.5, trailClear: 4);
      if (spot == null) continue;

      final root = _c(spot.x, spot.y);
      final size = 0.9 + random.nextDouble() * 1.6;

      _shadow(root, k, spot.x, spot.y, 1.5 * size, 1.2 * size, 1.6 * size);

      root.add(_n(
        k.sphere,
        i.isEven ? k.rock : k.rockDark,
        spot.x,
        0.3 * size,
        spot.y,
        3.0 * size,
        1.6 * size,
        2.4 * size,
        yaw: random.nextDouble() * math.pi,
      ));
      if (i % 2 == 0) {
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
      }

      placed.add(spot.x, spot.y);
      _circle(spot.x, spot.y, 1.15 * size);
    }
  }

  static void _addSpires(_Kit k, math.Random random, _Grid placed) {
    for (var i = 0; i < spireCount; i++) {
      final spot = _spot(random, placed, gap: 7, trailClear: 5);
      if (spot == null) continue;

      final root = _c(spot.x, spot.y);
      final h = 5 + random.nextDouble() * 6;
      final r = 1.2 + random.nextDouble() * 0.8;
      final mat = switch (i % 3) {
        0 => k.strata1,
        1 => k.strata2,
        _ => k.strata3,
      };

      _shadow(root, k, spot.x, spot.y, r * 0.9, r * 0.9, h * 0.6);

      root.add(_n(k.cone, mat, spot.x, h / 2, spot.y, r, h, r,
          yaw: random.nextDouble() * math.pi,
          tilt: (random.nextDouble() - 0.5) * 0.12));
      root.add(_n(k.cone, k.rock, spot.x + r * 1.1, h * 0.28, spot.y + r * 0.4,
          r * 0.7, h * 0.56, r * 0.7, tilt: 0.1));

      placed.add(spot.x, spot.y);
      _circle(spot.x, spot.y, r * 0.95);
    }
  }

  static void _addCraters(_Kit k, math.Random random, _Grid placed) {
    for (var c = 0; c < craterCount; c++) {
      final spot = _spot(random, placed, gap: 10, trailClear: 8, limit: 80);
      if (spot == null) continue;

      final root = _c(spot.x, spot.y);
      final r = 3.0 + random.nextDouble() * 2.0;
      final yaw = random.nextDouble() * math.pi;

      root.add(_n(k.blob, k.rim, spot.x, 0.04, spot.y, r * 1.45, 0.012, r * 1.3, yaw: yaw));
      root.add(_n(k.blob, k.scorch, spot.x, 0.052, spot.y, r, 0.012, r * 0.9, yaw: yaw));
      root.add(_n(k.blob, k.soilViolet, spot.x, 0.064, spot.y, r * 0.55, 0.012, r * 0.5, yaw: yaw));

      for (var j = 0; j < 6; j++) {
        final a = math.pi * 2 * j / 6 + random.nextDouble() * 0.4;
        final rx = spot.x + math.cos(a) * r * 1.25;
        final rz = spot.y + math.sin(a) * r * 1.25;
        final s = 0.6 + random.nextDouble() * 0.6;

        root.add(_n(
          k.sphere,
          j.isEven ? k.rock : k.rockDark,
          rx,
          0.25 * s,
          rz,
          1.7 * s,
          0.9 * s,
          1.3 * s,
          yaw: random.nextDouble() * math.pi,
        ));
        _circle(rx, rz, 0.7 * s);
      }

      root.add(_n(k.crystal, k.glowViolet, spot.x, 0.9, spot.y, 0.5, 1.8, 0.5,
          tilt: 0.12, roll: -0.08));
      root.add(_n(k.crystal, k.glowCyan, spot.x + 0.6, 0.55, spot.y - 0.3, 0.3,
          1.1, 0.3, roll: 0.15));
      _circle(spot.x, spot.y, 0.6);

      placed.add(spot.x, spot.y);
    }
  }

  /// Neuron-style trees: dark trunk, branching dendrites and glowing tips.
  static void _addTrees(_Kit k, math.Random random, _Grid placed) {
    for (var i = 0; i < treeCount; i++) {
      final spot = _spot(random, placed, gap: 7, trailClear: 5);
      if (spot == null) continue;

      final root = _c(spot.x, spot.y);
      final s = 0.9 + random.nextDouble() * 0.6;
      final h = (3.6 + random.nextDouble() * 1.8) * s;
      final glow = [k.glowCyan, k.glowMagenta, k.glowCyan, k.glowViolet][i % 4];

      _shadow(root, k, spot.x, spot.y, 1.4 * s, 1.2 * s, h);

      // Trunk with a flared base and a soft glow on the ground.
      root.add(_n(k.cyl, k.trunk, spot.x, h / 2, spot.y, 0.5 * s, h, 0.5 * s));
      root.add(_n(k.sphere, k.trunk, spot.x, 0.12 * s, spot.y, 1.5 * s,
          0.7 * s, 1.5 * s));
      _flat(root, k, k.padCyan, spot.x, _padY, spot.y, 2.8 * s, 2.8 * s);

      // Branches spreading out and up, each ending in a glowing tip.
      const limbs = 5;
      for (var l = 0; l < limbs; l++) {
        final a = l * math.pi * 2 / limbs + random.nextDouble() * 0.5;
        final reach = (2.2 + random.nextDouble() * 1.6) * s;
        final up = (0.8 + random.nextDouble() * 1.4) * s;

        final from = vm.Vector3(
          spot.x,
          h * (0.76 + 0.22 * random.nextDouble()),
          spot.y,
        );
        final to = vm.Vector3(
          spot.x + math.cos(a) * reach,
          from.y + up,
          spot.y + math.sin(a) * reach,
        );

        _limb(root, k, k.limb, from, to, 0.2 * s);
        root.add(_n(k.sphere, glow, to.x, to.y, to.z, 0.42 * s, 0.42 * s, 0.42 * s));

        // Two thin sub-branches with smaller glowing tips.
        for (final d in const [-0.55, 0.55]) {
          final to2 = vm.Vector3(
            to.x + math.cos(a + d) * 1.0 * s,
            to.y + (0.5 + random.nextDouble() * 0.8) * s,
            to.z + math.sin(a + d) * 1.0 * s,
          );
          _limb(root, k, k.limb, to, to2, 0.09 * s);
          root.add(_n(k.sphere, glow, to2.x, to2.y, to2.z, 0.22 * s, 0.22 * s,
              0.22 * s));
        }
      }

      placed.add(spot.x, spot.y);
      _circle(spot.x, spot.y, 0.6 * s);
    }
  }

  static void _addGiantShrooms(_Kit k, math.Random random, _Grid placed) {
    for (var i = 0; i < giantShroomCount; i++) {
      final spot = _spot(random, placed, gap: 9, trailClear: 6);
      if (spot == null) continue;

      _giantShroom(_c(spot.x, spot.y), k, spot.x, spot.y,
          0.8 + random.nextDouble() * 0.7, i.isOdd);
      placed.add(spot.x, spot.y);
    }
  }

  static void _addShrooms(_Kit k, math.Random random, _Grid placed) {
    for (var i = 0; i < shroomCount; i++) {
      final spot = _spot(random, placed, gap: 3, trailClear: 3);
      if (spot == null) continue;

      final root = _c(spot.x, spot.y);
      final s = 0.8 + random.nextDouble() * 0.9;
      final blue = i.isOdd;

      _cyl(root, k, k.shroomStem, spot.x, 0, spot.y, 0.3 * s, 1.3 * s);
      root.add(_n(k.sphere, blue ? k.shroomCapB : k.shroomCapA, spot.x,
          1.4 * s, spot.y, 1.8 * s, 0.8 * s, 1.8 * s));
      root.add(_n(k.sphere, blue ? k.glowCyan : k.glowMagenta, spot.x,
          1.82 * s, spot.y, 0.22 * s, 0.22 * s, 0.22 * s));

      placed.add(spot.x, spot.y);
    }
  }

  static void _addCrystals(_Kit k, math.Random random, _Grid placed) {
    for (var i = 0; i < crystalCount; i++) {
      final spot = _spot(random, placed, gap: 4, trailClear: 3.5);
      if (spot == null) continue;

      _crystalCluster(_c(spot.x, spot.y), k, random, spot.x, spot.y,
          0.6 + random.nextDouble() * 0.8, i);
      placed.add(spot.x, spot.y);
    }
  }

  static void _addTufts(_Kit k, math.Random random, _Grid placed) {
    for (var i = 0; i < tuftCount; i++) {
      final spot = _spot(random, placed, gap: 2, trailClear: 2.4);
      if (spot == null) continue;

      final root = _c(spot.x, spot.y);
      final s = 0.8 + random.nextDouble() * 0.8;
      final mat = [k.tuftA, k.tuftB, k.tuftC][i % 3];

      root.add(_n(k.cone, mat, spot.x, 0.55 * s, spot.y, 0.22 * s, 1.1 * s,
          0.22 * s,
          tilt: (random.nextDouble() - 0.5) * 0.5,
          roll: (random.nextDouble() - 0.5) * 0.5));
      root.add(_n(k.cone, mat, spot.x + 0.22, 0.4 * s, spot.y + 0.12,
          0.18 * s, 0.8 * s, 0.18 * s,
          tilt: (random.nextDouble() - 0.5) * 0.6,
          roll: (random.nextDouble() - 0.5) * 0.6));

      placed.add(spot.x, spot.y);
    }
  }

  /// Floating rock islands with a crystal on top.
  static void _addShards(_Kit k, math.Random random) {
    for (var i = 0; i < shardCount; i++) {
      final x = (random.nextDouble() * 2 - 1) * 84;
      final z = (random.nextDouble() * 2 - 1) * 84;
      if (x.abs() < 14 && (z - startZ).abs() < 14) continue;

      final y = 9 + random.nextDouble() * 13;
      final s = 0.8 + random.nextDouble() * 0.9;
      final root = _c(x, z);
      final glow = [k.glowCyan, k.glowMagenta, k.glowViolet][i % 3];

      root.add(_n(k.sphere, k.rock, x, y, z, 7 * s, 2.4 * s, 6 * s,
          yaw: random.nextDouble() * math.pi));
      root.add(_n(k.cone, k.rockDark, x, y - 2.4 * s, z, 4.6 * s, 4.8 * s,
          4.0 * s,
          tilt: math.pi));
      root.add(_n(k.crystal, glow, x, y + 1.8 * s, z, 1.0 * s, 2.8 * s, 1.0 * s));
      root.add(_n(k.sphere, glow, x, y - 5.4 * s, z, 0.5 * s, 0.5 * s, 0.5 * s));

      // Soft, small shadow on the ground below.
      root.add(_n(k.blob, k.shadow, x, 0.1, z, 2.2 * s, 0.01, 1.9 * s));
    }
  }

  static void _addSpores(_Kit k, math.Random random) {
    for (var i = 0; i < sporeCount; i++) {
      final x = (random.nextDouble() * 2 - 1) * 92;
      final z = (random.nextDouble() * 2 - 1) * 92;
      final y = 1.5 + random.nextDouble() * 6;
      final s = 0.08 + random.nextDouble() * 0.12;

      final mat = switch (i % 3) {
        0 => k.glowCyan,
        1 => k.glowViolet,
        _ => k.glowLime,
      };

      _c(x, z).add(_n(k.sphere, mat, x, y, z, s, s, s));
    }
  }

  // ---------------------------------------------------------------------
  // Coins: exactly [totalCoins] (110) in total
  // ---------------------------------------------------------------------
  static void _coinRing(double cx, double cz, double r, int n, double y) {
    for (var i = 0; i < n; i++) {
      final a = math.pi * 2 * i / n;
      coinSpots.add(vm.Vector3(
        cx + math.cos(a) * r,
        y,
        cz + math.sin(a) * r,
      ));
    }
  }

  static void _planCoins(math.Random random, _Grid placed) {
    const arcStarts = [-72.0, -40.0, -12.0, 20.0, 52.0];

    // 5 jump arcs along the road: 35 coins.
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

    // Small rings at the big landmarks: 30 coins.
    _coinRing(62, -55, 4.0, 8, 1.3); // portal
    _coinRing(-60, 42, 5.0, 8, 1.3); // crystal garden
    _coinRing(-66, -50, 4.0, 8, 1.3); // bones
    _coinRing(72, 10, 4.0, 6, 1.3); // mine

    // Hidden rings in the open field.
    for (var ring = 0; ring < coinRings; ring++) {
      final spot = _spot(random, placed, gap: 6, trailClear: 10, limit: 80);
      if (spot == null) continue;

      _coinRing(spot.x, spot.y, 2.4, 6, 1.3);
      placed.add(spot.x, spot.y);
    }

    // Candidate coins along the road (outside the arcs).
    final line = <vm.Vector3>[];
    for (var z = -92.0; z <= 92.0; z += 3.0) {
      var insideArc = false;
      for (final start in arcStarts) {
        if (z >= start - 0.5 && z <= start + 7.1) insideArc = true;
      }
      if (insideArc) continue;

      line.add(vm.Vector3(trailX(z), 1.0, z));
    }

    // Fill up to the total, spread evenly along the road.
    final remaining = totalCoins - coinSpots.length;
    if (remaining > 0 && line.isNotEmpty) {
      if (line.length <= remaining) {
        coinSpots.addAll(line);
      } else {
        for (var i = 0; i < remaining; i++) {
          final idx = remaining == 1
              ? 0
              : (i * (line.length - 1) / (remaining - 1)).round();
          coinSpots.add(line[idx]);
        }
      }
    }
  }
}