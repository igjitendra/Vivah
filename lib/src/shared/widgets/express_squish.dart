import 'package:flutter/animation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

/// Tactile spring curve inspired by iOS & InlitX/streak
class ExpressSpring extends Curve {
  const ExpressSpring({
    required this.ratio,
    required this.stiffness,
    required this.seconds,
  });

  final double ratio;
  final double stiffness;
  final double seconds;

  @override
  double transformInternal(double t) {
    final simulation = SpringSimulation(
      SpringDescription.withDampingRatio(
        mass: 1,
        stiffness: stiffness,
        ratio: ratio,
      ),
      0,
      1,
      0,
    );
    return simulation.x(t * seconds);
  }
}

/// Express Motion and Spacing Design Tokens
class Express {
  const Express._();

  static const fast = Duration(milliseconds: 160);
  static const quick = Duration(milliseconds: 280);
  static const normal = Duration(milliseconds: 450);

  static const bouncy = ExpressSpring(
    ratio: 0.58,
    stiffness: 380,
    seconds: 0.52,
  );
  static const settle = Curves.easeOutCubic;

  static const heroRadius = 28.0;
  static const cardRadius = 20.0;
  static const pillRadius = 16.0;
  static const inset = 16.0;
}

/// Tactile spring scale feedback on tap and long press
class ExpressSquish extends StatefulWidget {
  const ExpressSquish({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.scale = 0.965,
  });

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double scale;

  @override
  State<ExpressSquish> createState() => _ExpressSquishState();
}

class _ExpressSquishState extends State<ExpressSquish> {
  bool _down = false;

  void _set(bool value) {
    if (_down != value) setState(() => _down = value);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null || widget.onLongPress != null;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: enabled ? (_) => _set(true) : null,
      onTapUp: enabled ? (_) => _set(false) : null,
      onTapCancel: enabled ? () => _set(false) : null,
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      child: AnimatedScale(
        scale: _down && enabled ? widget.scale : 1,
        duration: _down ? Express.fast : Express.quick,
        curve: _down ? Express.settle : Express.bouncy,
        child: widget.child,
      ),
    );
  }
}

/// Reusable Express Material 3 Card with hairline border and optional squish
class ExpressCard extends StatelessWidget {
  const ExpressCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(Express.inset),
    this.radius = Express.cardRadius,
    this.color,
    this.borderColor,
    this.onTap,
    this.onLongPress,
    this.elevation = 0,
    this.clip = false,
  });

  final Widget child;
  final EdgeInsets padding;
  final double radius;
  final Color? color;
  final Color? borderColor;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double elevation;
  final bool clip;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final cardBg = color ?? (isDark ? theme.colorScheme.surface : Colors.white);
    final cardBorder = borderColor ?? (isDark ? const Color(0xFF262E3D) : const Color(0xFFE2E8F0));

    final body = Container(
      clipBehavior: clip ? Clip.antiAlias : Clip.none,
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: cardBorder, width: 1),
        boxShadow: elevation > 0
            ? [
                BoxShadow(
                  color: isDark ? Colors.black26 : const Color(0x120F172A),
                  blurRadius: elevation * 4,
                  offset: Offset(0, elevation * 1.5),
                ),
              ]
            : null,
      ),
      padding: padding,
      child: child,
    );

    if (onTap == null && onLongPress == null) return body;
    return ExpressSquish(onTap: onTap, onLongPress: onLongPress, child: body);
  }
}
