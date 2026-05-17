import 'package:flutter/material.dart';

/// Visual configuration for the team logo avatar in the default match card.
class TeamLogoTheme {
  const TeamLogoTheme({
    this.backgroundColor,
    this.fallbackIcon = Icons.sports_soccer,
    this.fallbackIconColor,
    this.size = 20.0,
    this.borderRadius,
    this.border,
    this.padding = EdgeInsets.zero,
  });

  /// Background color of the avatar circle/container.
  /// Defaults to theme's surfaceContainerHighest.
  final Color? backgroundColor;

  /// Icon shown when the team has no image or the image fails to load.
  final IconData fallbackIcon;

  /// Color of the fallback icon. Defaults to theme's onSurfaceVariant.
  final Color? fallbackIconColor;

  /// Total size (width & height) of the logo container.
  final double size;

  /// Optional border radius. If null, the logo is a perfect circle.
  final BorderRadius? borderRadius;

  /// Optional border around the logo.
  final BoxBorder? border;

  /// Padding inside the logo container (between border and image).
  final EdgeInsets padding;
}

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
    this.previousRoundPeek = 32.0,
    this.teamLogoTheme = const TeamLogoTheme(),
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

  /// How much of the previous round's connector area peeks from the left edge
  /// when snapped to a round. Set to 0 to disable the preview.
  /// Defaults to 32.0 (shows connectors of the previous round).
  final double previousRoundPeek;

  /// Visual configuration for team logo avatars in the default match card.
  /// Has no effect when a custom [BracketView.teamImageBuilder] is provided.
  final TeamLogoTheme teamLogoTheme;
}
