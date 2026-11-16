import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter_scene/scene.dart';
import 'package:vector_math/vector_math.dart' as vm;

class _Coin {
  _Coin(this.node, this.spot, this.phase, {required this.isHealth});

  final Node node;
  final vm.Vector3 spot;
  final double phase;
  final bool isHealth;
  bool taken = false;
  bool shown = true;
}

class CoinSystem {
  /// Gold coins collected (score).
  final ValueNotifier<int> collected = ValueNotifier<int>(0);

  /// Total gold coins in the world.
  int total = 0;

  /// Total health coins in the world.
  int healthTotal = 0;

  /// Called every time a health coin is picked up.
  void Function()? onHealthPickup;

  /// Set this to true while health is full: health coins are then left
  /// in place instead of being wasted.
  bool healthFull = false;

  final List<_Coin> _coins = [];

  // Stand the coin up so its face points sideways.
  static final vm.Quaternion _upright =
      vm.Quaternion.axisAngle(vm.Vector3(1, 0, 0), math.pi / 2);

  static PhysicallyBasedMaterial _pbr(
    double r,
    double g,
    double b,
    double roughness,
  ) {
    final material = PhysicallyBasedMaterial();
    material.baseColorFactor = vm.Vector4(r, g, b, 1);
    material.roughnessFactor = roughness;
    material.metallicFactor = 0;
    return material;
  }

  static UnlitMaterial _glow(double r, double g, double b) {
    return UnlitMaterial()..baseColorFactor = vm.Vector4(r, g, b, 1);
  }

  static Node _part(
    MeshGeometry geometry,
    Material material,
    double x,
    double y,
    double z,
    double sx,
    double sy,
    double sz, {
    double yaw = 0,
  }) {
    final node = Node(mesh: Mesh(geometry, material));
    node.position = vm.Vector3(x, y, z);
    node.scale = vm.Vector3(sx, sy, sz);
    if (yaw != 0) {
      node.rotation = vm.Quaternion.axisAngle(vm.Vector3(0, 1, 0), yaw);
    }
    return node;
  }

  void build(
    Scene scene,
    List<vm.Vector3> spots, {
    List<vm.Vector3> healthSpots = const [],
  }) {
    // Unit shapes: the cylinder axis is the coin thickness.
    final disc = CylinderGeometry(
      bottomRadius: 0.5,
      topRadius: 0.5,
      height: 1,
      radialSegments: 24,
    );
    final box = CuboidGeometry(vm.Vector3(1, 1, 1));

    // ---- gold coin: gold disc with a darker rim and a star
    final goldFace = _pbr(1.0, 0.80, 0.10, 0.35);
    final goldRim = _pbr(0.72, 0.48, 0.06, 0.45);

    Node goldCoin() {
      final coin = Node();
      coin.add(_part(disc, goldRim, 0, 0, 0, 1.0, 0.12, 1.0));
      coin.add(_part(disc, goldFace, 0, 0, 0, 0.8, 0.15, 0.8));
      // eight-point star
      coin.add(_part(box, goldRim, 0, 0, 0, 0.46, 0.17, 0.07));
      coin.add(_part(box, goldRim, 0, 0, 0, 0.07, 0.17, 0.46));
      coin.add(_part(box, goldRim, 0, 0, 0, 0.34, 0.17, 0.06,
          yaw: math.pi / 4));
      coin.add(_part(box, goldRim, 0, 0, 0, 0.34, 0.17, 0.06,
          yaw: -math.pi / 4));
      return coin;
    }

    // ---- health coin: red coin with a white heart and a pink glow edge
    final healthGlow = _glow(1.0, 0.35, 0.50);
    final healthRim = _pbr(0.55, 0.07, 0.20, 0.45);
    final healthFace = _pbr(1.0, 0.30, 0.43, 0.40);
    final heartMat = _glow(1.0, 0.90, 0.94);

    Node healthCoin() {
      final coin = Node();
      coin.add(_part(disc, healthGlow, 0, 0, 0, 1.18, 0.08, 1.18));
      coin.add(_part(disc, healthRim, 0, 0, 0, 1.0, 0.12, 1.0));
      coin.add(_part(disc, healthFace, 0, 0, 0, 0.8, 0.15, 0.8));
      // heart: two round lobes (up) and a diamond (down)
      coin.add(_part(disc, heartMat, -0.075, 0, -0.07, 0.2, 0.18, 0.2));
      coin.add(_part(disc, heartMat, 0.075, 0, -0.07, 0.2, 0.18, 0.2));
      coin.add(_part(box, heartMat, 0, 0, 0.03, 0.18, 0.18, 0.18,
          yaw: math.pi / 4));
      return coin;
    }

    final random = math.Random(3);

    for (final spot in spots) {
      final node = goldCoin();
      node.scale = vm.Vector3.all(1.3);
      node.position = spot.clone();
      node.rotation = _upright;
      scene.add(node);

      _coins.add(_Coin(node, spot, random.nextDouble() * math.pi * 2,
          isHealth: false));
    }
    total = spots.length;

    for (final spot in healthSpots) {
      final node = healthCoin();
      node.scale = vm.Vector3.all(1.6);
      node.position = spot.clone();
      node.rotation = _upright;
      scene.add(node);

      _coins.add(_Coin(node, spot, random.nextDouble() * math.pi * 2,
          isHealth: true));
    }
    healthTotal = healthSpots.length;

    debugPrint('Coins placed: gold $total, health $healthTotal');
  }

  void update(double time, double px, double py, double pz) {
    for (final c in _coins) {
      if (c.taken) continue;

      final dx = c.spot.x - px;
      final dz = c.spot.z - pz;
      final flat = dx * dx + dz * dz;

      // Very far coins are hidden (saves rendering work).
      if (flat > 6400) {
        if (c.shown) {
          c.node.visible = false;
          c.shown = false;
        }
        continue;
      } else if (!c.shown) {
        c.node.visible = true;
        c.shown = true;
      }

      // Far coins are not animated or checked.
      if (flat > 900) continue;

      final dy = c.spot.y - (py + 1.6);

      final close = flat + dy * dy < 2.6 * 2.6;
      if (close && !(c.isHealth && healthFull)) {
        c.taken = true;
        c.node.position = vm.Vector3(0, -100, 0);

        if (c.isHealth) {
          onHealthPickup?.call();
        } else {
          collected.value++;
        }
        continue;
      }

      c.node.rotation = vm.Quaternion.axisAngle(
            vm.Vector3(0, 1, 0),
            time * 3 + c.phase,
          ) *
          _upright;

      final bob = c.isHealth ? 0.18 : 0.12;
      c.node.position = vm.Vector3(
        c.spot.x,
        c.spot.y + math.sin(time * 2 + c.phase) * bob,
        c.spot.z,
      );
    }
  }
}