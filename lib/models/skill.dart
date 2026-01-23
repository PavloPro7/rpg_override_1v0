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

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'xp': xp,
      'color': color.value,
    };
  }

  factory Skill.fromMap(Map<String, dynamic> map) {
    return Skill(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      category: map['category'] ?? '',
      xp: (map['xp'] ?? 0.0).toDouble(),
      color: Color(map['color'] ?? Colors.blue.value),
    );
  }

  Skill copyWith({
    String? id,
    String? name,
    String? category,
    double? xp,
    Color? color,
  }) {
    return Skill(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      xp: xp ?? this.xp,
      color: color ?? this.color,
    );
  }

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
