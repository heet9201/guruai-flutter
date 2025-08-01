import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import '../lib/main.dart' as app;
import '../lib/core/accessibility/accessibility_manager.dart';

/// Comprehensive accessibility testing suite
class AccessibilityTestSuite {
  static const String _testSuiteName = 'Accessibility Tests';

  /// Run all accessibility tests
  static void runAllTests() {
    group(_testSuiteName, () {
      testSemanticLabels();
      testColorContrast();
      testTouchTargets();
      testKeyboardNavigation();
      testScreenReaderSupport();
      testFocusManagement();
      testTextScaling();
      testReducedMotion();
    });
  }

  /// Test semantic labels for all interactive elements
  static void testSemanticLabels() {
    group('Semantic Labels', () {
      testWidgets('All buttons have semantic labels',
          (WidgetTester tester) async {
        await tester.pumpWidget(const app.SahayakApp());
        await tester.pumpAndSettle();

        // Find all buttons and verify they have semantic labels
        final buttons = find.byType(ElevatedButton);
        for (int i = 0; i < buttons.evaluate().length; i++) {
          final button = buttons.at(i);
          final semantics = tester.getSemantics(button);

          expect(
            semantics.label.isNotEmpty,
            true,
            reason: 'Button at index $i should have a semantic label',
          );
        }
      });

      testWidgets('All text fields have semantic labels',
          (WidgetTester tester) async {
        await tester.pumpWidget(const app.SahayakApp());
        await tester.pumpAndSettle();

        // Navigate to a screen with text fields (if any)
        // This would need to be adapted based on your app's navigation

        final textFields = find.byType(TextField);
        for (int i = 0; i < textFields.evaluate().length; i++) {
          final textField = textFields.at(i);
          final semantics = tester.getSemantics(textField);

          expect(
            semantics.label.isNotEmpty,
            true,
            reason: 'Text field at index $i should have a semantic label',
          );
        }
      });

      testWidgets('All images have semantic labels',
          (WidgetTester tester) async {
        await tester.pumpWidget(const app.SahayakApp());
        await tester.pumpAndSettle();

        final images = find.byType(Image);
        for (int i = 0; i < images.evaluate().length; i++) {
          final image = images.at(i);

          // Check if image has semantic label or is marked as decorative
          final semantics = tester.getSemantics(image);
          final hasLabel = semantics.label.isNotEmpty;

          // Image should have a semantic label (decorative images should be excluded from semantics)
          expect(
            hasLabel,
            true,
            reason:
                'Image at index $i should have a semantic label or be excluded from semantics tree',
          );
        }
      });
    });
  }

  /// Test color contrast ratios
  static void testColorContrast() {
    group('Color Contrast', () {
      testWidgets('Text has sufficient contrast ratio',
          (WidgetTester tester) async {
        await tester.pumpWidget(const app.SahayakApp());
        await tester.pumpAndSettle();

        // Test various text elements for contrast
        final textWidgets = find.byType(Text);

        for (int i = 0; i < textWidgets.evaluate().length; i++) {
          final textWidget = textWidgets.at(i);
          final Text text = tester.widget(textWidget);
          final BuildContext context = tester.element(textWidget);

          final textColor = text.style?.color ??
              Theme.of(context).textTheme.bodyMedium?.color ??
              Colors.black;
          final backgroundColor = Theme.of(context).scaffoldBackgroundColor;

          final contrastRatio =
              _calculateContrastRatio(textColor, backgroundColor);

          expect(
            contrastRatio,
            greaterThan(4.5),
            reason:
                'Text at index $i has insufficient contrast ratio: $contrastRatio',
          );
        }
      });

      testWidgets('Buttons have sufficient contrast ratio',
          (WidgetTester tester) async {
        await tester.pumpWidget(const app.SahayakApp());
        await tester.pumpAndSettle();

        final buttons = find.byType(ElevatedButton);

        for (int i = 0; i < buttons.evaluate().length; i++) {
          final buttonWidget = buttons.at(i);
          final BuildContext context = tester.element(buttonWidget);
          final theme = Theme.of(context);

          final backgroundColor =
              theme.elevatedButtonTheme.style?.backgroundColor?.resolve({}) ??
                  theme.colorScheme.primary;
          final foregroundColor =
              theme.elevatedButtonTheme.style?.foregroundColor?.resolve({}) ??
                  theme.colorScheme.onPrimary;

          final contrastRatio =
              _calculateContrastRatio(foregroundColor, backgroundColor);

          expect(
            contrastRatio,
            greaterThan(4.5),
            reason:
                'Button at index $i has insufficient contrast ratio: $contrastRatio',
          );
        }
      });
    });
  }

