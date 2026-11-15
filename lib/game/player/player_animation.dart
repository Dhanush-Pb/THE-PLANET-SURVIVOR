// TODO: Implement player animations.
import 'package:flutter_scene/scene.dart';

class PlayerAnimation {
  PlayerAnimation(this.player);

  final Node player;
  final Map<String, AnimationClip> _clips = {};
  AnimationClip? _currentClip;

  List<String> get animationNames =>
      player.parsedAnimations.map((animation) => animation.name).toList();

  void play(String animationName, {bool loop = true}) {
    final animation = player.parsedAnimations.cast<Animation?>().firstWhere(
          (item) => item?.name == animationName,
          orElse: () => null,
        );

    if (animation == null) {
      print('Animation not found: $animationName');
      return;
    }

    _currentClip?.pause();

    final clip = _clips.putIfAbsent(
      animationName,
      () => player.createAnimationClip(animation),
    );

    clip.loop = loop;
    clip.replay();

    _currentClip = clip;
  }

  void playIdle() {
    final idle = player.parsedAnimations.cast<Animation?>().firstWhere(
          (item) => item?.name == 'Idle-loop',
          orElse: () => player.parsedAnimations.cast<Animation?>().firstWhere(
                (item) => item?.name.toLowerCase().contains('idle') ?? false,
                orElse: () => null,
              ),
        );

    if (idle != null) {
      play(idle.name);
    } else {
      print('No idle animation found.');
      print('Available animations: $animationNames');
    }
  }

  void stop() {
    _currentClip?.stop();
    _currentClip = null;
  }
}