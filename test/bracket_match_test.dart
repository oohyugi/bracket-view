import 'package:bracket_view/bracket_view.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BracketMatch', () {
    const teamA = BracketTeam(name: 'A');
    const teamB = BracketTeam(name: 'B');

    test('upcoming match has no winner and is not finished/live', () {
      const match = BracketMatch(id: 'm1', teamA: teamA, teamB: teamB);
      expect(match.isFinished, isFalse);
      expect(match.isLive, isFalse);
      expect(match.teamAWon, isFalse);
      expect(match.teamBWon, isFalse);
    });

    test('isLive reflects status', () {
      const match = BracketMatch(
        id: 'm1',
        teamA: teamA,
        teamB: teamB,
        status: BracketMatchStatus.live,
      );
      expect(match.isLive, isTrue);
      expect(match.isFinished, isFalse);
    });

    test('isFinished reflects status', () {
      const match = BracketMatch(
        id: 'm1',
        teamA: teamA,
        teamB: teamB,
        status: BracketMatchStatus.finished,
      );
      expect(match.isFinished, isTrue);
      expect(match.isLive, isFalse);
    });

    test('teamAWon when winnerSide == teamA', () {
      const match = BracketMatch(
        id: 'm1',
        teamA: teamA,
        teamB: teamB,
        scoreA: 2,
        scoreB: 1,
        status: BracketMatchStatus.finished,
        winnerSide: BracketWinnerSide.teamA,
      );
      expect(match.teamAWon, isTrue);
      expect(match.teamBWon, isFalse);
    });

    test('teamBWon when winnerSide == teamB', () {
      const match = BracketMatch(
        id: 'm1',
        teamA: teamA,
        teamB: teamB,
        scoreA: 1,
        scoreB: 3,
        status: BracketMatchStatus.finished,
        winnerSide: BracketWinnerSide.teamB,
      );
      expect(match.teamBWon, isTrue);
      expect(match.teamAWon, isFalse);
    });

    test('level score with explicit winnerSide still resolves a winner', () {
      // Aggregate 1-1 decided on penalties — winnerSide is the source of truth.
      const match = BracketMatch(
        id: 'm1',
        teamA: teamA,
        teamB: teamB,
        scoreA: 1,
        scoreB: 1,
        status: BracketMatchStatus.finished,
        winnerSide: BracketWinnerSide.teamA,
      );
      expect(match.teamAWon, isTrue);
      expect(match.teamBWon, isFalse);
    });

    test('null winnerSide = no winner regardless of scores', () {
      // Avoid auto-deriving from scores; relying on explicit winnerSide is
      // intentional (see discussion: live/in-progress scores must not
      // accidentally mark a leading team as the winner).
      const match = BracketMatch(
        id: 'm1',
        teamA: teamA,
        teamB: teamB,
        scoreA: 5,
        scoreB: 0,
        status: BracketMatchStatus.finished,
      );
      expect(match.teamAWon, isFalse);
      expect(match.teamBWon, isFalse);
    });

    test('hasMultipleLegs is false when legs is null or single', () {
      const noLegs = BracketMatch(id: 'm1', teamA: teamA, teamB: teamB);
      expect(noLegs.hasMultipleLegs, isFalse);

      const oneLeg = BracketMatch(
        id: 'm1',
        teamA: teamA,
        teamB: teamB,
        legs: [BracketMatchLeg(label: 'Match', scoreA: 1, scoreB: 0)],
      );
      expect(oneLeg.hasMultipleLegs, isFalse);
    });

    test('hasMultipleLegs is true for two-leg ties', () {
      const match = BracketMatch(
        id: 'm1',
        teamA: teamA,
        teamB: teamB,
        legs: [
          BracketMatchLeg(label: '1st Leg', scoreA: 1, scoreB: 0),
          BracketMatchLeg(label: '2nd Leg', scoreA: 0, scoreB: 1),
        ],
      );
      expect(match.hasMultipleLegs, isTrue);
    });
  });
}
