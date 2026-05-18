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
        onMatchTap: _handleMatchTap,
      ),
    );
  }

  Future<void> _handleMatchTap(BracketMatch match) async {
    // Two-leg tie → let the user pick which leg to view.
    if (match.hasMultipleLegs) {
      final selected = await showModalBottomSheet<BracketMatchLeg>(
        context: context,
        showDragHandle: true,
        builder: (_) => _LegPickerSheet(match: match),
      );
      if (selected == null || !mounted) return;
      _showLegDetail(match, selected);
      return;
    }
    // Single-leg / no legs metadata → just show a quick toast.
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${match.teamA.name} vs ${match.teamB.name}'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _showLegDetail(BracketMatch match, BracketMatchLeg leg) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder:
          (_) => Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  leg.label,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${match.teamA.name} vs ${match.teamB.name}',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                if (leg.scoreA != null && leg.scoreB != null)
                  Center(
                    child: Text(
                      '${leg.scoreA}  -  ${leg.scoreB}',
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                if (leg.date != null)
                  _DetailRow(
                    icon: Icons.calendar_today,
                    label: _formatDate(leg.date!),
                  ),
                if (leg.venue != null) ...[
                  const SizedBox(height: 8),
                  _DetailRow(icon: Icons.stadium, label: leg.venue!),
                ],
              ],
            ),
          ),
    );
  }

  String _formatDate(DateTime d) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final hh = d.hour.toString().padLeft(2, '0');
    final mm = d.minute.toString().padLeft(2, '0');
    return '${d.day} ${months[d.month - 1]} ${d.year} • $hh:$mm';
  }
}

class _LegPickerSheet extends StatelessWidget {
  const _LegPickerSheet({required this.match});
  final BracketMatch match;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${match.teamA.name} vs ${match.teamB.name}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Pick a leg to view details',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          for (final leg in match.legs!)
            ListTile(
              leading: const Icon(Icons.sports_soccer),
              title: Text(leg.label),
              subtitle:
                  leg.scoreA != null && leg.scoreB != null
                      ? Text(
                        '${match.teamA.name} ${leg.scoreA} – ${leg.scoreB} ${match.teamB.name}',
                      )
                      : null,
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).pop(leg),
            ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, size: 16, color: colorScheme.onSurfaceVariant),
        const SizedBox(width: 8),
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
        ),
      ],
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
      _twoLegMatch(
        'PSG',
        'Chelsea',
        leg1A: 4,
        leg1B: 1,
        leg2A: 4,
        leg2B: 1,
        winner: 'A',
        leg1Date: DateTime(2026, 3, 11, 21, 0),
        leg2Date: DateTime(2026, 3, 18, 21, 0),
        leg1Venue: 'Parc des Princes',
        leg2Venue: 'Stamford Bridge',
      ),
      _twoLegMatch(
        'Galatasaray',
        'Liverpool',
        leg1A: 0,
        leg1B: 2,
        leg2A: 1,
        leg2B: 2,
        winner: 'B',
        leg1Date: DateTime(2026, 3, 11, 21, 0),
        leg2Date: DateTime(2026, 3, 18, 21, 0),
        leg1Venue: 'Türk Telekom Stadyumu',
        leg2Venue: 'Anfield',
      ),
      _twoLegMatch(
        'Real Madrid',
        'Manchester City',
        leg1A: 3,
        leg1B: 1,
        leg2A: 2,
        leg2B: 0,
        winner: 'A',
      ),
      _twoLegMatch(
        'Atalanta',
        'Bayern Munich',
        leg1A: 1,
        leg1B: 5,
        leg2A: 1,
        leg2B: 5,
        winner: 'B',
      ),
      _twoLegMatch(
        'Newcastle United',
        'Barcelona',
        leg1A: 1,
        leg1B: 4,
        leg2A: 2,
        leg2B: 4,
        winner: 'B',
      ),
      _twoLegMatch(
        'Atletico Madrid',
        'Tottenham',
        leg1A: 4,
        leg1B: 3,
        leg2A: 3,
        leg2B: 2,
        winner: 'A',
      ),
      // Aggregate 1-1, Bodoe/Glimt advance on penalties — Inter still
      // gets the strikethrough because winnerSide is set explicitly.
      _twoLegMatch(
        'Bodoe/Glimt',
        'Inter',
        leg1A: 1,
        leg1B: 0,
        leg2A: 0,
        leg2B: 1,
        winner: 'A',
        label: 'Agg (4-2 pens)',
      ),
      _twoLegMatch(
        'Bayer Leverkusen',
        'Arsenal',
        leg1A: 0,
        leg1B: 1,
        leg2A: 1,
        leg2B: 2,
        winner: 'B',
      ),
    ],
  ),
  BracketRound(
    id: 'qf',
    name: 'Quarter Final',
    dateLabel: '8-9 Apr | 15-16 Apr',
    matches: [
      _twoLegMatch(
        'PSG',
        'Liverpool',
        leg1A: 2,
        leg1B: 0,
        leg2A: 2,
        leg2B: 0,
        winner: 'A',
      ),
      _twoLegMatch(
        'Real Madrid',
        'Bayern Munich',
        leg1A: 2,
        leg1B: 3,
        leg2A: 2,
        leg2B: 3,
        winner: 'B',
      ),
      _twoLegMatch(
        'Barcelona',
        'Atletico Madrid',
        leg1A: 1,
        leg1B: 2,
        leg2A: 1,
        leg2B: 1,
        winner: 'B',
      ),
      _twoLegMatch(
        'Bodoe/Glimt',
        'Arsenal',
        leg1A: 0,
        leg1B: 1,
        leg2A: 0,
        leg2B: 0,
        winner: 'B',
      ),
    ],
  ),
  BracketRound(
    id: 'sf',
    name: 'Semi Final',
    dateLabel: '29-30 Apr | 6-7 May',
    matches: [
      _twoLegMatch(
        'PSG',
        'Bayern Munich',
        leg1A: 3,
        leg1B: 2,
        leg2A: 3,
        leg2B: 3,
        winner: 'A',
      ),
      _twoLegMatch(
        'Atletico Madrid',
        'Arsenal',
        leg1A: 1,
        leg1B: 1,
        leg2A: 0,
        leg2B: 1,
        winner: 'B',
      ),
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

BracketMatch _twoLegMatch(
  String teamA,
  String teamB, {
  required int leg1A,
  required int leg1B,
  required int leg2A,
  required int leg2B,
  required String winner,
  String label = 'Aggregate',
  DateTime? leg1Date,
  DateTime? leg2Date,
  String? leg1Venue,
  String? leg2Venue,
}) {
  _matchId++;
  return BracketMatch(
    id: 'match_$_matchId',
    teamA: BracketTeam(name: teamA),
    teamB: BracketTeam(name: teamB),
    scoreA: leg1A + leg2A,
    scoreB: leg1B + leg2B,
    status: BracketMatchStatus.finished,
    winnerSide:
        winner == 'A' ? BracketWinnerSide.teamA : BracketWinnerSide.teamB,
    label: label,
    legs: [
      BracketMatchLeg(
        label: '1st Leg',
        scoreA: leg1A,
        scoreB: leg1B,
        date: leg1Date,
        venue: leg1Venue,
      ),
      BracketMatchLeg(
        label: '2nd Leg',
        scoreA: leg2A,
        scoreB: leg2B,
        date: leg2Date,
        venue: leg2Venue,
      ),
    ],
  );
}
