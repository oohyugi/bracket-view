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

class BracketExamplePage extends StatelessWidget {
  const BracketExamplePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Champions League 2025/26'),
        centerTitle: false,
      ),
      body: BracketView(
        rounds: _sampleRounds,
        initialRoundIndex: 0,
        onRoundChanged: (index) {
          debugPrint('Round changed: $index');
        },
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

// ─── Sample Data (UCL 2025/26 Knockout) ──────────────────────────────────────

final _sampleRounds = [
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
      _match('Bodoe/Glimt', 'Inter', 5, 2, 'A'),
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

int _matchId = 0;

BracketMatch _match(
  String teamA,
  String teamB,
  int scoreA,
  int scoreB,
  String winner,
) {
  _matchId++;
  return BracketMatch(
    id: 'match_$_matchId',
    teamA: BracketTeam(name: teamA),
    teamB: BracketTeam(name: teamB),
    scoreA: scoreA,
    scoreB: scoreB,
    status: BracketMatchStatus.finished,
    winnerSide: winner,
    label: 'Aggregate',
  );
}
