# bracket_view

A reusable Flutter tournament bracket widget with scroll-driven animations.

## Features

- Horizontal scroll bracket with snap-to-round behavior
- Scroll-driven card position animation (bracket-aligned ↔ compact)
- Connector lines between rounds (Type A fixed + Type B animated)
- Round chip selector with auto-scroll
- Customizable theme (colors, sizes, curves)
- Custom card builder and team image builder support
- Generic models — no external dependencies

## Usage

```dart
import 'package:bracket_view/bracket_view.dart';

BracketView(
  rounds: [
    BracketRound(
      id: 'qf',
      name: 'Quarter Final',
      dateLabel: '8-9 Apr | 15-16 Apr',
      matches: [
        BracketMatch(
          id: '1',
          teamA: BracketTeam(name: 'PSG', imageUrl: '...'),
          teamB: BracketTeam(name: 'Liverpool', imageUrl: '...'),
          scoreA: 4,
          scoreB: 0,
          status: BracketMatchStatus.finished,
          winnerSide: 'A',
          label: 'Aggregate',
        ),
        // ...
      ],
    ),
    // More rounds...
  ],
  onRoundChanged: (index) => print('Round: $index'),
  onMatchTap: (match) => print('Tapped: ${match.id}'),
  teamImageBuilder: (context, url, size) => MyTeamLogo(url: url, size: size),
  theme: BracketTheme(
    columnWidth: 220,
    columnGap: 24,
    cardHeight: 90,
  ),
)
```

## Animation Behavior

- **Scroll right (forward):** Next round cards animate from bracket-aligned (centered between parent pairs) to compact (stacked from top)
- **Snapped columns freeze:** Once a column is snapped, it stays compact — no re-animation on continued forward scroll
- **Scroll left (backward):** Frozen columns unfreeze and animate back to bracket-aligned positions
- **Connectors:** Right-side connectors (Type A) stay fixed with parent column. Left-side connectors (Type B) move with animated cards, creating a natural "disconnect" effect during transitions.

## Models

- `BracketRound` — A round with name, matches, and optional date label
- `BracketMatch` — A match/tie with two teams, scores, status, and winner
- `BracketTeam` — A team with name and optional image URL
- `BracketTheme` — Visual configuration (sizes, colors, animation curves)

## License

MIT
