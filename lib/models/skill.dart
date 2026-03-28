// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';

class Skill {
  final String id;
  final String name;
  final double xp;
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

  /// XP required to go from level N to level N+1.
  /// Uses a standard RPG curve: each level needs more XP than the last.
  /// Level 1→2: 100 XP, Level 2→3: 150 XP, Level 10→11: ~450 XP, etc.
  static double xpRequiredForLevel(int level) {
    // Base 100, grows by 50% compounding per level, floored to nice numbers
    return (100 * (1.0 + (level - 1) * 0.5)).roundToDouble();
  }

  /// Total cumulative XP needed to REACH a given level (from level 1).
  static double cumulativeXpForLevel(int level) {
    double total = 0;
    for (int i = 1; i < level; i++) {
      total += xpRequiredForLevel(i);
    }
    return total;
  }

  /// Current level based on total accumulated XP.
  int get level {
    int lvl = 1;
    double remaining = xp;
    while (remaining >= xpRequiredForLevel(lvl)) {
      remaining -= xpRequiredForLevel(lvl);
      lvl++;
    }
    return lvl;
  }

  /// Progress within current level (0.0 to 1.0).
  double get progressInLevel {
    double remaining = xp;
    int lvl = 1;
    while (remaining >= xpRequiredForLevel(lvl)) {
      remaining -= xpRequiredForLevel(lvl);
      lvl++;
    }
    return remaining / xpRequiredForLevel(lvl);
  }

  /// XP needed to complete current level.
  double get xpForCurrentLevel => xpRequiredForLevel(level);

  /// XP already earned within current level.
  double get xpInCurrentLevel {
    return xp - cumulativeXpForLevel(level);
  }
}
