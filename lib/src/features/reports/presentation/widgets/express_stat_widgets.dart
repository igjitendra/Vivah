import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/theme/app_semantic_colors.dart';
import '../../../../shared/widgets/express_squish.dart';

/// Geometric organic shapes adapted from Streak's ExpressShape system.
class ExpressBlobShape {
  const ExpressBlobShape({
    this.exponent = 4.2,
    this.sides = 8,
    this.amplitude = 0,
    this.rotation = 0,
  });

  static const squircle = ExpressBlobShape();
  static const circle = ExpressBlobShape(exponent: 2);
  static const cookie = ExpressBlobShape(exponent: 2, sides: 9, amplitude: 0.085);
  static const flower = ExpressBlobShape(exponent: 2, sides: 6, amplitude: 0.14);
  static const burst = ExpressBlobShape(exponent: 2, sides: 12, amplitude: 0.055);
  static const pebble = ExpressBlobShape(exponent: 2.6, sides: 4, amplitude: 0.045);
  static const clover = ExpressBlobShape(
    exponent: 2,
    sides: 4,
    amplitude: 0.155,
    rotation: 0.78,
  );
  static const gem = ExpressBlobShape(
    exponent: 3.2,
    sides: 6,
    amplitude: 0.03,
    rotation: 0.52,
  );
  static const sunny = ExpressBlobShape(exponent: 2, sides: 8, amplitude: 0.07);

  static const List<ExpressBlobShape> family = [
    cookie,
    clover,
    burst,
    gem,
    flower,
    sunny,
    pebble,
  ];

  static ExpressBlobShape pick(int index) => family[index.abs() % family.length];

  final double exponent;
  final double sides;
  final double amplitude;
  final double rotation;

  double _unitRadius(double angle) {
    final a = angle + rotation;
    final cos = math.cos(a).abs();
    final sin = math.sin(a).abs();
    final base = math.pow(
      math.pow(cos, exponent) + math.pow(sin, exponent),
      -1 / exponent,
    );
    return base * (1 - amplitude + amplitude * math.cos(sides * a));
  }

  Path path(Rect rect) {
    const steps = 96;
    final center = rect.center;
    final rx = rect.width / 2;
    final ry = rect.height / 2;
    final p = Path();
    for (var i = 0; i <= steps; i++) {
      final angle = i * 2 * math.pi / steps;
      final radius = _unitRadius(angle);
      final point = Offset(
        center.dx + radius * math.cos(angle) * rx,
        center.dy + radius * math.sin(angle) * ry,
      );
      if (i == 0) {
        p.moveTo(point.dx, point.dy);
      } else {
        p.lineTo(point.dx, point.dy);
      }
    }
    return p..close();
  }
}

class _ExpressBlobClipper extends CustomClipper<Path> {
  final ExpressBlobShape shape;
  const _ExpressBlobClipper(this.shape);

  @override
  Path getClip(Size size) => shape.path(Offset.zero & size);

  @override
  bool shouldReclip(_ExpressBlobClipper old) => old.shape != shape;
}

/// Organic shaped icon container inspired by Streak's ExpressBlob.
class ExpressBlob extends StatelessWidget {
  final double size;
  final Color color;
  final ExpressBlobShape shape;
  final Widget child;

  const ExpressBlob({
    super.key,
    required this.size,
    required this.color,
    this.shape = ExpressBlobShape.cookie,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: ClipPath(
        clipper: _ExpressBlobClipper(shape),
        child: ColoredBox(
          color: color,
          child: Center(child: child),
        ),
      ),
    );
  }
}

/// Spring-animated wobbling pill tab switcher adapted from Streak's ExpressTabs.
class ExpressPillTabs extends StatefulWidget {
  final List<String> labels;
  final int index;
  final ValueChanged<int> onChanged;
  final double height;

  const ExpressPillTabs({
    super.key,
    required this.labels,
    required this.index,
    required this.onChanged,
    this.height = 46,
  });

  @override
  State<ExpressPillTabs> createState() => _ExpressPillTabsState();
}