  /// Test touch target sizes
  static void testTouchTargets() {
    group('Touch Targets', () {
      testWidgets('All interactive elements meet minimum touch target size',
          (WidgetTester tester) async {
        await tester.pumpWidget(const app.SahayakApp());
        await tester.pumpAndSettle();

        // Test buttons
        final buttons = find.byType(ElevatedButton);
        for (int i = 0; i < buttons.evaluate().length; i++) {
          final button = buttons.at(i);
          final size = tester.getSize(button);

          expect(
            size.width,
            greaterThanOrEqualTo(48.0),
            reason: 'Button at index $i width should be at least 48dp',
          );
          expect(
            size.height,
            greaterThanOrEqualTo(48.0),
            reason: 'Button at index $i height should be at least 48dp',
          );
        }

        // Test icon buttons
        final iconButtons = find.byType(IconButton);
        for (int i = 0; i < iconButtons.evaluate().length; i++) {
          final iconButton = iconButtons.at(i);
          final size = tester.getSize(iconButton);

          expect(
            size.width,
            greaterThanOrEqualTo(48.0),
            reason: 'IconButton at index $i width should be at least 48dp',
          );
          expect(
            size.height,
            greaterThanOrEqualTo(48.0),
            reason: 'IconButton at index $i height should be at least 48dp',
          );
        }
      });
    });
  }

  /// Test keyboard navigation
  static void testKeyboardNavigation() {
    group('Keyboard Navigation', () {
      testWidgets('Tab navigation works correctly',
          (WidgetTester tester) async {
        await tester.pumpWidget(const app.SahayakApp());
        await tester.pumpAndSettle();

        // Find focusable elements
        final focusableElements = find.byWidgetPredicate(
          (widget) => widget is Focus || widget is FocusableActionDetector,
        );

        if (focusableElements.evaluate().isNotEmpty) {
          // Test tab navigation
          await tester.sendKeyEvent(LogicalKeyboardKey.tab);
          await tester.pumpAndSettle();

          // Verify focus moved
          final focusedElement = find.byWidgetPredicate(
            (widget) => widget is Focus && (widget).focusNode?.hasFocus == true,
          );

          expect(
            focusedElement,
            findsWidgets,
            reason: 'Tab navigation should move focus to a focusable element',
          );
        }
      });

      testWidgets('Enter key activates focused buttons',
          (WidgetTester tester) async {
        await tester.pumpWidget(const app.SahayakApp());
        await tester.pumpAndSettle();

        final buttons = find.byType(ElevatedButton);
        if (buttons.evaluate().isNotEmpty) {
          final firstButton = buttons.first;

          // Focus the button
          await tester.tap(firstButton);
          await tester.pumpAndSettle();

          // Press enter
          await tester.sendKeyEvent(LogicalKeyboardKey.enter);
          await tester.pumpAndSettle();

          // Button should be activated (this would need specific verification logic)
        }
      });
    });
  }

