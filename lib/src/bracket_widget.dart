import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

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
  bool _isSnapping = false;

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

  /// Handles scroll offset changes. Unfreezes columns when scrolling left.
  void _onScrollUpdate() {
    final newOffset = _hScrollController.offset;
    if (newOffset < _scrollOffset) {
      final unit = widget.theme.columnWidth + widget.theme.columnGap;
      final currentIdx = (newOffset / unit).floor().clamp(
        0,
        widget.rounds.length - 1,
      );
      if (currentIdx < _snappedIndex) {
        _snappedIndex = currentIdx;
      }
    }
    setState(() {
      _scrollOffset = newOffset;
    });
  }

  /// Scrolls the horizontal view to the given round index.
  void _scrollToIndex(int index, {required bool animated}) {
    if (!_hScrollController.hasClients) return;
    final unit = widget.theme.columnWidth + widget.theme.columnGap;
    final target = (index * unit).clamp(
      0.0,
      _hScrollController.position.maxScrollExtent,
    );
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

  /// Snaps to the nearest round column when user releases scroll.
  void _onScrollEnd() {
    if (!_hScrollController.hasClients || _isSnapping) return;
    final unit = widget.theme.columnWidth + widget.theme.columnGap;
    final offset = _hScrollController.offset;
    final idx = (offset / unit).round().clamp(0, widget.rounds.length - 1);

    if (idx != _activeIndex) {
      _activeIndex = idx;
      widget.onRoundChanged?.call(idx);
    }
    if (idx > _snappedIndex) {
      _snappedIndex = idx;
    }

    final snapOffset = (idx * unit).clamp(
      0.0,
      _hScrollController.position.maxScrollExtent,
    );
    if ((snapOffset - offset).abs() > 1.0) {
      _isSnapping = true;
      _hScrollController
          .animateTo(
            snapOffset,
            duration: widget.theme.snapDuration,
            curve: widget.theme.snapCurve,
          )
          .then((_) => _isSnapping = false);
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
          snappedIndex: 0,
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
    return ScrollConfiguration(
      behavior: const _WebDragScrollBehavior(),
      child: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification is ScrollEndNotification &&
              notification.metrics.axis == Axis.horizontal) {
            _onScrollEnd();
          }
          if (notification is UserScrollNotification &&
              notification.direction == ScrollDirection.idle &&
              notification.metrics.axis == Axis.horizontal) {
            _onScrollEnd();
          }
          return false;
        },
        child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: SingleChildScrollView(
            controller: _hScrollController,
            scrollDirection: Axis.horizontal,
            physics: const ClampingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _BracketBody(
              rounds: widget.rounds,
              scrollOffset: _scrollOffset,
              snappedIndex: _snappedIndex,
              theme: widget.theme,
              onMatchTap: widget.onMatchTap,
              matchCardBuilder: widget.matchCardBuilder,
              teamImageBuilder: widget.teamImageBuilder,
              showColumnHeaders: false,
              viewportWidth: _viewportWidth,
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
    final activeColumnFractional = scrollOffset / unit;

    // Calculate card center Ys per round
    final cardCenterYs = <int, List<double>>{};
    for (int i = 0; i < rounds.length; i++) {
      final matchCount = rounds[i].matches.length;
      if (i == 0) {
        cardCenterYs[i] = _compactCenterYs(matchCount);
      } else {
        final parentCenters = cardCenterYs[i - 1] ?? [];
        final bracketCenters = _bracketCenterYs(matchCount, parentCenters);
        final compactCenters = _compactCenterYs(matchCount);

        double snapFactor;
        if (i <= snappedIndex) {
          snapFactor = 1.0;
        } else {
          final dist = (activeColumnFractional - i).abs();
          snapFactor = (1.0 - dist).clamp(0.0, 1.0);
        }

        cardCenterYs[i] = List.generate(matchCount, (j) {
          final bracket =
              j < bracketCenters.length ? bracketCenters[j] : compactCenters[j];
          final compact = compactCenters[j];
          return bracket + (compact - bracket) * snapFactor;
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
          const SizedBox(width: 100),
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
          child: GestureDetector(
            onTap: onMatchTap != null ? () => onMatchTap!(matches[i]) : null,
            child:
                matchCardBuilder != null
                    ? matchCardBuilder!(context, matches[i])
                    : _DefaultMatchCard(
                      match: matches[i],
                      teamImageBuilder: teamImageBuilder,
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
  const _DefaultMatchCard({required this.match, this.teamImageBuilder});
  final BracketMatch match;
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
          ),
          const SizedBox(height: 3),
          _TeamRow(
            team: match.teamB,
            score: match.scoreB,
            isLoser: match.isFinished && match.teamAWon,
            isLive: match.isLive,
            teamImageBuilder: teamImageBuilder,
          ),
        ],
      ),
    );
  }
}

class _TeamRow extends StatelessWidget {
  const _TeamRow({
    required this.team,
    this.score,
    this.isLoser = false,
    this.isLive = false,
    this.teamImageBuilder,
  });
  final BracketTeam team;
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

    return Row(
      children: [
        if (teamImageBuilder != null)
          teamImageBuilder!(context, team.imageUrl, 16)
        else
          CircleAvatar(
            radius: 10,
            backgroundColor: colorScheme.surfaceContainerHighest,
            child:
                team.imageUrl != null
                    ? ClipOval(
                      child: Image.network(
                        team.imageUrl!,
                        width: 20,
                        height: 20,
                        fit: BoxFit.cover,
                        errorBuilder:
                            (_, __, ___) => Icon(
                              Icons.sports_soccer,
                              size: 12,
                              color: colorScheme.onSurfaceVariant,
                            ),
                      ),
                    )
                    : Icon(
                      Icons.sports_soccer,
                      size: 12,
                      color: colorScheme.onSurfaceVariant,
                    ),
          ),
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
