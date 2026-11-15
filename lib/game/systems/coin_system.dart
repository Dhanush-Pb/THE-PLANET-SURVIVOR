import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter_scene/scene.dart';
import 'package:vector_math/vector_math.dart' as vm;

class _Coin {
  _Coin(this.node, this.spot, this.phase);

  final Node node;
  final vm.Vector3 spot;
  final double phase;
  bool taken = false;
}

class CoinSystem {
  final ValueNotifier<int> collected = ValueNotifier<int>(0);
  int total = 0;

  final List<_Coin> _coins = [];

  // Stand the coin up so its face points sideways.
  static final vm.Quaternion _upright =
      vm.Quaternion.axisAngle(vm.Vector3(1, 0, 0), math.pi / 2);

  void build(Scene scene, List<vm.Vector3> spots) {
    final geometry =
        CylinderGeometry(bottomRadius: 0.5, topRadius: 0.5, height: 0.12);

    final material = PhysicallyBasedMaterial();
    material.baseColorFactor = vm.Vector4(1.0, 0.80, 0.10, 1);
    material.roughnessFactor = 0.35;
    material.metallicFactor = 0;

    final random = math.Random(3);

    for (final spot in spots) {
      final node = Node(mesh: Mesh(geometry, material));
      node.scale = vm.Vector3.all(1.3);
      node.position = spot.clone();
      node.rotation = _upright;
      scene.add(node);

      _coins.add(_Coin(node, spot, random.nextDouble() * math.pi * 2));
    }

    total = _coins.length;
    debugPrint('Coins placed: $total');
  }

  void update(double time, double px, double py, double pz) {
    for (final c in _coins) {
      if (c.taken) continue;

      final dx = c.spot.x - px;
      final dz = c.spot.z - pz;
      final flat = dx * dx + dz * dz;

      // Far coins are not touched at all (saves work).
      if (flat > 900) continue;

      final dy = c.spot.y - (py + 1.6);

      if (flat + dy * dy < 2.6 * 2.6) {
        c.taken = true;
        c.node.position = vm.Vector3(0, -100, 0);
        collected.value++;
        continue;
      }

      c.node.rotation = vm.Quaternion.axisAngle(
            vm.Vector3(0, 1, 0),
            time * 3 + c.phase,
          ) *
          _upright;

      c.node.position = vm.Vector3(
        c.spot.x,
        c.spot.y + math.sin(time * 2 + c.phase) * 0.12,
        c.spot.z,
      );
    }
  }
}