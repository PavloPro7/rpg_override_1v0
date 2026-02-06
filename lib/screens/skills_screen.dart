import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../models/skill.dart';

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
            onPressed: () => _showAddSkillDialog(context),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: appState.skills.length,
        itemBuilder: (context, index) {
          final skill = appState.skills[index];
          return SkillCard(skill: skill);
        },
      ),
    );
  }

  void _showAddSkillDialog(BuildContext context) {
    final nameController = TextEditingController();
    final categoryController = TextEditingController();
    double difficulty = 1.0;
    double startLevel = 1.0;
    Color selectedColor = Colors.blue;

    final List<Color> colorPresets = [
      Colors.blue,
      Colors.red,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.pink,
      Colors.teal,
      Colors.amber,
    ];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          icon: const Icon(Icons.psychology),
          title: const Text('Design New Skill'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Skill Name',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.label),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: categoryController,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.category),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Hardability (Difficulty)'),
                Slider(
                  value: difficulty,
                  min: 1.0,
                  max: 5.0,
                  divisions: 4,
                  label: 'x${difficulty.toInt()}',
                  onChanged: (val) => setDialogState(() => difficulty = val),
                ),
                Text(
                  difficulty == 1.0
                      ? 'Easy'
                      : difficulty <= 2.0
                      ? 'Medium'
                      : difficulty <= 3.0
                      ? 'Hard'
                      : 'Legendary',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                const Text('Starting Level'),
                Slider(
                  value: startLevel,
                  min: 1.0,
                  max: 50.0,
                  divisions: 49,
                  label: startLevel.toInt().toString(),
                  onChanged: (val) => setDialogState(() => startLevel = val),
                ),
                const SizedBox(height: 16),
                const Text('Skill Color'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: colorPresets.map((color) {
                    final isSelected = selectedColor == color;
                    return GestureDetector(
                      onTap: () => setDialogState(() => selectedColor = color),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: isSelected
                              ? Border.all(color: Colors.white, width: 2)
                              : null,
                          boxShadow: isSelected
                              ? [
                                  const BoxShadow(
                                    color: Colors.black26,
                                    blurRadius: 4,
                                  ),
                                ]
                              : null,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (nameController.text.isNotEmpty) {
                  final appState = Provider.of<AppState>(
                    context,
                    listen: false,
                  );
                  appState.addSkill(
                    nameController.text,
                    categoryController.text.isEmpty
                        ? 'General'
                        : categoryController.text,
                    selectedColor,
                    difficulty,
                    startLevel.toInt(),
                  );
                  Navigator.pop(context);
                }
              },
              child: const Text('Create Skill'),
            ),
          ],
        ),
      ),
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
      color: colorScheme.surfaceVariant.withOpacity(0.5),
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: colorScheme.outlineVariant.withOpacity(0.5)),
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
                      Text(
                        skill.name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.5,
                        ),
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
                    color: skill.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: skill.color.withOpacity(0.2)),
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
                    backgroundColor: colorScheme.outlineVariant.withOpacity(
                      0.3,
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
