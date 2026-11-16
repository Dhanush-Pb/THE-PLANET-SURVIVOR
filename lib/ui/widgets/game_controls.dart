
import 'package:flutter/material.dart';

/// Round action button used for Jump, Sprint, Crouch and Dodge.
class ActionButton extends StatefulWidget {
  const ActionButton({
    super.key,
    required this.icon,
    required this.onDown,
    this.onUp,
    this.size = 72,
    this.active = false,
  });

  final IconData icon;
  final VoidCallback onDown;
  final VoidCallback? onUp;
  final double size;
  final bool active;

  @override
  State<ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<ActionButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final lit = _pressed || widget.active;

    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: (_) {
        setState(() => _pressed = true);
        widget.onDown();
      },
      onPointerUp: (_) {
        setState(() => _pressed = false);
        widget.onUp?.call();
      },
      onPointerCancel: (_) {
        setState(() => _pressed = false);
        widget.onUp?.call();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 90),
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: lit
              ? Colors.amber.withValues(alpha: 0.85)
              : Colors.black.withValues(alpha: 0.45),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.7),
            width: 2.5,
          ),
        ),
        child: Icon(
          widget.icon,
          color: lit ? Colors.black87 : Colors.white,
          size: widget.size * 0.5,
        ),
      ),
    );
  }
}
