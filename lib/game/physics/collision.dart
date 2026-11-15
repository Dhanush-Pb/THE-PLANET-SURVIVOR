class CircleObstacle {
  const CircleObstacle(this.x, this.z, this.radius);

  final double x;
  final double z;
  final double radius;
}

class Collision {
  Collision._();

  /// Pushes a circle (the player) out of any obstacle it overlaps.
  static (double, double) pushOut(
    double x,
    double z,
    double playerRadius,
    List<CircleObstacle> obstacles,
  ) {
    for (final o in obstacles) {
      final dx = x - o.x;
      final dz = z - o.z;
      final minDist = o.radius + playerRadius;
      final d2 = dx * dx + dz * dz;

      if (d2 < minDist * minDist && d2 > 0.000001) {
        final d = _sqrt(d2);
        final push = (minDist - d) / d;
        x += dx * push;
        z += dz * push;
      }
    }
    return (x, z);
  }

  static double _sqrt(double v) {
    var guess = v > 1 ? v / 2 : 1.0;
    for (var i = 0; i < 6; i++) {
      guess = 0.5 * (guess + v / guess);
    }
    return guess;
  }
}