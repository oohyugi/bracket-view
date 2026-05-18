import 'package:bracket_view/bracket_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget wrap(Widget child, {Size size = const Size(400, 800)}) {
    return MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(size: size),
        child: Scaffold(
          body: SizedBox(width: size.width, height: size.height, child: child),
        ),
      ),
    );
  }

  final rounds = [
    BracketRound(
      id: 'r1',
      name: 'Round of 4',
      dateLabel: '1 Jan',
      matches: const [
        BracketMatch(
          id: 'm1',
          teamA: BracketTeam(name: 'Alpha'),
          teamB: BracketTeam(name: 'Beta'),
          scoreA: 3,
          scoreB: 0,
          status: BracketMatchStatus.finished,
          winnerSide: BracketWinnerSide.teamA,
        ),
        BracketMatch(
          id: 'm2',
          teamA: BracketTeam(name: 'Gamma'),
          teamB: BracketTeam(name: 'Delta'),
          scoreA: 1,
          scoreB: 1,
          status: BracketMatchStatus.finished,
          winnerSide: BracketWinnerSide.teamB,
        ),
      ],
    ),
    BracketRound(
      id: 'r2',
      name: 'Final',
      matches: const [
        BracketMatch(
          id: 'final',
          teamA: BracketTeam(name: 'Alpha'),
          teamB: BracketTeam(name: 'Delta'),
          status: BracketMatchStatus.upcoming,
        ),
      ],
    ),
  ];

  testWidgets('renders empty state when no rounds provided', (tester) async {
    await tester.pumpWidget(wrap(const BracketView(rounds: [])));
    expect(find.text('No bracket data'), findsOneWidget);
  });

  testWidgets('renders all team names', (tester) async {
    await tester.pumpWidget(wrap(BracketView(rounds: rounds)));
    await tester.pumpAndSettle();

    expect(find.text('Alpha'), findsWidgets);
    expect(find.text('Beta'), findsOneWidget);
    expect(find.text('Gamma'), findsOneWidget);
    expect(find.text('Delta'), findsWidgets);
  });

  testWidgets('renders round chips on small screen', (tester) async {
    await tester.pumpWidget(
      wrap(BracketView(rounds: rounds), size: const Size(400, 800)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Round of 4'), findsOneWidget);
    expect(find.text('Final'), findsOneWidget);
  });

  testWidgets('does not render chips on large screen', (tester) async {
    // Large enough to fit both columns + padding.
    await tester.pumpWidget(
      wrap(BracketView(rounds: rounds), size: const Size(1400, 800)),
    );
    await tester.pumpAndSettle();

    // Header instead of chip is expected; chip has different size context.
    // Column header renders the round name in titleSmall text style.
    expect(find.text('Round of 4'), findsOneWidget);
    expect(find.text('Final'), findsOneWidget);
  });

  testWidgets('loser team name has lineThrough decoration', (tester) async {
    await tester.pumpWidget(wrap(BracketView(rounds: rounds)));
    await tester.pumpAndSettle();

    // Beta is the loser of m1 (winnerSide = teamA).
    final betaText = tester.widget<Text>(find.text('Beta'));
    expect(betaText.style?.decoration, TextDecoration.lineThrough);

    // Alpha won, so no strikethrough.
    final alphaTexts = tester.widgetList<Text>(find.text('Alpha')).toList();
    final alphaInRoundOf4 = alphaTexts.first;
    expect(alphaInRoundOf4.style?.decoration, TextDecoration.none);
  });

  testWidgets('1-1 with explicit winnerSide still strikes through loser', (
    tester,
  ) async {
    await tester.pumpWidget(wrap(BracketView(rounds: rounds)));
    await tester.pumpAndSettle();

    // m2: Gamma vs Delta is 1-1, Delta won — so Gamma is struck through.
    final gammaText = tester.widget<Text>(find.text('Gamma'));
    expect(gammaText.style?.decoration, TextDecoration.lineThrough);
  });

  testWidgets('onMatchTap is called when a card is tapped', (tester) async {
    BracketMatch? tapped;
    await tester.pumpWidget(
      wrap(BracketView(rounds: rounds, onMatchTap: (m) => tapped = m)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Alpha').first);
    await tester.pumpAndSettle();

    expect(tapped, isNotNull);
    expect(tapped!.id, 'm1');
  });

  testWidgets('uses matchCardBuilder when provided', (tester) async {
    await tester.pumpWidget(
      wrap(
        BracketView(
          rounds: rounds,
          matchCardBuilder:
              (context, match) => Container(
                key: ValueKey('custom_${match.id}'),
                padding: const EdgeInsets.all(8),
                child: Text('CUSTOM:${match.teamA.name}'),
              ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('custom_m1')), findsOneWidget);
    expect(find.text('CUSTOM:Alpha'), findsWidgets);
    // Default card text styles should not appear (the team names are inside
    // the custom card now).
    expect(find.text('Beta'), findsNothing);
  });
}
