import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/errors/failures.dart';
import '../../../core/network/dio_client.dart';
import '../domain/quest_entity.dart';
import '../domain/quest_repository.dart';
import 'quest_local_datasource.dart';
import 'quest_model.dart';
import 'quest_remote_datasource.dart';

class QuestRepositoryImpl implements QuestRepository {
  const QuestRepositoryImpl({
    required QuestRemoteDataSource remoteDataSource,
    required QuestLocalDataSource localDataSource,
    required SharedPreferences preferences,
  }) : _remoteDataSource = remoteDataSource,
       _localDataSource = localDataSource,
       _preferences = preferences;

  static const completedQuestIdsKey = 'completed_quest_ids';
  static const completionTimesKey = 'quest_completion_times';
  static const cacheVersionKey = 'cache_version';
  static const _currentCacheVersion = '2';

  final QuestRemoteDataSource _remoteDataSource;
  final QuestLocalDataSource _localDataSource;
  final SharedPreferences _preferences;

  @override
  Future<Either<Failure, List<QuestEntity>>> getQuests({
    required int limit,
    required int skip,
    int? userId,
  }) async {
    await _ensureCacheVersion();
    final completedIds = _completedIds();

    try {
      debugPrint('Fetching quests from API: limit=$limit skip=$skip');
      final quests = await _remoteDataSource.getQuests(
        limit: limit,
        skip: skip,
        userId: userId,
      );
      debugPrint('Received ${quests.length} quests from API');

      final localTruthQuests = _applyLocalCompletion(quests, completedIds);
      if (skip == 0) {
        await _localDataSource.clearCache();
      }
      await _localDataSource.cacheQuests(
        localTruthQuests.map(QuestModel.fromEntity).toList(growable: false),
      );
      return Right(localTruthQuests);
    } catch (error) {
      final cached = await _localDataSource.getCachedQuests();
      if (cached.isNotEmpty) {
        return Right(_applyLocalCompletion(cached, completedIds));
      }
      return Left(mapDioFailure(error));
    }
  }

  @override
  Future<Either<Failure, QuestEntity>> completeQuest(QuestEntity quest) async {
    // User-created quests have no API counterpart, so PUT /todos/{id} would
    // 404. Record completion locally (same store as API quests) and return.
    if (quest.id >= kCustomQuestIdBase) {
      await _recordCompletion(quest.id);
      return Right(quest.copyWith(isCompleted: true));
    }
    try {
      final updated = await _remoteDataSource.completeQuest(
        QuestModel.fromEntity(quest),
      );
      final completed = QuestModel.fromEntity(
        updated.copyWith(isCompleted: true),
      );
      await _recordCompletion(completed.id);
      await _localDataSource.upsertQuest(completed);
      return Right(completed);
    } catch (error) {
      return Left(mapDioFailure(error));
    }
  }

  @override
  Future<List<QuestEntity>> getCachedQuests() async {
    final cached = await _localDataSource.getCachedQuests();
    return _applyLocalCompletion(cached, _completedIds());
  }

  Future<void> _ensureCacheVersion() async {
    if (_preferences.getString(cacheVersionKey) == _currentCacheVersion) {
      return;
    }
    await _localDataSource.clearCache();
    await _preferences.setString(cacheVersionKey, _currentCacheVersion);
  }

  List<QuestEntity> _applyLocalCompletion(
    List<QuestEntity> quests,
    Set<int> completedIds,
  ) {
    return quests
        .map(
          (quest) =>
              quest.copyWith(isCompleted: completedIds.contains(quest.id)),
        )
        .toList(growable: false);
  }

  Set<int> _completedIds() {
    return (_preferences.getStringList(completedQuestIdsKey) ??
            const <String>[])
        .map(int.tryParse)
        .whereType<int>()
        .toSet();
  }

  Future<void> _recordCompletion(int questId) async {
    final ids = _completedIds()..add(questId);
    await _preferences.setStringList(
      completedQuestIdsKey,
      ids.map((id) => id.toString()).toList(growable: false)..sort(),
    );

    final times = _completionTimes();
    times['$questId'] = DateTime.now().toUtc().toIso8601String();
    await _preferences.setString(completionTimesKey, jsonEncode(times));
  }

  Map<String, String> _completionTimes() {
    final raw = _preferences.getString(completionTimesKey);
    if (raw == null || raw.isEmpty) {
      return <String, String>{};
    }
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    return decoded.map((key, value) => MapEntry(key, value.toString()));
  }
}
