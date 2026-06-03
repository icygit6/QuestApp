import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../auth/presentation/auth_provider.dart';
import '../../gamification/presentation/gamification_provider.dart';
import '../data/leaderboard_remote_datasource.dart';
import '../domain/leaderboard_entity.dart';

final leaderboardRemoteDataSourceProvider =
    Provider<LeaderboardRemoteDataSource>(
      (ref) => LeaderboardRemoteDataSource(ref.watch(dioClientProvider)),
    );

final leaderboardProvider = FutureProvider<List<LeaderboardEntry>>((ref) async {
  final gamification = ref.watch(gamificationProvider);
  final currentUser = ref.watch(authStateProvider).user;
  final remoteUsers = await ref
      .read(leaderboardRemoteDataSourceProvider)
      .getLeaderboard();

  final entries = remoteUsers
      .map((user) {
        final isCurrentUser = user.userId == currentUser?.id;
        if (isCurrentUser) {
          return user.copyWith(
            xp: gamification.totalXpEarned,
            questsCompleted: gamification.totalQuestsCompleted,
            isCurrentUser: true,
          );
        }
        return user.copyWith(
          xp: _xpForUser(user.userId),
          questsCompleted: _questsCompletedForUser(user.userId),
          isCurrentUser: false,
        );
      })
      .toList(growable: true);

  if (currentUser != null &&
      !entries.any((entry) => entry.userId == currentUser.id)) {
    entries.add(
      LeaderboardEntry(
        userId: currentUser.id,
        rank: 0,
        username: currentUser.username,
        displayName: currentUser.displayName,
        avatarUrl: currentUser.image,
        xp: gamification.totalXpEarned,
        questsCompleted: gamification.totalQuestsCompleted,
        isCurrentUser: true,
      ),
    );
  }

  entries.sort((a, b) => b.xp.compareTo(a.xp));
  return [
    for (var i = 0; i < entries.length; i++) entries[i].copyWith(rank: i + 1),
  ];
});

final leaderboardSearchProvider = StateProvider<String>((ref) => '');

final filteredLeaderboardProvider =
    Provider<AsyncValue<List<LeaderboardEntry>>>((ref) {
      final query = ref.watch(leaderboardSearchProvider).trim().toLowerCase();
      return ref.watch(leaderboardProvider).whenData((entries) {
        if (query.isEmpty) {
          return entries;
        }
        return entries
            .where(
              (entry) =>
                  entry.username.toLowerCase().contains(query) ||
                  entry.displayName.toLowerCase().contains(query),
            )
            .toList(growable: false);
      });
    });

int _xpForUser(int userId) {
  return (userId * 47 + userId % 7 * 31) % 2000 + 100;
}

int _questsCompletedForUser(int userId) {
  return (userId * 3) % 25 + 1;
}
