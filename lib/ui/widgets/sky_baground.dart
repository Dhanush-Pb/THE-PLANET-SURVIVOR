import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../game/camera/game_camera.dart';

/// Deep-space sky: nebulae, milky-way band, twinkling stars, a ringed gas
/// giant, a moon, a distant blue sun and the odd shooting star.
/// Everything is projected from azimuth/elevation so it turns with the camera.
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

class _Star {
  const _Star(this.az, this.el, this.size, this.alpha, this.phase, this.speed,
      this.tint);

  final double az;
  final double el;
  final double size;
  final double alpha;
  final double phase;
  final double speed;
  final Color tint;
}

class _Nebula {
  const _Nebula(this.az, this.el, this.radius, this.inner, this.outer);

  final double az;
  final double el;
  final double radius; // fraction of screen height
  final Color inner;
  final Color outer;
}

class _SkyPainter extends CustomPainter {
  _SkyPainter(this.camera, this.time) : super(repaint: time);

  final GameCamera camera;
  final ValueNotifier<double> time;

  static const double _tanHalfFov = 0.41421356; // 45 degree field of view
  static const double _tau = math.pi * 2;

  static const _tints = [
    Color(0xFFFFFFFF),
    Color(0xFFCFE6FF),
    Color(0xFFBFD0FF),
    Color(0xFFFFE6C9),
    Color(0xFFD9C4FF),
  ];

  static final List<_Star> _stars = () {
    final r = math.Random(11);
    return List.generate(280, (i) {
      final big = r.nextDouble() > 0.93;
      return _Star(
        r.nextDouble() * _tau,
        math.asin(r.nextDouble() * 0.98), // uniform over the dome
        big ? 1.6 + r.nextDouble() * 1.2 : 0.5 + r.nextDouble() * 0.8,
        big ? 0.9 : 0.35 + r.nextDouble() * 0.5,
        r.nextDouble() * _tau,
        0.6 + r.nextDouble() * 2.2,
        _tints[r.nextInt(_tints.length)],
      );
    });
  }();

  /// Dense little stars hugging a tilted band: the galaxy core.
  static double _bandEl(double az) => 0.62 + 0.38 * math.sin(az * 1.0 + 0.6);

  static final List<_Star> _bandStars = () {
    final r = math.Random(29);
    return List.generate(260, (i) {
      final az = r.nextDouble() * _tau;
      final spread = (r.nextDouble() + r.nextDouble() - 1) * 0.16;
      return _Star(
        az,
        (_bandEl(az) + spread).clamp(0.02, 1.4).toDouble(),
        0.4 + r.nextDouble() * 0.7,
        0.25 + r.nextDouble() * 0.45,
        r.nextDouble() * _tau,
        0.5 + r.nextDouble() * 1.5,
        _tints[r.nextInt(3)],
      );
    });
  }();

