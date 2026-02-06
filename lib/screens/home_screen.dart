import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import 'dashboard_screen.dart';
import 'skills_screen.dart';
import 'task_list.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  static const List<Widget> _pages = [
    DashboardScreen(),
    TodayTasksScreen(),
    SkillsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.today), label: 'Today'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Skills'),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddTaskDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddTaskDialog(BuildContext context) {
    final titleController = TextEditingController();
    String? selectedSkillId;
    final appState = Provider.of<AppState>(context, listen: false);
    selectedSkillId = appState.skills.first.id;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('New Quest'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Quest Title'),
              ),
              const SizedBox(height: 16),
              DropdownButton<String>(
                value: selectedSkillId,
                isExpanded: true,
                items: appState.skills.map((skill) {
                  return DropdownMenuItem(
                    value: skill.id,
                    child: Text(skill.name),
                  );
                }).toList(),
                onChanged: (value) =>
                    setDialogState(() => selectedSkillId = value),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (titleController.text.isNotEmpty &&
                    selectedSkillId != null) {
                  appState.addTask(titleController.text, selectedSkillId!);
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
