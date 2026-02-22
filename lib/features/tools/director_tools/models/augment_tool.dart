import 'package:flutter/material.dart';

enum AugmentTool {
  bgRemoval('bg-removal', 'Remove BG', Icons.content_cut),
  lineart('lineart', 'Line Art', Icons.draw),
  sketch('sketch', 'Sketch', Icons.gesture),
  colorize('colorize', 'Colorize', Icons.color_lens),
  emotion('emotion', 'Emotion', Icons.mood),
  declutter('declutter', 'Declutter', Icons.cleaning_services);

  final String apiValue;
  final String label;
  final IconData icon;
  const AugmentTool(this.apiValue, this.label, this.icon);

  bool get hasDefry => this == colorize || this == emotion;
  bool get hasPrompt => this == colorize || this == emotion;
}

enum EmotionMood {
  neutral('neutral', 'Neutral'),
  happy('happy', 'Happy'),
  sad('sad', 'Sad'),
  angry('angry', 'Angry'),
  scared('scared', 'Scared'),
  surprised('surprised', 'Surprised'),
  tired('tired', 'Tired'),
  excited('excited', 'Excited'),
  nervous('nervous', 'Nervous'),
  thinking('thinking', 'Thinking'),
  confused('confused', 'Confused'),
  shy('shy', 'Shy'),
  disgusted('disgusted', 'Disgusted'),
  smug('smug', 'Smug'),
  bored('bored', 'Bored'),
  laughing('laughing', 'Laughing'),
  irritated('irritated', 'Irritated'),
  aroused('aroused', 'Aroused'),
  embarrassed('embarrassed', 'Embarrassed'),
  worried('worried', 'Worried'),
  love('love', 'Love'),
  determined('determined', 'Determined'),
  hurt('hurt', 'Hurt'),
  playful('playful', 'Playful');

  final String apiValue;
  final String label;
  const EmotionMood(this.apiValue, this.label);
}
