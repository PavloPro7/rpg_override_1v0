import 'package:flutter/material.dart';

class Skill {
  final String id;
  final String name;
  final String category;
  double xp;
  final Color color;

  Skill({
    required this.id,
    required this.name,
    required this.category,
    this.xp = 0.0,
    required this.color,
  });

  int get level => (xp / 100).floor() + 1;
  double get progressInLevel => (xp % 10) / 10;

  void addXp(double amount) {
    xp += amount;
    if (xp < 0) xp = 0;
  }

  void applyDailyPenalty(double amount) {
    if (xp > 0) {
      xp -= amount;
      if (xp < 0) xp = 0;
    }
  }
}