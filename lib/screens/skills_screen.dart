import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../models/skill.dart';
import '../utils/skill_dialog_utils.dart';
import 'settings_screen.dart';

class SkillsScreen extends StatefulWidget {
  final VoidCallback? onProfileTap;
  const SkillsScreen({super.key, this.onProfileTap});

  @override
  State<SkillsScreen> createState() => _SkillsScreenState();
}

class _SkillsScreenState extends State<SkillsScreen> {
  Skill? selectedSkill;

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: selectedSkill != null
          ? AppBar(
              leading: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  setState(() {
                    selectedSkill = null;
                  });
                },
              ),
              title: const Text('1'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () {
                    final skillToEdit = selectedSkill!;
                    setState(() {
                      selectedSkill = null;
                    });
                    SkillDialogUtils.showSkillDialog(
                      context,
                      skill: skillToEdit,
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete_forever, color: Colors.red),
                  onPressed: () {
                    final skillToDelete = selectedSkill!;
                    setState(() {
                      selectedSkill = null;
                    });
                    Provider.of<AppState>(
                      context,
                      listen: false,
                    ).removeSkill(skillToDelete.id);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('${skillToDelete.name} deleted')),
                    );
                  },
                ),
              ],
            )
          : AppBar(
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
                    onTap: widget.onProfileTap,
                    child: CircleAvatar(
                      radius: 18,
                      backgroundColor: colorScheme.primaryContainer,
                      backgroundImage: appState.avatarUrl != null
                          ? NetworkImage(appState.avatarUrl!, headers: const {})
                          : null,
                      onBackgroundImageError: appState.avatarUrl != null
                          ? (e, s) {}
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
          final isSelected = selectedSkill?.id == skill.id;

          return SkillCard(
            skill: skill,
            isSelected: isSelected,
            onLongPress: () {
              setState(() {
                selectedSkill = skill;
              });
            },
            onTap: () {
              if (selectedSkill != null) {
                // Toggle selection if in selection mode
                setState(() {
                  selectedSkill = isSelected ? null : skill;
                });
              } else {
                // Show recent tasks
                _showRecentTasksBottomSheet(context, skill);
              }
            },
          );
        },
      ),
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
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const SkillCard({
    super.key, 
    required this.skill,
    required this.isSelected,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      borderRadius: BorderRadius.circular(28),
      onTap: onTap,
      onLongPress: onLongPress,
      child: Card(
        elevation: isSelected ? 8 : 2,
        shadowColor: colorScheme.onSurface.withValues(alpha: 0.05),
        color: isSelected 
            ? colorScheme.primaryContainer 
            : colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        margin: const EdgeInsets.only(bottom: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
          side: BorderSide(
            color: isSelected 
                ? colorScheme.primary 
                : colorScheme.outlineVariant.withValues(alpha: 0.5),
            width: isSelected ? 2 : 1,
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