  static const List<_Nebula> _nebulae = [
    _Nebula(0.7, 0.55, 0.62, Color(0x66B03CFF), Color(0x00B03CFF)),
    _Nebula(2.0, 0.30, 0.55, Color(0x5500D5FF), Color(0x0000D5FF)),
    _Nebula(3.5, 0.65, 0.70, Color(0x55FF3C9A), Color(0x00FF3C9A)),
    _Nebula(4.7, 0.35, 0.58, Color(0x553C5BFF), Color(0x003C5BFF)),
    _Nebula(5.7, 0.70, 0.50, Color(0x4400FFC8), Color(0x0000FFC8)),
    _Nebula(1.3, 0.15, 0.45, Color(0x44FF7A3C), Color(0x00FF7A3C)),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    if (w <= 0 || h <= 0) return;

    final aspect = w / h;
    final heading = camera.yaw + math.pi;
    final t = time.value;

    final horizonY = h / 2 - (math.tan(camera.pitch) / _tanHalfFov) * (h / 2);

    Offset? project(double azimuth, double elevation) {
      var d = (heading - azimuth) % _tau;
      if (d > math.pi) d -= _tau;
      if (d.abs() > 1.35) return null;

      final x = w / 2 + (w / 2) * math.tan(d) / (_tanHalfFov * aspect);
      final y = horizonY -
          (math.tan(elevation) / math.cos(d)) / _tanHalfFov * (h / 2);
      return Offset(x, y);
    }

    // ---- Base gradient: void -> indigo -> teal horizon glow -> dark ground haze
    final gradient = ui.Gradient.linear(
      Offset(0, horizonY - h),
      Offset(0, horizonY + h * 0.9),
      const [
        Color(0xFF01020A),
        Color(0xFF050818),
        Color(0xFF0E0F33),
        Color(0xFF1B1A55),
        Color(0xFF2B5E85),
        Color(0xFF0F2A3A),
        Color(0xFF08141D),
        Color(0xFF050C12),
      ],
      const [0.0, 0.22, 0.38, 0.47, 0.526, 0.57, 0.75, 1.0],
    );
    canvas.drawRect(Offset.zero & size, Paint()..shader = gradient);

    // ---- Nebulae (additive-ish glow clouds)
    for (final n in _nebulae) {
      final p = project(n.az, n.el);
      if (p == null) continue;
      final r = h * n.radius;
      canvas.drawCircle(
        p,
        r,
        Paint()
          ..blendMode = BlendMode.screen
          ..shader = ui.Gradient.radial(p, r, [n.inner, n.outer]),
      );
    }

    // ---- Galaxy band glow
    for (var i = 0; i < 36; i++) {
      final az = i / 36 * _tau;
      final p = project(az, _bandEl(az));
      if (p == null) continue;
      final r = h * 0.28;
      canvas.drawCircle(
        p,
        r,
        Paint()
          ..blendMode = BlendMode.screen
          ..shader = ui.Gradient.radial(p, r, const [
            Color(0x2EC9B8FF),
            Color(0x00C9B8FF),
          ]),
      );
    }

    // ---- Stars
    void drawStars(List<_Star> list) {
      final paint = Paint();
      for (final s in list) {
        final p = project(s.az, s.el);
        if (p == null || p.dy > horizonY - 2 || p.dy < -10) continue;

        final twinkle = 0.65 + 0.35 * math.sin(t * s.speed + s.phase);
        final a = (s.alpha * twinkle).clamp(0.0, 1.0);
        final c = s.tint.withValues(alpha: a);

        if (s.size > 1.5) {
          paint.shader = ui.Gradient.radial(p, s.size * 5, [
            c.withValues(alpha: a * 0.55),
            c.withValues(alpha: 0),
          ]);
          canvas.drawCircle(p, s.size * 5, paint);
          paint.shader = null;
        }
        paint.color = c;
        canvas.drawCircle(p, s.size, paint);
      }
    }

    drawStars(_bandStars);
    drawStars(_stars);

    // ---- Distant blue sun
    final sun = project(2.4, 0.55);
    if (sun != null) {
      final r = h * 0.30;
      canvas.drawCircle(
        sun,
        r,
        Paint()
          ..blendMode = BlendMode.screen
          ..shader = ui.Gradient.radial(sun, r, const [
            Color(0x88BFE6FF),
            Color(0x2260A8FF),
            Color(0x0060A8FF),
          ], const [
            0.0,
            0.35,
            1.0
          ]),
      );
      canvas.drawCircle(
          sun, h * 0.022, Paint()..color = const Color(0xFFF2FAFF));
    }

    // ---- Ringed gas giant
    _drawGiant(canvas, project(0.95, 0.40), h * 0.15);

    // ---- Small moon
    final moon = project(3.7, 0.26);
    if (moon != null) {
      final r = h * 0.045;
      canvas.drawCircle(
        moon,
        r * 2.2,
        Paint()
          ..blendMode = BlendMode.screen
          ..shader = ui.Gradient.radial(moon, r * 2.2,
              const [Color(0x33AEC8FF), Color(0x00AEC8FF)]),
      );
      _drawSphere(
        canvas,
        moon,
        r,
        const Color(0xFFE9EEF8),
        const Color(0xFF7F8AA6),
        const Color(0xFF1B2034),
      );
    }

    // ---- Shooting star every ~9 s
    final cycle = t % 9.0;
    if (cycle < 0.9) {
      final k = cycle / 0.9;
      final seed = (t / 9.0).floor();
      final rr = math.Random(seed + 5);
      final start = Offset(w * (0.15 + rr.nextDouble() * 0.6), h * 0.06);
      final dir = Offset(0.8, 0.45);
      final head = start + dir * (k * w * 0.45);
      final tail = head - dir * (w * 0.12);
      final fade = math.sin(k * math.pi);
      canvas.drawLine(
        tail,
        head,
        Paint()
          ..strokeWidth = 1.8
          ..strokeCap = StrokeCap.round
          ..shader = ui.Gradient.linear(tail, head, [
            const Color(0x00FFFFFF),
            Color.fromRGBO(255, 255, 255, fade),
          ]),
      );
    }

    // ---- Horizon atmosphere glow (cyan to magenta rim)
    final rimTop = horizonY - h * 0.22;
    final rimBottom = horizonY + h * 0.06;
    canvas.drawRect(
      Rect.fromLTRB(0, rimTop, w, rimBottom),
      Paint()
        ..blendMode = BlendMode.screen
        ..shader = ui.Gradient.linear(
          Offset(0, rimTop),
          Offset(0, rimBottom),
          const [
            Color(0x00000000),
            Color(0x2A7B4BFF),
            Color(0x5530D8E8),
            Color(0x00000000),
          ],
          const [0.0, 0.5, 0.85, 1.0],
        ),
    );
  }

