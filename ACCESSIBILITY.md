# Accessibility & Testing Guide

This guide covers the comprehensive accessibility features and testing setup implemented in the Sahayak Flutter application.

## 🔍 Accessibility Features

### Screen Reader Support

- **Semantic Labels**: All interactive elements have proper semantic labels
- **Live Regions**: Dynamic content changes are announced to screen readers
- **Focus Management**: Proper focus order and management throughout the app
- **Content Descriptions**: Images and interactive elements have meaningful descriptions

### High Contrast Mode

- **Automatic Detection**: App detects system high contrast settings
- **Enhanced Colors**: High contrast color schemes for better visibility
- **Increased Borders**: Thicker borders and outlines in high contrast mode
- **Clear Visual Hierarchy**: Enhanced visual separation between elements

### Font Size Support

- **Dynamic Scaling**: Text scales according to system font size settings
- **Minimum Sizes**: Ensures text never becomes unreadably small
- **Maximum Limits**: Prevents layout breakage at very large sizes
- **Responsive Design**: UI adapts to different text sizes

### Keyboard Navigation

- **Tab Order**: Logical tab order through all interactive elements
- **Focus Indicators**: Clear visual indicators for focused elements
- **Keyboard Shortcuts**: Support for standard keyboard navigation
- **Skip Links**: Quick navigation to main content areas

### Touch Target Sizes

- **Minimum Size**: All interactive elements meet 48dp minimum size
- **Comfortable Spacing**: Adequate spacing between touch targets
- **Visual Feedback**: Clear feedback for touch interactions
- **Gesture Support**: Support for accessibility gestures

### Color Design

- **Contrast Ratios**: All text meets WCAG AA contrast requirements (4.5:1)
- **Color Independence**: Information isn't conveyed by color alone
- **Color Blind Friendly**: Design works for users with color vision deficiencies
- **Focus Colors**: High contrast focus indicators

### Motion & Animation

- **Reduced Motion**: Respects system reduce motion preferences
- **Essential Motion**: Critical animations are maintained even with reduced motion
- **Alternative Feedback**: Non-motion feedback for important state changes
- **Customizable**: Users can adjust animation preferences

## 📁 File Structure

```
lib/core/accessibility/
├── accessibility_manager.dart     # Central accessibility management
├── accessible_widgets.dart       # Accessibility-enhanced UI components
└── accessible_themes.dart        # High contrast and accessible themes

test/
├── accessibility_test.dart       # Comprehensive accessibility tests
└── test_main.dart                # Test suite runner and utilities
```

## 🛠 Implementation

### AccessibilityManager

Central manager for all accessibility features:

```dart
// Initialize accessibility settings
AccessibilityManager.initialize(context);

// Announce messages to screen reader
AccessibilityManager.announceSuccess('Content saved successfully');
AccessibilityManager.announceError('Please check your input');

// Create semantic labels
final buttonLabel = AccessibilityManager.createButtonLabel(
  label: 'Save',
  hint: 'Save your work',
  isEnabled: true,
);

// Manage focus
AccessibilityManager.manageFocus(
  context: context,
  focusNode: myFocusNode,
  announcement: 'Moved to settings page',
);

// Get accessible measurements
final fontSize = AccessibilityManager.getAccessibleFontSize(16.0, context);
final duration = AccessibilityManager.getAccessibleDuration(Duration(milliseconds: 300));
```

### Accessible Widgets

Enhanced widgets with built-in accessibility features:

```dart
// Accessible button with proper semantics
AccessibleButton(
  onPressed: () => _handleSave(),
  semanticLabel: 'Save document',
  tooltip: 'Save your current work',
  child: Text('Save'),
)

// Accessible text field with validation support
AccessibleTextField(
  labelText: 'Email Address',
  hintText: 'Enter your email',
  isRequired: true,
  errorText: hasError ? 'Please enter a valid email' : null,
  helperText: 'We will never share your email',
)

// Accessible card with focus management
AccessibleCard(
  onTap: () => _handleCardTap(),
  semanticLabel: 'User profile card for John Doe',
  child: ProfileContent(),
)

// Accessible progress indicator with announcements
AccessibleProgressIndicator(
  value: uploadProgress,
  label: 'Upload Progress',
  showPercentage: true,
)

// Accessible loading indicator
AccessibleLoadingIndicator(
  message: 'Loading your content...',
  isLoading: true,
  child: ContentWidget(),
)
```

### Accessible Themes

High contrast and scalable themes:

```dart
// Create accessible theme
final theme = AccessibleThemeData.createLightTheme(
  isHighContrast: MediaQuery.of(context).highContrast,
  textScaleFactor: MediaQuery.of(context).textScaleFactor,
  languageCode: 'en',
);

// Apply theme
MaterialApp(
  theme: theme,
  home: MyHomePage(),
)
```

### Mixin for Easy Integration

Use the AccessibilityMixin for consistent implementation:

```dart
class MyWidget extends StatefulWidget {
  @override
  _MyWidgetState createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> with AccessibilityMixin {
  late FocusNode _buttonFocusNode;

  @override
  void initState() {
    super.initState();
    _buttonFocusNode = createFocusNode(debugLabel: 'SaveButton');
  }

  void _handleSave() {
    announce('Document saved successfully');
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      focusNode: _buttonFocusNode,
      onPressed: _handleSave,
      child: Text(
        'Save',
        style: TextStyle(fontSize: getAccessibleFontSize(16)),
      ),
    );
  }
}
```

## 🧪 Testing

### Running Tests

```bash
# Run all tests
flutter test

# Run specific test suites
flutter test test/accessibility_test.dart
flutter test test/test_main.dart

# Run with coverage
flutter test --coverage
```

