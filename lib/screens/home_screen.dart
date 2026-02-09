import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../widgets/verification_dialog.dart';
import 'dashboard_screen.dart';
import 'skills_screen.dart';
import 'task_list.dart';
import 'profile_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  Timer? _verificationTimer;

  @override
  void initState() {
    super.initState();
    _startVerificationTimer();
  }

  @override
  void dispose() {
    _verificationTimer?.cancel();
    super.dispose();
  }

  void _startVerificationTimer() {
    final appState = context.read<AppState>();
    if (appState.isAuthenticated &&
        !appState.isAnonymous &&
        !appState.isEmailVerified) {
      _verificationTimer = Timer(const Duration(seconds: 30), () {
        if (mounted && !appState.isEmailVerified) {
          VerificationDialog.show(context);
        }
      });
    }
  }

  List<Widget> get _pages => [
    DashboardScreen(onProfileTap: () => setState(() => _selectedIndex = 3)),
    SkillsScreen(onProfileTap: () => setState(() => _selectedIndex = 3)),
    TodayTasksScreen(
      onProfileTap: () => setState(() => _selectedIndex = 3),
      onSettingsTap: () => setState(() => _selectedIndex = 4),
    ),
    const ProfileScreen(),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 5.0,
        child: Row(
          children: [
            Expanded(
              child: _buildNavItem(
                0,
                Icons.dashboard_outlined,
                Icons.dashboard,
                'Stats',
              ),
            ),
            Expanded(
              child: _buildNavItem(
                1,
                Icons.bar_chart_outlined,
                Icons.bar_chart,
                'Skills',
              ),
            ),
            const SizedBox(width: 72), // Centered spacing for the FAB
            Expanded(
              child: _buildNavItem(
                3,
                Icons.person_outline_rounded,
                Icons.person_rounded,
                'Profile',
              ),
            ),
            Expanded(
              child: _buildNavItem(
                4,
                Icons.settings_outlined,
                Icons.settings,
                'Settings',
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => setState(() => _selectedIndex = 2),
        backgroundColor: _selectedIndex == 2
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.primaryContainer,
        foregroundColor: _selectedIndex == 2
            ? Theme.of(context).colorScheme.onPrimary
            : Theme.of(context).colorScheme.onPrimaryContainer,
        child: const Icon(Icons.today),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Widget _buildNavItem(
    int index,
    IconData icon,
    IconData selectedIcon,
    String label,
  ) {
    final isSelected = _selectedIndex == index;
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: () => setState(() => _selectedIndex = index),
      borderRadius: BorderRadius.circular(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isSelected ? selectedIcon : icon,
            color: isSelected
                ? colorScheme.primary
                : colorScheme.onSurfaceVariant,
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isSelected
                  ? colorScheme.primary
                  : colorScheme.onSurfaceVariant,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
