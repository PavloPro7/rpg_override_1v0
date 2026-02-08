import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/app_state.dart';
import '../models/task.dart';
import 'settings_screen.dart';

class TodayTasksScreen extends StatefulWidget {
  final VoidCallback? onProfileTap;
  const TodayTasksScreen({super.key, this.onProfileTap});

  @override
  State<TodayTasksScreen> createState() => _TodayTasksScreenState();
}

class _TodayTasksScreenState extends State<TodayTasksScreen> {
  DateTime _selectedDate = DateTime.now();
  bool _isCompletedExpanded = false;

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final colorScheme = Theme.of(context).colorScheme;

    final tasksForDate = appState.getTasksForDate(_selectedDate);
    final activeTasks = tasksForDate.where((t) => !t.isCompleted).toList();
    final completedTasks = tasksForDate.where((t) => t.isCompleted).toList();

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text(
          'Tasks',
          style: TextStyle(fontWeight: FontWeight.w500),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.settings),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const SettingsScreen()),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: InkWell(
              onTap: widget.onProfileTap,
              child: CircleAvatar(
                radius: 18,
                backgroundColor: colorScheme.primaryContainer,
                backgroundImage: appState.avatarUrl != null
                    ? NetworkImage(appState.avatarUrl!)
                    : null,
                child: appState.avatarUrl == null
                    ? Icon(
                        Icons.person_rounded,
                        size: 20,
                        color: colorScheme.onPrimaryContainer,
                      )
                    : null,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildDateSelector(context),
          const Divider(height: 1),
          Expanded(child: _buildTaskList(context, activeTasks, completedTasks)),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddTaskDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildDateSelector(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    // Generate dates around today
    final dates = List.generate(7, (index) {
      return DateTime.now().add(Duration(days: index - 2));
    });

    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: dates.length + 1, // +1 for "New list"
        itemBuilder: (context, index) {
          if (index < dates.length) {
            final date = dates[index];
            final isSelected = DateUtils.isSameDay(date, _selectedDate);
            final label = _getDateLabel(date);

            return Padding(
              padding: const EdgeInsets.only(right: 24.0),
              child: InkWell(
                onTap: () => setState(() => _selectedDate = date),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        color: isSelected
                            ? colorScheme.primary
                            : colorScheme.onSurfaceVariant,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                    if (isSelected)
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        height: 3,
                        width: 24,
                        decoration: BoxDecoration(
                          color: colorScheme.primary,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                  ],
                ),
              ),
            );
          } else {
            return TextButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.add, size: 18),
              label: const Text('New list'),
            );
          }
        },
      ),
    );
  }

  String _getDateLabel(DateTime date) {
    if (DateUtils.isSameDay(date, DateTime.now())) {
      return DateFormat('d.MM').format(date);
    }
    return DateFormat('d.MM').format(date);
  }

  Widget _buildTaskList(
    BuildContext context,
    List<Task> activeTasks,
    List<Task> completedTasks,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              children: [
                if (activeTasks.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Center(child: Text('No tasks for this day')),
                  )
                else
                  ...activeTasks.map((task) => _buildTaskTile(context, task)),

                if (completedTasks.isNotEmpty) ...[
                  const Divider(height: 1),
                  _buildCompletedHeader(context, completedTasks.length),
                  if (_isCompletedExpanded)
                    ...completedTasks.map(
                      (task) => _buildTaskTile(context, task),
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskTile(BuildContext context, Task task) {
    final appState = Provider.of<AppState>(context, listen: false);
    final skill = appState.skills.firstWhere(
      (s) => s.id == task.skillId,
      orElse: () => appState.skills.first,
    );

    return ListTile(
      horizontalTitleGap: 8,
      leading: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(
              task.isCompleted
                  ? Icons.check_circle
                  : Icons.radio_button_unchecked,
              color: task.isCompleted ? Colors.green : skill.color,
              size: 28,
            ),
            onPressed: () => appState.completeTask(task.id),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 2),
          Visibility(
            visible: !task.isCompleted,
            maintainSize: true,
            maintainAnimation: true,
            maintainState: true,
            child: IconButton(
              icon: const Icon(Icons.swap_horiz, size: 20, color: Colors.grey),
              onPressed: () => _showMoveTaskDialog(context, task),
              tooltip: 'Move to another date',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ),
        ],
      ),
      title: Text(
        task.title,
        style: TextStyle(
          decoration: task.isCompleted ? TextDecoration.lineThrough : null,
          color: task.isCompleted ? Colors.grey : null,
        ),
      ),
      trailing: !task.isCompleted
          ? const Icon(Icons.star_border, color: Colors.grey)
          : null,
    );
  }

  Widget _buildCompletedHeader(BuildContext context, int count) {
    return InkWell(
      onTap: () => setState(() => _isCompletedExpanded = !_isCompletedExpanded),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Text(
              'Completed ($count)',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            const Spacer(),
            Icon(
              _isCompletedExpanded
                  ? Icons.keyboard_arrow_up
                  : Icons.keyboard_arrow_down,
            ),
          ],
        ),
      ),
    );
  }

  void _showMoveTaskDialog(BuildContext context, Task task) {
    // Basic dialog to pick a new date
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Move Task'),
        content: const Text('Select a new date for this task:'),
        actions: [
          TextButton(
            onPressed: () {
              final newDate = DateTime.now().add(const Duration(days: 1));
              context.read<AppState>().updateTaskDate(task.id, newDate);
              Navigator.pop(context);
            },
            child: const Text('Move to Tomorrow'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showAddTaskDialog(BuildContext context) {
    final titleController = TextEditingController();
    final appState = Provider.of<AppState>(context, listen: false);

    // Initial skill selection
    String? selectedSkillId = appState.skills.isNotEmpty
        ? appState.skills.first.id
        : null;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          icon: const Icon(Icons.auto_awesome),
          title: const Text('Accept New Quest'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: InputDecoration(
                  labelText: 'Quest Name',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                ),
              ),
              const SizedBox(height: 20),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Target Skill',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: selectedSkillId,
                    isExpanded: true,
                    items: appState.skills.map((skill) {
                      return DropdownMenuItem(
                        value: skill.id,
                        child: Row(
                          children: [
                            Text(
                              skill.icon,
                              style: const TextStyle(fontSize: 16),
                            ),
                            const SizedBox(width: 12),
                            Text(skill.name),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (value) =>
                        setDialogState(() => selectedSkillId = value),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Decline'),
            ),
            FilledButton(
              onPressed: () {
                if (titleController.text.isNotEmpty &&
                    selectedSkillId != null) {
                  appState.addTask(
                    titleController.text,
                    selectedSkillId!,
                    date: _selectedDate,
                  );
                  Navigator.pop(context);
                }
              },
              child: const Text('Accept Quest'),
            ),
          ],
        ),
      ),
    );
  }
}