  void _drawSphere(Canvas canvas, Offset c, double r, Color lit, Color mid,
      Color dark) {
    final light = c + Offset(-r * 0.4, -r * 0.35);
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..shader = ui.Gradient.radial(
          light,
          r * 1.9,
          [lit, mid, dark],
          const [0.0, 0.5, 1.0],
        ),
    );
  }

  void _drawGiant(Canvas canvas, Offset? c, double r) {
    if (c == null) return;

    // outer atmosphere haze
    canvas.drawCircle(
      c,
      r * 1.9,
      Paint()
        ..blendMode = BlendMode.screen
        ..shader = ui.Gradient.radial(c, r * 1.9,
            const [Color(0x33B07CFF), Color(0x00B07CFF)]),
    );

    void ring(double width, Color color, double scale, {bool frontOnly = false}) {
      canvas.save();
      canvas.translate(c.dx, c.dy);
      canvas.rotate(-0.38);
      if (frontOnly) {
        canvas.clipRect(Rect.fromLTRB(-r * 4, 0, r * 4, r * 4));
      }
      canvas.drawOval(
        Rect.fromCenter(
            center: Offset.zero, width: r * scale, height: r * scale * 0.24),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = width
          ..color = color,
      );
      canvas.restore();
    }

    // back half of rings
    ring(r * 0.16, const Color(0x66D9B8FF), 3.4);
    ring(r * 0.07, const Color(0x55FFD9A8), 3.0);

    // planet body with banding
    _drawSphere(
      canvas,
      c,
      r,
      const Color(0xFFF1C9FF),
      const Color(0xFF7C4FC0),
      const Color(0xFF120A2A),
    );
    canvas.save();
    canvas.clipPath(Path()..addOval(Rect.fromCircle(center: c, radius: r)));
    for (var i = -3; i <= 3; i++) {
      canvas.drawRect(
        Rect.fromLTWH(c.dx - r, c.dy + i * r * 0.26, r * 2, r * 0.09),
        Paint()..color = const Color(0x18FFFFFF),
      );
    }
    // night-side shadow
    canvas.drawCircle(
      c + Offset(r * 0.55, r * 0.45),
      r * 1.15,
      Paint()
        ..shader = ui.Gradient.radial(
          c + Offset(r * 0.55, r * 0.45),
          r * 1.15,
          const [Color(0xCC030210), Color(0x00030210)],
          const [0.5, 1.0],
        ),
    );
    canvas.restore();

    // front half of rings crosses over the planet
    ring(r * 0.16, const Color(0xAAE6CCFF), 3.4, frontOnly: true);
    ring(r * 0.07, const Color(0x99FFE2BC), 3.0, frontOnly: true);
  }

  @override
  bool shouldRepaint(_SkyPainter old) => true;
}