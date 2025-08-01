import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/semantics.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Enhanced accessibility manager with blackboard mode and theme switching
class EnhancedAccessibilityManager extends ChangeNotifier {
  static EnhancedAccessibilityManager? _instance;
  static EnhancedAccessibilityManager get instance {
    _instance ??= EnhancedAccessibilityManager._internal();
    return _instance!;
  }

  EnhancedAccessibilityManager._internal();

  static const Duration announceDelay = Duration(milliseconds: 100);

  // Accessibility preferences
  bool _screenReaderEnabled = false;
  bool _highContrastMode = false;
  bool _blackboardMode = false; // Enhanced dark theme with chalk aesthetic
  double _fontScale = 1.0;
  double _iconScale = 1.0;
  bool _reducedMotion = false;
  bool _tooltipsEnabled = true;
  bool _soundEnabled = true;
  bool _hapticEnabled = true;
  bool _colorBlindMode = false;
  String _colorBlindType = 'none'; // none, protanopia, deuteranopia, tritanopia

  // Getters
  bool get screenReaderEnabled => _screenReaderEnabled;
  bool get highContrastMode => _highContrastMode;
  bool get blackboardMode => _blackboardMode;
  double get fontScale => _fontScale;
  double get iconScale => _iconScale;
  bool get reducedMotion => _reducedMotion;
  bool get tooltipsEnabled => _tooltipsEnabled;
  bool get soundEnabled => _soundEnabled;
  bool get hapticEnabled => _hapticEnabled;
  bool get colorBlindMode => _colorBlindMode;
  String get colorBlindType => _colorBlindType;

  /// Initialize accessibility settings from system and preferences
  Future<void> initialize(BuildContext context) async {
    final mediaQuery = MediaQuery.of(context);

    // Check system accessibility settings
    _screenReaderEnabled = mediaQuery.accessibleNavigation;
    _reducedMotion = mediaQuery.disableAnimations;
    _fontScale = mediaQuery.textScaler.scale(1.0);

    // Load saved preferences
    await _loadPreferences();

    notifyListeners();
  }

