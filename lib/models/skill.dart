// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';

class Skill {
  final String id;
  final String name;
  final String category;
  double xp;
  final Color color;
  final double difficulty; // 1.0 = normal, 2.0 = double xp needed, etc.
  final String icon; // emoji icon

  Skill({
    required this.id,
    required this.name,
    required this.category,
    this.xp = 0.0,
    required this.color,
    this.difficulty = 1.0,
    this.icon = '⭐',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'xp': xp,
      'color': color.value,
      'difficulty': difficulty,
      'icon': icon,
    };
  }

  factory Skill.fromMap(Map<String, dynamic> map) {
    return Skill(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      category: map['category'] ?? '',
      xp: (map['xp'] ?? 0.0).toDouble(),
      color: Color(map['color'] ?? Colors.blue.value),
      difficulty: (map['difficulty'] ?? 1.0).toDouble(),
      icon: map['icon'] ?? '⭐',
    );
  }

  Skill copyWith({
    String? id,
    String? name,
    String? category,
    double? xp,
    Color? color,
    double? difficulty,
    String? icon,
  }) {
    return Skill(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      xp: xp ?? this.xp,
      color: color ?? this.color,
      difficulty: difficulty ?? this.difficulty,
      icon: icon ?? this.icon,
    );
  }

  // Base XP per level is 100, multiplied by difficulty
  double get totalXpForCurrentLevel => 100 * difficulty;

  int get level => (xp / totalXpForCurrentLevel).floor() + 1;
  double get progressInLevel =>
      (xp % totalXpForCurrentLevel) / totalXpForCurrentLevel;

  void addXp(double amount) {
    xp += amount;
    if (xp < 0) xp = 0;
  }

  void applyDailyPenalty(double amount) {
    if (xp > 0) {
      xp -= amount * difficulty; // Penalty also scales with difficulty
      if (xp < 0) xp = 0;
    }
  }
}
