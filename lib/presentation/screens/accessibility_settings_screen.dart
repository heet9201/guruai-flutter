import 'package:flutter/material.dart';
import '../../core/accessibility/enhanced_accessibility_manager.dart';

class AccessibilitySettingsScreen extends StatefulWidget {
  const AccessibilitySettingsScreen({Key? key}) : super(key: key);

  @override
  State<AccessibilitySettingsScreen> createState() =>
      _AccessibilitySettingsScreenState();
}

class _AccessibilitySettingsScreenState
    extends State<AccessibilitySettingsScreen> {
  late EnhancedAccessibilityManager _accessibilityManager;

  @override
  void initState() {
    super.initState();
    _accessibilityManager = EnhancedAccessibilityManager.instance;
    _accessibilityManager.addListener(_onAccessibilityChanged);
  }

  @override
  void dispose() {
    _accessibilityManager.removeListener(_onAccessibilityChanged);
    super.dispose();
  }

  void _onAccessibilityChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Accessibility Settings',
          semanticsLabel: 'Accessibility Settings Screen',
        ),
        elevation: 0,
        centerTitle: false,
        actions: [
          Semantics(
            label: 'Reset all accessibility settings to defaults',
            child: IconButton(
              onPressed: _showResetDialog,
              icon: const Icon(Icons.refresh_rounded),
              tooltip: 'Reset to defaults',
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.accessibility_new_rounded,
                      size: 32,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Customize Sahayak for Your Needs',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Adjust settings to make the app more accessible and comfortable for your teaching needs.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Visual Settings
            _buildSection(
              title: 'Visual Settings',
              icon: Icons.visibility_rounded,
              children: [
                _buildThemeToggle(),
                const SizedBox(height: 16),
                _buildFontScaleSlider(),
                const SizedBox(height: 16),
                _buildIconScaleSlider(),
                const SizedBox(height: 16),
                _buildColorBlindSettings(),
              ],
            ),

            const SizedBox(height: 24),

            // Interaction Settings
            _buildSection(
              title: 'Interaction Settings',
              icon: Icons.touch_app_rounded,
              children: [
                _buildTooltipsToggle(),
                const SizedBox(height: 16),
                _buildSoundToggle(),
                const SizedBox(height: 16),
                _buildHapticToggle(),
              ],
            ),

            const SizedBox(height: 24),

            // Quick Actions
            _buildQuickActions(),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  size: 24,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildThemeToggle() {
    return Column(
      children: [
        // High Contrast Toggle
        SwitchListTile.adaptive(
          title: const Text('High Contrast Mode'),
          subtitle: Text(
            'Increases color contrast for better visibility',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
          ),
          value: _accessibilityManager.highContrastMode,
          onChanged: (_) => _accessibilityManager.toggleHighContrast(),
          secondary: Icon(
            Icons.contrast_rounded,
            color: Theme.of(context).colorScheme.primary,
          ),
          contentPadding: EdgeInsets.zero,
        ),

        const SizedBox(height: 8),

        // Blackboard Mode Toggle
        SwitchListTile.adaptive(
          title: const Text('Dark Blackboard Mode'),
          subtitle: Text(
            'Teacher-friendly dark theme with chalk-like aesthetics',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
          ),
          value: _accessibilityManager.blackboardMode,
          onChanged: (_) => _accessibilityManager.toggleBlackboardMode(),
          secondary: Icon(
            Icons.school_rounded,
            color: Theme.of(context).colorScheme.primary,
          ),
          contentPadding: EdgeInsets.zero,
        ),
      ],
    );
  }

  Widget _buildFontScaleSlider() {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Text Size',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Adjust text size for better readability',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Icon(
              Icons.text_decrease_rounded,
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
            Expanded(
              child: Slider.adaptive(
                value: _accessibilityManager.fontScale,
                min: 0.8,
                max: 2.0,
                divisions: 12,
                label: '${(_accessibilityManager.fontScale * 100).round()}%',
                onChanged: _accessibilityManager.setFontScale,
                semanticFormatterCallback: (value) =>
                    'Text size ${(value * 100).round()} percent',
              ),
            ),
            Icon(
              Icons.text_increase_rounded,
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ],
        ),
        Center(
          child: Text(
            '${(_accessibilityManager.fontScale * 100).round()}%',
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.primary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildIconScaleSlider() {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Icon Size',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Make icons larger for easier interaction',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Icon(
              Icons.photo_size_select_small_rounded,
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
            Expanded(
              child: Slider.adaptive(
                value: _accessibilityManager.iconScale,
                min: 0.8,
                max: 1.5,
                divisions: 7,
                label: '${(_accessibilityManager.iconScale * 100).round()}%',
                onChanged: _accessibilityManager.setIconScale,
                semanticFormatterCallback: (value) =>
                    'Icon size ${(value * 100).round()} percent',
              ),
            ),
            Icon(
              Icons.photo_size_select_large_rounded,
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ],
        ),
        Center(
          child: Text(
            '${(_accessibilityManager.iconScale * 100).round()}%',
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.primary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildColorBlindSettings() {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SwitchListTile.adaptive(
          title: const Text('Color Blind Support'),
          subtitle: Text(
            'Enhances color differentiation for color vision differences',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          value: _accessibilityManager.colorBlindMode,
          onChanged: (value) => _accessibilityManager.setColorBlindSupport(
            value,
            _accessibilityManager.colorBlindType,
          ),
          secondary: Icon(
            Icons.palette_rounded,
            color: theme.colorScheme.primary,
          ),
          contentPadding: EdgeInsets.zero,
        ),
        if (_accessibilityManager.colorBlindMode) ...[
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.only(left: 16),
            child: DropdownButtonFormField<String>(
              value: _accessibilityManager.colorBlindType,
              decoration: InputDecoration(
                labelText: 'Color Vision Type',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              items: const [
                DropdownMenuItem(value: 'none', child: Text('None')),
                DropdownMenuItem(
                    value: 'protanopia', child: Text('Protanopia (Red-Green)')),
                DropdownMenuItem(
                    value: 'deuteranopia',
                    child: Text('Deuteranopia (Red-Green)')),
                DropdownMenuItem(
                    value: 'tritanopia',
                    child: Text('Tritanopia (Blue-Yellow)')),
              ],
              onChanged: (value) {
                if (value != null) {
                  _accessibilityManager.setColorBlindSupport(true, value);
                }
              },
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildTooltipsToggle() {
    return SwitchListTile.adaptive(
      title: const Text('Show Tooltips'),
      subtitle: Text(
        'Display helpful hints and explanations',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
      ),
      value: _accessibilityManager.tooltipsEnabled,
      onChanged: (_) => _accessibilityManager.toggleTooltips(),
      secondary: Icon(
        Icons.help_outline_rounded,
        color: Theme.of(context).colorScheme.primary,
      ),
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildSoundToggle() {
    return SwitchListTile.adaptive(
      title: const Text('Sound Effects'),
      subtitle: Text(
        'Play sounds for actions and notifications',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
      ),
      value: _accessibilityManager.soundEnabled,
      onChanged: (_) => _accessibilityManager.toggleSound(),
      secondary: Icon(
        _accessibilityManager.soundEnabled
            ? Icons.volume_up_rounded
            : Icons.volume_off_rounded,
        color: Theme.of(context).colorScheme.primary,
      ),
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildHapticToggle() {
    return SwitchListTile.adaptive(
      title: const Text('Haptic Feedback'),
      subtitle: Text(
        'Feel vibrations for interactions and feedback',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
      ),
      value: _accessibilityManager.hapticEnabled,
      onChanged: (_) => _accessibilityManager.toggleHaptic(),
      secondary: Icon(
        Icons.vibration_rounded,
        color: Theme.of(context).colorScheme.primary,
      ),
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildQuickActions() {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.speed_rounded,
                  size: 24,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Text(
                  'Quick Actions',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _showImportDialog,
                    icon: const Icon(Icons.file_download_rounded),
                    label: const Text('Import'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _exportSettings,
                    icon: const Icon(Icons.file_upload_rounded),
                    label: const Text('Export'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showResetDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Settings'),
        content: const Text(
            'Are you sure you want to reset all accessibility settings to their default values?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _accessibilityManager.resetToDefaults();
            },
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  void _showImportDialog() {
    // Implementation for importing settings
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Import functionality coming soon!'),
      ),
    );
  }

  void _exportSettings() {
    final settings = _accessibilityManager.exportSettings();

    // Implementation for exporting settings
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Settings exported: ${settings.length} preferences'),
        action: SnackBarAction(
          label: 'Copy',
          onPressed: () {
            // Copy to clipboard logic
          },
        ),
      ),
    );
  }
}
