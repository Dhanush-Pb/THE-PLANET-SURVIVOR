// TODO: Implement world objects.

import 'package:flutter_scene/scene.dart';
import 'package:vector_math/vector_math.dart' as vm;

class WorldObjects {
  WorldObjects._();

  static final groundGeometry = CuboidGeometry(
    vm.Vector3(150, 1, 150),
  );

  static final pathGeometry = CuboidGeometry(
    vm.Vector3(7, 0.12, 150),
  );

  static final trunkGeometry = CylinderGeometry(
    bottomRadius: 0.35,
    topRadius: 0.25,
    height: 4,
    radialSegments: 7,
  );

  static final canopyGeometry = SphereGeometry(
    radius: 1,
    segments: 9,
    rings: 7,
  );

  static final rockGeometry = SphereGeometry(
    radius: 1,
    segments: 8,
    rings: 6,
  );

  static final coinGeometry = CylinderGeometry(
    bottomRadius: 0.48,
    topRadius: 0.48,
    height: 0.12,
    radialSegments: 12,
  );

  static final grass = _material(0.12, 0.32, 0.10);
  static final path = _material(0.38, 0.22, 0.12);
  static final trunk = _material(0.24, 0.11, 0.055);
  static final leaves = _material(0.055, 0.26, 0.09);
  static final leavesLight = _material(0.12, 0.39, 0.12);
  static final rock = _material(0.28, 0.31, 0.30);
  static final water = _material(0.035, 0.34, 0.48);
  static final bridge = _material(0.35, 0.17, 0.075);
  static final gold = _material(1.0, 0.62, 0.025);

  static UnlitMaterial _material(
    double r,
    double g,
    double b,
  ) {
    return UnlitMaterial()
      ..baseColorFactor = vm.Vector4(r, g, b, 1);
  }

  static Node createNode(
    String name,
    Geometry geometry,
    Material material, {
    double x = 0,
    double y = 0,
    double z = 0,
    double scaleX = 1,
    double scaleY = 1,
    double scaleZ = 1,
  }) {
    final node = Node(
      name: name,
      mesh: Mesh(geometry, material),
    );

    node.position = vm.Vector3(x, y, z);
    node.scale = vm.Vector3(scaleX, scaleY, scaleZ);
    node.castsShadows = false;

    return node;
  }
}
