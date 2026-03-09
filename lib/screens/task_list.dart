import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import 'dart:ui';
import '../widgets/app_calendar.dart';
import '../providers/app_state.dart';
import '../models/task.dart';

class TodayTasksScreen extends StatefulWidget {
  final VoidCallback? onProfileTap;
  final VoidCallback? onSettingsTap;
  final VoidCallback? onBackTap;
  final DateTime? initialDate;
  final bool showBackButton;
  const TodayTasksScreen({
    super.key,
    this.onProfileTap,
    this.onSettingsTap,
    this.onBackTap,
    this.initialDate,
    this.showBackButton = false,
  });

  @override
  State<TodayTasksScreen> createState() => TodayTasksScreenState();
}

class TodayTasksScreenState extends State<TodayTasksScreen> {
  late DateTime _selectedDate;
  late DateTime _timelineFocusDate;
  late DateTime _baseDate;
  late PageController _pageController;
  final int _initialPage = 10000;
  bool _isCompletedExpanded = false;
  bool _isStarredView = false;
  late ScrollController _dateScrollController;
  bool _initializedScrollController = false;
  final Set<String> _selectedTaskIds = {};
  final Set<String> _animatingTaskIds = {};
  final Set<String> _fadingTaskIds = {};
  bool _isAnimatingToPage = false;

