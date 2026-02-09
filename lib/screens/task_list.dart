import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/app_state.dart';
import '../models/task.dart';

class TodayTasksScreen extends StatefulWidget {
  final VoidCallback? onProfileTap;
  final VoidCallback? onSettingsTap;
  const TodayTasksScreen({super.key, this.onProfileTap, this.onSettingsTap});

  @override
  State<TodayTasksScreen> createState() => _TodayTasksScreenState();
}

class _TodayTasksScreenState extends State<TodayTasksScreen> {
  late DateTime _selectedDate;
  bool _isCompletedExpanded = false;
  bool _isStarredView = false;
  final ScrollController _dateScrollController = ScrollController();
  final Set<String> _selectedTaskIds = {};

  bool get _isSelectionMode => _selectedTaskIds.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateUtils.dateOnly(DateTime.now());
    WidgetsBinding.instance.addPostFrameCallback((_) => _centerSelectedDate());
  }

  @override
  void dispose() {
    _dateScrollController.dispose();
    super.dispose();
  }

  void _centerSelectedDate() {
    if (_dateScrollController.hasClients) {
      final screenWidth = MediaQuery.of(context).size.width;
      final itemWidth = (screenWidth - 32) / 7;
      // Scroll to exactly 1 item width to hide the Star icon (index 0)
      // and center index 4 (the selected date) perfectly.
      _dateScrollController.animateTo(
        itemWidth,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final colorScheme = Theme.of(context).colorScheme;

    final tasksForDate = _isStarredView
        ? appState.tasks.where((t) => t.isStarred).toList()
        : appState.getTasksForDate(_selectedDate);
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);

    final activeTasks = tasksForDate.where((t) {
      if (t.isPinned) return !t.completedDates.contains(dateStr);
      return !t.isCompleted;
    }).toList();

    final completedTasks = tasksForDate.where((t) {
      if (t.isPinned) return t.completedDates.contains(dateStr);
      return t.isCompleted;
    }).toList();

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: _isSelectionMode
          ? AppBar(
              backgroundColor: Colors.black, // Darker, Telegram-style
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => setState(() => _selectedTaskIds.clear()),
              ),
              title: Text(
                '${_selectedTaskIds.length}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(
                    Icons.push_pin_outlined,
                    color: Colors.white,
                  ),
                  onPressed: () {
                    final selectedTasks = appState.tasks.where(
                      (t) => _selectedTaskIds.contains(t.id),
                    );
                    final allPinned = selectedTasks.every((t) => t.isPinned);
                    appState.togglePinTasks(
                      _selectedTaskIds.toList(),
                      !allPinned,
                    );
                    setState(() => _selectedTaskIds.clear());
                  },
                  tooltip: 'Toggle Pin',
                ),
                IconButton(
                  icon: const Icon(Icons.star_outline, color: Colors.white),
                  onPressed: () {
                    final selectedTasks = appState.tasks.where(
                      (t) => _selectedTaskIds.contains(t.id),
                    );
                    final allStarred = selectedTasks.every((t) => t.isStarred);
                    appState.toggleStarTasks(
                      _selectedTaskIds.toList(),
                      !allStarred,
                    );
                    setState(() => _selectedTaskIds.clear());
                  },
                  tooltip: 'Toggle Star',
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.white),
                  onPressed: () {
                    appState.deleteTasks(_selectedTaskIds.toList());
                    setState(() => _selectedTaskIds.clear());
                  },
                  tooltip: 'Delete selected',
                ),
                const SizedBox(width: 8),
              ],
            )
          : AppBar(
              title: const Text(
                'Tasks',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              centerTitle: true,
              leading: IconButton(
                icon: const Icon(Icons.settings),
                onPressed: widget.onSettingsTap,
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
    final screenWidth = MediaQuery.of(context).size.width;
    final itemWidth = (screenWidth - 32) / 7;

    // Generate dates around the selected date - all normalized to midnight
    final dates = List.generate(7, (index) {
      return _selectedDate.add(Duration(days: index - 3));
    });

    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.builder(
        controller: _dateScrollController,
        scrollDirection: Axis.horizontal,
        itemCount: dates.length + 2, // Star + Dates + Calendar
        itemBuilder: (context, index) {
          if (index == 0) {
            // Restore Starred View icon at the start
            return SizedBox(
              width: itemWidth,
              child: Center(
                child: IconButton(
                  onPressed: () =>
                      setState(() => _isStarredView = !_isStarredView),
                  icon: Icon(
                    _isStarredView ? Icons.star : Icons.star_border,
                    color: _isStarredView
                        ? Colors.amber
                        : colorScheme.onSurfaceVariant,
                  ),
                  tooltip: 'Starred (Saved) Tasks',
                  padding: EdgeInsets.zero,
                ),
              ),
            );
          } else if (index < dates.length + 1) {
            final date = dates[index - 1];
            final isSelected =
                !_isStarredView && DateUtils.isSameDay(date, _selectedDate);
            final label = _getDateLabel(date);

            return SizedBox(
              width: itemWidth,
              child: InkWell(
                onTap: () => setState(() {
                  _selectedDate = date;
                  _isStarredView = false;
                }),
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
            // Calendar Icon for Date Picker
            return SizedBox(
              width: itemWidth,
              child: Center(
                child: IconButton(
                  onPressed: () async {
                    final DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null && picked != _selectedDate) {
                      setState(() {
                        _selectedDate = DateUtils.dateOnly(picked);
                        _isStarredView = false;
                      });
                    }
                  },
                  icon: const Icon(Icons.calendar_month),
                  tooltip: 'Select date',
                  padding: EdgeInsets.zero,
                ),
              ),
            );
          }
        },
      ),
    );
  }

  String _getDateLabel(DateTime date) {
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
              color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              children: [
                if (activeTasks.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Center(
                      child: Text(
                        _isStarredView
                            ? (completedTasks.isEmpty
                                  ? 'No starred tasks'
                                  : 'No active starred tasks')
                            : (completedTasks.isEmpty
                                  ? 'No tasks for this day'
                                  : 'No active tasks for this day'),
                      ),
                    ),
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

    final colorScheme = Theme.of(context).colorScheme;
    final isSelected = _selectedTaskIds.contains(task.id);
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
    final isDone = task.isPinned
        ? task.completedDates.contains(dateStr)
        : task.isCompleted;

    return InkWell(
      onLongPress: () {
        setState(() {
          if (isSelected) {
            _selectedTaskIds.remove(task.id);
          } else {
            _selectedTaskIds.add(task.id);
          }
        });
      },
      onTap: _isSelectionMode
          ? () {
              setState(() {
                if (isSelected) {
                  _selectedTaskIds.remove(task.id);
                } else {
                  _selectedTaskIds.add(task.id);
                }
              });
            }
          : null,
      child: Container(
        color: isSelected ? colorScheme.primary.withOpacity(0.15) : null,
        child: ListTile(
          horizontalTitleGap: 8,
          leading: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(
                  isDone ? Icons.check_circle : Icons.radio_button_unchecked,
                  color: isDone ? Colors.green : skill.color,
                  size: 28,
                ),
                onPressed: _isSelectionMode
                    ? null
                    : () =>
                          appState.completeTask(task.id, onDate: _selectedDate),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 2),
              Visibility(
                visible: !isDone,
                maintainSize: true,
                maintainAnimation: true,
                maintainState: true,
                child: IconButton(
                  icon: const Icon(
                    Icons.swap_horiz,
                    size: 20,
                    color: Colors.grey,
                  ),
                  onPressed: (_isSelectionMode || task.isPinned)
                      ? null
                      : () => _showMoveTaskDialog(context, task),
                  tooltip: 'Move to another date',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ),
            ],
          ),
          title: Row(
            children: [
              if (task.isPinned) ...[
                IconButton(
                  icon: const Icon(
                    Icons.push_pin,
                    size: 16,
                    color: Colors.grey,
                  ),
                  onPressed: _isSelectionMode
                      ? null
                      : () => appState.togglePin(task.id),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  tooltip: 'Unpin task',
                ),
                const SizedBox(width: 4),
              ],
              Expanded(
                child: Text(
                  task.title,
                  style: TextStyle(
                    decoration: isDone ? TextDecoration.lineThrough : null,
                    color: isDone ? Colors.grey : null,
                  ),
                ),
              ),
            ],
          ),
          trailing: !isDone
              ? IconButton(
                  icon: Icon(
                    task.isStarred ? Icons.star : Icons.star_border,
                    color: task.isStarred ? Colors.amber : Colors.grey,
                  ),
                  onPressed: _isSelectionMode
                      ? null
                      : () => appState.toggleStar(task.id),
                )
              : null,
        ),
      ),
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
    final prevDay = task.date.subtract(const Duration(days: 1));
    final nextDay = task.date.add(const Duration(days: 1));

    final prevLabel = _getDateLabel(prevDay);
    final nextLabel = _getDateLabel(nextDay);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Move Task'),
        content: const Text('Select a new date for this task:'),
        actions: [
          TextButton(
            onPressed: () {
              context.read<AppState>().updateTaskDate(task.id, prevDay);
              Navigator.pop(context);
            },
            child: Text('Move to $prevLabel'),
          ),
          TextButton(
            onPressed: () {
              context.read<AppState>().updateTaskDate(task.id, nextDay);
              Navigator.pop(context);
            },
            child: Text('Move to $nextLabel'),
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
