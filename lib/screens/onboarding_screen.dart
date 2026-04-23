import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
class _SkillConfig {
  String icon;
  Color color = Colors.blue;
  int startLevel = 1;

  _SkillConfig({required this.icon});
}

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  bool _isLoading = false;
  int _currentStep = 0;
  String? _selectedAvatarUrl;

  static const List<Map<String, String>> _presetSkills = [
    {'name': 'Programming', 'icon': '💻'},
    {'name': 'English', 'icon': '🇬🇧'},
    {'name': 'Sport', 'icon': '🏃'},
    {'name': 'Education', 'icon': '📚'},
    {'name': 'Strength', 'icon': '💪'},
    {'name': 'Drawing', 'icon': '🎨'},
    {'name': 'Art', 'icon': '🎭'},
    {'name': 'Business', 'icon': '💼'},
    {'name': 'Work', 'icon': '🔧'},
    {'name': 'Cooking', 'icon': '🍳'},
    {'name': 'Music', 'icon': '🎵'},
    {'name': 'Reading', 'icon': '📖'},
  ];

  final Set<String> _selectedPresets = {};
  final List<Map<String, String>> _customSkills = [];
  final Map<String, _SkillConfig> _skillConfigs = {};

  void _ensureConfig(String name, String defaultIcon) {
    _skillConfigs.putIfAbsent(name, () => _SkillConfig(icon: defaultIcon));
  }

  void _nextStep() {
    final name = _nameController.text.trim();
    final age = int.tryParse(_ageController.text.trim()) ?? 0;

    if (name.isEmpty || age <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Please enter a valid Hero Name and Age"),
          backgroundColor: Colors.orangeAccent,
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.only(
            left: 16,
            right: 16,
            bottom: 16 + MediaQuery.of(context).padding.bottom,
          ),
        ),
      );
      return;
    }
    setState(() => _currentStep = 1);
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    final age = int.tryParse(_ageController.text.trim()) ?? 0;

    setState(() => _isLoading = true);
    final appState = context.read<AppState>();

    final error = await appState.updateProfile(name, age, _selectedAvatarUrl ?? appState.avatarUrl);

    if (mounted && error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.only(
            left: 16,
            right: 16,
            bottom: 16 + MediaQuery.of(context).padding.bottom,
          ),
        ),
      );
    }

    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _submitWithSkills() async {
    setState(() => _isLoading = true);
    final appState = context.read<AppState>();

    final name = _nameController.text.trim();
    final age = int.tryParse(_ageController.text.trim()) ?? 0;
    final error = await appState.updateProfile(name, age, _selectedAvatarUrl ?? appState.avatarUrl);

    if (error != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: Colors.redAccent),
      );
      setState(() => _isLoading = false);
      return;
    }

    for (final entry in _skillConfigs.entries) {
      final config = entry.value;
      await appState.addSkill(
        entry.key,
        config.color,
        config.startLevel,
        config.icon,
      );
    }

    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _skipToDefaultAndSubmit() async {
    await _submit();
  }

  void _showAddCustomSkillDialog(ColorScheme colorScheme) {
    final controller = TextEditingController();
    final iconController = TextEditingController(text: '⭐');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Custom Skill'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Skill Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: iconController,
              decoration: const InputDecoration(
                labelText: 'Emoji Icon',
                border: OutlineInputBorder(),
                hintText: '💪',
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final name = controller.text.trim();
              final icon = iconController.text.trim().isEmpty
                  ? '⭐'
                  : iconController.text.trim();
              if (name.isNotEmpty) {
                setState(() {
                  _customSkills.add({'name': name, 'icon': icon});
                  _ensureConfig(name, icon);
                });
                Navigator.pop(ctx);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          // Base Gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  colorScheme.surface,
                  colorScheme.primaryContainer.withValues(alpha: 0.1),
                ],
              ),
            ),
          ),

          // Abstract Blobs
          Positioned(
            top: -100,
            right: -50,
            child: _buildBlob(250, colorScheme.primary.withValues(alpha: 0.15)),
          ),
          Positioned(
            bottom: -50,
            left: -100,
            child: _buildBlob(
              300,
              colorScheme.secondary.withValues(alpha: 0.15),
            ),
          ),
          Positioned(
            top: size.height * 0.4,
            right: -100,
            child: _buildBlob(
              200,
              colorScheme.tertiary.withValues(alpha: 0.1),
            ),
          ),

          // Glassmorphism Blur
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
              child: Container(color: Colors.transparent),
            ),
          ),

          // Content
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: AutofillGroup(
                  child: Card(
                    elevation: 0,
                    color: colorScheme.surface.withValues(alpha: 0.7),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(32),
                      side: BorderSide(
                        color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: _currentStep == 0
                            ? _buildStepOne(colorScheme)
                            : _currentStep == 1
                                ? _buildStepSkillPicker(colorScheme)
                                : _buildStepSkillCustomize(colorScheme),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepOne(ColorScheme colorScheme) {
    return Column(
      key: const ValueKey(0),
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorScheme.primary.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.manage_accounts_rounded,
            size: 48,
            color: colorScheme.primary,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Customize Hero',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w900,
                color: colorScheme.onSurface,
                letterSpacing: -0.5,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'We need a few details to forge your adventure',
          textAlign: TextAlign.center,
          style: TextStyle(color: colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 32),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          alignment: WrapAlignment.center,
          children: [
            'https://api.dicebear.com/7.x/pixel-art/png?seed=Warrior',
            'https://api.dicebear.com/7.x/pixel-art/png?seed=Mage',
            'https://api.dicebear.com/7.x/pixel-art/png?seed=Rogue',
            'https://api.dicebear.com/7.x/pixel-art/png?seed=Cleric',
            'https://api.dicebear.com/7.x/pixel-art/png?seed=Paladin',
          ].map((url) {
            final isSelected = _selectedAvatarUrl == url;
            return GestureDetector(
              onTap: () => setState(() => _selectedAvatarUrl = url),
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected
                        ? colorScheme.primary
                        : Colors.transparent,
                    width: 3,
                  ),
                ),
                child: CircleAvatar(
                  radius: 28,
                  backgroundImage: NetworkImage(url),
                  onBackgroundImageError: (e, s) {},
                  backgroundColor: Colors.transparent,
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 8),
        _buildTextField(
          controller: _nameController,
          label: 'Hero Name',
          icon: Icons.badge_outlined,
          autofillHints: [AutofillHints.name],
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _ageController,
          label: 'Age',
          icon: Icons.cake_outlined,
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _nextStep(),
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: FilledButton(
            onPressed: _nextStep,
            style: FilledButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
            child: const Text(
              'Next',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStepSkillPicker(ColorScheme colorScheme) {
    return Column(
      key: const ValueKey(1),
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorScheme.secondary.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.psychology_rounded, size: 48, color: colorScheme.secondary),
        ),
        const SizedBox(height: 24),
        Text(
          'Choose Skills',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w900,
                color: colorScheme.onSurface,
                letterSpacing: -0.5,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'Pick skills you want to track, or add your own.',
          textAlign: TextAlign.center,
          style: TextStyle(color: colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 4),
        Text(
          'You can edit this later in settings.',
          style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 12),
        ),
        const SizedBox(height: 24),

        // Preset skill chips
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: _presetSkills.map((skill) {
            final isSelected = _selectedPresets.contains(skill['name']);
            return FilterChip(
              label: Text(skill['name']!),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedPresets.add(skill['name']!);
                    _ensureConfig(skill['name']!, skill['icon']!);
                  } else {
                    _selectedPresets.remove(skill['name']!);
                    _skillConfigs.remove(skill['name']!);
                  }
                });
              },
              avatar: isSelected
                  ? null
                  : Text(skill['icon']!, style: const TextStyle(fontSize: 14)),
              selectedColor: colorScheme.primaryContainer,
              checkmarkColor: colorScheme.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            );
          }).toList(),
        ),

        // Custom skills if any
        if (_customSkills.isNotEmpty) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: _customSkills.map((skill) {
              return Chip(
                label: Text(skill['name']!),
                avatar: Text(skill['icon']!, style: const TextStyle(fontSize: 14)),
                deleteIcon: const Icon(Icons.close, size: 16),
                onDeleted: () {
                  setState(() {
                    _customSkills.remove(skill);
                    _skillConfigs.remove(skill['name']!);
                  });
                },
              );
            }).toList(),
          ),
        ],

        const SizedBox(height: 16),
        const Text('OR', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),

        // Add custom skill button
        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton.icon(
            onPressed: () => _showAddCustomSkillDialog(colorScheme),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add a custom skill'),
            style: OutlinedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),

        const SizedBox(height: 24),

        // Bottom buttons row
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => _skipToDefaultAndSubmit(),
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Start with default'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton(
                onPressed: (_selectedPresets.isNotEmpty || _customSkills.isNotEmpty)
                    ? () => setState(() => _currentStep = 2)
                    : null,
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Save skills'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStepSkillCustomize(ColorScheme colorScheme) {
    final allSkills = [
      ..._selectedPresets.map((name) {
        final preset = _presetSkills.firstWhere((s) => s['name'] == name);
        return {'name': name, 'icon': preset['icon']!};
      }),
      ..._customSkills,
    ];

    final List<Color> colorPresets = [
      Colors.blue,
      Colors.indigo,
      Colors.purple,
      Colors.pink,
      Colors.red,
      Colors.deepOrange,
      Colors.orange,
      Colors.amber,
      Colors.yellow,
      Colors.lime,
      Colors.green,
      Colors.teal,
      Colors.cyan,
      Colors.blueGrey,
      Colors.brown,
      Colors.grey,
    ];

    return Column(
      key: const ValueKey(2),
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorScheme.tertiary.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.tune_rounded, size: 48, color: colorScheme.tertiary),
        ),
        const SizedBox(height: 24),
        Text(
          'Customize Skills',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w900,
                color: colorScheme.onSurface,
                letterSpacing: -0.5,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'Set icon, color and starting level for each skill.',
          textAlign: TextAlign.center,
          style: TextStyle(color: colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 24),

        // List of skills to customize
        ...allSkills.map((skill) {
          final name = skill['name']!;
          final config = _skillConfigs[name]!;

          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: config.color.withValues(alpha: 0.5)),
                color: config.color.withValues(alpha: 0.05),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Skill name with icon
                  Row(
                    children: [
                      Text(config.icon, style: const TextStyle(fontSize: 24)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Icon row
                  Row(
                    children: [
                      const Text('Icon: ', style: TextStyle(fontSize: 12)),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 50,
                        child: TextField(
                          controller: TextEditingController(text: config.icon),
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 20),
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(vertical: 4),
                            isDense: true,
                          ),
                          onChanged: (val) {
                            setState(() => config.icon = val.isEmpty ? '⭐' : val);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Color carousel — separate row below the icon row
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Color:', style: TextStyle(fontSize: 12)),
                      const SizedBox(height: 6),
                      SizedBox(
                        height: 36,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: colorPresets.length,
                          separatorBuilder: (context, index) => const SizedBox(width: 8),
                          itemBuilder: (context, colorIndex) {
                            final color = colorPresets[colorIndex];
                            final isSelected = config.color == color;
                            return GestureDetector(
                              onTap: () => setState(() => config.color = color),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                width: isSelected ? 32 : 28,
                                height: isSelected ? 32 : 28,
                                decoration: BoxDecoration(
                                  color: color,
                                  shape: BoxShape.circle,
                                  border: isSelected
                                      ? Border.all(color: Colors.white, width: 2.5)
                                      : Border.all(color: Colors.transparent, width: 2.5),
                                  boxShadow: isSelected
                                      ? [BoxShadow(color: color.withValues(alpha: 0.6), blurRadius: 6, spreadRadius: 1)]
                                      : null,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Starting level
                  Row(
                    children: [
                      const Text('Starting Level: ', style: TextStyle(fontSize: 12)),
                      Text(
                        '${config.startLevel}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Expanded(
                        child: Slider(
                          value: config.startLevel.toDouble(),
                          min: 1,
                          max: 50,
                          divisions: 49,
                          label: config.startLevel.toString(),
                          onChanged: (val) =>
                              setState(() => config.startLevel = val.toInt()),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }),

        const SizedBox(height: 16),

        // Bottom buttons
        Row(
          children: [
            TextButton(
              onPressed: () => setState(() => _currentStep = 1),
              child: const Text('Back'),
            ),
            const Spacer(),
            FilledButton(
              onPressed: _isLoading ? null : _submitWithSkills,
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Begin Adventure',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBlob(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    Iterable<String>? autofillHints,
    TextInputAction? textInputAction,
    ValueChanged<String>? onSubmitted,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      autofillHints: autofillHints,
      textInputAction: textInputAction,
      onSubmitted: onSubmitted,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 22),
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
        ),
        floatingLabelStyle: TextStyle(
          color: colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