### Accessibility Tests

Comprehensive test suite covering:

1. **Semantic Labels**: Verify all interactive elements have proper labels
2. **Color Contrast**: Check contrast ratios meet WCAG guidelines
3. **Touch Targets**: Ensure minimum touch target sizes
4. **Keyboard Navigation**: Test tab order and keyboard interactions
5. **Screen Reader Support**: Verify announcements and live regions
6. **Focus Management**: Test focus behavior and indicators
7. **Text Scaling**: Verify UI works at different text sizes
8. **Reduced Motion**: Test animation behavior with motion preferences

### Performance Tests

1. **Scroll Performance**: Measure scrolling frame rates
2. **Animation Performance**: Check animation smoothness
3. **Memory Usage**: Monitor memory consumption
4. **App Launch Time**: Measure startup performance

### Multi-Language Tests

1. **Language Switching**: Test language change functionality
2. **Text Direction**: Verify RTL language support
3. **Localized Content**: Check all text is properly localized
4. **Date/Time Formatting**: Verify locale-specific formatting

### Example Tests

```dart
// Test semantic labels
testWidgets('All buttons have semantic labels', (WidgetTester tester) async {
  await tester.pumpWidget(MyApp());

  final buttons = find.byType(ElevatedButton);
  for (int i = 0; i < buttons.evaluate().length; i++) {
    final semantics = tester.getSemantics(buttons.at(i));
    expect(semantics.label.isNotEmpty, true);
  }
});

// Test color contrast
testWidgets('Text has sufficient contrast', (WidgetTester tester) async {
  await tester.pumpWidget(MyApp());

  final textWidgets = find.byType(Text);
  for (int i = 0; i < textWidgets.evaluate().length; i++) {
    final textColor = /* get text color */;
    final backgroundColor = /* get background color */;
    final contrastRatio = calculateContrastRatio(textColor, backgroundColor);
    expect(contrastRatio, greaterThan(4.5));
  }
});

// Test touch targets
testWidgets('Touch targets meet minimum size', (WidgetTester tester) async {
  await tester.pumpWidget(MyApp());

  final buttons = find.byType(ElevatedButton);
  for (int i = 0; i < buttons.evaluate().length; i++) {
    final size = tester.getSize(buttons.at(i));
    expect(size.width, greaterThanOrEqualTo(48.0));
    expect(size.height, greaterThanOrEqualTo(48.0));
  }
});
```

## 📋 Accessibility Checklist

### ✅ Implementation Checklist

- [ ] All interactive elements have semantic labels
- [ ] Images have alternative text or are marked as decorative
- [ ] Form fields have labels and validation messages
- [ ] Focus order is logical and complete
- [ ] Touch targets are at least 48dp
- [ ] Color contrast meets WCAG AA standards (4.5:1)
- [ ] Information isn't conveyed by color alone
- [ ] Text scales with system settings
- [ ] App works with screen readers
- [ ] Keyboard navigation is complete
- [ ] Reduced motion preferences are respected
- [ ] High contrast mode is supported
- [ ] Loading states are announced
- [ ] Error messages are accessible
- [ ] Success feedback is provided

### 🧪 Testing Checklist

- [ ] Semantic label tests pass
- [ ] Color contrast tests pass
- [ ] Touch target size tests pass
- [ ] Keyboard navigation tests pass
- [ ] Screen reader tests pass
- [ ] Focus management tests pass
- [ ] Text scaling tests pass
- [ ] Reduced motion tests pass
- [ ] Performance tests pass
- [ ] Multi-language tests pass

### 📱 Manual Testing

1. **Screen Reader Testing**:

   - Test with TalkBack (Android) or VoiceOver (iOS)
   - Verify all content is announced correctly
   - Check navigation flow makes sense

2. **Keyboard Testing**:

   - Navigate using only Tab and Enter keys
   - Verify focus indicators are visible
   - Check skip links work properly

3. **Visual Testing**:

   - Test with high contrast mode enabled
   - Verify app works at 200% text size
   - Check color blind simulation tools

4. **Motion Testing**:
   - Enable reduce motion in system settings
   - Verify essential animations still work
   - Check alternative feedback is provided

## 🚀 Continuous Integration

Add accessibility testing to your CI/CD pipeline:

```yaml
# .github/workflows/accessibility.yml
name: Accessibility Tests
on: [push, pull_request]

jobs:
  accessibility:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - uses: subosito/flutter-action@v2
      - run: flutter pub get
      - run: flutter test test/accessibility_test.dart
      - run: flutter test test/test_main.dart
```

## 📚 Resources

- [Flutter Accessibility Guide](https://docs.flutter.dev/development/accessibility-and-localization/accessibility)
- [WCAG 2.1 Guidelines](https://www.w3.org/WAI/WCAG21/quickref/)
- [Material Design Accessibility](https://material.io/design/usability/accessibility.html)
- [iOS Accessibility Guidelines](https://developer.apple.com/accessibility/)
- [Android Accessibility Guidelines](https://developer.android.com/guide/topics/ui/accessibility)

## 🤝 Contributing

When contributing to accessibility features:

1. Run accessibility tests before submitting PRs
2. Update semantic labels when changing UI
3. Test with screen readers when possible
4. Consider color blind users in design choices
5. Document accessibility features in PR descriptions
6. Update this guide when adding new accessibility features

## 📞 Support

For accessibility questions or issues:

- File an issue with the "accessibility" label
- Include details about assistive technology used
- Provide steps to reproduce accessibility barriers
- Suggest specific improvements when possible
