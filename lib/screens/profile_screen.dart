import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/app_state.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final appState = context.watch<AppState>();
    final user = appState.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile'), centerTitle: true),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 32),
            CircleAvatar(
              radius: 60,
              backgroundColor: colorScheme.primaryContainer,
              backgroundImage: appState.avatarUrl != null
                  ? NetworkImage(appState.avatarUrl!)
                  : null,
              child: appState.avatarUrl == null
                  ? Icon(
                      Icons.person_rounded,
                      size: 64,
                      color: colorScheme.onPrimaryContainer,
                    )
                  : null,
            ),
            const SizedBox(height: 24),
            Text(
              appState.userName ??
                  user?.email?.split('@')[0] ??
                  'Hero Candidate',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            if (appState.userAge != null)
              Text(
                'Age: ${appState.userAge}',
                style: TextStyle(
                  fontSize: 16,
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
            Text(
              user?.email ?? 'anonymous@rpg.life',
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 32),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Card(
                elevation: 0,
                color: colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.3,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      _buildInfoRow(
                        context,
                        Icons.calendar_today_rounded,
                        'Date of Start',
                        appState.registrationDate != null
                            ? DateFormat(
                                'MMM dd, yyyy',
                              ).format(appState.registrationDate!)
                            : 'Authenticating...',
                      ),
                      const Divider(height: 32),
                      _buildActionRow(
                        context,
                        Icons.edit_rounded,
                        'Edit Profile',
                        () => _showEditProfileDialog(context, appState),
                      ),
                      const Divider(height: 32),
                      _buildActionRow(
                        context,
                        Icons.email_outlined,
                        'Change E-mail',
                        () {},
                      ),
                      const SizedBox(height: 16),
                      _buildActionRow(
                        context,
                        Icons.lock_outline_rounded,
                        'Change Password',
                        () {},
                      ),
                      const Divider(height: 32),
                      _buildActionRow(
                        context,
                        Icons.logout_rounded,
                        'Logout Account',
                        () => appState.signOut(),
                        isDestructive: true,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'Infrastructure Ready for Auth',
              style: TextStyle(
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditProfileDialog(BuildContext context, AppState appState) {
    final nameController = TextEditingController(text: appState.userName);
    final ageController = TextEditingController(
      text: appState.userAge?.toString() ?? '',
    );
    String? selectedAvatar = appState.avatarUrl;
    bool isLoading = false;

    final avatars = [
      'https://api.dicebear.com/7.x/pixel-art/png?seed=Warrior',
      'https://api.dicebear.com/7.x/pixel-art/png?seed=Mage',
      'https://api.dicebear.com/7.x/pixel-art/png?seed=Rogue',
      'https://api.dicebear.com/7.x/pixel-art/png?seed=Cleric',
      'https://api.dicebear.com/7.x/pixel-art/png?seed=Paladin',
    ];

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Edit Profile'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Choose Avatar',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  alignment: WrapAlignment.center,
                  children: avatars.map((url) {
                    final isSelected = selectedAvatar == url;
                    return GestureDetector(
                      onTap: isLoading
                          ? null
                          : () => setDialogState(() => selectedAvatar = url),
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected
                                ? Theme.of(context).colorScheme.primary
                                : Colors.transparent,
                            width: 3,
                          ),
                        ),
                        child: CircleAvatar(
                          radius: 28,
                          backgroundImage: NetworkImage(url),
                          backgroundColor: Colors.transparent,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: nameController,
                  enabled: !isLoading,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    prefixIcon: Icon(Icons.badge_outlined),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: ageController,
                  enabled: !isLoading,
                  decoration: const InputDecoration(
                    labelText: 'Age',
                    prefixIcon: Icon(Icons.cake_outlined),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: isLoading
                  ? null
                  : () async {
                      final name = nameController.text.trim();
                      final ageString = ageController.text.trim();
                      final age = int.tryParse(ageString) ?? 0;

                      if (name.isEmpty || age <= 0) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please enter valid details'),
                          ),
                        );
                        return;
                      }

                      setDialogState(() => isLoading = true);

                      try {
                        final error = await appState.updateProfile(
                          name,
                          age,
                          selectedAvatar,
                        );
                        if (context.mounted) {
                          if (error != null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(error),
                                backgroundColor: Colors.red,
                              ),
                            );
                            setDialogState(() => isLoading = false);
                          } else {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Profile updated!')),
                            );
                          }
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                          setDialogState(() => isLoading = false);
                        }
                      }
                    },
              child: isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 16),
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        const Spacer(),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildActionRow(
    BuildContext context,
    IconData icon,
    String label,
    VoidCallback onTap, {
    bool isDestructive = false,
  }) {
    final color = isDestructive ? Colors.redAccent : null;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 16),
            Text(
              label,
              style: TextStyle(fontWeight: FontWeight.w500, color: color),
            ),
            const Spacer(),
            if (!isDestructive)
              const Icon(Icons.chevron_right_rounded, size: 20),
          ],
        ),
      ),
    );
  }
}