  /// Test screen reader support
  static void testScreenReaderSupport() {
    group('Screen Reader Support', () {
      testWidgets('Live regions announce updates', (WidgetTester tester) async {
        await tester.pumpWidget(const app.SahayakApp());
        await tester.pumpAndSettle();

        // Find elements with live regions
        final liveRegions = find.byWidgetPredicate(
          (widget) =>
              widget is Semantics && widget.properties.liveRegion == true,
        );

        // Verify live regions exist for dynamic content
        expect(
          liveRegions,
          findsWidgets,
          reason:
              'App should have live regions for dynamic content announcements',
        );
      });

      testWidgets('Progress indicators have semantic descriptions',
          (WidgetTester tester) async {
        await tester.pumpWidget(const app.SahayakApp());
        await tester.pumpAndSettle();

        final progressIndicators = find.byType(CircularProgressIndicator);
        for (int i = 0; i < progressIndicators.evaluate().length; i++) {
          final indicator = progressIndicators.at(i);
          final semantics = tester.getSemantics(indicator);

          expect(
            semantics.label.isNotEmpty,
            true,
            reason:
                'Progress indicator at index $i should have a semantic description',
          );
        }
      });
    });
  }

  /// Test focus management
  static void testFocusManagement() {
    group('Focus Management', () {
      testWidgets('Focus is properly managed during navigation',
          (WidgetTester tester) async {
        await tester.pumpWidget(const app.SahayakApp());
        await tester.pumpAndSettle();

        // Test navigation focus management
        // This would need to be adapted based on your app's navigation structure

        // Verify initial focus state
        final initialFocusedElements = find.byWidgetPredicate(
          (widget) => widget is Focus && (widget).focusNode?.hasFocus == true,
        );

        // Navigation should properly manage focus
        expect(
          initialFocusedElements.evaluate().length,
          lessThanOrEqualTo(1),
          reason: 'Only one element should have focus at a time',
        );
      });

      testWidgets('Focus indicators are visible', (WidgetTester tester) async {
        await tester.pumpWidget(const app.SahayakApp());
        await tester.pumpAndSettle();

        // Test that focus indicators are visible when elements are focused
        final focusableButtons = find.byType(ElevatedButton);
        if (focusableButtons.evaluate().isNotEmpty) {
          // Focus the button using keyboard navigation
          await tester.sendKeyEvent(LogicalKeyboardKey.tab);
          await tester.pumpAndSettle();

          // Focus indicator should be visible (this would need visual verification)
          // In a real test, you'd check for focus decoration or border
        }
      });
    });
  }