  bool get _isSelectionMode => _selectedTaskIds.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _baseDate = DateUtils.dateOnly(DateTime.now());
    _selectedDate = widget.initialDate != null
        ? DateUtils.dateOnly(widget.initialDate!)
        : _baseDate;
    _timelineFocusDate = _selectedDate;
    final diff = _selectedDate.difference(_baseDate).inDays;
    _pageController = PageController(initialPage: _initialPage + diff);
    WidgetsBinding.instance.addPostFrameCallback((_) => _centerSelectedDate());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initializedScrollController) {
      final screenWidth = MediaQuery.of(context).size.width;
      final itemWidth = (screenWidth - 32) / 7;
      _dateScrollController = ScrollController(
        initialScrollOffset: 14 * itemWidth,
      );
      _initializedScrollController = true;
    }
  }

  @override
  void dispose() {
    _dateScrollController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(TodayTasksScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialDate != null &&
        widget.initialDate != oldWidget.initialDate) {
      final newDate = DateUtils.dateOnly(widget.initialDate!);
      // Only recalculate if the date is actually different from our current state
      if (!DateUtils.isSameDay(newDate, _selectedDate)) {
        setState(() {
          _selectedDate = newDate;
          _isStarredView = false;
        });
        final diff = _selectedDate.difference(_baseDate).inDays;

        // Jump the page controller instantly
        if (_pageController.hasClients) {
          _pageController.jumpToPage(_initialPage + diff);
        } else {
          // If somehow lost clients, recreate
          _pageController = PageController(initialPage: _initialPage + diff);
        }

        // Re-center the horizontal date selector
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => _centerSelectedDate(),
        );
      }
    }
  }

  Future<void> _centerSelectedDate() async {
    if (!_dateScrollController.hasClients) return;

    final screenWidth = MediaQuery.of(context).size.width;
    final itemWidth = (screenWidth - 32) / 7;
    final parkOffset = 14 * itemWidth;

    final diffDays = _selectedDate.difference(_timelineFocusDate).inDays;
    if (diffDays == 0) {
      if ((_dateScrollController.offset - parkOffset).abs() > 1.0) {
        _dateScrollController.jumpTo(parkOffset);
      }
      return;
    }

    final targetOffset = parkOffset + (diffDays * itemWidth);

    _isAnimatingToPage = true;
    await _dateScrollController.animateTo(
      targetOffset.clamp(0.0, _dateScrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
    _isAnimatingToPage = false;

    if (mounted) {
      setState(() {
        _timelineFocusDate = _selectedDate;
      });
      _dateScrollController.jumpTo(parkOffset);
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final colorScheme = Theme.of(context).colorScheme;

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
                if (_selectedTaskIds.length == 1)
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, color: Colors.white),
                    onPressed: () {
                      final selectedTask = appState.tasks.firstWhere(
                        (t) => t.id == _selectedTaskIds.first,
                      );
                      _showAddTaskDialog(context, selectedTask);
                      setState(() => _selectedTaskIds.clear());
                    },
                    tooltip: 'Edit task',
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
              leading: widget.showBackButton
                  ? IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: widget.onBackTap,
                    )
                  : IconButton(
                      icon: Icon(
                        _isStarredView ? Icons.star : Icons.star_border,
                        color: _isStarredView
                            ? Colors.amber
                            : colorScheme.onSurfaceVariant,
                      ),
                      onPressed: () =>
                          setState(() => _isStarredView = !_isStarredView),
                      tooltip: 'Starred Tasks',
                    ),
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: IconButton(
                    icon: const Icon(Icons.calendar_month),
                    onPressed: () async {
                      final DateTime? picked = await _showCustomDatePicker(
                        context,
                      );
                      if (picked != null && picked != _selectedDate) {
                        final diff = DateUtils.dateOnly(
                          picked,
                        ).difference(_baseDate).inDays;
                        _pageController.jumpToPage(_initialPage + diff);
                        setState(() {
                          _selectedDate = DateUtils.dateOnly(picked);
                          _isStarredView = false;
                        });
                        WidgetsBinding.instance.addPostFrameCallback(
                          (_) => _centerSelectedDate(),
                        );
                      }
                    },
                    tooltip: 'Select date',
                  ),
                ),
              ],
            ),
      body: Focus(
        autofocus: true,
        onKeyEvent: (node, event) {
          if (event is KeyDownEvent) {
            final isShiftPressed = HardwareKeyboard.instance.isShiftPressed;
            if ((event.logicalKey == LogicalKeyboardKey.equal ||
                    event.logicalKey == LogicalKeyboardKey.add) &&
                isShiftPressed) {
              _showAddTaskDialog(context);
              return KeyEventResult.handled;
            }
            if (event.logicalKey == LogicalKeyboardKey.delete &&
                _isSelectionMode) {
              appState.deleteTasks(_selectedTaskIds.toList());
              setState(() => _selectedTaskIds.clear());
              return KeyEventResult.handled;
            }
          }
          return KeyEventResult.ignored;
        },
        child: Column(
          children: [
            _buildDateSelector(context),
            const Divider(height: 1),
            Expanded(
              child: NotificationListener<ScrollNotification>(
                onNotification: (notification) {
                  if (notification.depth != 0) return false;

                  void checkAndSnap(int settledPage) {
                    if (_isAnimatingToPage) return;

                    final newDate = _baseDate.add(
                      Duration(days: settledPage - _initialPage),
                    );
                    if (!DateUtils.isSameDay(newDate, _selectedDate)) {
                      setState(() {
                        _selectedDate = newDate;
                        _isStarredView = false;
                      });
                      _centerSelectedDate();
                    }
                  }

                  if (notification is ScrollUpdateNotification) {
                    final page = _pageController.page;
                    if (page != null && notification.dragDetails == null) {
                      final settled = page.round();
                      if ((page - settled).abs() < 0.1) {
                        checkAndSnap(settled);
                      }
                    }
                  } else if (notification is ScrollEndNotification) {
                    final settled =
                        _pageController.page?.round() ?? _initialPage;
                    checkAndSnap(settled);
                  }
                  return false;
                },
                child: PageView.builder(
                  controller: _pageController,
                  itemBuilder: (context, index) {
                    final pageDate = _baseDate.add(
                      Duration(days: index - _initialPage),
                    );
                    final pageTasks = _isStarredView
                        ? appState.tasks.where((t) => t.isStarred).toList()
                        : appState.getTasksForDate(pageDate);

                    final dateStr = DateFormat('yyyy-MM-dd').format(pageDate);
                    final active = pageTasks.where((t) {
                      if (t.isPinned) {
                        return !t.completedDates.contains(dateStr);
                      }
                      return !t.isCompleted;
                    }).toList();

                    final completed = pageTasks.where((t) {
                      if (t.isPinned) return t.completedDates.contains(dateStr);
                      return t.isCompleted;
                    }).toList();

                    return _buildTaskList(context, active, completed, pageDate);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void showAddTask() => _showAddTaskDialog(context);

  Widget _buildDateSelector(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final screenWidth = MediaQuery.of(context).size.width;
    final itemWidth = (screenWidth - 32) / 7;

    // Generate dates around the timeline focus date - all normalized to midnight
    // We generate 35 items so the scroll container has physically 14 items
    // to the left and 14 items to the right to animate through smoothly!
    final dates = List.generate(35, (index) {
      return _timelineFocusDate.add(Duration(days: index - 17));
    });

    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.builder(
        controller: _dateScrollController,
        scrollDirection: Axis.horizontal,
        itemCount: dates.length,
        itemBuilder: (context, index) {
          final date = dates[index];
          final label = _getDateLabel(date);

          return SizedBox(
            width: itemWidth,
            child: InkWell(
              onTap: () async {
                final diff = date.difference(_baseDate).inDays;
                final targetPage = _initialPage + diff;

                if (_pageController.page?.round() == targetPage) return;

                setState(() {
                  _selectedDate = date;
                  _isStarredView = false;
                });
                _centerSelectedDate();

                _isAnimatingToPage = true;
                await _pageController.animateToPage(
                  targetPage,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
                _isAnimatingToPage = false;
              },
              child: AnimatedBuilder(
                animation: _pageController,
                builder: (context, child) {
                  final selectedPageNum =
                      _initialPage + _selectedDate.difference(_baseDate).inDays;
                  double page = selectedPageNum.toDouble();

                  if (_pageController.hasClients &&
                      _pageController.position.haveDimensions) {
                    page = _pageController.page ?? page;
                  }

                  final isSelected = DateUtils.isSameDay(date, _selectedDate);

                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          color: (!_isStarredView && isSelected)
                              ? colorScheme.primary
                              : colorScheme.onSurfaceVariant,
                          fontWeight: (!_isStarredView && isSelected)
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        height: 3,
                        width: itemWidth,
                        alignment: Alignment.center,
                        child: (!_isStarredView && isSelected)
                            ? Transform.translate(
                                // This creates the Google Tasks stretch physics effect
                                offset: Offset(
                                  (page - selectedPageNum) * itemWidth / 2,
                                  0,
                                ),
                                child: Container(
                                  width:
                                      24.0 +
                                      ((page - selectedPageNum).abs() *
                                          itemWidth),
                                  height: 3,
                                  decoration: BoxDecoration(
                                    color: colorScheme.primary,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                              )
                            : const SizedBox(height: 3),
                      ),
                    ],
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }

  String _getDateLabel(DateTime date) {
    return DateFormat('d.MM').format(date);
  }

  String _getTimeLabel(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateUtils.dateOnly(now);
    final tomorrow = today.add(const Duration(days: 1));
    final date = DateUtils.dateOnly(dateTime);

    if (DateUtils.isSameDay(date, today)) {
      return 'Today';
    } else if (DateUtils.isSameDay(date, tomorrow)) {
      return 'Tomorrow';
    } else {
      return DateFormat('d MMM').format(date);
    }
  }

  Widget _buildTaskList(
    BuildContext context,
    List<Task> activeTasks,
    List<Task> completedTasks,
    DateTime pageDate,
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
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              child: Column(
                key: ValueKey(
                  '${_isStarredView}_${_selectedDate.toIso8601String()}',
                ),
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
                    ...activeTasks.map(
                      (task) => _buildTaskTile(context, task, pageDate),
                    ),

                  if (completedTasks.isNotEmpty) ...[
                    const Divider(height: 1),
                    _buildCompletedHeader(context, completedTasks.length),
                    if (_isCompletedExpanded)
                      ...completedTasks.map(
                        (task) => _buildTaskTile(context, task, pageDate),
                      ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskTile(BuildContext context, Task task, DateTime pageDate) {
    final appState = Provider.of<AppState>(context, listen: false);
    final taskSkillId = task.skillId;
    final skill = taskSkillId == 'none'
        ? null
        : appState.skills.firstWhere(
            (s) => s.id == taskSkillId,
            orElse: () => appState.skills.first,
          );

    final skillColor = skill?.color ?? Colors.grey;

    final colorScheme = Theme.of(context).colorScheme;
    final isSelected = _selectedTaskIds.contains(task.id);
    final dateStr = DateFormat('yyyy-MM-dd').format(pageDate);
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
      child: AnimatedSize(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 400),
          opacity: _fadingTaskIds.contains(task.id) ? 0.0 : 1.0,
          child: _fadingTaskIds.contains(task.id) && !isSelected
              ? const SizedBox(height: 0, width: double.infinity)
              : Container(
                  color: isSelected
                      ? colorScheme.primary.withValues(alpha: 0.15)
                      : null,
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    horizontalTitleGap: 8,
                    leading: Stack(
                      alignment: Alignment.center,
                      clipBehavior: Clip.none,
                      children: [
                        if (_animatingTaskIds.contains(task.id) && !isDone)
                          Positioned(
                            child: Transform.translate(
                              offset: const Offset(-24, 0),
                              child: const SizedBox(
                                width: 60,
                                height: 60,
                                child: CompletionBurst(),
                              ),
                            ),
                          ),
                        Opacity(
                          opacity:
                              (_animatingTaskIds.contains(task.id) && !isDone)
                              ? 0.0
                              : 1.0,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(
                                  isDone
                                      ? Icons.check_circle
                                      : Icons.radio_button_unchecked,
                                  color: isDone ? Colors.green : skillColor,
                                  size: 28,
                                ),
                                onPressed: _isSelectionMode
                                    ? null
                                    : () async {
                                        if (!isDone) {
                                          setState(
                                            () =>
                                                _animatingTaskIds.add(task.id),
                                          );
                                          // Wait for burst to happen a bit before fading
                                          await Future.delayed(
                                            const Duration(milliseconds: 350),
                                          );
                                          if (mounted) {
                                            setState(
                                              () => _fadingTaskIds.add(task.id),
                                            );
                                          }
                                          await Future.delayed(
                                            const Duration(milliseconds: 400),
                                          );
                                        }
                                        if (mounted) {
                                          appState.completeTask(
                                            task.id,
                                            onDate: pageDate,
                                          );
                                          setState(() {
                                            _animatingTaskIds.remove(task.id);
                                            _fadingTaskIds.remove(task.id);
                                          });
                                        }
                                      },
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
                                      : () =>
                                            _showMoveTaskDialog(context, task),
                                  tooltip: 'Move to another date',
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                              ),
                            ],
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
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                task.title,
                                style: TextStyle(
                                  decoration: isDone
                                      ? TextDecoration.lineThrough
                                      : null,
                                  color: isDone ? Colors.grey : null,
                                  fontWeight:
                                      (skill != null &&
                                          task.title == skill.name)
                                      ? FontWeight.w600
                                      : null,
                                  letterSpacing:
                                      (skill != null &&
                                          task.title == skill.name)
                                      ? 1.2
                                      : null,
                                ),
                              ),
                              if (task.time != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 2),
                                  child: Text(
                                    '${_getTimeLabel(task.time!)}, ${DateFormat('HH:mm').format(task.time!)}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isDone
                                          ? Colors.grey.withValues(alpha: 0.7)
                                          : colorScheme.onSurfaceVariant,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    trailing: !isDone
                        ? IconButton(
                            icon: Icon(
                              task.isStarred ? Icons.star : Icons.star_border,
                              color: task.isStarred
                                  ? Colors.amber
                                  : Colors.grey,
                            ),
                            onPressed: _isSelectionMode
                                ? null
                                : () => appState.toggleStar(task.id),
                          )
                        : null,
                  ),
                ),
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

  Future<DateTime?> _showCustomDatePicker(BuildContext context) async {
    final colorScheme = Theme.of(context).colorScheme;
    DateTime focusedDay = _selectedDate;
    DateTime? selectedDay = _selectedDate;

    return showDialog<DateTime>(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: 5,
                sigmaY: 5,
              ), // Reduced by 3x per request
              child: Dialog(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
                backgroundColor: colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.90,
                ), // Much less transparent
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Select Date',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 16),
                      AppCalendar(
                        focusedDay: focusedDay,
                        selectedDay: selectedDay,
                        onDaySelected: (selected, focused) {
                          Navigator.pop(dialogContext, selected);
                        },
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showAddTaskDialog(BuildContext context, [Task? taskToEdit]) {
    final titleController = TextEditingController(
      text: taskToEdit?.title ?? '',
    );
    final appState = Provider.of<AppState>(context, listen: false);

    // Initial skill selection
    String? selectedSkillId =
        taskToEdit?.skillId ?? appState.defaultSkillId ?? 'none';
    TimeOfDay? selectedTime = taskToEdit?.time != null
        ? TimeOfDay.fromDateTime(taskToEdit!.time!)
        : null;
    bool timeWasCleared = false;
    int selectedDifficulty = taskToEdit?.difficulty ?? 1;

    bool isSubmitting = false;

    void submitQuest() {
      if (isSubmitting) return;
      isSubmitting = true;
      if (selectedSkillId != null) {
        final skill = selectedSkillId == 'none'
            ? null
            : appState.skills.firstWhere((s) => s.id == selectedSkillId);
        final taskTitle = titleController.text.trim().isEmpty
            ? (skill?.name ?? 'New Quest')
            : titleController.text.trim();

        final taskDate = taskToEdit?.date ?? _selectedDate;
        final taskTime = selectedTime != null
            ? DateTime(
                taskDate.year,
                taskDate.month,
                taskDate.day,
                selectedTime!.hour,
                selectedTime!.minute,
              )
            : null;

        if (taskToEdit == null) {
          appState.addTask(
            taskTitle,
            selectedSkillId!,
            date: _selectedDate,
            time: taskTime,
            difficulty: selectedDifficulty,
          );
        } else {
          appState.updateTaskContent(
            taskToEdit.id,
            taskTitle,
            selectedSkillId!,
            date: taskDate,
            time: taskTime,
            clearTime: timeWasCleared,
            difficulty: selectedDifficulty,
          );
        }
        Navigator.pop(context);
      } else {
        isSubmitting = false;
      }
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Focus(
          onKeyEvent: (node, event) {
            if (event is KeyDownEvent) {
              if (event.logicalKey == LogicalKeyboardKey.escape) {
                Navigator.pop(context);
                return KeyEventResult.handled;
              }
              if (event.logicalKey == LogicalKeyboardKey.enter ||
                  event.logicalKey == LogicalKeyboardKey.numpadEnter) {
                submitQuest();
                return KeyEventResult.handled;
              }
            }
            return KeyEventResult.ignored;
          },
          child: AlertDialog(
            icon: const Icon(Icons.auto_awesome),
            title: Text(taskToEdit == null ? 'Accept New Quest' : 'Edit Quest'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  autofocus: true,
                  controller: titleController,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => submitQuest(),
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
                      items: [
                        const DropdownMenuItem(
                          value: 'none',
                          child: Row(
                            children: [
                              Text('📝', style: TextStyle(fontSize: 16)),
                              SizedBox(width: 12),
                              Text(
                                'None / General',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                        ...appState.skills.map((skill) {
                          return DropdownMenuItem(
                            value: skill.id,
                            child: Row(
                              children: [
                                Text(
                                  skill.icon,
                                  style: const TextStyle(fontSize: 16),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  skill.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                      onChanged: (value) =>
                          setDialogState(() => selectedSkillId = value),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Difficulty (1=20%, 5=100%)',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(5, (index) {
                    final diff = index + 1;
                    final isSelected = selectedDifficulty == diff;
                    final colorScheme = Theme.of(context).colorScheme;
                    return InkWell(
                      onTap: () =>
                          setDialogState(() => selectedDifficulty = diff),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? colorScheme.primary
                              : colorScheme.surfaceContainerHighest,
                          border: Border.all(
                            color: isSelected
                                ? colorScheme.primary
                                : Colors.transparent,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            '$diff',
                            style: TextStyle(
                              color: isSelected
                                  ? colorScheme.onPrimary
                                  : colorScheme.onSurface,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final TimeOfDay? picked = await showTimePicker(
                            context: context,
                            initialTime: selectedTime ?? TimeOfDay.now(),
                          );
                          if (picked != null) {
                            setDialogState(() {
                              selectedTime = picked;
                              timeWasCleared = false;
                            });
                          }
                        },
                        icon: const Icon(Icons.access_time_rounded, size: 18),
                        label: Text(
                          selectedTime == null
                              ? 'Add Time (Optional)'
                              : 'Time: ${selectedTime!.format(context)}',
                        ),
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    if (selectedTime != null) ...[
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.clear, color: Colors.grey),
                        onPressed: () {
                          setDialogState(() {
                            selectedTime = null;
                            timeWasCleared = true;
                          });
                        },
                        tooltip: 'Clear time',
                      ),
                    ],
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: submitQuest,
                child: Text(taskToEdit == null ? 'Accept Quest' : 'Save Quest'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CompletionBurst extends StatefulWidget {
  const CompletionBurst({super.key});

  @override
  State<CompletionBurst> createState() => _CompletionBurstState();
}

class _CompletionBurstState extends State<CompletionBurst>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(painter: BurstPainter(_controller.value));
      },
    );
  }
}

class BurstPainter extends CustomPainter {
  final double progress;
  BurstPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final colors = [Colors.blue, Colors.red, Colors.yellow[700]!, Colors.green];

    final paint = Paint()..strokeCap = StrokeCap.round;

    // Draw Checkmark
    final checkPaint = Paint()
      ..color = Colors.white.withValues(
        alpha: (1.0 - progress * 0.5).clamp(0.0, 1.0),
      )
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final checkPath = Path();
    // Centered checkmark relative to (0,0) after translation
    checkPath.moveTo(-6, 0);
    checkPath.lineTo(-2, 4);
    checkPath.lineTo(6, -4);

    canvas.save();
    canvas.translate(center.dx, center.dy);
    // Draw the checkmark
    canvas.drawPath(checkPath, checkPaint);

    for (int i = 0; i < 8; i++) {
      final double angle = (i * 45) * (math.pi / 180);
      final color = colors[i % colors.length];

      // Expand distance and length over progress
      final double startDist = 12 + progress * 15;
      final double length = 6 * (1.0 - progress);
      final double particleOpacity = (1.0 - progress).clamp(0.0, 1.0);

      paint.color = color.withValues(alpha: particleOpacity);
      paint.strokeWidth = 3.0 * (1.0 - progress);

      // Rotate and draw
      final cos = math.cos(angle);
      final sin = math.sin(angle);

      final p1 = Offset(startDist * cos, startDist * sin);
      final p2 = Offset((startDist + length) * cos, (startDist + length) * sin);

      canvas.drawLine(p1, p2, paint);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant BurstPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
