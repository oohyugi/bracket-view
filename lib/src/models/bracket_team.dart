/// Represents a team in a bracket match.
class BracketTeam {
  const BracketTeam({required this.name, this.imageUrl, this.id});

  /// Display name of the team.
  final String name;

  /// Optional logo/image URL.
  final String? imageUrl;

  /// Optional unique identifier.
  final String? id;
}
