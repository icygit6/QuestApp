/// Ranked player entry shown in the leaderboard.
class LeaderboardEntry {
  const LeaderboardEntry({
    required this.userId,
    required this.rank,
    required this.username,
    required this.displayName,
    required this.avatarUrl,
    required this.xp,
    required this.questsCompleted,
    this.isCurrentUser = false,
  });

  final int userId;
  final int rank;
  final String username;
  final String displayName;
  final String avatarUrl;
  final int xp;
  final int questsCompleted;
  final bool isCurrentUser;

  LeaderboardEntry copyWith({
    int? rank,
    int? xp,
    int? questsCompleted,
    bool? isCurrentUser,
  }) {
    return LeaderboardEntry(
      userId: userId,
      rank: rank ?? this.rank,
      username: username,
      displayName: displayName,
      avatarUrl: avatarUrl,
      xp: xp ?? this.xp,
      questsCompleted: questsCompleted ?? this.questsCompleted,
      isCurrentUser: isCurrentUser ?? this.isCurrentUser,
    );
  }
}
