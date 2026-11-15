
import 'package:flutter_scene/scene.dart';

class PlayerAnimation {
  PlayerAnimation(this.player);

  final Node player;

  final Map<String, AnimationClip> _clips = {};

  AnimationClip? _currentClip;
  String? _currentName;

  List<String> get animationNames =>
      player.parsedAnimations.map((a) => a.name).toList();

  String? _find(List<String> keywords) {
    for (final name in animationNames) {
      final lower = name.toLowerCase();

      if (keywords.every((word) => lower.contains(word))) {
        return name;
      }
    }
    return null;
  }

  void play(String name, {bool loop = true}) {
    if (_currentName == name) return;

    final animation = player.findAnimationByName(name);

    if (animation == null) {
      print('Animation unavailable: $name');
      return;
    }

    // Remove the previous animation's influence on the character.
    if (_currentClip != null) {
      _currentClip!.weight = 0.0;
      _currentClip!.stop();
    }

    final clip = _clips.putIfAbsent(
      name,
      () => player.createAnimationClip(animation),
    );

    // Only the selected animation controls the character's pose.
    clip.weight = 1.0;
    clip.loop = loop;
    clip.replay();

    _currentClip = clip;
    _currentName = name;
  }

  // Normal standing pose.
  void playIdle() {
    play('Idle-loop');
  }

  // Ground movement.
  void playWalk() {
    play('Walk-loop');
  }

  void playRun() {
    play('Run-loop');
  }

  void playBackward() {
    play('Walk backwards-loop');
  }

  void playLeft() {
    play('Strafe left-loop');
  }

  void playRight() {
    play('Strafe right-loop');
  }

  // Jump sequence.
  void playJumpStart() {
    play('Jump start', loop: false);
  }

  void playJumpAir() {
    play('Jump (in air)-loop');
  }

  void playJumpLand() {
    play('Jump land', loop: false);
  }

  void playFall() {
    play('Fall', loop: false);
  }

  // Other actions.
  void playPunch() {
    play('Punch', loop: false);
  }

  void playRoll() {
    play('Forward roll', loop: false);
  }

  // Stop current activity and return to normal idle.
  void stop() {
    if (_currentName == 'Idle-loop') return;

    if (_currentClip != null) {
      _currentClip!.weight = 0.0;
      _currentClip!.stop();
    }

    _currentClip = null;
    _currentName = null;

    playIdle();
  }
}
