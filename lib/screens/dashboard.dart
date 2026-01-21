import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../models/skill.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    return Scaffold(
      appBar: AppBar(title: const Text('Character Skills')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: appState.skills.length,
        itemBuilder: (context, index) {
          final skill = appState.skills[index];
          return SkillCard(skill: skill);
        },
      ),
    );
  }
}

class SkillCard extends StatelessWidget {
  final Skill skill;

  const SkillCard({super.key, required this.skill});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      skill.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      skill.category,
                      style: TextStyle(color: Colors.grey[600],
                      fontSize: 12),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: skill.color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Level ${skill.level}',
                    style: TextStyle(
                      color: skill.color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: skill.progressInLevel,
                minHeight: 12,
                backgroundColor: Colors.grey[300],
                color: skill.color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}