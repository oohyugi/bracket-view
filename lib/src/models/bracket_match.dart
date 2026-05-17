import 'package:bracket_view/src/models/bracket_team.dart';

/// Status of a bracket match.
enum BracketMatchStatus { upcoming, live, finished }

/// Represents a single match/tie in the bracket.
///
/// For two-leg ties, scores should be the aggregate.
class BracketMatch {
  const BracketMatch({
    required this.id,
    required this.teamA,
    required this.teamB,
    this.scoreA,
    this.scoreB,
    this.status = BracketMatchStatus.upcoming,
    this.winnerSide,
    this.label,
  });

  /// Unique identifier for this match.
  final String id;

  /// First team (home in first leg).
  final BracketTeam teamA;

  /// Second team (away in first leg).
  final BracketTeam teamB;

  /// Score for team A (aggregate for two-leg ties).
  final int? scoreA;

  /// Score for team B (aggregate for two-leg ties).
  final int? scoreB;

  /// Current status of the match.
  final BracketMatchStatus status;

  /// Winner side: 'A', 'B', or null (not determined / tie).
  final String? winnerSide;

  /// Optional label shown above the match card (e.g. "Aggregate", "Match").
  final String? label;

  /// Whether the match has finished.
  bool get isFinished => status == BracketMatchStatus.finished;

  /// Whether the match is currently live.
  bool get isLive => status == BracketMatchStatus.live;

  /// Whether team A won the match.
  bool get teamAWon => winnerSide == 'A';

  /// Whether team B won the match.
  bool get teamBWon => winnerSide == 'B';
}
