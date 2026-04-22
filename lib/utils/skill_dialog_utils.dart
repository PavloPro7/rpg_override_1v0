// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/skill.dart';
import '../providers/app_state.dart';

class SkillDialogUtils {
  static void showSkillDialog(BuildContext context, {Skill? skill}) {
    final isEditing = skill != null;
    final nameController = TextEditingController(text: skill?.name);
    final iconController = TextEditingController(text: skill?.icon ?? '⭐');
    double startLevel = skill?.level.toDouble() ?? 1.0;
    Color selectedColor = skill?.color ?? Colors.blue;

    final List<Color> colorPresets = [
      Colors.blue, Colors.indigo, Colors.purple, Colors.pink,
      Colors.red, Colors.deepOrange, Colors.orange, Colors.amber,
      Colors.yellow, Colors.lime, Colors.green, Colors.teal,
      Colors.cyan, Colors.blueGrey, Colors.brown, Colors.grey,
    ];

    void submitSkill() {
      if (nameController.text.isNotEmpty) {
        final appState = Provider.of<AppState>(context, listen: false);
        if (isEditing) {
          appState.updateSkill(
            skill.copyWith(
              name: nameController.text,
              icon: iconController.text,
              color: selectedColor,
            ),
          );
        } else {
          appState.addSkill(
            nameController.text,
            selectedColor,
            startLevel.toInt(),
            iconController.text.isEmpty ? '⭐' : iconController.text,
          );
        }
        Navigator.pop(context);
      }
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          icon: Icon(isEditing ? Icons.edit_note : Icons.psychology),
          title: Text(isEditing ? 'Edit Skill' : 'Design New Skill'),
          content: SingleChildScrollView(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: selectedColor.withValues(alpha: 0.5)),
                color: selectedColor.withValues(alpha: 0.05),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    textInputAction: TextInputAction.next,
                    onSubmitted: (_) => submitSkill(),
                    decoration: InputDecoration(
                      labelText: 'Skill Name',
                      border: const OutlineInputBorder(),
                      prefixIcon: Padding(
                        padding: const EdgeInsets.only(left: 12, right: 4),
                        child: Text(iconController.text, style: const TextStyle(fontSize: 20)),
                      ),
                      prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: iconController,
                    textInputAction: TextInputAction.next,
                    onSubmitted: (_) => submitSkill(),
                    decoration: const InputDecoration(
                      labelText: 'Emoji (Optional)',
                      border: OutlineInputBorder(),
                      hintText: '💪',
                    ),
                    textAlign: TextAlign.center,
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
                  SizedBox(
                    height: 36,
                    width: double.maxFinite,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: colorPresets.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, colorIndex) {
                        final color = colorPresets[colorIndex];
                        final isSelected = selectedColor.value == color.value;
                        return GestureDetector(
                          onTap: () => setDialogState(() => selectedColor = color),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            width: isSelected ? 32 : 28,
                            height: isSelected ? 32 : 28,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border: isSelected
                                  ? Border.all(color: Colors.white, width: 2.5)
                                  : Border.all(color: Colors.transparent, width: 2.5),
                              boxShadow: isSelected
                                  ? [BoxShadow(color: color.withValues(alpha: 0.6), blurRadius: 6, spreadRadius: 1)]
                                  : null,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: submitSkill,
              child: Text(isEditing ? 'Update Skill' : 'Create Skill'),
            ),
          ],
        ),
      ),
    );
  }
}
