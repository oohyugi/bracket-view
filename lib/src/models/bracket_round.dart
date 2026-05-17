import 'package:bracket_view/src/models/bracket_match.dart';

/// Represents a round in the tournament bracket.
class BracketRound {
  const BracketRound({
    required this.id,
    required this.name,
    required this.matches,
    this.dateLabel,
  });

  /// Unique identifier for this round.
  final String id;

  /// Display name (e.g. "Quarter Final", "Semi Final").
  final String name;

  /// Matches in this round, ordered for bracket alignment.
  final List<BracketMatch> matches;

  /// Optional date range label (e.g. "8-9 Apr | 15-16 Apr").
  final String? dateLabel;
}
