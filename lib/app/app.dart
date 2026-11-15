// TODO: Build the root application widget.
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:jungle_advanture/ui/screens/game_screen.dart';



class WildStepApp extends StatelessWidget {
  const WildStepApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'THE WILD STEP',
      home: GameScreen(),//!
    );
  }
}