import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_semantic_colors.dart';
import '../../../../core/utils/currency_utils.dart';
import '../../../../core/utils/date_utils.dart';

/// Single slice data model for [VyavahaarInteractiveDonut].
class DonutSliceData {
  final String label;
  final int count;
  final int volumePaise;
  final Color color;

  const DonutSliceData({
    required this.label,
    required this.count,
    required this.volumePaise,
    required this.color,
  });
}

/// 52-week scrollable calendar heatmap inspired by Streak's YearHeatmap.
class VyavahaarYearHeatmap extends StatefulWidget {
  final int year;
  final Map<String, int> dailyCounts;
  final Map<String, int> dailyVolumePaise;
  final Color accentColor;
  final String localeCode;

  const VyavahaarYearHeatmap({
    super.key,
    required this.year,
    required this.dailyCounts,
    required this.dailyVolumePaise,
    required this.accentColor,
    required this.localeCode,
  });

  @override
  State<VyavahaarYearHeatmap> createState() => _VyavahaarYearHeatmapState();
}

class _VyavahaarYearHeatmapState extends State<VyavahaarYearHeatmap> {
  final ScrollController _scroll = ScrollController();
  String? _selectedIsoDay;

  static const double _cell = 14.0;
  static const double _gap = 3.0;
  static const double _step = _cell + _gap;

  @override
  void initState() {
    super.initState();
    _focusLatest();
  }