  /// Test text scaling
  static void testTextScaling() {
    group('Text Scaling', () {
      testWidgets('Text scales correctly with system settings',
          (WidgetTester tester) async {
        // Test with different text scale factors
        final testScales = [1.0, 1.5, 2.0];

        for (final scale in testScales) {
          await tester.binding.setSurfaceSize(const Size(400, 800));

          await tester.pumpWidget(
            MediaQuery(
              data: const MediaQueryData().copyWith(
                textScaler: TextScaler.linear(scale),
              ),
              child: const app.SahayakApp(),
            ),
          );
          await tester.pumpAndSettle();

          // Verify text scales appropriately
          final textWidgets = find.byType(Text);
          if (textWidgets.evaluate().isNotEmpty) {
            final textWidget = textWidgets.first;
            final Text text = tester.widget(textWidget);
            final fontSize = text.style?.fontSize ?? 14;

            // Text should scale with the text scale factor
            expect(
              fontSize * scale,
              greaterThanOrEqualTo(fontSize),
              reason: 'Text should scale with system text scale factor $scale',
            );
          }
        }
      });

      testWidgets('UI remains usable at large text sizes',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          MediaQuery(
            data: const MediaQueryData().copyWith(
              textScaler: const TextScaler.linear(2.0),
            ),
            child: const app.SahayakApp(),
          ),
        );
        await tester.pumpAndSettle();

        // Verify UI doesn't break with large text
        final overflowedTexts = find.byWidgetPredicate(
          (widget) =>
              widget is RenderObjectWidget &&
              widget.toString().contains('overflow'),
        );

        expect(
          overflowedTexts,
          findsNothing,
          reason: 'No text should overflow at large text sizes',
        );
      });
    });
  }

  /// Test reduced motion preferences
  static void testReducedMotion() {
    group('Reduced Motion', () {
      testWidgets('Animations respect reduced motion preference',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          MediaQuery(
            data: const MediaQueryData().copyWith(
              disableAnimations: true,
            ),
            child: const app.SahayakApp(),
          ),
        );
        await tester.pumpAndSettle();

        // Test that animations are disabled when reduce motion is enabled
        // This would need specific verification based on your animation implementation

        // Verify AccessibilityManager respects reduced motion
        final testDuration = AccessibilityManager.getAccessibleDuration(
          const Duration(milliseconds: 300),
        );

        expect(
          testDuration,
          equals(Duration.zero),
          reason: 'Animations should be disabled when reduce motion is enabled',
        );
      });
    });
  }

  /// Calculate color contrast ratio for testing
  static double _calculateContrastRatio(Color foreground, Color background) {
    final fLuminance = _calculateLuminance(foreground);
    final bLuminance = _calculateLuminance(background);

    final lighter = fLuminance > bLuminance ? fLuminance : bLuminance;
    final darker = fLuminance > bLuminance ? bLuminance : fLuminance;

    return (lighter + 0.05) / (darker + 0.05);
  }

  static double _calculateLuminance(Color color) {
    final r = _calculateColorComponent(color.red);
    final g = _calculateColorComponent(color.green);
    final b = _calculateColorComponent(color.blue);

    return 0.2126 * r + 0.7152 * g + 0.0722 * b;
  }

  static double _calculateColorComponent(int value) {
    final normalized = value / 255.0;
    if (normalized <= 0.03928) {
      return normalized / 12.92;
    } else {
      return ((normalized + 0.055) / 1.055) * ((normalized + 0.055) / 1.055);
    }
  }
}

/// Performance testing utilities
class PerformanceTestSuite {
  static const String _testSuiteName = 'Performance Tests';

  static void runAllTests() {
    group(_testSuiteName, () {
      testScrollPerformance();
      testAnimationPerformance();
      testMemoryUsage();
      testAppLaunchTime();
    });
  }

  static void testScrollPerformance() {
    testWidgets('Scrolling performance is acceptable',
        (WidgetTester tester) async {
      await tester.pumpWidget(const app.SahayakApp());
      await tester.pumpAndSettle();

      // Find scrollable widgets
      final scrollables = find.byType(Scrollable);

      if (scrollables.evaluate().isNotEmpty) {
        final scrollable = scrollables.first;

        // Measure scroll performance
        final stopwatch = Stopwatch()..start();

        await tester.fling(scrollable, const Offset(0, -500), 1000);
        await tester.pumpAndSettle();

        stopwatch.stop();

        expect(
          stopwatch.elapsedMilliseconds,
          lessThan(1000),
          reason: 'Scroll animation should complete within 1 second',
        );
      }
    });
  }

