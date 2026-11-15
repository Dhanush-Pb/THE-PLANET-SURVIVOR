
import 'package:flutter_scene/scene.dart';

class PlayerAnimation {
  PlayerAnimation(this.player);

  final Node player;

  final Map<String, AnimationClip> _clips = {};

  AnimationClip? _currentClip;
  String? _currentName;

  List<String> get animationNames =>
      player.parsedAnimations.map((animation) => animation.name).toList();

  void play(String name) {
    if (_currentName == name) return;

    final animation = player.parsedAnimations
        .cast<Animation?>()
        .firstWhere(
          (item) => item?.name == name,
          orElse: () => null,
        );

    if (animation == null) {
      print('Animation not found: $name');
      return;
    }

    _currentClip?.pause();

    final clip = _clips.putIfAbsent(
      name,
      () => player.createAnimationClip(animation),
    );

    clip.loop = true;
    clip.replay();

    _currentClip = clip;
    _currentName = name;
  }

  void playIdle() => play('Idle-loop');

  void playForward() => play('Walk-loop');

  void playBackward() => play('Walk backwards-loop');

  void playLeft() => play('Strafe left-loop');

  void playRight() => play('Strafe right-loop');

  void playRun() => play('Run-loop');

  void stop() {
    _currentClip?.stop();
    _currentClip = null;
    _currentName = null;
  }
}
