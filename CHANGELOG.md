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
