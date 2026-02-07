import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../models/skill.dart';
import '../utils/skill_dialog_utils.dart';

class SkillsScreen extends StatelessWidget {
  const SkillsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Character Skills'),
        centerTitle: true,
        actions: [
          IconButton.filledTonal(
            icon: const Icon(Icons.library_add_rounded),
            onPressed: () => SkillDialogUtils.showSkillDialog(context),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: appState.skills.length,
        itemBuilder: (context, index) {
          final skill = appState.skills[index];
          return GestureDetector(
            onLongPress: () => _showSkillOptionsBottomSheet(context, skill),
            child: SkillCard(skill: skill),
          );
        },
      ),
    );
  }

  void _showSkillOptionsBottomSheet(BuildContext context, Skill skill) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Edit Skill'),
                onTap: () {
                  Navigator.pop(context); // Close bottom sheet
                  SkillDialogUtils.showSkillDialog(
                    context,
                    skill: skill,
                  ); // Open edit dialog
                },
              ),
              ListTile(
                leading: const Icon(Icons.dashboard),
                title: const Text('Go to Dashboard'),
                onTap: () {
                  Navigator.pop(context); // Close bottom sheet
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Navigating to ${skill.name} dashboard (Not implemented yet)',
                      ),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_forever, color: Colors.red),
                title: const Text(
                  'Delete Skill',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () {
                  Navigator.pop(context); // Close bottom sheet
                  Provider.of<AppState>(
                    context,
                    listen: false,
                  ).removeSkill(skill.id);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${skill.name} deleted')),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class SkillCard extends StatelessWidget {
  final Skill skill;

  const SkillCard({super.key, required this.skill});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            skill.icon,
                            style: const TextStyle(fontSize: 20),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              skill.name,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                letterSpacing: -0.5,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        skill.category.toUpperCase(),
                        style: TextStyle(
                          color: colorScheme.onSurfaceVariant,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: skill.color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: skill.color.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Text(
                    'Level ${skill.level}',
                    style: TextStyle(
                      color: skill.color,
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: skill.progressInLevel,
                    minHeight: 20,
                    backgroundColor: colorScheme.outlineVariant.withValues(
                      alpha: 0.3,
                    ),
                    color: skill.color,
                  ),
                ),
                Positioned.fill(
                  child: Center(
                    child: Text(
                      '${(skill.progressInLevel * 100).toInt()}% OF LEVEL',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        shadows: [Shadow(color: Colors.black45, blurRadius: 2)],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
