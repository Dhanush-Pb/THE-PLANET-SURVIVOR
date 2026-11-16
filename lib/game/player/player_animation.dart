
import 'package:flutter_scene/scene.dart';

class PlayerAnimation {
  PlayerAnimation(this.player);

  final Node player;
  final Map<String, AnimationClip> _clips = {};

  AnimationClip? _currentClip;
  String? _currentName;

  List<String> get animationNames =>
      player.parsedAnimations.map((a) => a.name).toList();

  bool play(
    String name, {
    bool loop = true,
    bool restart = false,
  }) {
    if (_currentName == name && !restart) return true;

    final animation = player.findAnimationByName(name);

    if (animation == null) {
      print('Animation unavailable: $name');
      return false;
    }

    if (_currentClip != null) {
      _currentClip!.weight = 0.0;
      _currentClip!.stop();
    }

    final clip = _clips.putIfAbsent(
      name,
      () => player.createAnimationClip(animation),
    );

    clip.weight = 1.0;
    clip.loop = loop;
    clip.replay();

    _currentClip = clip;
    _currentName = name;

    return true;
  }

  void playIdle() => play('Idle-loop');

  void playWalk() => play('Walk-loop');

  void playRun() => play('Run-loop');

  void playLeft() => play('Strafe left-loop');

  void playRight() => play('Strafe right-loop');

  void playCrouchIdle() {
    if (!play('Crouch idle-loop')) {
      playIdle();
    }
  }

  void playCrouchWalk() {
    if (!play('Slouch walk-loop')) {
      playWalk();
    }
  }

  void playJumpStart() {
    play('Jump start', loop: false, restart: true);
  }

  void playJumpAir() {
    play('Jump (in air)-loop');
  }

  void playJumpLand() {
    play('Jump land', loop: false, restart: true);
  }

  void playFall() {
    play('Fall', loop: false, restart: true);
  }

  void playPunch() {
    play('Punch', loop: false, restart: true);
  }

  void playRoll() {
    play('Forward roll', loop: false, restart: true);
  }

  void stop() {
    if (_currentClip != null) {
      _currentClip!.weight = 0.0;
      _currentClip!.stop();
    }

    _currentClip = null;
    _currentName = null;

    playIdle();
  }
}
