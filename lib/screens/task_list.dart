import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';

class TodayTasksScreen extends StatelessWidget {
  const TodayTasksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final todayTasks = appState.todayTasks;

    return Scaffold(
      appBar: AppBar(title: const Text('Today\'s Quests')),
      body: todayTasks.isEmpty
        ? const Center(child: Text('No quests for today! Use the + button to add one.'))
        : ListView.builder(
          itemCount: todayTasks.length,
          itemBuilder: (context, index) {
            final task = todayTasks[index];
            final skill = appState.skills.firstWhere(
              (s) => s.id == task.skillId,
            );

            return ListTile(
              leading: Icon(
                task.isCompleted
                  ? Icons.check_circle
                  : Icons.radio_button_unchecked,
                  color: skill.color,
              ),
              title: Text(
                task.title,
                style: TextStyle(
                  decoration: task.isCompleted
                    ? TextDecoration.lineThrough
                    : null,
                ),
              ),
              subtitle: Text(skill.name),
              onTap: task.isCompleted
                ? null
                : () => appState.completeTask(task.id),
            );
          },
        ),
    );
  }
}