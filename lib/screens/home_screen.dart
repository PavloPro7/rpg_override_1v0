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
      key: ValueKey(_targetDateForTasks),
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

    return Scaffold(
      extendBody: true,
      body: _pages[_selectedIndex],
      bottomNavigationBar: _buildBottomNav(context, appState),
    );
  }

  Widget _buildBottomNav(BuildContext context, AppState appState) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(left: 12, right: 12, bottom: 24),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildNavPill(
              context,
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
              ],
            ),
            _buildNavPill(
              context,
              children: [
                _buildNavItem(
                  2,
                  Icons.today_outlined,
                  Icons.today,
                  'Quests',
                  appState,
                ),
              ],
            ),
            _buildNavPill(
              context,
              children: [
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
          ],
        ),
      ),
    );
  }

  Widget _buildNavPill(BuildContext context, {required List<Widget> children}) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Row(mainAxisSize: MainAxisSize.min, children: children),
    );
  }

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
        borderRadius: BorderRadius.circular(24),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? colorScheme.primary.withOpacity(0.12)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(24),
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