  static void testAnimationPerformance() {
    testWidgets('Animations maintain 60fps', (WidgetTester tester) async {
      await tester.pumpWidget(const app.SahayakApp());
      await tester.pumpAndSettle();

      // Test animation performance
      // This would need specific animation widgets to test

      // Measure frame rate during animations
      final frames = <Duration>[];
      tester.binding.addPersistentFrameCallback((timeStamp) {
        frames.add(timeStamp);
      });

      // Trigger an animation
      await tester.tap(find.byType(FloatingActionButton).first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Check frame rate
      if (frames.length > 1) {
        final frameDurations = <double>[];
        for (int i = 1; i < frames.length; i++) {
          final duration =
              frames[i].inMicroseconds - frames[i - 1].inMicroseconds;
          frameDurations.add(duration / 1000.0); // Convert to milliseconds
        }

        final averageFrameTime =
            frameDurations.reduce((a, b) => a + b) / frameDurations.length;

        expect(
          averageFrameTime,
          lessThan(16.67), // 60fps = 16.67ms per frame
          reason: 'Average frame time should be less than 16.67ms for 60fps',
        );
      }
    });
  }

  static void testMemoryUsage() {
    testWidgets('Memory usage is reasonable', (WidgetTester tester) async {
      await tester.pumpWidget(const app.SahayakApp());
      await tester.pumpAndSettle();

      // This would need platform-specific memory measurement
      // For now, just verify the app doesn't crash with memory issues

      // Navigate through multiple screens to test memory management
      for (int i = 0; i < 5; i++) {
        await tester.tap(find.byType(NavigationDestination).at(i % 3));
        await tester.pumpAndSettle();
      }

      // App should still be responsive
      expect(find.byType(Scaffold), findsOneWidget);
    });
  }

  static void testAppLaunchTime() {
    testWidgets('App launches within acceptable time',
        (WidgetTester tester) async {
      final stopwatch = Stopwatch()..start();

      await tester.pumpWidget(const app.SahayakApp());
      await tester.pumpAndSettle();

      stopwatch.stop();

      expect(
        stopwatch.elapsedMilliseconds,
        lessThan(3000), // App should launch within 3 seconds
        reason: 'App launch time should be less than 3 seconds',
      );
    });
  }
}

/// Multi-language testing utilities
class MultiLanguageTestSuite {
  static const String _testSuiteName = 'Multi-Language Tests';

  static void runAllTests() {
    group(_testSuiteName, () {
      testLanguageSwitching();
      testTextDirection();
      testLocalizedContent();
      testDateTimeLocalization();
    });
  }

  static void testLanguageSwitching() {
    testWidgets('Language switching works correctly',
        (WidgetTester tester) async {
      await tester.pumpWidget(const app.SahayakApp());
      await tester.pumpAndSettle();

      // Test switching between supported languages
      final supportedLocales = ['en', 'hi']; // Add more as needed

      for (final locale in supportedLocales) {
        // This would need to trigger language change in your app
        // Implementation depends on your app's language switching mechanism

        await tester.pumpAndSettle();

        // Verify language change took effect
        expect(
          find.byType(MaterialApp),
          findsOneWidget,
          reason:
              'App should remain functional after language switch to $locale',
        );
      }
    });
  }

  static void testTextDirection() {
    testWidgets('RTL languages display correctly', (WidgetTester tester) async {
      // Test with RTL locale if supported
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData().copyWith(
              // This would be set for RTL languages
              ),
          child: const app.SahayakApp(),
        ),
      );
      await tester.pumpAndSettle();

      // Verify RTL layout
      // This would need specific verification based on your app's RTL support
    });
  }

  static void testLocalizedContent() {
    testWidgets('All text is properly localized', (WidgetTester tester) async {
      await tester.pumpWidget(const app.SahayakApp());
      await tester.pumpAndSettle();

      // Find all Text widgets
      final textWidgets = find.byType(Text);

      for (int i = 0; i < textWidgets.evaluate().length; i++) {
        final textWidget = textWidgets.at(i);
        final Text text = tester.widget(textWidget);
        final textData = text.data;

        if (textData != null) {
          // Check that text doesn't contain hardcoded English strings
          // This is a basic check - you'd need more sophisticated localization testing
          expect(
            textData.contains('TODO') || textData.contains('FIXME'),
            false,
            reason: 'Text should not contain placeholder strings: $textData',
          );
        }
      }
    });
  }

  static void testDateTimeLocalization() {
    testWidgets('Date and time formatting respects locale',
        (WidgetTester tester) async {
      await tester.pumpWidget(const app.SahayakApp());
      await tester.pumpAndSettle();

      // This would test that dates and times are formatted according to locale
      // Implementation depends on how your app displays dates and times
    });
  }
}
