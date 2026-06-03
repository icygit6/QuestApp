import '../../../core/network/dio_client.dart';
import 'leaderboard_model.dart';

class LeaderboardRemoteDataSource {
  const LeaderboardRemoteDataSource(this._dioClient);

  final DioClient _dioClient;

  /// Loads users and assigns deterministic leaderboard seed values.
  Future<List<LeaderboardModel>> getLeaderboard() async {
    final response = await _dioClient.dummyDio.get<Map<String, dynamic>>(
      '/users',
      queryParameters: {'limit': 20},
    );
    final users =
        (response.data?['users'] as List<dynamic>? ?? const <dynamic>[])
            .whereType<Map<String, dynamic>>()
            .toList(growable: false);

    final entries = users
        .map((user) {
          final id = (user['id'] as num?)?.toInt() ?? 0;
          return LeaderboardModel.fromUser(
            user: user,
            xp: _xpForUser(id),
            questsCompleted: _questsCompletedForUser(id),
          );
        })
        .toList(growable: false);

    entries.sort((a, b) => b.xp.compareTo(a.xp));
    return [
      for (var i = 0; i < entries.length; i++) entries[i].withRank(i + 1),
    ];
  }

  int _xpForUser(int userId) {
    return (userId * 47 + userId % 7 * 31) % 2000 + 100;
  }

  int _questsCompletedForUser(int userId) {
    return (userId * 3) % 25 + 1;
  }
}
