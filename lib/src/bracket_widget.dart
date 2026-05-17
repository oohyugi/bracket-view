import 'dart:ui';

import 'package:flutter/material.dart';

import 'package:bracket_view/src/bracket_theme.dart';
import 'package:bracket_view/src/models/bracket_match.dart';
import 'package:bracket_view/src/models/bracket_round.dart';
import 'package:bracket_view/src/models/bracket_team.dart';

/// A responsive tournament bracket widget.
///
/// On small screens: horizontal scroll with snap-to-round behavior and
/// scroll-driven card position animations (bracket-aligned ↔ compact).
///
/// On large screens: displays all rounds at once as a static bracket tree
/// with round name headers above each column.
class BracketView extends StatefulWidget {
  const BracketView({
    super.key,
    required this.rounds,
    this.initialRoundIndex = 0,
    this.onRoundChanged,
    this.onMatchTap,
    this.matchCardBuilder,
    this.teamImageBuilder,
    this.theme = const BracketTheme(),
  });

  /// List of rounds in bracket order (first round → final).
  final List<BracketRound> rounds;

  /// Initial round to scroll to.
  final int initialRoundIndex;

  /// Called when the active round changes (via scroll or chip tap).
  final ValueChanged<int>? onRoundChanged;

  /// Called when a match card is tapped.
  final ValueChanged<BracketMatch>? onMatchTap;

  /// Optional custom builder for match cards.
  /// If null, uses default card design.
  final Widget Function(BuildContext context, BracketMatch match)?
  matchCardBuilder;

  /// Optional builder for team images/logos.
  /// If null, shows a placeholder circle.
  final Widget Function(BuildContext context, String? imageUrl, double size)?
  teamImageBuilder;

  /// Visual theme configuration.
  final BracketTheme theme;

  @override
  State<BracketView> createState() => _BracketViewState();
}

class _BracketViewState extends State<BracketView> {
  final ScrollController _hScrollController = ScrollController();
  double _scrollOffset = 0;
  int _snappedIndex = 0;
  int _activeIndex = 0;

