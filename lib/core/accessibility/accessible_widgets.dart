import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../accessibility/accessibility_manager.dart';

/// Accessible button with proper semantics and focus management
class AccessibleButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final String? semanticLabel;
  final String? tooltip;
  final bool isLoading;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final EdgeInsetsGeometry? padding;
  final double? elevation;
  final BorderRadius? borderRadius;
  final FocusNode? focusNode;

  const AccessibleButton({
    super.key,
    required this.child,
    this.onPressed,
    this.semanticLabel,
    this.tooltip,
    this.isLoading = false,
    this.backgroundColor,
    this.foregroundColor,
    this.padding,
    this.elevation,
    this.borderRadius,
    this.focusNode,
  });

  @override
  State<AccessibleButton> createState() => _AccessibleButtonState();
}

class _AccessibleButtonState extends State<AccessibleButton>
    with AccessibilityMixin {
  late FocusNode _focusNode;
  bool _isHovered = false;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode =
        widget.focusNode ?? createFocusNode(debugLabel: 'AccessibleButton');
    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChanged);
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  void _onFocusChanged() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });
  }

  void _handleTap() {
    if (widget.onPressed != null && !widget.isLoading) {
      HapticFeedback.lightImpact();
      widget.onPressed!();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final backgroundColor = widget.backgroundColor ?? colorScheme.primary;
    final foregroundColor = widget.foregroundColor ?? colorScheme.onPrimary;

    // Apply high contrast if needed
    final effectiveBackgroundColor = AccessibilityManager.getAccessibleColor(
      color: backgroundColor,
      backgroundColor: colorScheme.surface,
      isDark: theme.brightness == Brightness.dark,
    );

    final effectiveForegroundColor = AccessibilityManager.getAccessibleColor(
      color: foregroundColor,
      backgroundColor: effectiveBackgroundColor,
      isDark: theme.brightness == Brightness.dark,
    );

    return Semantics(
      label: widget.semanticLabel ?? widget.tooltip,
      button: true,
      enabled: widget.onPressed != null && !widget.isLoading,
      child: Tooltip(
        message: widget.tooltip ?? '',
        child: MouseRegion(
          onEnter: (_) => setState(() => _isHovered = true),
          onExit: (_) => setState(() => _isHovered = false),
          child: Focus(
            focusNode: _focusNode,
            child: Container(
              constraints: const BoxConstraints(
                minHeight: AccessibilityConstants.minTouchTarget,
                minWidth: AccessibilityConstants.minTouchTarget,
              ),
              child: Material(
                color: effectiveBackgroundColor,
                elevation:
                    widget.elevation ?? (_isHovered || _isFocused ? 4 : 2),
                borderRadius: widget.borderRadius ?? BorderRadius.circular(8),
                child: InkWell(
                  onTap: _handleTap,
                  borderRadius: widget.borderRadius ?? BorderRadius.circular(8),
                  focusNode: _focusNode,
                  child: Container(
                    padding: widget.padding ??
                        const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                    decoration: BoxDecoration(
                      border: _isFocused
                          ? Border.all(
                              color: colorScheme.outline,
                              width: 2,
                            )
                          : null,
                      borderRadius:
                          widget.borderRadius ?? BorderRadius.circular(8),
                    ),
                    child: widget.isLoading
                        ? SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation(
                                  effectiveForegroundColor),
                            ),
                          )
                        : DefaultTextStyle(
                            style: TextStyle(color: effectiveForegroundColor),
                            child: widget.child,
                          ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Accessible text field with proper semantics and validation
class AccessibleTextField extends StatefulWidget {
  final TextEditingController? controller;
  final String? labelText;
  final String? hintText;
  final String? errorText;
  final String? helperText;
  final bool isRequired;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;
  final FocusNode? focusNode;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final int? maxLines;
  final int? maxLength;

  const AccessibleTextField({
    super.key,
    this.controller,
    this.labelText,
    this.hintText,
    this.errorText,
    this.helperText,
    this.isRequired = false,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.onChanged,
    this.onTap,
    this.focusNode,
    this.prefixIcon,
    this.suffixIcon,
    this.maxLines = 1,
    this.maxLength,
  });

  @override
  State<AccessibleTextField> createState() => _AccessibleTextFieldState();
}

class _AccessibleTextFieldState extends State<AccessibleTextField>
    with AccessibilityMixin {
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode =
        widget.focusNode ?? createFocusNode(debugLabel: 'AccessibleTextField');
  }

  @override
  void dispose() {
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  String _buildSemanticLabel() {
    return AccessibilityManager.createFieldLabel(
      label: widget.labelText ?? widget.hintText ?? 'Text field',
      isRequired: widget.isRequired,
      hasError: widget.errorText != null,
      errorMessage: widget.errorText,
      hint: widget.helperText,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      label: _buildSemanticLabel(),
      textField: true,
      child: TextFormField(
        controller: widget.controller,
        focusNode: _focusNode,
        obscureText: widget.obscureText,
        keyboardType: widget.keyboardType,
        textInputAction: widget.textInputAction,
        onChanged: widget.onChanged,
        onTap: widget.onTap,
        maxLines: widget.maxLines,
        maxLength: widget.maxLength,
        style: TextStyle(
          fontSize: getAccessibleFontSize(16),
        ),
        decoration: InputDecoration(
          labelText: widget.labelText,
          hintText: widget.hintText,
          errorText: widget.errorText,
          helperText: widget.helperText,
          prefixIcon: widget.prefixIcon,
          suffixIcon: widget.suffixIcon,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(
              color: theme.colorScheme.primary,
              width: 2,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(
              color: theme.colorScheme.error,
              width: 2,
            ),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(
              color: theme.colorScheme.error,
              width: 2,
            ),
          ),
        ),
      ),
    );
  }
}

/// Accessible card with proper focus and hover states
class AccessibleCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final String? semanticLabel;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;
  final Color? color;
  final double? elevation;
  final BorderRadius? borderRadius;

  const AccessibleCard({
    super.key,
    required this.child,
    this.onTap,
    this.semanticLabel,
    this.margin,
    this.padding,
    this.color,
    this.elevation,
    this.borderRadius,
  });

  @override
  State<AccessibleCard> createState() => _AccessibleCardState();
}

class _AccessibleCardState extends State<AccessibleCard>
    with AccessibilityMixin {
  late FocusNode _focusNode;
  bool _isHovered = false;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode = createFocusNode(debugLabel: 'AccessibleCard');
    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChanged);
    super.dispose();
  }

  void _onFocusChanged() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });
  }

  void _handleTap() {
    if (widget.onTap != null) {
      HapticFeedback.selectionClick();
      widget.onTap!();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      label: widget.semanticLabel,
      button: widget.onTap != null,
      child: Container(
        margin: widget.margin ?? const EdgeInsets.all(8),
        child: MouseRegion(
          onEnter: (_) => setState(() => _isHovered = true),
          onExit: (_) => setState(() => _isHovered = false),
          child: Focus(
            focusNode: widget.onTap != null ? _focusNode : null,
            child: Material(
              color: widget.color ?? theme.colorScheme.surface,
              elevation: widget.elevation ?? (_isHovered || _isFocused ? 4 : 1),
              borderRadius: widget.borderRadius ?? BorderRadius.circular(12),
              child: InkWell(
                onTap: _handleTap,
                borderRadius: widget.borderRadius ?? BorderRadius.circular(12),
                focusNode: widget.onTap != null ? _focusNode : null,
                child: Container(
                  padding: widget.padding ?? const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: _isFocused
                        ? Border.all(
                            color: theme.colorScheme.primary,
                            width: 2,
                          )
                        : null,
                    borderRadius:
                        widget.borderRadius ?? BorderRadius.circular(12),
                  ),
                  child: widget.child,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Accessible progress indicator with semantic announcements
class AccessibleProgressIndicator extends StatefulWidget {
  final double? value;
  final String? label;
  final String? semanticLabel;
  final Color? color;
  final Color? backgroundColor;
  final bool showPercentage;

  const AccessibleProgressIndicator({
    super.key,
    this.value,
    this.label,
    this.semanticLabel,
    this.color,
    this.backgroundColor,
    this.showPercentage = true,
  });

  @override
  State<AccessibleProgressIndicator> createState() =>
      _AccessibleProgressIndicatorState();
}

class _AccessibleProgressIndicatorState
    extends State<AccessibleProgressIndicator> {
  double? _previousValue;

  @override
  void didUpdateWidget(AccessibleProgressIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Announce progress changes
    if (widget.value != null &&
        _previousValue != null &&
        widget.value != _previousValue) {
      final progress = (widget.value! * 100).round();
      final previousProgress = (_previousValue! * 100).round();

      // Only announce at 25% intervals to avoid spam
      if (progress % 25 == 0 && progress != previousProgress) {
        AccessibilityManager.announceMessage('$progress percent complete');
      }
    }

    _previousValue = widget.value;
  }

  String _buildSemanticLabel() {
    return AccessibilityManager.createProgressLabel(
      label: widget.semanticLabel ?? widget.label ?? 'Progress',
      progress: widget.value,
      status: widget.value == null ? 'Loading' : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      label: _buildSemanticLabel(),
      value: widget.value != null ? '${(widget.value! * 100).round()}%' : null,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.label != null) ...[
            Text(
              widget.label!,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
          ],
          LinearProgressIndicator(
            value: widget.value,
            color: widget.color ?? theme.colorScheme.primary,
            backgroundColor:
                widget.backgroundColor ?? theme.colorScheme.primaryContainer,
            minHeight: 8,
          ),
          if (widget.showPercentage && widget.value != null) ...[
            const SizedBox(height: 4),
            Text(
              '${(widget.value! * 100).round()}%',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ],
      ),
    );
  }
}

/// Accessible loading indicator with semantic announcements
class AccessibleLoadingIndicator extends StatefulWidget {
  final String? message;
  final bool isLoading;
  final Widget? child;

  const AccessibleLoadingIndicator({
    super.key,
    this.message,
    this.isLoading = true,
    this.child,
  });

  @override
  State<AccessibleLoadingIndicator> createState() =>
      _AccessibleLoadingIndicatorState();
}

class _AccessibleLoadingIndicatorState
    extends State<AccessibleLoadingIndicator> {
  @override
  void initState() {
    super.initState();
    if (widget.isLoading && widget.message != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        AccessibilityManager.announceLoading(widget.message!);
      });
    }
  }

  @override
  void didUpdateWidget(AccessibleLoadingIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.isLoading != oldWidget.isLoading) {
      if (widget.isLoading && widget.message != null) {
        AccessibilityManager.announceLoading(widget.message!);
      } else if (!widget.isLoading) {
        AccessibilityManager.announceMessage('Loading complete');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isLoading && widget.child != null) {
      return widget.child!;
    }

    return Semantics(
      label: widget.message ?? AccessibilityConstants.loadingLabel,
      liveRegion: true,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            if (widget.message != null) ...[
              const SizedBox(height: 16),
              Text(
                widget.message!,
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
