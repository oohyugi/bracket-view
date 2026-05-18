import 'package:bracket_view/bracket_view.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const BracketExampleApp());
}

class BracketExampleApp extends StatelessWidget {
  const BracketExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bracket View Example',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(useMaterial3: true),
      home: const BracketExamplePage(),
    );
  }
}

enum _Dataset { ucl, worldCup }

class BracketExamplePage extends StatefulWidget {
  const BracketExamplePage({super.key});

  @override
  State<BracketExamplePage> createState() => _BracketExamplePageState();
}

class _BracketExamplePageState extends State<BracketExamplePage> {
  _Dataset _dataset = _Dataset.ucl;

  @override
  Widget build(BuildContext context) {
    final isUcl = _dataset == _Dataset.ucl;
    return Scaffold(
      appBar: AppBar(
        title: Text(isUcl ? 'Champions League 2025/26' : 'World Cup 2022'),
        centerTitle: false,
        actions: [
          PopupMenuButton<_Dataset>(
            icon: const Icon(Icons.swap_horiz),
            tooltip: 'Switch dataset',
            initialValue: _dataset,
            onSelected: (v) => setState(() => _dataset = v),
            itemBuilder:
                (_) => const [
                  PopupMenuItem(
                    value: _Dataset.ucl,
                    child: Text('UCL (two-leg, aggregate)'),
                  ),
                  PopupMenuItem(
                    value: _Dataset.worldCup,
                    child: Text('World Cup (single-leg)'),
                  ),
                ],
          ),
        ],
      ),
      body: BracketView(
        // ValueKey forces reset of internal scroll/active-round state when
        // the dataset changes.
        key: ValueKey(_dataset),
        rounds: isUcl ? _uclRounds : _worldCupRounds,
        initialRoundIndex: 0,
        theme: const BracketTheme(previousRoundPeek: 12),
        onRoundChanged: (index) => debugPrint('Round changed: $index'),
        onMatchTap: (match) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${match.teamA.name} vs ${match.teamB.name}'),
              duration: const Duration(seconds: 1),
            ),
          );
        },
      ),
    );
  }
}

// ─── UCL 2025/26 (two-leg ties, scores are aggregate) ────────────────────────

final _uclRounds = [
  BracketRound(
    id: 'r16',
    name: 'Round of 16',
    dateLabel: '11-12 Mar | 18-19 Mar',
    matches: [
      _match('PSG', 'Chelsea', 8, 2, 'A'),
      _match('Galatasaray', 'Liverpool', 1, 4, 'B'),
      _match('Real Madrid', 'Manchester City', 5, 1, 'A'),
      _match('Atalanta', 'Bayern Munich', 2, 10, 'B'),
      _match('Newcastle United', 'Barcelona', 3, 8, 'B'),
      _match('Atletico Madrid', 'Tottenham', 7, 5, 'A'),
      // Aggregate 1-1, Bodoe/Glimt advance on penalties — Inter still
      // gets the strikethrough because winnerSide is set explicitly.
      _match('Bodoe/Glimt', 'Inter', 1, 1, 'A', label: 'Agg (4-2 pens)'),
      _match('Bayer Leverkusen', 'Arsenal', 1, 3, 'B'),
    ],
  ),
  BracketRound(
    id: 'qf',
    name: 'Quarter Final',
    dateLabel: '8-9 Apr | 15-16 Apr',
    matches: [
      _match('PSG', 'Liverpool', 4, 0, 'A'),
      _match('Real Madrid', 'Bayern Munich', 4, 6, 'B'),
      _match('Barcelona', 'Atletico Madrid', 2, 3, 'B'),
      _match('Bodoe/Glimt', 'Arsenal', 0, 1, 'B'),
    ],
  ),
  BracketRound(
    id: 'sf',
    name: 'Semi Final',
    dateLabel: '29-30 Apr | 6-7 May',
    matches: [
      _match('PSG', 'Bayern Munich', 6, 5, 'A'),
      _match('Atletico Madrid', 'Arsenal', 1, 2, 'B'),
    ],
  ),
  BracketRound(
    id: 'final',
    name: 'Final',
    dateLabel: '30 May',
    matches: [
      BracketMatch(
        id: 'final_1',
        teamA: const BracketTeam(name: 'PSG'),
        teamB: const BracketTeam(name: 'Arsenal'),
        status: BracketMatchStatus.upcoming,
        label: 'Match',
      ),
    ],
  ),
];

// ─── World Cup 2022 (single-leg, full-time / AET / penalties) ────────────────

final _worldCupRounds = [
  BracketRound(
    id: 'wc_r16',
    name: 'Round of 16',
    dateLabel: '3-6 Dec',
    matches: [
      _match('Netherlands', 'USA', 3, 1, 'A', label: 'Full Time'),
      _match('Argentina', 'Australia', 2, 1, 'A', label: 'Full Time'),
      _match('France', 'Poland', 3, 1, 'A', label: 'Full Time'),
      _match('England', 'Senegal', 3, 0, 'A', label: 'Full Time'),
      // Single-leg level after 120', decided on penalties.
      _match('Japan', 'Croatia', 1, 1, 'B', label: 'AET (1-3 pens)'),
      _match('Brazil', 'South Korea', 4, 1, 'A', label: 'Full Time'),
      _match('Morocco', 'Spain', 0, 0, 'A', label: 'AET (3-0 pens)'),
      _match('Portugal', 'Switzerland', 6, 1, 'A', label: 'Full Time'),
    ],
  ),
  BracketRound(
    id: 'wc_qf',
    name: 'Quarter Final',
    dateLabel: '9-10 Dec',
    matches: [
      _match('Croatia', 'Brazil', 1, 1, 'A', label: 'AET (4-2 pens)'),
      _match('Netherlands', 'Argentina', 2, 2, 'B', label: 'AET (3-4 pens)'),
      _match('Morocco', 'Portugal', 1, 0, 'A', label: 'Full Time'),
      _match('England', 'France', 1, 2, 'B', label: 'Full Time'),
    ],
  ),
  BracketRound(
    id: 'wc_sf',
    name: 'Semi Final',
    dateLabel: '13-14 Dec',
    matches: [
      _match('Argentina', 'Croatia', 3, 0, 'A', label: 'Full Time'),
      _match('France', 'Morocco', 2, 0, 'A', label: 'Full Time'),
    ],
  ),
  BracketRound(
    id: 'wc_final',
    name: 'Final',
    dateLabel: '18 Dec',
    matches: [
      _match('Argentina', 'France', 3, 3, 'A', label: 'AET (4-2 pens)'),
    ],
  ),
];

int _matchId = 0;

BracketMatch _match(
  String teamA,
  String teamB,
  int scoreA,
  int scoreB,
  String winner, {
  String label = 'Aggregate',
}) {
  _matchId++;
  return BracketMatch(
    id: 'match_$_matchId',
    teamA: BracketTeam(name: teamA),
    teamB: BracketTeam(name: teamB),
    scoreA: scoreA,
    scoreB: scoreB,
    status: BracketMatchStatus.finished,
    winnerSide:
        winner == 'A' ? BracketWinnerSide.teamA : BracketWinnerSide.teamB,
    label: label,
  );
}
