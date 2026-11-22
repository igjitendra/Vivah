import 'dart:io';
import 'package:flutter/widgets.dart';

/// Responsive Breakpoint Tokens inspired directly by InlitX/streak
const double phoneWidth = 560.0;
const double railWidth = 640.0;
const double splitWidth = 900.0;
const double wideWidth = 1060.0;
const double paneWidth = 480.0;

/// Returns true if layout has ample room for a side navigation rail (PC desktop or wide tablet)
bool hasSideRail(BuildContext context) {
  final width = MediaQuery.sizeOf(context).width;
  // If desktop (Windows, Linux, macOS) or wide screen on web/tablet
  return width >= railWidth;
}

/// Returns true if wide enough for dual-pane split view (List on left, Details on right)
bool isWideLayout(BuildContext context) {
  final width = MediaQuery.sizeOf(context).width;
  return width >= splitWidth;
}

/// Returns true if navigation rail should be in compact (icon-only) mode
bool isCompactRail(BuildContext context) {
  final width = MediaQuery.sizeOf(context).width;
  return width >= railWidth && width < wideWidth;
}

/// Returns true if screen is narrow phone format (<560dp)
bool isPhone(BuildContext context) {
  return MediaQuery.sizeOf(context).width < phoneWidth;
}
