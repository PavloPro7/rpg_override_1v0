import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import 'settings_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    final totalTasks = appState.tasks.length;
    final completedTasks = appState.tasks.where((t) => t.isCompleted).length;
    final progress = totalTasks > 0 ? completedTasks / totalTasks : 0.0;

    final highestLevelSkill = appState.skills.isNotEmpty
        ? appState.skills.reduce(
            (curr, next) => curr.level > next.level ? curr : next,
          )
        : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSummaryCard(
              context,
              'Overall Progress',
              '${(progress * 100).toStringAsFixed(1)}%',
              Icons.trending_up,
              Theme.of(context).colorScheme.primary,
              progress,
            ),
            const SizedBox(height: 24),
            const Text(
              'Skills Overview',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: appState.skills.length,
                itemBuilder: (context, index) {
                  final skill = appState.skills[index];
                  return _buildCompactSkillCard(context, skill);
                },
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    context,
                    'Quests',
                    '$completedTasks / $totalTasks',
                    Icons.task_alt,
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 8),
                if (highestLevelSkill != null)
                  Expanded(
                    child: _buildStatCard(
                      context,
                      'Top Rank',
                      highestLevelSkill.name,
                      Icons.star,
                      Colors.orange,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              'Recent Activity',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (appState.tasks.isEmpty)
              const Text('No activity yet. Start a quest!')
            else
              ...appState.tasks.reversed.take(5).map((task) {
                final skill = appState.skills.firstWhere(
                  (s) => s.id == task.skillId,
                );
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    task.isCompleted
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                    color: skill.color,
                  ),
                  title: Text(task.title),
                  subtitle: Text(skill.name),
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactSkillCard(BuildContext context, dynamic skill) {
    return Container(
      width: 100,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: skill.color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: skill.color.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            skill.name,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text('Lvl ${skill.level}', style: const TextStyle(fontSize: 10)),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: skill.progressInLevel,
              backgroundColor: Colors.grey[300],
              color: skill.color,
              minHeight: 4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
    double progress,
  ) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 60,
                  height: 60,
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 8,
                    backgroundColor: Colors.grey[200],
                    color: color,
                  ),
                ),
                Icon(icon, color: color, size: 30),
              ],
            ),
            const SizedBox(width: 20),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(
          title,
          style: TextStyle(color: Colors.grey[600], fontSize: 14),
        ),
        subtitle: Text(
          value,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
