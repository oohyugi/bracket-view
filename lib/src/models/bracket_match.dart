import 'package:bracket_view/src/models/bracket_team.dart';

/// Status of a bracket match.
enum BracketMatchStatus { upcoming, live, finished }

/// Which side of a [BracketMatch] won the tie.
enum BracketWinnerSide { teamA, teamB }

/// Represents a single match/tie in the bracket.
///
/// [scoreA]/[scoreB] hold the final score used to display the result —
/// the full-time (or extra-time) score for a single-leg knockout, or the
/// aggregate for a two-leg tie. When the score is level and the tie is
/// decided on penalties or away goals, set [winnerSide] explicitly so the
/// loser is still struck through.
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

  /// Final score for team A (full-time score, or aggregate for two-leg ties).
  final int? scoreA;

  /// Final score for team B (full-time score, or aggregate for two-leg ties).
  final int? scoreB;

  /// Current status of the match.
  final BracketMatchStatus status;

  /// Winning side of the tie, or null if not determined / drawn.
  ///
  /// Set this explicitly to mark the loser with a strikethrough — useful when
  /// the aggregate is level and the tie is decided on penalties or away
  /// goals, where score comparison alone can't determine the winner.
  final BracketWinnerSide? winnerSide;

  /// Optional label shown above the match card (e.g. "Aggregate", "Match").
  final String? label;

  /// Whether the match has finished.
  bool get isFinished => status == BracketMatchStatus.finished;

  /// Whether the match is currently live.
  bool get isLive => status == BracketMatchStatus.live;

  /// Whether team A won the match.
  bool get teamAWon => winnerSide == BracketWinnerSide.teamA;

  /// Whether team B won the match.
  bool get teamBWon => winnerSide == BracketWinnerSide.teamB;
}
