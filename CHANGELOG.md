## 0.3.1

- Fix vertical scroll jank when flinging fast — body now rebuilds via `AnimatedBuilder` listening to the horizontal scroll controller, so the vertical scroll widget tree stays stable
- Replace card `GestureDetector` with `InkWell` for gesture-cooperative tap handling and ripple effect

## 0.3.0

- Add `previousRoundPeek` to `BracketTheme` — controls how much of the previous round peeks from the left edge when snapped (default 32.0)
- Add `TeamLogoTheme` (via `BracketTheme.teamLogoTheme`) — customize default avatar background, fallback icon/color, size, border radius, border, and padding without writing a custom `teamImageBuilder`
- Replace manual snap detection with custom `ScrollPhysics` that snaps natively on fling/drag, mirroring `PageView` behavior (velocity-aware)
- Fix snap-to-round position accuracy (no more off-by-padding errors)
- Fix card animation: focused round displays compact, next rounds show bracket-aligned preview
- Fix `_snappedIndex` getting stuck during left scroll — active tab now updates correctly
- Fix last round (Final) being unreachable with proper `previousRoundPeek` due to insufficient trailing space
- Fix bracket positions cascading incorrectly when parent rounds are compact
- First round now snaps to offset 0 so the leading 16px padding is visible
- Cleanup: remove unused `_isSnapping` flag and `dart:rendering` import

## 0.2.0

- Add `chipHeight`, `chipPadding`, `chipTextStyle` to `BracketTheme`
- Reduce default chip size for a more compact look (height 38→32, padding 14→10, fontSize 11)

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