  @override
  void initState() {
    super.initState();
    _activeIndex = widget.initialRoundIndex;
    _snappedIndex = widget.initialRoundIndex;
    _hScrollController.addListener(_onScrollUpdate);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToIndex(_activeIndex, animated: false);
    });
  }

  @override
  void dispose() {
    _hScrollController.removeListener(_onScrollUpdate);
    _hScrollController.dispose();
    super.dispose();
  }

  double _viewportWidth = 0;

  /// Updates snappedIndex on backward scroll. Does NOT call setState
  /// because the body rebuilds via AnimatedBuilder listening to the
  /// scroll controller. State updates that need a rebuild of the chip
  /// bar happen in _onScrollEnd via setState.
  void _onScrollUpdate() {
    final newOffset = _hScrollController.offset;
    if (newOffset < _scrollOffset) {
      int currentIdx = 0;
      double minDist = double.infinity;
      for (int i = 0; i < widget.rounds.length; i++) {
        final snapTarget = _snapOffsetForIndex(i);
        final dist = (newOffset - snapTarget).abs();
        if (dist < minDist) {
          minDist = dist;
          currentIdx = i;
        }
      }
      if (currentIdx < _snappedIndex) {
        // Only rebuild when snappedIndex actually changes.
        setState(() {
          _snappedIndex = currentIdx;
          _scrollOffset = newOffset;
        });
        return;
      }
    }
    // No state change needed; AnimatedBuilder handles the body refresh.
    _scrollOffset = newOffset;
  }

  /// Calculates the snap scroll offset for a given round index.
  /// Account for the SingleChildScrollView's horizontal padding (16px each side).
  double _snapOffsetForIndex(int index) {
    // For the first round, snap to offset 0 so the leading padding stays
    // visible on the left edge.
    if (index == 0) {
      if (!_hScrollController.hasClients) return 0.0;
      return 0.0.clamp(0.0, _hScrollController.position.maxScrollExtent);
    }

    final unit = widget.theme.columnWidth + widget.theme.columnGap;
    final prevPeek = widget.theme.previousRoundPeek;
    const horizontalPadding = 16.0; // matches SingleChildScrollView padding

    // Position of column `index` within the scrollable content (after padding):
    //   columnStartInContent = horizontalPadding + index * unit
    // To show the column with prevPeek visible space on the left,
    // scroll offset should be:
    //   scrollOffset = columnStartInContent - prevPeek
    final target = horizontalPadding + index * unit - prevPeek;

    if (!_hScrollController.hasClients) {
      return target.clamp(0.0, double.infinity);
    }
    return target.clamp(0.0, _hScrollController.position.maxScrollExtent);
  }

  /// Scrolls the horizontal view to the given round index.
  void _scrollToIndex(int index, {required bool animated}) {
    if (!_hScrollController.hasClients) return;
    final target = _snapOffsetForIndex(index);
    if (animated) {
      _hScrollController.animateTo(
        target,
        duration: widget.theme.snapDuration,
        curve: widget.theme.snapCurve,
      );
    } else {
      _hScrollController.jumpTo(target);
    }
  }

  /// Called after physics settles. Updates active/snapped index based on
  /// the final scroll position. No re-animation needed since physics
  /// already snapped to the correct target.
  void _onScrollEnd() {
    if (!_hScrollController.hasClients) return;
    final offset = _hScrollController.offset;

    // Find the closest snap point to determine which round is active.
    int idx = 0;
    double minDist = double.infinity;
    for (int i = 0; i < widget.rounds.length; i++) {
      final snapTarget = _snapOffsetForIndex(i);
      final dist = (offset - snapTarget).abs();
      if (dist < minDist) {
        minDist = dist;
        idx = i;
      }
    }

    if (idx != _activeIndex) {
      setState(() {
        _activeIndex = idx;
      });
      widget.onRoundChanged?.call(idx);
    }
    if (idx > _snappedIndex) {
      setState(() {
        _snappedIndex = idx;
      });
    }
  }

  /// Programmatically selects a round (from chip tap).
  void _selectRound(int index) {
    setState(() {
      _activeIndex = index;
      if (index > _snappedIndex) _snappedIndex = index;
    });
    widget.onRoundChanged?.call(index);
    _scrollToIndex(index, animated: true);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.rounds.isEmpty) {
      return const Center(child: Text('No bracket data'));
    }

    return LayoutBuilder(
      builder: (context, outerConstraints) {
        final viewportWidth = outerConstraints.maxWidth;
        _viewportWidth = viewportWidth;
        final totalBracketWidth =
            widget.rounds.length * widget.theme.columnWidth +
            (widget.rounds.length - 1) * widget.theme.columnGap +
            32;
        final isLargeScreen = outerConstraints.maxWidth >= totalBracketWidth;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 8),
            if (!isLargeScreen) ...[
              _ChipBar(
                rounds: widget.rounds,
                activeIndex: _activeIndex,
                onSelected: _selectRound,
                theme: widget.theme,
              ),
              const SizedBox(height: 8),
            ],
            Expanded(
              child:
                  isLargeScreen
                      ? _buildLargeScreenBracket()
                      : _buildSmallScreenBracket(),
            ),
          ],
        );
      },
    );
  }

  /// Builds the static full-bracket layout for large screens (no scroll animation).
  Widget _buildLargeScreenBracket() {
    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: _BracketBody(
          rounds: widget.rounds,
          scrollOffset: 0,
          snappedIndex: -1,
          theme: widget.theme,
          onMatchTap: widget.onMatchTap,
          matchCardBuilder: widget.matchCardBuilder,
          teamImageBuilder: widget.teamImageBuilder,
          showColumnHeaders: true,
          viewportWidth: _viewportWidth,
        ),
      ),
    );
  }

  /// Builds the scrollable bracket with snap and animation for small screens.
  Widget _buildSmallScreenBracket() {
    // Build the list of snap targets for all rounds.
    final snapTargets = [
      for (int i = 0; i < widget.rounds.length; i++) _snapOffsetForIndex(i),
    ];

    return ScrollConfiguration(
      behavior: const _WebDragScrollBehavior(),
      child: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification is ScrollEndNotification &&
              notification.metrics.axis == Axis.horizontal) {
            _onScrollEnd();
          }
          return false;
        },
        // Vertical scroll is the outer scrollable. Horizontal snap-scroll
        // is inside. AnimatedBuilder rebuilds only the inner body when the
        // horizontal controller updates, so vertical scroll structure stays
        // stable and free of jank.
        child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: SingleChildScrollView(
            controller: _hScrollController,
            scrollDirection: Axis.horizontal,
            physics: _BracketSnapPhysics(snapTargets: snapTargets),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: AnimatedBuilder(
              animation: _hScrollController,
              builder: (context, _) {
                final offset =
                    _hScrollController.hasClients
                        ? _hScrollController.offset
                        : 0.0;
                return _BracketBody(
                  rounds: widget.rounds,
                  scrollOffset: offset,
                  snappedIndex: _snappedIndex,
                  theme: widget.theme,
                  onMatchTap: widget.onMatchTap,
                  matchCardBuilder: widget.matchCardBuilder,
                  teamImageBuilder: widget.teamImageBuilder,
                  showColumnHeaders: false,
                  viewportWidth: _viewportWidth,
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

/// Enables drag-to-scroll on all platforms (needed for web).
class _WebDragScrollBehavior extends MaterialScrollBehavior {
  const _WebDragScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.trackpad,
  };
}

/// Custom physics that snaps to one of the provided target offsets on
/// fling/drag end. Uses velocity direction to bias the snap target so any
/// meaningful drag commits to a target in that direction (like PageView).
class _BracketSnapPhysics extends ScrollPhysics {
  const _BracketSnapPhysics({required this.snapTargets, super.parent});

  /// Sorted list of snap offsets (ascending).
  final List<double> snapTargets;

  @override
  _BracketSnapPhysics applyTo(ScrollPhysics? ancestor) {
    return _BracketSnapPhysics(
      snapTargets: snapTargets,
      parent: buildParent(ancestor),
    );
  }

  /// Index of the snap target closest to [offset].
  int _nearestIndex(double offset) {
    if (snapTargets.isEmpty) return 0;
    int idx = 0;
    double minDist = (offset - snapTargets[0]).abs();
    for (int i = 1; i < snapTargets.length; i++) {
      final d = (offset - snapTargets[i]).abs();
      if (d < minDist) {
        minDist = d;
        idx = i;
      }
    }
    return idx;
  }

  /// Decides which snap target index to settle on based on current pixels
  /// and release velocity.
  ///
  /// Behavior (mirrors `PageScrollPhysics`):
  /// - Find the snap target closest to current position.
  /// - If velocity is rightward and current pixels are at/past that target,
  ///   commit to the next target.
  /// - If velocity is leftward and current pixels are at/before that target,
  ///   commit to the previous target.
  /// - Otherwise stay at the nearest target.
  int _targetIndex(
    ScrollMetrics position,
    double velocity,
    Tolerance tolerance,
  ) {
    final pixels = position.pixels;
    final nearestIdx = _nearestIndex(pixels);

    // No meaningful velocity → snap to nearest.
    if (velocity.abs() < tolerance.velocity) {
      return nearestIdx;
    }

    final nearestTarget = snapTargets[nearestIdx];
    if (velocity > 0) {
      // Fling right: if already past nearest target, jump to next.
      if (pixels >= nearestTarget) {
        return (nearestIdx + 1).clamp(0, snapTargets.length - 1);
      }
      return nearestIdx;
    } else {
      // Fling left: if still at or before nearest target, jump to previous.
      if (pixels <= nearestTarget) {
        return (nearestIdx - 1).clamp(0, snapTargets.length - 1);
      }
      return nearestIdx;
    }
  }

  @override
  Simulation? createBallisticSimulation(
    ScrollMetrics position,
    double velocity,
  ) {
    // Out of bounds — defer to parent for bounce/clamp behavior.
    if ((velocity <= 0.0 && position.pixels <= position.minScrollExtent) ||
        (velocity >= 0.0 && position.pixels >= position.maxScrollExtent)) {
      return super.createBallisticSimulation(position, velocity);
    }

    final tolerance = toleranceFor(position);
    final targetIdx = _targetIndex(position, velocity, tolerance);
    final target = snapTargets[targetIdx];

    // Already at target with no velocity.
    if ((target - position.pixels).abs() < tolerance.distance &&
        velocity.abs() < tolerance.velocity) {
      return null;
    }

    return ScrollSpringSimulation(
      spring,
      position.pixels,
      target,
      velocity,
      tolerance: tolerance,
    );
  }

  @override
  bool get allowImplicitScrolling => false;
}

// ─── Chip Bar ────────────────────────────────────────────────────────────────

class _ChipBar extends StatefulWidget {
  const _ChipBar({
    required this.rounds,
    required this.activeIndex,
    required this.onSelected,
    required this.theme,
  });
  final List<BracketRound> rounds;
  final int activeIndex;
  final ValueChanged<int> onSelected;
  final BracketTheme theme;

  @override
  State<_ChipBar> createState() => _ChipBarState();
}

class _ChipBarState extends State<_ChipBar> {
  final ScrollController _controller = ScrollController();

  @override
  void didUpdateWidget(covariant _ChipBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.activeIndex != oldWidget.activeIndex) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToActive());
    }
  }

  void _scrollToActive() {
    if (!_controller.hasClients) return;
    const chipUnit = 80.0;
    final viewportWidth = _controller.position.viewportDimension;
    final target = (widget.activeIndex * chipUnit -
            viewportWidth / 2 +
            chipUnit / 2)
        .clamp(0.0, _controller.position.maxScrollExtent);
    _controller.animateTo(
      target,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final chipTheme = widget.theme;

    return SizedBox(
      height: chipTheme.chipHeight,
      child: ListView.separated(
        controller: _controller,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: widget.rounds.length,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (context, index) {
          final round = widget.rounds[index];
          final isSelected = index == widget.activeIndex;
          final selectedColor =
              chipTheme.chipSelectedColor ?? colorScheme.primary;
          final unselectedColor =
              chipTheme.chipUnselectedColor ??
              colorScheme.surfaceContainerHighest;

          final baseTextStyle =
              chipTheme.chipTextStyle ??
              Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 11);

          return GestureDetector(
            onTap: () => widget.onSelected(index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: chipTheme.chipPadding,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected ? selectedColor : unselectedColor,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color:
                      isSelected
                          ? selectedColor
                          : colorScheme.outlineVariant.withValues(alpha: 0.4),
                ),
              ),
              child: Text(
                round.name,
                style: baseTextStyle?.copyWith(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color:
                      isSelected
                          ? colorScheme.onPrimary
                          : colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─── Bracket Body (positions cards) ──────────────────────────────────────────

class _BracketBody extends StatelessWidget {
  const _BracketBody({
    required this.rounds,
    required this.scrollOffset,
    required this.snappedIndex,
    required this.theme,
    this.onMatchTap,
    this.matchCardBuilder,
    this.teamImageBuilder,
    this.showColumnHeaders = false,
    this.viewportWidth,
  });
  final List<BracketRound> rounds;
  final double scrollOffset;
  final int snappedIndex;
  final BracketTheme theme;
  final ValueChanged<BracketMatch>? onMatchTap;
  final Widget Function(BuildContext, BracketMatch)? matchCardBuilder;
  final Widget Function(BuildContext, String?, double)? teamImageBuilder;
  final bool showColumnHeaders;
  final double? viewportWidth;

  @override
  Widget build(BuildContext context) {
    final unit = theme.columnWidth + theme.columnGap;
    final activeColumnFractional = unit > 0 ? scrollOffset / unit : 0.0;

    // Calculate card center Ys per round sequentially.
    // Each round's bracket-aligned position is based on the ACTUAL displayed
    // positions of its parent round (which may already be compact).
    final cardCenterYs = <int, List<double>>{};
    for (int i = 0; i < rounds.length; i++) {
      final matchCount = rounds[i].matches.length;
      final compactCenters = _compactCenterYs(matchCount);

      if (i == 0) {
        // First round is always compact (no parent to align to)
        cardCenterYs[i] = compactCenters;
      } else {
        // Bracket-aligned = midpoints of parent's ACTUAL displayed positions
        final parentCenters = cardCenterYs[i - 1]!;
        final bracketCenters = _bracketCenterYs(matchCount, parentCenters);

        double t; // 0 = compact, 1 = bracket-aligned
        if (i <= snappedIndex) {
          // Already snapped/focused — compact layout for readability
          t = 0.0;
        } else {
          // Not yet scrolled to — starts bracket-aligned (matching parent connectors),
          // then transitions to compact as user scrolls toward this column.
          // At activeColumnFractional = i-1: t = 1 (bracket-aligned, preview)
          // At activeColumnFractional = i:   t = 0 (compact, focused)
          t = 1.0 - (activeColumnFractional - (i - 1)).clamp(0.0, 1.0);
        }

        cardCenterYs[i] = List.generate(matchCount, (j) {
          final bracket =
              j < bracketCenters.length ? bracketCenters[j] : compactCenters[j];
          final compact = compactCenters[j];
          // t=0 → compact, t=1 → bracket-aligned
          return compact + (bracket - compact) * t;
        });
      }
    }

    // Total height
    double maxHeight = 0;
    for (final centers in cardCenterYs.values) {
      if (centers.isNotEmpty) {
        final lastBottom = centers.last + theme.cardHeight / 2;
        if (lastBottom > maxHeight) maxHeight = lastBottom;
      }
    }
    maxHeight += 200; // extra space for last cards + bottom padding

    final lineColor =
        theme.connectorColor ?? Theme.of(context).colorScheme.outlineVariant;

    final headerHeight = showColumnHeaders ? 40.0 : 0.0;

    return SizedBox(
      height: maxHeight + headerHeight,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (int i = 0; i < rounds.length; i++) ...[
            SizedBox(
              width: theme.columnWidth,
              height: maxHeight + headerHeight,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (showColumnHeaders)
                    SizedBox(
                      height: headerHeight,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          rounds[i].name,
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  Expanded(
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: _buildCards(
                        context,
                        i,
                        cardCenterYs[i] ?? [],
                        lineColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (i < rounds.length - 1) SizedBox(width: theme.columnGap),
          ],
          // Trailing space — large enough that the last round can be scrolled
          // to its proper snap position (with previousRoundPeek respected).
          // Use viewportWidth as a reasonable upper bound.
          SizedBox(width: (viewportWidth ?? 0) > 0 ? viewportWidth! : 200),
        ],
      ),
    );
  }

  /// Returns compact Y center positions (evenly spaced from top).
  List<double> _compactCenterYs(int count) {
    final unit = theme.cardHeight + theme.compactGap;
    return List.generate(count, (i) => i * unit + theme.cardHeight / 2);
  }

  /// Returns bracket-aligned Y centers (each card centered between 2 parent cards).
  List<double> _bracketCenterYs(int count, List<double> parentCenters) {
    if (parentCenters.isEmpty) return _compactCenterYs(count);
    return List.generate(count, (i) {
      final top = i * 2;
      final bottom = i * 2 + 1;
      if (top < parentCenters.length && bottom < parentCenters.length) {
        return (parentCenters[top] + parentCenters[bottom]) / 2;
      } else if (top < parentCenters.length) {
        return parentCenters[top];
      }
      final unit = theme.cardHeight + theme.compactGap;
      return i * unit + theme.cardHeight / 2;
    });
  }

  /// Builds positioned card widgets + connector lines for a single round column.
  List<Widget> _buildCards(
    BuildContext context,
    int roundIdx,
    List<double> centers,
    Color lineColor,
  ) {
    final round = rounds[roundIdx];
    final matches = round.matches;
    final widgets = <Widget>[];
    const headerOffset = 20.0;

    // Date label
    if (round.dateLabel != null && round.dateLabel!.isNotEmpty) {
      widgets.add(
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Text(
            round.dateLabel!,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }

    for (int i = 0; i < matches.length; i++) {
      final centerY = i < centers.length ? centers[i] : i * 100.0;
      final topY = centerY - theme.cardHeight / 2;

      // Type B: Left connector (moves with card)
      if (roundIdx > 0) {
        widgets.add(
          Positioned(
            top:
                topY +
                headerOffset +
                theme.cardHeight / 2 -
                theme.connectorWidth / 2,
            left: -theme.columnGap / 2,
            width: theme.columnGap / 2,
            height: theme.connectorWidth,
            child: ColoredBox(color: lineColor),
          ),
        );
      }

      // Card
      widgets.add(
        Positioned(
          top: topY + headerOffset,
          left: 0,
          right: 0,
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              onTap: onMatchTap != null ? () => onMatchTap!(matches[i]) : null,
              borderRadius: BorderRadius.circular(12),
              child:
                  matchCardBuilder != null
                      ? matchCardBuilder!(context, matches[i])
                      : _DefaultMatchCard(
                        match: matches[i],
                        teamImageBuilder: teamImageBuilder,
                        bracketTheme: theme,
                      ),
            ),
          ),
        ),
      );

      // Type A: Right connector (fixed to this column)
      if (roundIdx < rounds.length - 1) {
        widgets.add(
          Positioned(
            top:
                topY +
                headerOffset +
                theme.cardHeight / 2 -
                theme.connectorWidth / 2,
            right: -theme.columnGap / 2,
            width: theme.columnGap / 2,
            height: theme.connectorWidth,
            child: ColoredBox(color: lineColor),
          ),
        );
      }
    }

    // Vertical merge lines (every 2 cards)
    if (roundIdx < rounds.length - 1) {
      for (int i = 0; i < matches.length - 1; i += 2) {
        if (i + 1 >= centers.length) break;
        final topCenter = centers[i] + headerOffset;
        final bottomCenter = centers[i + 1] + headerOffset;

        widgets.add(
          Positioned(
            top: topCenter,
            right: -theme.columnGap / 2 - theme.connectorWidth / 2,
            width: theme.connectorWidth,
            height: bottomCenter - topCenter,
            child: ColoredBox(color: lineColor),
          ),
        );
      }
    }

    return widgets;
  }
}

// ─── Default Match Card ──────────────────────────────────────────────────────

class _DefaultMatchCard extends StatelessWidget {
  const _DefaultMatchCard({
    required this.match,
    required this.bracketTheme,
    this.teamImageBuilder,
  });
  final BracketMatch match;
  final BracketTheme bracketTheme;
  final Widget Function(BuildContext, String?, double)? teamImageBuilder;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color:
              match.isLive
                  ? colorScheme.primary.withValues(alpha: 0.6)
                  : colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (match.label != null)
            Text(
              match.label!,
              style: theme.textTheme.labelSmall?.copyWith(
                color:
                    match.isLive
                        ? colorScheme.error
                        : colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
                fontSize: 10,
              ),
            ),
          const SizedBox(height: 4),
          _TeamRow(
            team: match.teamA,
            score: match.scoreA,
            isLoser: match.isFinished && match.teamBWon,
            isLive: match.isLive,
            teamImageBuilder: teamImageBuilder,
            bracketTheme: bracketTheme,
          ),
          const SizedBox(height: 3),
          _TeamRow(
            team: match.teamB,
            score: match.scoreB,
            isLoser: match.isFinished && match.teamAWon,
            isLive: match.isLive,
            teamImageBuilder: teamImageBuilder,
            bracketTheme: bracketTheme,
          ),
        ],
      ),
    );
  }
}

class _TeamRow extends StatelessWidget {
  const _TeamRow({
    required this.team,
    required this.bracketTheme,
    this.score,
    this.isLoser = false,
    this.isLive = false,
    this.teamImageBuilder,
  });
  final BracketTeam team;
  final BracketTheme bracketTheme;
  final int? score;
  final bool isLoser;
  final bool isLive;
  final Widget Function(BuildContext, String?, double)? teamImageBuilder;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textColor =
        isLoser ? colorScheme.onSurfaceVariant : colorScheme.onSurface;

    final logoTheme = bracketTheme.teamLogoTheme;
    final logoBg =
        logoTheme.backgroundColor ?? colorScheme.surfaceContainerHighest;
    final iconColor =
        logoTheme.fallbackIconColor ?? colorScheme.onSurfaceVariant;
    final logoSize = logoTheme.size;
    final iconSize = logoSize * 0.6;

    Widget buildLogo() {
      if (teamImageBuilder != null) {
        return teamImageBuilder!(context, team.imageUrl, logoSize);
      }
      final inner =
          team.imageUrl != null
              ? Image.network(
                team.imageUrl!,
                width: logoSize,
                height: logoSize,
                fit: BoxFit.cover,
                errorBuilder:
                    (_, __, ___) => Icon(
                      logoTheme.fallbackIcon,
                      size: iconSize,
                      color: iconColor,
                    ),
              )
              : Icon(logoTheme.fallbackIcon, size: iconSize, color: iconColor);

      return Container(
        width: logoSize,
        height: logoSize,
        padding: logoTheme.padding,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: logoBg,
          shape:
              logoTheme.borderRadius == null
                  ? BoxShape.circle
                  : BoxShape.rectangle,
          borderRadius: logoTheme.borderRadius,
          border: logoTheme.border,
        ),
        child: ClipRRect(
          borderRadius:
              logoTheme.borderRadius ?? BorderRadius.circular(logoSize),
          child: inner,
        ),
      );
    }

    return Row(
      children: [
        buildLogo(),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            team.name,
            style: theme.textTheme.bodySmall?.copyWith(
              fontSize: 12,
              fontWeight: isLoser ? FontWeight.w400 : FontWeight.w600,
              color: textColor,
              decoration:
                  isLoser ? TextDecoration.lineThrough : TextDecoration.none,
              decorationColor: colorScheme.onSurfaceVariant,
              decorationThickness: 1.5,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (score != null) ...[
          const SizedBox(width: 4),
          Text(
            score.toString(),
            style: theme.textTheme.bodyMedium?.copyWith(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color:
                  isLive
                      ? colorScheme.primary
                      : isLoser
                      ? colorScheme.onSurfaceVariant
                      : colorScheme.onSurface,
            ),
          ),
        ],
      ],
    );
  }
}
