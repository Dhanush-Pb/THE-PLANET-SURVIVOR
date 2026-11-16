import 'package:vector_math/vector_math.dart' as vm;

import '../world/world_builder.dart';

/// All the numbers that control health, health coins and the finish.
/// Change them here to tune the game.
class GameRules {
  GameRules._();

  static const double maxHealth = 100;

  /// Health lost per second. 0.5 = 1 health every 2 seconds
  /// (about 3 minutes 20 seconds from full to empty).
  static const double drainPerSecond = 0.5;

  /// Health restored by one health coin.
  static const double healthCoinHeal = 15;

  /// At or below this value the health bar turns red.
  static const double lowHealth = 25;

  /// Finish area: the glowing portal ring in the east.
  static const double finishX = 62;
  static const double finishZ = -55;
  static const double finishRadius = 5;

  /// 12 health coins: 4 along the road to rescue low players,
  /// 8 near landmarks to reward exploring.
  static List<vm.Vector3> healthSpots() {
    final spots = <vm.Vector3>[];

    // [z along the road, sideways offset from the road centre]
    const roadSpots = [
      [-75.0, 2.8],
      [-35.0, -2.8],
      [25.0, 2.8],
      [70.0, -2.8],
    ];
    for (final r in roadSpots) {
      final z = r[0];
      spots.add(vm.Vector3(WorldBuilder.trailX(z) + r[1], 1.5, z));
    }

    // [x, z] next to the landmarks.
    const landmarkSpots = [
      [15.5, -12.0], // outpost gate
      [-19.0, 22.0], // colony
      [14.0, 26.0], // cargo yard
      [14.0, -32.0], // landing pad
      [64.0, 10.0], // mine
      [-6.0, -72.0], // observatory
      [-42.0, 42.0], // crystal garden
      [-16.0, -27.0], // crash site
    ];
    for (final p in landmarkSpots) {
      spots.add(vm.Vector3(p[0], 1.5, p[1]));
    }

    return spots;
  }
}