class _ExpressPillTabsState extends State<ExpressPillTabs>
    with SingleTickerProviderStateMixin {
  late final AnimationController _slide = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 340),
    value: 1,
  );
  late double _from = widget.index.toDouble();
  late double _to = widget.index.toDouble();

  @override
  void didUpdateWidget(ExpressPillTabs old) {
    super.didUpdateWidget(old);
    if (old.index == widget.index) return;
    _from = _position;
    _to = widget.index.toDouble();
    _slide.forward(from: 0);
  }

  @override
  void dispose() {
    _slide.dispose();
    super.dispose();
  }

  double get _position =>
      _from + (_to - _from) * Curves.easeOutBack.transform(_slide.value);

  @override
  Widget build(BuildContext context) {
    final semantic = AppSemanticColors.of(context);
    final count = widget.labels.length;
    final inner = widget.height - 8;

    return LayoutBuilder(
      builder: (context, box) {
        final available = math.max(0.0, box.maxWidth - 8);
        final slot = available / count;
        return Container(
          height: widget.height,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: semantic.cardSubtleBg,
            borderRadius: BorderRadius.circular(widget.height / 2),
            border: Border.all(color: semantic.cardBorder),
          ),
          child: Stack(
            children: [
              AnimatedBuilder(
                animation: _slide,
                builder: (context, _) {
                  final travel = (_to - _from).abs().clamp(0.0, 2.0).toDouble();
                  final wobble = math.sin(math.pi * _slide.value) * 0.12 * travel;
                  final width = (slot * (1 + wobble)).clamp(0.0, available).toDouble();
                  final maxLeft = math.max(0.0, available - width);
                  final left = (_position * slot - slot * wobble / 2).clamp(0.0, maxLeft).toDouble();
                  return Transform.translate(
                    offset: Offset(left, 0),
                    child: Container(
                      width: width,
                      height: inner,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            semantic.primary,
                            semantic.primary.withValues(alpha: 0.85),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(inner / 2),
                      ),
                    ),
                  );
                },
              ),
              Row(
                children: [
                  for (var i = 0; i < count; i++)
                    Expanded(
                      child: Semantics(
                        button: true,
                        selected: i == widget.index,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () {
                            if (i != widget.index) widget.onChanged(i);
                          },
                          child: Center(
                            child: AnimatedDefaultTextStyle(
                              duration: const Duration(milliseconds: 220),
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: i == widget.index
                                    ? semantic.onVibrant
                                    : semantic.textSecondary,
                              ),
                              child: Text(
                                widget.labels[i],
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Sinusoidal wavy progress ring adapted from Streak's ExpressWaveRing.
class ExpressWaveRing extends StatelessWidget {
  final double value;
  final Color color;
  final Color track;
  final double size;
  final double stroke;
  final int waves;
  final double amplitude;
  final Widget? child;

  const ExpressWaveRing({
    super.key,
    required this.value,
    required this.color,
    required this.track,
    this.size = 168,
    this.stroke = 15,
    this.waves = 10,
    this.amplitude = 2.6,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.88, end: 1.0),
        duration: const Duration(milliseconds: 520),
        curve: Curves.easeOutBack,
        builder: (context, pop, c) => Transform.scale(scale: pop, child: c),
        child: SizedBox(
          width: size,
          height: size,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: value.clamp(0.0, 1.0)),
            duration: const Duration(milliseconds: 1000),
            curve: Curves.easeOutCubic,
            builder: (context, val, c) => CustomPaint(
              painter: _WaveRingPainter(
                value: val,
                color: color,
                track: track,
                stroke: stroke,
                waves: waves,
                amplitude: amplitude,
              ),
              child: c,
            ),
            child: Center(child: child),
          ),
        ),
      ),
    );
  }
}

class _WaveRingPainter extends CustomPainter {
  final double value;
  final Color color;
  final Color track;
  final double stroke;
  final int waves;
  final double amplitude;

  const _WaveRingPainter({
    required this.value,
    required this.color,
    required this.track,
    required this.stroke,
    required this.waves,
    required this.amplitude,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = (size.shortestSide - stroke) / 2 - amplitude;
    final paint = Paint()
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    canvas.drawCircle(center, radius, paint..color = track);
    if (value <= 0) return;

    final sweep = 2 * math.pi * value.clamp(0.0, 1.0);
    final swell = Curves.easeOutCubic.transform(math.min(value * 5, 1));
    final path = Path();
    final steps = math.max((sweep * radius / 2).round(), 10);
    for (var i = 0; i <= steps; i++) {
      final t = i / steps;
      final angle = -math.pi / 2 + sweep * t;
      final edge = math.min((1 - t) * 12, 1).clamp(0.0, 1.0) *
          math.min(t * 12, 1).clamp(0.0, 1.0);
      final lift = amplitude * swell * edge * math.sin(waves * angle);
      final r = radius + lift;
      final pt = Offset(
        center.dx + r * math.cos(angle),
        center.dy + r * math.sin(angle),
      );
      if (i == 0) {
        path.moveTo(pt.dx, pt.dy);
      } else {
        path.lineTo(pt.dx, pt.dy);
      }
    }
    canvas.drawPath(path, paint..color = color);
  }

  @override
  bool shouldRepaint(_WaveRingPainter old) =>
      old.value != value || old.color != color || old.track != track;
}

/// Year navigator bar with All-Years toggle chip.
class ExpressYearNavigator extends StatelessWidget {
  final int? selectedYear;
  final int fallbackYear;
  final bool canGoForward;
  final String allYearsLabel;
  final ValueChanged<int?> onSelectYear;

  const ExpressYearNavigator({
    super.key,
    required this.selectedYear,
    required this.fallbackYear,
    required this.canGoForward,
    required this.allYearsLabel,
    required this.onSelectYear,
  });

  @override
  Widget build(BuildContext context) {
    final semantic = AppSemanticColors.of(context);
    final displayYear = selectedYear ?? fallbackYear;
    final isAllYears = selectedYear == null;

    return Row(
      children: [
        _CircleNavBtn(
          icon: Icons.chevron_left_rounded,
          semantic: semantic,
          onTap: () => onSelectYear(displayYear - 1),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Center(
            child: InkWell(
              onTap: () => onSelectYear(isAllYears ? fallbackYear : null),
              borderRadius: BorderRadius.circular(22),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                decoration: BoxDecoration(
                  color: semantic.primary.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: semantic.primary.withValues(alpha: 0.30)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.calendar_today_rounded, size: 15, color: semantic.primary),
                    const SizedBox(width: 8),
                    Text(
                      isAllYears ? allYearsLabel : '$displayYear',
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                        color: semantic.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        _CircleNavBtn(
          icon: Icons.chevron_right_rounded,
          semantic: semantic,
          onTap: (!isAllYears && canGoForward)
              ? () => onSelectYear(displayYear + 1)
              : null,
        ),
        const SizedBox(width: 8),
        InkWell(
          onTap: () => onSelectYear(isAllYears ? fallbackYear : null),
          borderRadius: BorderRadius.circular(18),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: isAllYears ? semantic.primary : semantic.cardSubtleBg,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isAllYears ? semantic.primary : semantic.cardBorder,
              ),
            ),
            child: Text(
              allYearsLabel,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: isAllYears ? semantic.onVibrant : semantic.textSecondary,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _CircleNavBtn extends StatelessWidget {
  final IconData icon;
  final AppSemanticColors semantic;
  final VoidCallback? onTap;

  const _CircleNavBtn({
    required this.icon,
    required this.semantic,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Material(
      color: semantic.cardBg,
      shape: CircleBorder(side: BorderSide(color: semantic.cardBorder)),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(
            icon,
            size: 20,
            color: enabled
                ? semantic.textPrimary
                : semantic.textSecondary.withValues(alpha: 0.35),
          ),
        ),
      ),
    );
  }
}

/// Compact KPI Bento Tile styled after Streak's ExpressStatTile.
class ExpressStatTile extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final String? sublabel;
  final Color tint;
  final ExpressBlobShape shape;
  final VoidCallback? onTap;

  const ExpressStatTile({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
    this.sublabel,
    required this.tint,
    this.shape = ExpressBlobShape.cookie,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final semantic = AppSemanticColors.of(context);
    return ExpressSquish(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: tint.withValues(alpha: 0.11),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: tint.withValues(alpha: 0.24)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            ExpressBlob(
              size: 36,
              color: tint.withValues(alpha: 0.20),
              shape: shape,
              child: Icon(icon, size: 17, color: tint),
            ),
            const SizedBox(height: 12),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                  color: semantic.textPrimary,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: semantic.textSecondary,
              ),
            ),
            if (sublabel != null) ...[
              const SizedBox(height: 2),
              Text(
                sublabel!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: tint,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Stat row styled after Streak's ExpressStatRow.
class ExpressStatRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color tint;
  final ExpressBlobShape shape;
  final VoidCallback? onTap;

  const ExpressStatRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.tint,
    this.shape = ExpressBlobShape.cookie,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final semantic = AppSemanticColors.of(context);
    return ExpressSquish(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: semantic.cardBg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: semantic.cardBorder),
        ),
        child: Row(
          children: [
            ExpressBlob(
              size: 42,
              color: tint.withValues(alpha: 0.16),
              shape: shape,
              child: Icon(icon, size: 19, color: tint),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: semantic.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      value,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                        color: semantic.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (onTap != null)
              Icon(Icons.chevron_right_rounded, size: 20, color: semantic.textSecondary),
          ],
        ),
      ),
    );
  }
}

/// Section panel card wrapping charts and breakdowns.
class ExpressStatPanel extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color tint;
  final ExpressBlobShape shape;
  final Widget? trailing;
  final Widget child;

  const ExpressStatPanel({
    super.key,
    required this.title,
    required this.icon,
    required this.tint,
    this.shape = ExpressBlobShape.cookie,
    this.trailing,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final semantic = AppSemanticColors.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: semantic.cardBg,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: semantic.cardBorder),
        boxShadow: [
          BoxShadow(
            color: semantic.shadow,
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ExpressBlob(
                size: 34,
                color: tint.withValues(alpha: 0.16),
                shape: shape,
                child: Icon(icon, size: 17, color: tint),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w800,
                    color: semantic.textPrimary,
                  ),
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

/// Animated rounded progress track with dot endpoint adapted from Streak's ExpressLevelBar.
class ExpressLevelBar extends StatelessWidget {
  final double value;
  final Color color;
  final double stroke;

  const ExpressLevelBar({
    super.key,
    required this.value,
    required this.color,
    this.stroke = 7,
  });

  @override
  Widget build(BuildContext context) {
    final semantic = AppSemanticColors.of(context);
    final track = semantic.cardBorder.withValues(alpha: 0.7);
    return SizedBox(
      height: stroke,
      child: LayoutBuilder(
        builder: (context, box) => TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: value.clamp(0.0, 1.0)),
          duration: const Duration(milliseconds: 700),
          curve: Curves.easeOutCubic,
          builder: (context, t, _) {
            final maxWidth = box.maxWidth;
            final usable = math.max(0.0, maxWidth - stroke - 6);
            final filled = usable * t;
            return Stack(
              children: [
                Positioned(
                  right: 0,
                  child: Container(
                    width: stroke,
                    height: stroke,
                    decoration: BoxDecoration(
                      color: t >= 0.99 ? color : track,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                if (t < 0.99)
                  Positioned(
                    left: filled + 6,
                    right: stroke + 6,
                    child: Container(
                      height: stroke,
                      decoration: BoxDecoration(
                        color: track,
                        borderRadius: BorderRadius.circular(stroke),
                      ),
                    ),
                  ),
                Container(
                  width: math.max(stroke, filled),
                  height: stroke,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(stroke),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Single ranked entry item for [ExpressRankingList].
class ExpressRankedItem {
  final String name;
  final String formattedValue;
  final int rawScore;
  final String? subtitle;
  final Color color;
  final VoidCallback? onTap;

  const ExpressRankedItem({
    required this.name,
    required this.formattedValue,
    required this.rawScore,
    this.subtitle,
    required this.color,
    this.onTap,
  });
}

/// Streak-style ranked list with animated level bars.
class ExpressRankingList extends StatelessWidget {
  final List<ExpressRankedItem> items;

  const ExpressRankingList({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    final semantic = AppSemanticColors.of(context);
    final maxScore = items.map((e) => e.rawScore).reduce(math.max);
    final totalScore = items.fold<int>(0, (sum, e) => sum + e.rawScore);

    return Column(
      children: [
        for (var i = 0; i < items.length; i++) ...[
          InkWell(
            onTap: items[i].onTap,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 22,
                        height: 22,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: items[i].color.withValues(alpha: 0.16),
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '${i + 1}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: items[i].color,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              items[i].name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: semantic.textPrimary,
                              ),
                            ),
                            if (items[i].subtitle != null)
                              Text(
                                items[i].subtitle!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: semantic.textSecondary,
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        totalScore > 0
                            ? '${items[i].formattedValue} · ${(items[i].rawScore / totalScore * 100).round()}%'
                            : items[i].formattedValue,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: semantic.textSecondary,
                        ),
                      ),
                      if (items[i].onTap != null) ...[
                        const SizedBox(width: 2),
                        Icon(
                          Icons.chevron_right_rounded,
                          size: 16,
                          color: semantic.textSecondary,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),
                  ExpressLevelBar(
                    value: maxScore == 0 ? 0.0 : items[i].rawScore / maxScore,
                    color: items[i].color,
                  ),
                ],
              ),
            ),
          ),
          if (i < items.length - 1) const SizedBox(height: 12),
        ],
      ],
    );
  }
}
