import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/theme/express_type.dart';
import 'express_squish.dart';

/// Button visual tones inspired by InlitX/streak
enum ExpressTone {
  /// Filled solid background with primary or custom accent color
  filled,

  /// Tonal soft pastel/tinted background with solid foreground
  tonal,

  /// Ghost transparent background with tinted border and foreground
  ghost,
}

/// Tactile Express Button with spring physics, press scale, and morphing corners.
/// Directly adapted from InlitX/streak button architecture.
class ExpressButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final ExpressTone tone;
  final Color? tint;
  final Color? foregroundColor;
  final bool expand;
  final bool compact;
  final bool isLoading;

  const ExpressButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.tone = ExpressTone.filled,
    this.tint,
    this.foregroundColor,
    this.expand = false,
    this.compact = false,
    this.isLoading = false,
  });

  @override
  State<ExpressButton> createState() => _ExpressButtonState();
}

class _ExpressButtonState extends State<ExpressButton> {
  bool _down = false;
  bool _hover = false;

  void _set(bool value) {
    if (_down != value) setState(() => _down = value);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final enabled = widget.onPressed != null && !widget.isLoading;

    final accent = widget.tint ?? theme.colorScheme.primary;

    final (background, foreground) = switch (widget.tone) {
      ExpressTone.filled => (accent, widget.foregroundColor ?? Colors.white),
      ExpressTone.tonal => (
          accent.withValues(alpha: isDark ? 0.22 : 0.12),
          widget.foregroundColor ?? (isDark ? accent : AppColors.terracotta)
        ),
      ExpressTone.ghost => (
          Colors.transparent,
          widget.foregroundColor ?? (isDark ? Colors.white : AppColors.deepNavy)
        ),
    };

    final height = widget.compact ? 40.0 : 52.0;
    final double restingRadius = height / 2;
    final double pressedRadius = 14.0;

    return Semantics(
      button: true,
      enabled: enabled,
      label: widget.label,
      excludeSemantics: true,
      child: MouseRegion(
        cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: enabled ? (_) => _set(true) : null,
          onTapUp: enabled ? (_) => _set(false) : null,
          onTapCancel: enabled ? () => _set(false) : null,
          onTap: enabled ? widget.onPressed : null,
          child: AnimatedScale(
            scale: _down ? 0.94 : (_hover ? 1.015 : 1.0),
            duration: _down ? Express.fast : Express.quick,
            curve: _down ? Express.settle : Express.bouncy,
            child: AnimatedContainer(
              duration: Express.quick,
              curve: Express.settle,
              height: height,
              width: widget.expand ? double.infinity : null,
              padding: EdgeInsets.symmetric(horizontal: widget.compact ? 16 : 22),
              decoration: BoxDecoration(
                color: enabled
                    ? (widget.tone == ExpressTone.ghost && _hover
                        ? accent.withValues(alpha: 0.08)
                        : background)
                    : (isDark ? const Color(0xFF262C38) : const Color(0xFFE2E8F0)),
                borderRadius: BorderRadius.circular(_down ? pressedRadius : restingRadius),
                border: widget.tone == ExpressTone.ghost
                    ? Border.all(
                        color: enabled
                            ? accent.withValues(alpha: _hover ? 0.8 : 0.4)
                            : Colors.transparent,
                        width: 1.5,
                      )
                    : null,
                boxShadow: widget.tone == ExpressTone.filled && enabled
                    ? [
                        BoxShadow(
                          color: accent.withValues(alpha: _down ? 0.15 : 0.32),
                          blurRadius: _down ? 6 : 14,
                          offset: Offset(0, _down ? 2 : 5),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                mainAxisSize: widget.expand ? MainAxisSize.max : MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (widget.isLoading) ...[
                    SizedBox(
                      width: widget.compact ? 16 : 18,
                      height: widget.compact ? 16 : 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: foreground,
                      ),
                    ),
                    const SizedBox(width: 10),
                  ] else if (widget.icon != null) ...[
                    Icon(
                      widget.icon,
                      size: widget.compact ? 17 : 19,
                      color: enabled ? foreground : const Color(0xFF94A3B8),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    widget.label,
                    style: ExpressType.labelLarge(
                      color: enabled ? foreground : const Color(0xFF94A3B8),
                      weight: FontWeight.w700,
                    ).copyWith(
                      fontSize: widget.compact ? 13.5 : 15.0,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Tactile Icon Button with desktop hover, squish feedback, and tooltip
class ExpressIconButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final double size;
  final Color? tint;
  final Color? background;
  final Color? hoverBackground;
  final double radius;

  const ExpressIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.tooltip,
    this.size = 40.0,
    this.tint,
    this.background,
    this.hoverBackground,
    this.radius = 12.0,
  });

  @override
  State<ExpressIconButton> createState() => _ExpressIconButtonState();
}

class _ExpressIconButtonState extends State<ExpressIconButton> {
  bool _down = false;
  bool _hover = false;

  void _set(bool value) {
    if (_down != value) setState(() => _down = value);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final enabled = widget.onPressed != null;

    final defaultBg = isDark
        ? const Color(0xFF1E2634)
        : const Color(0xFFF1F5F9);
    final defaultTint = isDark ? Colors.white : AppColors.deepNavy;

    final bgColor = widget.background ?? defaultBg;
    final fgColor = widget.tint ?? defaultTint;

    final button = MouseRegion(
      cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: enabled ? (_) => _set(true) : null,
        onTapUp: enabled ? (_) => _set(false) : null,
        onTapCancel: enabled ? () => _set(false) : null,
        onTap: enabled ? widget.onPressed : null,
        child: AnimatedScale(
          scale: _down ? 0.92 : (_hover ? 1.05 : 1.0),
          duration: _down ? Express.fast : Express.quick,
          curve: _down ? Express.settle : Express.bouncy,
          child: AnimatedContainer(
            duration: Express.quick,
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              color: _hover
                  ? (widget.hoverBackground ?? fgColor.withValues(alpha: 0.14))
                  : bgColor,
              borderRadius: BorderRadius.circular(_down ? widget.radius * 0.75 : widget.radius),
              border: Border.all(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                width: 1,
              ),
            ),
            child: Icon(
              widget.icon,
              size: widget.size * 0.46,
              color: enabled ? fgColor : const Color(0xFF94A3B8),
            ),
          ),
        ),
      ),
    );

    if (widget.tooltip != null) {
      return Tooltip(message: widget.tooltip!, child: button);
    }
    return button;
  }
}