  @override
  void didUpdateWidget(VyavahaarYearHeatmap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.year != widget.year) {
      _selectedIsoDay = null;
      _focusLatest();
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _focusLatest() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scroll.hasClients) return;
      final now = DateTime.now();
      if (widget.year == now.year) {
        final dayOfYear = now.difference(DateTime(widget.year, 1, 1)).inDays;
        final weekIndex = (dayOfYear / 7).floor();
        final target = math.max(0.0, weekIndex * _step - 180);
        _scroll.jumpTo(target.clamp(0.0, _scroll.position.maxScrollExtent));
      } else {
        _scroll.jumpTo(0);
      }
    });
  }

  static String _iso(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  @override
  Widget build(BuildContext context) {
    final semantic = AppSemanticColors.of(context);
    final jan1 = DateTime(widget.year, 1, 1);
    final dec31 = DateTime(widget.year, 12, 31);
    // Align grid start to Monday of the week containing Jan 1
    final gridStart = jan1.subtract(Duration(days: jan1.weekday - 1));
    final totalDays = dec31.difference(gridStart).inDays + 1;
    final totalWeeks = (totalDays / 7).ceil();

    final maxCount = widget.dailyCounts.values.isEmpty
        ? 1
        : widget.dailyCounts.values.reduce(math.max);

    final monthsShort = widget.localeCode == 'en'
        ? const ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec']
        : const ['जन', 'फर', 'मार्च', 'अप्रै', 'मई', 'जून', 'जुल', 'अग', 'सित', 'अक्टू', 'नव', 'दिस'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SingleChildScrollView(
          controller: _scroll,
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Month Header Row
              SizedBox(
                height: 18,
                width: totalWeeks * _step,
                child: Stack(
                  children: [
                    for (int m = 1; m <= 12; m++)
                      Positioned(
                        left: (DateTime(widget.year, m, 1).difference(gridStart).inDays ~/ 7) * _step,
                        child: Text(
                          monthsShort[m - 1],
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: semantic.textSecondary,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              // 7-Row x 53-Week Grid
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (int w = 0; w < totalWeeks; w++)
                    Padding(
                      padding: const EdgeInsets.only(right: _gap),
                      child: Column(
                        children: [
                          for (int d = 0; d < 7; d++)
                            _buildCell(
                              date: gridStart.add(Duration(days: w * 7 + d)),
                              maxCount: maxCount,
                              semantic: semantic,
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _selectedIsoDay != null
                  ? Text(
                      '${AppDateUtils.formatLocalizedDate(_selectedIsoDay!, widget.localeCode)}: '
                      '${widget.dailyCounts[_selectedIsoDay!] ?? 0} • '
                      '${CurrencyUtils.formatPaise(widget.dailyVolumePaise[_selectedIsoDay!] ?? 0)}',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: widget.accentColor,
                      ),
                    )
                  : Text(
                      widget.localeCode == 'en'
                          ? 'Tap any square to inspect day total'
                          : 'किसी भी दिन की राशि देखने के लिए बॉक्स पर टैप करें',
                      style: TextStyle(
                        fontSize: 11,
                        color: semantic.textSecondary,
                      ),
                    ),
            ),
            const SizedBox(width: 8),
            // Intensity Legend
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final alpha in [0.0, 0.28, 0.55, 0.80, 1.0])
                  Container(
                    width: 10,
                    height: 10,
                    margin: const EdgeInsets.only(left: 3),
                    decoration: BoxDecoration(
                      color: alpha == 0.0
                          ? semantic.cardSubtleBg
                          : widget.accentColor.withValues(alpha: alpha),
                      borderRadius: BorderRadius.circular(3),
                      border: Border.all(
                        color: semantic.cardBorder.withValues(alpha: 0.5),
                        width: 0.5,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCell({
    required DateTime date,
    required int maxCount,
    required AppSemanticColors semantic,
  }) {
    final inYear = date.year == widget.year;
    final iso = _iso(date);
    final count = inYear ? (widget.dailyCounts[iso] ?? 0) : 0;
    final selected = _selectedIsoDay == iso;

    Color fillColor;
    if (!inYear) {
      fillColor = Colors.transparent;
    } else if (count == 0) {
      fillColor = semantic.cardSubtleBg;
    } else {
      final ratio = (count / maxCount).clamp(0.25, 1.0);
      fillColor = widget.accentColor.withValues(alpha: 0.25 + ratio * 0.75);
    }

    return GestureDetector(
      onTap: (!inYear || count == 0)
          ? null
          : () => setState(() => _selectedIsoDay = _selectedIsoDay == iso ? null : iso),
      child: Container(
        width: _cell,
        height: _cell,
        margin: const EdgeInsets.only(bottom: _gap),
        decoration: BoxDecoration(
          color: fillColor,
          borderRadius: BorderRadius.circular(3.5),
          border: selected
              ? Border.all(color: semantic.textPrimary, width: 1.5)
              : (inYear
                  ? Border.all(
                      color: semantic.cardBorder.withValues(alpha: 0.45),
                      width: 0.5,
                    )
                  : null),
        ),
      ),
    );
  }
}

/// Smooth dual-line monthly trend chart (Mila vs Diya) using fl_chart.
class VyavahaarMonthlyTrendChart extends StatelessWidget {
  final List<int> monthlyReceivedPaise;
  final List<int> monthlyGivenPaise;
  final String localeCode;
  final String milaLabel;
  final String diyaLabel;
  final bool showMila;
  final bool showDiya;

  const VyavahaarMonthlyTrendChart({
    super.key,
    required this.monthlyReceivedPaise,
    required this.monthlyGivenPaise,
    required this.localeCode,
    required this.milaLabel,
    required this.diyaLabel,
    this.showMila = true,
    this.showDiya = true,
  });

  @override
  Widget build(BuildContext context) {
    final semantic = AppSemanticColors.of(context);
    final monthsShort = localeCode == 'en'
        ? const ['J', 'F', 'M', 'A', 'M', 'J', 'J', 'A', 'S', 'O', 'N', 'D']
        : const ['ज', 'फ', 'मा', 'अ', 'म', 'जू', 'जु', 'अ', 'सि', 'अ', 'न', 'दि'];

    double maxRupees = 0;
    final milaSpots = <FlSpot>[];
    final diyaSpots = <FlSpot>[];
    for (int i = 0; i < 12; i++) {
      final r = (i < monthlyReceivedPaise.length ? monthlyReceivedPaise[i] : 0) / 100.0;
      final g = (i < monthlyGivenPaise.length ? monthlyGivenPaise[i] : 0) / 100.0;
      if (showMila && r > maxRupees) maxRupees = r;
      if (showDiya && g > maxRupees) maxRupees = g;
      milaSpots.add(FlSpot(i.toDouble(), r));
      diyaSpots.add(FlSpot(i.toDouble(), g));
    }

    final chartMaxY = maxRupees <= 0 ? 1000.0 : (maxRupees * 1.18);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Legend Pills
        Row(
          children: [
            if (showMila) _LegendDot(label: milaLabel, color: semantic.mila, textColor: semantic.textSecondary),
            if (showMila && showDiya) const SizedBox(width: 14),
            if (showDiya) _LegendDot(label: diyaLabel, color: semantic.diya, textColor: semantic.textSecondary),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 205,
          child: LineChart(
            LineChartData(
              minX: 0,
              maxX: 11,
              minY: 0,
              maxY: chartMaxY,
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: chartMaxY / 4,
                getDrawingHorizontalLine: (_) => FlLine(
                  color: semantic.cardBorder.withValues(alpha: 0.6),
                  strokeWidth: 1,
                  dashArray: [4, 4],
                ),
              ),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 44,
                    interval: chartMaxY / 4,
                    getTitlesWidget: (val, meta) {
                      if (val == 0) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: Text(
                          _compactRupees(val),
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: semantic.textSecondary,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: 1,
                    reservedSize: 24,
                    getTitlesWidget: (val, meta) {
                      final idx = val.toInt();
                      if (idx < 0 || idx >= 12) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          monthsShort[idx],
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: semantic.textSecondary,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              lineTouchData: LineTouchData(
                handleBuiltInTouches: true,
                touchTooltipData: LineTouchTooltipData(
                  getTooltipColor: (_) => semantic.heroStart,
                  getTooltipItems: (spots) {
                    return spots.map((s) {
                      final isMilaLine = showMila && s.barIndex == 0;
                      final prefix = isMilaLine ? milaLabel : diyaLabel;
                      return LineTooltipItem(
                        '$prefix: ${CurrencyUtils.formatPaise((s.y * 100).round())}',
                        TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: semantic.onHero,
                        ),
                      );
                    }).toList();
                  },
                ),
              ),
              lineBarsData: [
                if (showMila)
                  LineChartBarData(
                    spots: milaSpots,
                    isCurved: true,
                    preventCurveOverShooting: true,
                    color: semantic.mila,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, bar, idx) => FlDotCirclePainter(
                        radius: spot.y > 0 ? 3.2 : 0,
                        color: semantic.mila,
                        strokeWidth: 1.5,
                        strokeColor: semantic.cardBg,
                      ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          semantic.mila.withValues(alpha: 0.24),
                          semantic.mila.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                if (showDiya)
                  LineChartBarData(
                    spots: diyaSpots,
                    isCurved: true,
                    preventCurveOverShooting: true,
                    color: semantic.diya,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, bar, idx) => FlDotCirclePainter(
                        radius: spot.y > 0 ? 3.2 : 0,
                        color: semantic.diya,
                        strokeWidth: 1.5,
                        strokeColor: semantic.cardBg,
                      ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          semantic.diya.withValues(alpha: 0.22),
                          semantic.diya.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            duration: const Duration(milliseconds: 500),
          ),
        ),
      ],
    );
  }

  static String _compactRupees(double rupees) {
    if (rupees >= 100000) return '${(rupees / 100000).toStringAsFixed(1)}L';
    if (rupees >= 1000) return '${(rupees / 1000).toStringAsFixed(1)}k';
    return rupees.round().toString();
  }
}

class _LegendDot extends StatelessWidget {
  final String label;
  final Color color;
  final Color textColor;

  const _LegendDot({
    required this.label,
    required this.color,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: textColor),
        ),
      ],
    );
  }
}

/// Interactive animated donut chart adapted from Streak's HabitDonut.
class VyavahaarInteractiveDonut extends StatefulWidget {
  final List<DonutSliceData> slices;
  final String centerTitle;
  final double height;

  const VyavahaarInteractiveDonut({
    super.key,
    required this.slices,
    required this.centerTitle,
    this.height = 210,
  });

  @override
  State<VyavahaarInteractiveDonut> createState() => _VyavahaarInteractiveDonutState();
}

class _VyavahaarInteractiveDonutState extends State<VyavahaarInteractiveDonut>
    with TickerProviderStateMixin {
  late final AnimationController _reveal = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 850),
  )..forward();

  late final AnimationController _select = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 280),
    value: 1,
  );

  int? _selected;
  List<double> _from = const [];
  List<double> _to = const [];

  @override
  void didUpdateWidget(VyavahaarInteractiveDonut oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.slices.length != widget.slices.length) {
      _selected = null;
      _from = const [];
      _to = const [];
    }
  }

  @override
  void dispose() {
    _reveal.dispose();
    _select.dispose();
    super.dispose();
  }

  double _at(List<double> vals, int idx) => idx < vals.length ? vals[idx] : 0.0;

  List<double> get _expansion => [
        for (int i = 0; i < widget.slices.length; i++)
          _at(_from, i) + (_at(_to, i) - _at(_from, i)) * _select.value,
      ];

  void _tapSlice(int? idx) {
    final next = idx == _selected ? null : idx;
    setState(() {
      _from = _expansion;
      _to = [
        for (int i = 0; i < widget.slices.length; i++) i == next ? 1.0 : 0.0,
      ];
      _selected = next;
    });
    _select.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final semantic = AppSemanticColors.of(context);
    final total = widget.slices.fold<int>(0, (sum, s) => sum + s.count);
    if (total == 0) return const SizedBox.shrink();

    final activeSlice =
        (_selected != null && _selected! < widget.slices.length) ? widget.slices[_selected!] : null;

    return Column(
      children: [
        SizedBox(
          height: widget.height,
          width: double.infinity,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final size = constraints.biggest;
              final center = size.center(Offset.zero);
              final outer = math.min(size.width, size.height) * 0.42;
              final inner = outer * 0.56;

              return GestureDetector(
                onTapDown: (details) {
                  final dx = details.localPosition.dx - center.dx;
                  final dy = details.localPosition.dy - center.dy;
                  final dist = math.sqrt(dx * dx + dy * dy);
                  if (dist < inner * 0.85 || dist > outer * 1.15) {
                    _tapSlice(null);
                    return;
                  }
                  var angle = math.atan2(dy, dx) + math.pi / 2;
                  if (angle < 0) angle += 2 * math.pi;
                  double running = 0;
                  for (int i = 0; i < widget.slices.length; i++) {
                    final sweep = (widget.slices[i].count / total) * 2 * math.pi;
                    if (angle >= running && angle <= running + sweep) {
                      _tapSlice(i);
                      return;
                    }
                    running += sweep;
                  }
                },
                child: AnimatedBuilder(
                  animation: Listenable.merge([_reveal, _select]),
                  builder: (context, _) {
                    return CustomPaint(
                      painter: _DonutChartPainter(
                        slices: widget.slices,
                        total: total,
                        reveal: Curves.easeOutCubic.transform(_reveal.value),
                        expansions: _expansion,
                        selected: _selected,
                        gapColor: semantic.cardBg,
                      ),
                      child: Center(
                        child: SizedBox(
                          width: inner * 1.65,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                activeSlice != null
                                    ? '${((activeSlice.count / total) * 100).round()}%'
                                    : '$total',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: activeSlice?.color ?? semantic.textPrimary,
                                ),
                              ),
                              Text(
                                activeSlice != null ? activeSlice.label : widget.centerTitle,
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: semantic.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: [
            for (int i = 0; i < widget.slices.length; i++)
              InkWell(
                onTap: () => _tapSlice(i),
                borderRadius: BorderRadius.circular(18),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: _selected == i
                        ? widget.slices[i].color.withValues(alpha: 0.16)
                        : semantic.cardSubtleBg,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: _selected == i ? widget.slices[i].color : semantic.cardBorder,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: widget.slices[i].color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${widget.slices[i].label} (${widget.slices[i].count})',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: semantic.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _DonutChartPainter extends CustomPainter {
  final List<DonutSliceData> slices;
  final int total;
  final double reveal;
  final List<double> expansions;
  final int? selected;
  final Color gapColor;

  const _DonutChartPainter({
    required this.slices,
    required this.total,
    required this.reveal,
    required this.expansions,
    required this.selected,
    required this.gapColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final outerRadius = math.min(size.width, size.height) * 0.41;
    final innerRadius = outerRadius * 0.56;
    final strokeWidth = outerRadius - innerRadius;
    final midRadius = (outerRadius + innerRadius) / 2;

    double startAngle = -math.pi / 2;
    for (int i = 0; i < slices.length; i++) {
      final slice = slices[i];
      final sweep = (slice.count / total) * 2 * math.pi * reveal;
      if (sweep <= 0) continue;

      final expand = i < expansions.length ? expansions[i] : 0.0;
      final midAngle = startAngle + sweep / 2;
      final shift = Offset(
        math.cos(midAngle) * expand * 7.0,
        math.sin(midAngle) * expand * 7.0,
      );

      final isDimmed = selected != null && selected != i;
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth + expand * 5.0
        ..color = isDimmed ? slice.color.withValues(alpha: 0.35) : slice.color;

      final gap = slices.length > 1 ? 0.035 : 0.0;
      final drawSweep = math.max(0.01, sweep - gap);
      canvas.drawArc(
        Rect.fromCircle(center: center + shift, radius: midRadius),
        startAngle + gap / 2,
        drawSweep,
        false,
        paint,
      );
      startAngle += sweep;
    }
  }

  @override
  bool shouldRepaint(_DonutChartPainter old) => true;
}

/// Weekday column bar chart adapted from Streak's WeekdayBars.
class VyavahaarWeekdayBars extends StatelessWidget {
  final List<int> weekdayCounts;
  final List<int> weekdayVolumePaise;
  final Color barColor;
  final String localeCode;

  const VyavahaarWeekdayBars({
    super.key,
    required this.weekdayCounts,
    required this.weekdayVolumePaise,
    required this.barColor,
    required this.localeCode,
  });

  @override
  Widget build(BuildContext context) {
    final semantic = AppSemanticColors.of(context);
    final days = localeCode == 'en'
        ? const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
        : const ['सोम', 'मंगल', 'बुध', 'गुरु', 'शुक्र', 'शनि', 'रवि'];

    final maxCount = weekdayCounts.isEmpty ? 1 : math.max(1, weekdayCounts.reduce(math.max));

    return SizedBox(
      height: 170,
      child: BarChart(
        BarChartData(
          maxY: (maxCount * 1.25).ceilToDouble(),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) => FlLine(
              color: semantic.cardBorder.withValues(alpha: 0.55),
              strokeWidth: 1,
              dashArray: [4, 4],
            ),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 26,
                getTitlesWidget: (val, meta) {
                  final idx = val.toInt();
                  if (idx < 0 || idx >= 7) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      days[idx],
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: semantic.textSecondary,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) => semantic.heroStart,
              getTooltipItem: (group, groupIdx, rod, rodIdx) {
                final idx = group.x;
                final vol = idx < weekdayVolumePaise.length ? weekdayVolumePaise[idx] : 0;
                return BarTooltipItem(
                  '${days[idx]}: ${rod.toY.round()}\n${CurrencyUtils.formatPaise(vol)}',
                  TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: semantic.onHero,
                  ),
                );
              },
            ),
          ),
          barGroups: [
            for (int i = 0; i < 7; i++)
              BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY: (i < weekdayCounts.length ? weekdayCounts[i] : 0).toDouble(),
                    width: 22,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        barColor.withValues(alpha: 0.72),
                        barColor,
                      ],
                    ),
                    backDrawRodData: BackgroundBarChartRodData(
                      show: true,
                      toY: (maxCount * 1.25).ceilToDouble(),
                      color: semantic.cardSubtleBg,
                    ),
                  ),
                ],
              ),
          ],
        ),
        duration: const Duration(milliseconds: 500),
      ),
    );
  }
}
