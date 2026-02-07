// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/skill.dart';
import '../providers/app_state.dart';

class SkillDialogUtils {
  static void showSkillDialog(BuildContext context, {Skill? skill}) {
    final isEditing = skill != null;
    final nameController = TextEditingController(text: skill?.name);
    final categoryController = TextEditingController(text: skill?.category);
    final iconController = TextEditingController(text: skill?.icon ?? '⭐');
    double difficulty = skill?.difficulty ?? 1.0;
    double startLevel = skill?.level.toDouble() ?? 1.0;
    Color selectedColor = skill?.color ?? Colors.blue;

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
          icon: Icon(isEditing ? Icons.edit_note : Icons.psychology),
          title: Text(isEditing ? 'Edit Skill' : 'Design New Skill'),
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
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: iconController,
                        decoration: const InputDecoration(
                          labelText: 'Emoji',
                          border: OutlineInputBorder(),
                          hintText: '💪',
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 5,
                      child: TextField(
                        controller: categoryController,
                        decoration: const InputDecoration(
                          labelText: 'Category',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
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
                const SizedBox(height: 16),
                if (!isEditing) ...[
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
                ],
                const Text('Skill Color'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: colorPresets.map((color) {
                    final isSelected = selectedColor.value == color.value;
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
                  if (isEditing) {
                    appState.updateSkill(
                      skill.copyWith(
                        name: nameController.text,
                        category: categoryController.text,
                        icon: iconController.text,
                        difficulty: difficulty,
                        color: selectedColor,
                      ),
                    );
                  } else {
                    appState.addSkill(
                      nameController.text,
                      categoryController.text.isEmpty
                          ? 'General'
                          : categoryController.text,
                      selectedColor,
                      difficulty,
                      startLevel.toInt(),
                      iconController.text.isEmpty ? '⭐' : iconController.text,
                    );
                  }
                  Navigator.pop(context);
                }
              },
              child: Text(isEditing ? 'Update Skill' : 'Create Skill'),
            ),
          ],
        ),
      ),
    );
  }
}
