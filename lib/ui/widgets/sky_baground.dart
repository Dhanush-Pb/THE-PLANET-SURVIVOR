import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../game/camera/game_camera.dart';

/// Painted sky: gradient, sun and clouds. It turns with the camera.
class SkyBackground extends StatelessWidget {
  const SkyBackground({super.key, required this.camera, required this.time});

  final GameCamera camera;
  final ValueNotifier<double> time;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _SkyPainter(camera, time),
      size: Size.infinite,
    );
  }
}

class _Cloud {
  const _Cloud(this.azimuth, this.elevation, this.scale);

  final double azimuth;
  final double elevation;
  final double scale;
}

class _SkyPainter extends CustomPainter {
  _SkyPainter(this.camera, this.time) : super(repaint: time);

  final GameCamera camera;
  final ValueNotifier<double> time;

  static const double _tanHalfFov = 0.41421356; // 45 degree field of view
  static const double _sunAzimuth = 2.4;
  static const double _sunElevation = 0.55;

  static final List<_Cloud> _clouds = () {
    final random = math.Random(3);
    return List.generate(
      11,
      (i) => _Cloud(
        i * 0.57 + random.nextDouble() * 0.3,
        0.10 + random.nextDouble() * 0.5,
        0.7 + random.nextDouble() * 0.9,
      ),
    );
  }();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    if (w <= 0 || h <= 0) return;

    final aspect = w / h;
    final heading = camera.yaw + math.pi;

    // Where the horizon line is on the screen.
    final horizonY = h / 2 - (math.tan(camera.pitch) / _tanHalfFov) * (h / 2);

    Offset? project(double azimuth, double elevation) {
      var d = (heading - azimuth) % (math.pi * 2);
      if (d > math.pi) d -= math.pi * 2;
      if (d.abs() > 1.35) return null;

      final x = w / 2 + (w / 2) * math.tan(d) / (_tanHalfFov * aspect);
      final y = horizonY -
          (math.tan(elevation) / math.cos(d)) / _tanHalfFov * (h / 2);
      return Offset(x, y);
    }

    // Sky above the horizon, soft green haze below it.
    final gradient = ui.Gradient.linear(
      Offset(0, horizonY - h),
      Offset(0, horizonY + h * 0.9),
      const [
        Color(0xFF1B5FC2),
        Color(0xFF4A9BE0),
        Color(0xFF9CD1F2),
        Color(0xFFEFF7E6),
        Color(0xFFCBE2C6),
        Color(0xFF9BBE98),
        Color(0xFF6D9672),
      ],
      const [0.0, 0.30, 0.46, 0.526, 0.56, 0.75, 1.0],
    );
    canvas.drawRect(Offset.zero & size, Paint()..shader = gradient);

    // Sun.
    final sun = project(_sunAzimuth, _sunElevation);
    if (sun != null) {
      canvas.drawCircle(
        sun,
        h * 0.35,
        Paint()
          ..shader = ui.Gradient.radial(
            sun,
            h * 0.35,
            const [Color(0xAAFFF3C4), Color(0x00FFF3C4)],
          ),
      );
      canvas.drawCircle(sun, h * 0.04, Paint()..color = const Color(0xFFFFF7D6));
    }

    // Clouds drift slowly.
    final t = time.value;
    final shade = Paint()..color = const Color(0xFFD5E3F2);
    final white = Paint()..color = const Color(0xF2FFFFFF);

    for (final c in _clouds) {
      final p = project(c.azimuth + t * 0.015, c.elevation);
      if (p == null || p.dy < -h * 0.3 || p.dy > h) continue;

      final s = w * 0.09 * c.scale;

      void puff(Paint paint, double dx, double dy, double ow, double oh) {
        canvas.drawOval(
          Rect.fromCenter(
            center: p + Offset(dx * s, dy * s),
            width: ow * s,
            height: oh * s,
          ),
          paint,
        );
      }

      puff(shade, 0, 0.18, 2.3, 0.7);
      puff(white, 0, 0, 2.2, 0.7);
      puff(white, -0.9, -0.2, 1.3, 0.8);
      puff(white, 0.8, -0.25, 1.5, 0.9);
      puff(white, 0, -0.45, 1.4, 0.9);
    }
  }

  @override
  bool shouldRepaint(_SkyPainter old) => true;
}