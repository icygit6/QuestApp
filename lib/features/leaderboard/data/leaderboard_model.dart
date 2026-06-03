import '../domain/leaderboard_entity.dart';

class LeaderboardModel extends LeaderboardEntry {
  const LeaderboardModel({
    required super.userId,
    required super.rank,
    required super.username,
    required super.displayName,
    required super.avatarUrl,
    required super.xp,
    required super.questsCompleted,
    super.isCurrentUser,
  });

  factory LeaderboardModel.fromUser({
    required Map<String, dynamic> user,
    required int xp,
    required int questsCompleted,
  }) {
    final firstName = user['firstName']?.toString() ?? '';
    final lastName = user['lastName']?.toString() ?? '';
    final username = user['username']?.toString() ?? '';
    final displayName = '$firstName $lastName'.trim();
    return LeaderboardModel(
      userId: (user['id'] as num?)?.toInt() ?? 0,
      rank: 0,
      username: username,
      displayName: displayName.isEmpty ? username : displayName,
      avatarUrl: user['image']?.toString() ?? '',
      xp: xp,
      questsCompleted: questsCompleted,
    );
  }

  LeaderboardModel withRank(int rank) {
    return LeaderboardModel(
      userId: userId,
      rank: rank,
      username: username,
      displayName: displayName,
      avatarUrl: avatarUrl,
      xp: xp,
      questsCompleted: questsCompleted,
      isCurrentUser: isCurrentUser,
    );
  }
}
