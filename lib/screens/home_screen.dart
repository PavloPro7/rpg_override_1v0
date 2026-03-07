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
  DateTime? _targetDateForTasks;
  bool _cameFromDashboard = false;
  final GlobalKey<TodayTasksScreenState> _taskListKey =
      GlobalKey<TodayTasksScreenState>();

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
    DashboardScreen(
      onProfileTap: () => setState(() => _selectedIndex = 3),
      onDateSelected: (date) {
        setState(() {
          _targetDateForTasks = date;
          _cameFromDashboard = true;
          _selectedIndex = 2; // Tasks view
        });
      },
    ),
    SkillsScreen(onProfileTap: () => setState(() => _selectedIndex = 3)),
    TodayTasksScreen(
      key: _taskListKey,
      initialDate: _targetDateForTasks,
      showBackButton: _cameFromDashboard,
      onBackTap: () {
        setState(() {
          _cameFromDashboard = false;
          _selectedIndex = 0; // Dashboard view
        });
      },
      onProfileTap: () => setState(() {
        _cameFromDashboard = false;
        _selectedIndex = 3;
      }),
      onSettingsTap: () => setState(() {
        _cameFromDashboard = false;
        _selectedIndex = 4;
      }),
    ),
    const ProfileScreen(),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          _pages[_selectedIndex],
          // Gradient shadow (Moved from nav bar to body to avoid pushing FAB too high)
          Align(
            alignment: Alignment.bottomCenter,
            child: IgnorePointer(
              child: Container(
                height: 150,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      colorScheme.surface.withOpacity(0.0),
                      colorScheme.surface.withOpacity(0.6),
                      colorScheme.surface.withOpacity(0.9),
                      colorScheme.surface,
                    ],
                    stops: const [0.0, 0.4, 0.7, 1.0],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(context, appState),
      floatingActionButton: _selectedIndex == 2
          ? Padding(
              padding: const EdgeInsets.only(
                bottom: 2.0, // Reduced by 30px per request
                right: 8.0,
              ),
              child: FloatingActionButton(
                onPressed: () {
                  _taskListKey.currentState?.showAddTask();
                },
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                shape: const CircleBorder(),
                child: const Icon(Icons.add),
              ),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildBottomNav(BuildContext context, AppState appState) {
    final colorScheme = Theme.of(context).colorScheme;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(left: 16, right: 16, bottom: 24),
        child: Container(
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(100),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                0,
                Icons.dashboard_outlined,
                Icons.dashboard,
                'Stats',
                appState,
              ),
              _buildNavItem(
                1,
                Icons.bar_chart_outlined,
                Icons.bar_chart,
                'Skills',
                appState,
              ),
              _buildNavItem(
                2,
                Icons.today_outlined,
                Icons.today,
                'Quests',
                appState,
              ),
              _buildNavItem(
                4,
                Icons.settings_outlined,
                Icons.settings,
                'Settings',
                appState,
              ),
              _buildNavItem(
                3,
                Icons.person_outline_rounded,
                Icons.person_rounded,
                'Profile',
                appState,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Deprecated individual pills; now a unified pill.

  Widget _buildNavItem(
    int index,
    IconData icon,
    IconData selectedIcon,
    String label,
    AppState appState,
  ) {
    final isSelected = _selectedIndex == index;
    final colorScheme = Theme.of(context).colorScheme;

    Widget iconWidget;
    if (label == 'Profile' && appState.avatarUrl != null) {
      iconWidget = Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? colorScheme.primary : Colors.transparent,
            width: 2,
          ),
          image: DecorationImage(
            image: NetworkImage(appState.avatarUrl!),
            fit: BoxFit.cover,
          ),
        ),
      );
    } else if (label == 'Profile' && appState.avatarUrl == null) {
      iconWidget = Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: colorScheme.primaryContainer,
          border: Border.all(
            color: isSelected ? colorScheme.primary : Colors.transparent,
            width: 2,
          ),
        ),
        child: Icon(
          Icons.person_rounded,
          size: 16,
          color: colorScheme.onPrimaryContainer,
        ),
      );
    } else {
      iconWidget = Icon(
        isSelected ? selectedIcon : icon,
        color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2.0),
      child: InkWell(
        onTap: () {
          setState(() {
            _cameFromDashboard = false;
            _selectedIndex = index;
          });
        },
        borderRadius: BorderRadius.circular(100),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ), // Perfect circular/pill dimension
          decoration: BoxDecoration(
            color: isSelected
                ? colorScheme.primary.withOpacity(0.12)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(100),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              iconWidget,
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: isSelected
                      ? colorScheme.primary
                      : colorScheme.onSurfaceVariant,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
