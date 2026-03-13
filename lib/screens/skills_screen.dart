import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../models/skill.dart';
import '../utils/skill_dialog_utils.dart';
import 'settings_screen.dart';

class SkillsScreen extends StatelessWidget {
  final VoidCallback? onProfileTap;
  const SkillsScreen({super.key, this.onProfileTap});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Character Skills'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.settings),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const SettingsScreen()),
          ),
        ),
        actions: [
          IconButton.filledTonal(
            icon: const Icon(Icons.library_add_rounded),
            onPressed: () => SkillDialogUtils.showSkillDialog(context),
          ),
          const SizedBox(width: 8),
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: InkWell(
              onTap: onProfileTap,
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
      body: ListView.builder(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 8,
          bottom: 120 + MediaQuery.of(context).padding.bottom, // Added clearance for tap bar
        ),
        itemCount: appState.skills.length,
        itemBuilder: (context, index) {
          final skill = appState.skills[index];
          return GestureDetector(
            onLongPress: () => _showSkillOptionsBottomSheet(context, skill),
            child: SkillCard(skill: skill),
          );
        },
      ),
    );
  }

  void _showSkillOptionsBottomSheet(BuildContext context, Skill skill) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Edit Skill'),
                onTap: () {
                  Navigator.pop(context); // Close bottom sheet
                  SkillDialogUtils.showSkillDialog(
                    context,
                    skill: skill,
                  ); // Open edit dialog
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_forever, color: Colors.red),
                title: const Text(
                  'Delete Skill',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () {
                  Navigator.pop(context); // Close bottom sheet
                  Provider.of<AppState>(
                    context,
                    listen: false,
                  ).removeSkill(skill.id);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${skill.name} deleted')),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

void _showRecentTasksBottomSheet(BuildContext context, Skill skill) {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) {
      return DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(skill.icon, style: const TextStyle(fontSize: 24)),
                    const SizedBox(width: 12),
                    Text(
                      'Recent ${skill.name} Quests',
                      style: const TextStyle(
                        fontSize: 20, 
                        fontWeight: FontWeight.bold
                      ),
                    ),
                  ],
                ),
                const Divider(height: 32),
                Expanded(
                  child: FutureBuilder<QuerySnapshot>(
                    future: FirebaseFirestore.instance
                        .collection('users')
                        .doc(user.uid)
                        .collection('tasks')
                        .where('skillId', isEqualTo: skill.id)
                        .where('isCompleted', isEqualTo: true)
                        .get()
                        .then((QuerySnapshot snapshot) {
                      // We sort locally to avoid needing a Firebase Composite Index
                      final docs = snapshot.docs.toList();
                      docs.sort((a, b) {
                        try {
                          final dataA = a.data() as Map<String, dynamic>;
                          final dataB = b.data() as Map<String, dynamic>;
                          final dateA = DateTime.parse(dataA['date']);
                          final dateB = DateTime.parse(dataB['date']);
                          return dateB.compareTo(dateA); // Descending
                        } catch (e) {
                          return 0;
                        }
                      });

                      // Apply limit locally
                      if (docs.length > 10) {
                        docs.removeRange(10, docs.length);
                      }
                      
                      // Return a constructed snapshot-like list wrapper for simplicity in builder
                      return snapshot;
                    }),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      
                      if (snapshot.hasError) {
                        return Center(
                          child: Text(
                            'Error loading tasks: ${snapshot.error}',
                            style: const TextStyle(color: Colors.red),
                            textAlign: TextAlign.center,
                          ),
                        );
                      }
                      
                      // Grab the globally sorted docs we cached from the future or fallback to original snapshot
                      List<QueryDocumentSnapshot> sortedDocs = [];
                      if (snapshot.hasData) {
                          sortedDocs = snapshot.data!.docs.toList();
                          sortedDocs.sort((a, b) {
                              try {
                                final dataA = a.data() as Map<String, dynamic>;
                                final dataB = b.data() as Map<String, dynamic>;
                                final dateA = DateTime.parse(dataA['date']);
                                final dateB = DateTime.parse(dataB['date']);
                                return dateB.compareTo(dateA); // Descending
                              } catch (e) {
                                return 0;
                              }
                            });
                            
                            if (sortedDocs.length > 10) {
                                sortedDocs = sortedDocs.sublist(0, 10);
                            }
                      }
                      
                      if (!snapshot.hasData || sortedDocs.isEmpty) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(24.0),
                            child: Text(
                              'No tasks completed for this skill yet. Time to get to work! 💪',
                              style: TextStyle(
                                fontSize: 16, 
                                color: Colors.grey
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        );
                      }

                      return ListView.builder(
                        controller: scrollController,
                        itemCount: sortedDocs.length,
                        itemBuilder: (context, index) {
                          final data = sortedDocs[index].data() as Map<String, dynamic>;
                          final title = data['title'] ?? 'Unnamed Task';
                          
                          return ListTile(
                            leading: const Icon(
                                Icons.check_circle, 
                                color: Colors.green
                            ),
                            title: Text(title),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}

class SkillCard extends StatelessWidget {
  final Skill skill;

  const SkillCard({super.key, required this.skill});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      borderRadius: BorderRadius.circular(28),
      onTap: () => _showRecentTasksBottomSheet(context, skill),
      child: Card(
        elevation: 2,
        shadowColor: colorScheme.onSurface.withValues(alpha: 0.05),
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        margin: const EdgeInsets.only(bottom: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
          side: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            skill.icon,
                            style: const TextStyle(fontSize: 20),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              skill.name,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                letterSpacing: -0.5,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: skill.color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: skill.color.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Text(
                    'Level ${skill.level}',
                    style: TextStyle(
                      color: skill.color,
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: skill.progressInLevel,
                    minHeight: 20,
                    backgroundColor: colorScheme.outlineVariant.withValues(
                      alpha: 0.3,
                    ),
                    color: skill.color,
                  ),
                ),
                Positioned.fill(
                  child: Center(
                    child: Text(
                      '${(skill.progressInLevel * 100).toInt()}% OF LEVEL',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        ),
      ),
    );
  }
}
