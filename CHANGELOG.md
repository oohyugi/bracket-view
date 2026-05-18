## 0.2.1

- README: restore Screenshots section (images exist), remove Demo placeholder (gif not yet available)
- No code changes

## 0.2.0

This release consolidates several internal iterations into the next pub.dev
release after `0.1.0`. Highlights:

### Breaking changes

- `BracketMatch.winnerSide` is now a `BracketWinnerSide?` enum (`teamA`/`teamB`) instead of `String?`. Replace `'A'`/`'B'` with `BracketWinnerSide.teamA`/`BracketWinnerSide.teamB`.

### New features

- Loser strikethrough works for level scores (e.g. 1-1 decided on penalties) when `winnerSide` is set explicitly
- `BracketMatchLeg` model and `BracketMatch.legs` for optional per-leg metadata (label, score, date, venue), plus `BracketMatch.hasMultipleLegs`
- `BracketTheme.previousRoundPeek` — controls how much of the previous round peeks from the left edge when snapped (default 32.0)
- `BracketTheme.teamLogoTheme` (`TeamLogoTheme`) — customize avatar background, fallback icon/color, size, border radius, border, and padding without a custom `teamImageBuilder`
- `BracketTheme.chipHeight`, `chipPadding`, `chipTextStyle` for chip customization (and tighter defaults: height 38→32, padding 14→10, fontSize 11)

### Behavior & fixes

- Replace manual snap detection with custom `ScrollPhysics` that snaps natively on fling/drag, mirroring `PageView` (velocity-aware)
- First round now snaps to offset 0 so the leading 16px padding is visible
- Fix snap-to-round position accuracy (no more off-by-padding errors)
- Fix card animation: focused round displays compact, next rounds show bracket-aligned preview
- Fix `_snappedIndex` getting stuck during left scroll — active tab now updates correctly
- Fix last round (Final) being unreachable with proper `previousRoundPeek` due to insufficient trailing space
- Fix bracket positions cascading incorrectly when parent rounds are compact
- Fix vertical scroll jank when flinging fast — body now rebuilds via `AnimatedBuilder` listening to the horizontal scroll controller
- Replace card `GestureDetector` with `InkWell` for gesture-cooperative tap handling + ripple
- More breathing room between chip bar, round date label, and the first match card

### Docs & tooling

- `scoreA`/`scoreB` doc-string clarified to cover both single-leg full-time scores and two-leg aggregates
- `library;` directive added to `lib/bracket_view.dart` so the doc comment is no longer dangling (clears the analyzer info on pub.dev)
- `flutter_lints` added to the example app
- Example: switchable datasets (UCL two-leg with leg picker bottom sheet vs World Cup 2022 single-leg with AET/penalties)
- Add unit + widget test suite under `test/`

## 0.1.0

- Initial release
- Horizontal scroll bracket with snap-to-round behavior
- Scroll-driven card position animation (bracket-aligned ↔ compact)
- Connector lines between rounds (Type A fixed + Type B animated)
- Responsive layout: scroll mode on mobile, full bracket on desktop
- Round chip selector with auto-scroll
- Customizable theme via `BracketTheme`
- Custom `matchCardBuilder` and `teamImageBuilder` support
- Web support with drag-to-scroll
- Generic models: `BracketMatch`, `BracketRound`, `BracketTeam`
