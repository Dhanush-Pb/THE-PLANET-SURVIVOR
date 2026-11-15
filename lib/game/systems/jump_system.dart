class JumpSystem {
  static const double jumpSpeed = 9.5;
  static const double gravity = 24.0;

  double y = 0;
  double velocity = 0;

  bool get grounded => y <= 0 && velocity == 0;

  /// Returns true if a jump started.
  bool jump() {
    if (!grounded) return false;
    velocity = jumpSpeed;
    y = 0.001;
    return true;
  }

  /// Returns true on the frame the player lands.
  bool update(double dt) {
    if (grounded) return false;

    velocity -= gravity * dt;
    y += velocity * dt;

    if (y <= 0) {
      y = 0;
      velocity = 0;
      return true;
    }
    return false;
  }
}