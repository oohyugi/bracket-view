import 'package:flutter/material.dart';

/// Visual configuration for the bracket widget.
class BracketTheme {
  const BracketTheme({
    this.columnWidth = 220.0,
    this.columnGap = 24.0,
    this.cardHeight = 90.0,
    this.compactGap = 12.0,
    this.connectorColor,
    this.connectorWidth = 1.5,
    this.cardDecoration,
    this.chipSelectedColor,
    this.chipUnselectedColor,
    this.chipHeight = 32.0,
    this.chipPadding = const EdgeInsets.symmetric(horizontal: 10),
    this.chipTextStyle,
    this.snapDuration = const Duration(milliseconds: 250),
    this.snapCurve = Curves.easeOutCubic,
  });

  /// Width of each round column.
  final double columnWidth;

  /// Gap between columns (connector area).
  final double columnGap;

  /// Estimated card height for position calculations.
  final double cardHeight;

  /// Gap between cards in compact (snapped) layout.
  final double compactGap;

  /// Color of connector lines. Defaults to theme's outlineVariant.
  final Color? connectorColor;

  /// Stroke width of connector lines.
  final double connectorWidth;

  /// Optional custom decoration for match cards.
  final BoxDecoration? cardDecoration;

  /// Chip selected color. Defaults to theme's primary.
  final Color? chipSelectedColor;

  /// Chip unselected color. Defaults to theme's surfaceContainerHighest.
  final Color? chipUnselectedColor;

  /// Height of the chip bar row.
  final double chipHeight;

  /// Padding inside each chip.
  final EdgeInsets chipPadding;

  /// Text style for chip labels. Defaults to bodySmall with fontSize 11.
  final TextStyle? chipTextStyle;

  /// Duration of snap animation.
  final Duration snapDuration;

  /// Curve of snap animation.
  final Curve snapCurve;
}
