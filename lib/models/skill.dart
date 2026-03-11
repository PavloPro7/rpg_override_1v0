// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';

class Skill {
  final String id;
  final String name;
  double xp;
  final Color color;
  final String icon; // emoji icon

  Skill({
    required this.id,
    required this.name,
    this.xp = 0.0,
    required this.color,
    this.icon = '⭐',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'xp': xp,
      'color': color.value,
      'icon': icon,
    };
  }

  factory Skill.fromMap(Map<String, dynamic> map) {
    return Skill(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      xp: (map['xp'] ?? 0.0).toDouble(),
      color: Color(map['color'] ?? Colors.blue.value),
      icon: map['icon'] ?? '⭐',
    );
  }

  Skill copyWith({
    String? id,
    String? name,
    double? xp,
    Color? color,
    String? icon,
  }) {
    return Skill(
      id: id ?? this.id,
      name: name ?? this.name,
      xp: xp ?? this.xp,
      color: color ?? this.color,
      icon: icon ?? this.icon,
    );
  }

  // Base XP per level is 100
  double get totalXpForCurrentLevel => 100;

  int get level => (xp / totalXpForCurrentLevel).floor() + 1;
  double get progressInLevel =>
      (xp % totalXpForCurrentLevel) / totalXpForCurrentLevel;

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