  /// Load preferences from storage
  Future<void> _loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      _highContrastMode = prefs.getBool('accessibility_high_contrast') ?? false;
      _blackboardMode = prefs.getBool('accessibility_blackboard_mode') ?? false;
      _fontScale = prefs.getDouble('accessibility_font_scale') ?? 1.0;
      _iconScale = prefs.getDouble('accessibility_icon_scale') ?? 1.0;
      _tooltipsEnabled = prefs.getBool('accessibility_tooltips') ?? true;
      _soundEnabled = prefs.getBool('accessibility_sound') ?? true;
      _hapticEnabled = prefs.getBool('accessibility_haptic') ?? true;
      _colorBlindMode = prefs.getBool('accessibility_color_blind') ?? false;
      _colorBlindType =
          prefs.getString('accessibility_color_blind_type') ?? 'none';
    } catch (e) {
      // Fallback to defaults if loading fails
      debugPrint('Failed to load accessibility preferences: $e');
    }
  }

  /// Save preferences to storage
  Future<void> _savePreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      await prefs.setBool('accessibility_high_contrast', _highContrastMode);
      await prefs.setBool('accessibility_blackboard_mode', _blackboardMode);
      await prefs.setDouble('accessibility_font_scale', _fontScale);
      await prefs.setDouble('accessibility_icon_scale', _iconScale);
      await prefs.setBool('accessibility_tooltips', _tooltipsEnabled);
      await prefs.setBool('accessibility_sound', _soundEnabled);
      await prefs.setBool('accessibility_haptic', _hapticEnabled);
      await prefs.setBool('accessibility_color_blind', _colorBlindMode);
      await prefs.setString('accessibility_color_blind_type', _colorBlindType);
    } catch (e) {
      debugPrint('Failed to save accessibility preferences: $e');
    }
  }

  /// Toggle high contrast mode
  Future<void> toggleHighContrast() async {
    _highContrastMode = !_highContrastMode;
    await _savePreferences();
    notifyListeners();

    announceMessage(_highContrastMode
        ? 'High contrast mode enabled'
        : 'High contrast mode disabled');

    if (_hapticEnabled) {
      HapticFeedback.lightImpact();
    }
  }

  /// Toggle blackboard mode (enhanced dark theme)
  Future<void> toggleBlackboardMode() async {
    _blackboardMode = !_blackboardMode;

    // If blackboard mode is enabled, disable high contrast
    if (_blackboardMode) {
      _highContrastMode = false;
    }

    await _savePreferences();
    notifyListeners();

    announceMessage(_blackboardMode
        ? 'Dark Blackboard Mode enabled'
        : 'Dark Blackboard Mode disabled');

    if (_hapticEnabled) {
      HapticFeedback.mediumImpact();
    }
  }

  /// Set font scale
  Future<void> setFontScale(double scale) async {
    _fontScale = scale.clamp(0.8, 2.0);
    await _savePreferences();
    notifyListeners();

    announceMessage('Font size changed to ${(_fontScale * 100).round()}%');

    if (_hapticEnabled) {
      HapticFeedback.selectionClick();
    }
  }

  /// Set icon scale
  Future<void> setIconScale(double scale) async {
    _iconScale = scale.clamp(0.8, 1.5);
    await _savePreferences();
    notifyListeners();

    announceMessage('Icon size changed to ${(_iconScale * 100).round()}%');

    if (_hapticEnabled) {
      HapticFeedback.selectionClick();
    }
  }

  /// Toggle tooltips
  Future<void> toggleTooltips() async {
    _tooltipsEnabled = !_tooltipsEnabled;
    await _savePreferences();
    notifyListeners();

    announceMessage(
        _tooltipsEnabled ? 'Tooltips enabled' : 'Tooltips disabled');
  }

  /// Toggle sound effects
  Future<void> toggleSound() async {
    _soundEnabled = !_soundEnabled;
    await _savePreferences();
    notifyListeners();

    announceMessage(
        _soundEnabled ? 'Sound effects enabled' : 'Sound effects disabled');
  }

  /// Toggle haptic feedback
  Future<void> toggleHaptic() async {
    _hapticEnabled = !_hapticEnabled;
    await _savePreferences();
    notifyListeners();

    announceMessage(_hapticEnabled
        ? 'Haptic feedback enabled'
        : 'Haptic feedback disabled');

    if (_hapticEnabled) {
      HapticFeedback.lightImpact();
    }
  }

  /// Set color blind support
  Future<void> setColorBlindSupport(bool enabled, String type) async {
    _colorBlindMode = enabled;
    _colorBlindType = type;
    await _savePreferences();
    notifyListeners();

    if (enabled) {
      announceMessage('Color blind support enabled for $type');
    } else {
      announceMessage('Color blind support disabled');
    }

    if (_hapticEnabled) {
      HapticFeedback.lightImpact();
    }
  }

  /// Get effective theme mode based on accessibility settings
  ThemeMode getEffectiveThemeMode() {
    if (_blackboardMode) {
      return ThemeMode.dark;
    } else if (_highContrastMode) {
      return ThemeMode
          .light; // High contrast uses light theme with enhanced colors
    }
    return ThemeMode.system;
  }

  /// Check if system dark mode should be overridden
  bool shouldOverrideSystemTheme() {
    return _blackboardMode || _highContrastMode;
  }

  /// Announce message to screen reader
  void announceMessage(String message, {bool isAssertive = false}) {
    if (_screenReaderEnabled) {
      Future.delayed(announceDelay, () {
        SemanticsService.announce(message, TextDirection.ltr);
      });
    }
  }

  /// Announce success message with feedback
  void announceSuccess(String message) {
    announceMessage(message, isAssertive: true);

    if (_hapticEnabled) {
      HapticFeedback.lightImpact();
    }

    if (_soundEnabled) {
      SystemSound.play(SystemSoundType.click);
    }
  }

  /// Announce error message with feedback
  void announceError(String message) {
    announceMessage(message, isAssertive: true);

    if (_hapticEnabled) {
      HapticFeedback.heavyImpact();
    }

    if (_soundEnabled) {
      SystemSound.play(SystemSoundType.alert);
    }
  }

  /// Announce loading state
  void announceLoading(String message) {
    announceMessage(message, isAssertive: false);
  }

  /// Create semantic label for buttons with accessibility enhancements
  String createButtonLabel({
    required String label,
    String? hint,
    bool isEnabled = true,
    bool isLoading = false,
  }) {
    String semanticLabel = label;

    if (isLoading) {
      semanticLabel += ', loading';
    } else if (!isEnabled) {
      semanticLabel += ', disabled';
    }

    if (hint != null && _tooltipsEnabled) {
      semanticLabel += ', $hint';
    }

    return semanticLabel;
  }

  /// Create semantic label for form fields
  String createFieldLabel({
    required String label,
    bool isRequired = false,
    bool hasError = false,
    String? errorMessage,
    String? hint,
  }) {
    String semanticLabel = label;

    if (isRequired) {
      semanticLabel += ', required';
    }

    if (hasError && errorMessage != null) {
      semanticLabel += ', error: $errorMessage';
    }

    if (hint != null && _tooltipsEnabled) {
      semanticLabel += ', $hint';
    }

    return semanticLabel;
  }

  /// Get accessibility-aware animation duration
  Duration getAnimationDuration(Duration defaultDuration) {
    if (_reducedMotion) {
      return Duration.zero;
    }
    return defaultDuration;
  }

  /// Get accessibility-aware font size
  double getAccessibleFontSize(double baseSize) {
    return baseSize * _fontScale;
  }

  /// Get accessibility-aware icon size
  double getAccessibleIconSize(double baseSize) {
    return baseSize * _iconScale;
  }

  /// Check if an action should provide feedback
  bool shouldProvideFeedback() {
    return _hapticEnabled || _soundEnabled;
  }

  /// Provide appropriate feedback for actions
  void provideFeedback({
    bool isSuccess = false,
    bool isError = false,
  }) {
    if (!shouldProvideFeedback()) return;

    if (isError) {
      if (_hapticEnabled) HapticFeedback.heavyImpact();
      if (_soundEnabled) SystemSound.play(SystemSoundType.alert);
    } else if (isSuccess) {
      if (_hapticEnabled) HapticFeedback.lightImpact();
      if (_soundEnabled) SystemSound.play(SystemSoundType.click);
    } else {
      if (_hapticEnabled) HapticFeedback.selectionClick();
    }
  }

  /// Reset all accessibility settings to defaults
  Future<void> resetToDefaults() async {
    _highContrastMode = false;
    _blackboardMode = false;
    _fontScale = 1.0;
    _iconScale = 1.0;
    _tooltipsEnabled = true;
    _soundEnabled = true;
    _hapticEnabled = true;
    _colorBlindMode = false;
    _colorBlindType = 'none';

    await _savePreferences();
    notifyListeners();

    announceSuccess('Accessibility settings reset to defaults');
  }

  /// Export accessibility settings
  Map<String, dynamic> exportSettings() {
    return {
      'high_contrast': _highContrastMode,
      'blackboard_mode': _blackboardMode,
      'font_scale': _fontScale,
      'icon_scale': _iconScale,
      'tooltips_enabled': _tooltipsEnabled,
      'sound_enabled': _soundEnabled,
      'haptic_enabled': _hapticEnabled,
      'color_blind_mode': _colorBlindMode,
      'color_blind_type': _colorBlindType,
    };
  }

  /// Import accessibility settings
  Future<void> importSettings(Map<String, dynamic> settings) async {
    try {
      _highContrastMode = settings['high_contrast'] ?? false;
      _blackboardMode = settings['blackboard_mode'] ?? false;
      _fontScale = (settings['font_scale'] ?? 1.0).clamp(0.8, 2.0);
      _iconScale = (settings['icon_scale'] ?? 1.0).clamp(0.8, 1.5);
      _tooltipsEnabled = settings['tooltips_enabled'] ?? true;
      _soundEnabled = settings['sound_enabled'] ?? true;
      _hapticEnabled = settings['haptic_enabled'] ?? true;
      _colorBlindMode = settings['color_blind_mode'] ?? false;
      _colorBlindType = settings['color_blind_type'] ?? 'none';

      await _savePreferences();
      notifyListeners();

      announceSuccess('Accessibility settings imported successfully');
    } catch (e) {
      announceError('Failed to import accessibility settings');
      debugPrint('Failed to import accessibility settings: $e');
    }
  }
}
