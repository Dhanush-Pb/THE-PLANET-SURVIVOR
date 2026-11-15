
import 'package:flutter_scene/scene.dart';

class PlayerAnimation {
  PlayerAnimation(this.player);

  final Node player;

  final Map<String, AnimationClip> _clips = {};

  AnimationClip? _currentClip;
  String? _currentName;

  List<String> get animationNames =>
      player.parsedAnimations.map((a) => a.name).toList();

  void play(String name) {
    if (_currentName == name) return;

    final animation = player.findAnimationByName(name);

    if (animation == null) {
      print('Animation unavailable: $name');
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

  String? _find(List<String> keywords) {
    for (final name in animationNames) {
      final lower = name.toLowerCase();

      if (keywords.every(lower.contains)) {
        return name;
      }
    }

    return null;
  }

  void playIdle() {
    play(_find(['idle']) ?? 'Idle-loop');
  }

  void playWalk() {
    play(_find(['walk']) ?? 'Walk-loop');
  }

  void playRun() {
    play(_find(['run']) ?? 'Run-loop');
  }

  void playBackward() {
    play(_find(['backward']) ?? 'Walk backwards-loop');
  }

  void playLeft() {
    play(_find(['strafe', 'left']) ?? 'Strafe left-loop');
  }

  void playRight() {
    play(_find(['strafe', 'right']) ?? 'Strafe right-loop');
  }

  void playJump() {
    final name = _find(['jump']) ?? _find(['leap']);

    if (name != null) play(name);
  }

  void playFall() {
    final name = _find(['fall']);

    if (name != null) play(name);
  }

  void playLand() {
    final name = _find(['land']);

    if (name != null) play(name);
  }

  void stop() {
    _currentClip?.stop();
    _currentClip = null;
    _currentName = null;
  }
}
