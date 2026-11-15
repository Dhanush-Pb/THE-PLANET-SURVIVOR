// TODO: Implement the joystick widget.
import 'dart:math' as math;

import 'package:flutter/material.dart';

/// On-screen analog stick. x: right is +1. y: forward (up) is +1.
class Joystick extends StatefulWidget {
  const Joystick({
    super.key,
    required this.onChanged,
    this.size = 150,
  });

  final void Function(double x, double y) onChanged;
  final double size;

  @override
  State<Joystick> createState() => _JoystickState();
}

class _JoystickState extends State<Joystick> {
  Offset _knob = Offset.zero;
  int? _pointer;

  double get _radius => widget.size * 0.32;

  void _update(Offset local) {
    final center = Offset(widget.size / 2, widget.size / 2);
    var d = local - center;

    if (d.distance > _radius) {
      d = d / d.distance * _radius;
    }

    setState(() => _knob = d);

    var x = d.dx / _radius;
    var y = -d.dy / _radius;

    // Small dead zone so the character does not drift.
    if (math.sqrt(x * x + y * y) < 0.12) {
      x = 0;
      y = 0;
    }

    widget.onChanged(x, y);
  }

  void _release() {
    _pointer = null;
    setState(() => _knob = Offset.zero);
    widget.onChanged(0, 0);
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: (event) {
        if (_pointer != null) return;
        _pointer = event.pointer;
        _update(event.localPosition);
      },
      onPointerMove: (event) {
        if (event.pointer == _pointer) _update(event.localPosition);
      },
      onPointerUp: (event) {
        if (event.pointer == _pointer) _release();
      },
      onPointerCancel: (event) {
        if (event.pointer == _pointer) _release();
      },
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: CustomPaint(painter: _StickPainter(_knob, widget.size)),
      ),
    );
  }
}

class _StickPainter extends CustomPainter {
  _StickPainter(this.knob, this.size);

  final Offset knob;
  final double size;

  @override
  void paint(Canvas canvas, Size canvasSize) {
    final center = Offset(size / 2, size / 2);

    canvas.drawCircle(
      center,
      size * 0.46,
      Paint()..color = Colors.black.withValues(alpha: 0.25),
    );
    canvas.drawCircle(
      center,
      size * 0.46,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.45)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );
    canvas.drawCircle(
      center + knob,
      size * 0.17,
      Paint()..color = Colors.white.withValues(alpha: 0.75),
    );
  }

  @override
  bool shouldRepaint(_StickPainter old) => old.knob != knob;
}