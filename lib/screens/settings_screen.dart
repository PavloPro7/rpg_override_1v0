import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../utils/skill_dialog_utils.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final isDark =
        appState.themeMode == ThemeMode.dark ||
        (appState.themeMode == ThemeMode.system &&
            MediaQuery.of(context).platformBrightness == Brightness.dark);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings'), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // Appearance Box
            _buildSectionCard(context, 'Appearance', [
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Dark Mode'),
                subtitle: const Text('Switch between light and dark themes'),
                secondary: Icon(isDark ? Icons.dark_mode : Icons.light_mode),
                value: isDark,
                onChanged: (value) {
                  appState.toggleTheme(value);
                },
              ),
            ]),
            const SizedBox(height: 24),

            // Profile Settings Box
            _buildSectionCard(context, 'Profile Settings', [
              _buildActionRow(
                context,
                Icons.edit_rounded,
                'Edit Profile',
                () => _showEditProfileDialog(context, appState),
              ),
              const SizedBox(height: 16),
              _buildActionRow(
                context,
                Icons.email_outlined,
                'Change E-mail',
                appState.isAnonymous
                    ? null
                    : () => _showChangeEmailDialog(context, appState),
              ),
              const SizedBox(height: 16),
              _buildActionRow(
                context,
                Icons.lock_outline_rounded,
                'Change Password',
                appState.isAnonymous
                    ? null
                    : () => _showChangePasswordDialog(context, appState),
              ),
            ]),
            const SizedBox(height: 24),

            // Skill Management Box
            _buildSectionCard(context, 'Skill Management', [
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(
                  Icons.add_task_rounded,
                  color: Colors.green,
                ),
                title: const Text('Add New Skill'),
                onTap: () => SkillDialogUtils.showSkillDialog(context),
              ),
              const Divider(height: 32),
              ...appState.skills.map(
                (skill) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Text(
                    skill.icon,
                    style: const TextStyle(fontSize: 20),
                  ),
                  title: Text(skill.name),
                  subtitle: Text(skill.category),
                  trailing: IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 20),
                    onPressed: () =>
                        SkillDialogUtils.showSkillDialog(context, skill: skill),
                  ),
                ),
              ),
            ]),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard(
    BuildContext context,
    String title,
    List<Widget> children,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildActionRow(
    BuildContext context,
    IconData icon,
    String label,
    VoidCallback? onTap, {
    bool isDestructive = false,
  }) {
    final color = isDestructive
        ? Colors.redAccent
        : (onTap == null
              ? Theme.of(
                  context,
                ).colorScheme.onSurfaceVariant.withValues(alpha: 0.4)
              : null);

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
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: onTap == null ? color : null,
              ),
          ],
        ),
      ),
    );
  }

  void _showChangeEmailDialog(BuildContext context, AppState appState) {
    final emailController = TextEditingController();
    bool isLoading = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Change E-mail'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Enter your new e-mail address. A verification link will be sent before the change takes effect.',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: emailController,
                enabled: !isLoading,
                decoration: const InputDecoration(
                  labelText: 'New E-mail',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
            ],
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
                      final email = emailController.text.trim();
                      if (email.isEmpty || !email.contains('@')) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please enter a valid e-mail'),
                          ),
                        );
                        return;
                      }

                      setDialogState(() => isLoading = true);
                      final error = await appState.updateEmail(email);
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
                            const SnackBar(
                              content: Text('Verification sent to new e-mail!'),
                              backgroundColor: Colors.blueAccent,
                            ),
                          );
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
                  : const Text('Send Verification'),
            ),
          ],
        ),
      ),
    );
  }

  void _showChangePasswordDialog(BuildContext context, AppState appState) {
    final passController = TextEditingController();
    final confirmController = TextEditingController();
    bool isLoading = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Change Password'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: passController,
                enabled: !isLoading,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'New Password',
                  prefixIcon: Icon(Icons.lock_outline_rounded),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: confirmController,
                enabled: !isLoading,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Confirm New Password',
                  prefixIcon: Icon(Icons.lock_reset_rounded),
                ),
              ),
            ],
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
                      final pass = passController.text;
                      if (pass.length < 6) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Password must be at least 6 characters',
                            ),
                          ),
                        );
                        return;
                      }
                      if (pass != confirmController.text) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Passwords do not match'),
                          ),
                        );
                        return;
                      }

                      setDialogState(() => isLoading = true);
                      final error = await appState.updatePassword(pass);
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
                            const SnackBar(
                              content: Text('Password updated successfully!'),
                            ),
                          );
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
                  : const Text('Update'),
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
}
