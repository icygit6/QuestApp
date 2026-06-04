import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../../../core/errors/failures.dart';
import '../../../core/providers.dart';
import '../../auth/presentation/auth_provider.dart';
import '../data/quest_local_datasource.dart';
import '../data/quest_model.dart';
import '../data/quest_remote_datasource.dart';
import '../data/quest_repository_impl.dart';
import '../domain/complete_quest_usecase.dart';
import '../domain/get_quests_usecase.dart';
import '../domain/quest_entity.dart';
import '../domain/quest_repository.dart';
import 'custom_quest_provider.dart';

final questBoxProvider = Provider<Box<QuestModel>>(
  (ref) => Hive.box<QuestModel>('quests'),
);

final questRemoteDataSourceProvider = Provider<QuestRemoteDataSource>(
  (ref) => QuestRemoteDataSource(ref.watch(dioClientProvider)),
);

final questLocalDataSourceProvider = Provider<QuestLocalDataSource>(
  (ref) => QuestLocalDataSource(ref.watch(questBoxProvider)),
);

final questRepositoryProvider = Provider<QuestRepository>(
  (ref) => QuestRepositoryImpl(
    remoteDataSource: ref.watch(questRemoteDataSourceProvider),
    localDataSource: ref.watch(questLocalDataSourceProvider),
    preferences: ref.watch(sharedPreferencesProvider),
  ),
);

final getQuestsUseCaseProvider = Provider<GetQuestsUseCase>(
  (ref) => GetQuestsUseCase(ref.watch(questRepositoryProvider)),
);

final completeQuestUseCaseProvider = Provider<CompleteQuestUseCase>(
  (ref) => CompleteQuestUseCase(ref.watch(questRepositoryProvider)),
);

final questsProvider = StateNotifierProvider<QuestsNotifier, QuestsState>((
  ref,
) {
  final notifier = QuestsNotifier(
    getQuestsUseCase: ref.watch(getQuestsUseCaseProvider),
    completeQuestUseCase: ref.watch(completeQuestUseCaseProvider),
    userId: ref.watch(authStateProvider).user?.id,
    customQuests: ref.read(customQuestsProvider),
  )..load(refresh: true);
  // Keep the merged list in sync as the user creates/edits/deletes quests.
  ref.listen<List<QuestEntity>>(customQuestsProvider, (_, next) {
    notifier.setCustomQuests(next);
  });
  return notifier;
});

final searchQueryProvider = StateProvider<String>((ref) => '');

final difficultyFilterProvider = StateProvider<String?>((ref) => null);

final categoryFilterProvider = StateProvider<String?>((ref) => null);

final completionFilterProvider = StateProvider<bool>((ref) => false);

final filteredQuestsProvider = Provider<List<QuestEntity>>((ref) {
  final quests = ref.watch(questsProvider).quests;
  final query = ref.watch(searchQueryProvider).trim().toLowerCase();
  final difficulty = ref.watch(difficultyFilterProvider);
  final category = ref.watch(categoryFilterProvider);
  final completedOnly = ref.watch(completionFilterProvider);

  return quests
      .where((quest) {
        final matchesQuery =
            query.isEmpty || quest.title.toLowerCase().contains(query);
        final matchesDifficulty =
            difficulty == null || quest.difficulty.label == difficulty;
        final matchesCategory =
            category == null || quest.category.label == category;
        final matchesCompletion = !completedOnly || quest.isCompleted;
        return matchesQuery &&
            matchesDifficulty &&
            matchesCategory &&
            matchesCompletion;
      })
      .toList(growable: false);
});

final pendingQuestCountProvider = Provider<int>((ref) {
  return ref
      .watch(questsProvider)
      .quests
      .where((quest) => !quest.isCompleted)
      .length;
});

enum QuestStatus { loading, loaded, error }

class QuestsState {
  const QuestsState({
    required this.status,
    required this.quests,
    required this.hasMore,
    required this.isFetchingMore,
    this.message,
  });

  factory QuestsState.initial() {
    return const QuestsState(
      status: QuestStatus.loading,
      quests: [],
      hasMore: true,
      isFetchingMore: false,
    );
  }

  final QuestStatus status;
  final List<QuestEntity> quests;
  final bool hasMore;
  final bool isFetchingMore;
  final String? message;

  QuestsState copyWith({
    QuestStatus? status,
    List<QuestEntity>? quests,
    bool? hasMore,
    bool? isFetchingMore,
    String? message,
  }) {
    return QuestsState(
      status: status ?? this.status,
      quests: quests ?? this.quests,
      hasMore: hasMore ?? this.hasMore,
      isFetchingMore: isFetchingMore ?? this.isFetchingMore,
      message: message,
    );
  }
}

class QuestsNotifier extends StateNotifier<QuestsState> {
  QuestsNotifier({
    required GetQuestsUseCase getQuestsUseCase,
    required CompleteQuestUseCase completeQuestUseCase,
    required int? userId,
    List<QuestEntity> customQuests = const <QuestEntity>[],
  }) : _getQuestsUseCase = getQuestsUseCase,
       _completeQuestUseCase = completeQuestUseCase,
       _userId = userId,
       _custom = customQuests,
       super(QuestsState.initial());

  static const _pageSize = 20;

  final GetQuestsUseCase _getQuestsUseCase;
  final CompleteQuestUseCase _completeQuestUseCase;
  final int? _userId;

  /// User-created quests, always shown on top of the API quests.
  List<QuestEntity> _custom;

  int _skip = 0;

  /// Prepends custom quests to [apiQuests], dropping any API quest that shares
  /// an id (custom ids never collide in practice, but dedupe defensively).
  List<QuestEntity> _mergeCustom(List<QuestEntity> apiQuests) {
    final customIds = {for (final quest in _custom) quest.id};
    return [
      ..._custom,
      ...apiQuests.where((quest) => !customIds.contains(quest.id)),
    ];
  }

  /// Called when the custom-quest store changes; re-merges without refetching.
  void setCustomQuests(List<QuestEntity> custom) {
    _custom = custom;
    final apiQuests = state.quests
        .where((quest) => !quest.isCustom)
        .toList(growable: false);
    state = state.copyWith(quests: _mergeCustom(apiQuests));
  }

  /// Loads the first quest page or refreshes from the start.
  Future<void> load({bool refresh = false}) async {
    if (refresh) {
      _skip = 0;
      state = state.copyWith(
        status: QuestStatus.loading,
        quests: [],
        hasMore: true,
        isFetchingMore: false,
      );
    }
    final result = await _getQuestsUseCase(
      limit: _pageSize,
      skip: _skip,
      userId: null,
    );
    state = result.fold(
      (failure) => state.copyWith(
        status: QuestStatus.error,
        message: failure.message,
        isFetchingMore: false,
      ),
      (quests) {
        _skip = quests.length;
        return state.copyWith(
          status: QuestStatus.loaded,
          quests: _mergeCustom(quests),
          hasMore: quests.length >= _pageSize && _userId == null,
          isFetchingMore: false,
        );
      },
    );
  }

  /// Fetches the next page when pagination is available.
  Future<void> loadMore() async {
    if (!state.hasMore ||
        state.isFetchingMore ||
        state.status != QuestStatus.loaded) {
      return;
    }
    state = state.copyWith(isFetchingMore: true);
    final result = await _getQuestsUseCase(
      limit: _pageSize,
      skip: _skip,
      userId: null,
    );
    state = result.fold(
      (failure) =>
          state.copyWith(message: failure.message, isFetchingMore: false),
      (quests) {
        _skip += quests.length;
        // Merge only the API quests (exclude custom) then re-prepend custom so
        // user quests stay pinned to the top regardless of their large ids.
        final apiQuests =
            {
              for (final quest in state.quests)
                if (!quest.isCustom) quest.id: quest,
              for (final quest in quests) quest.id: quest,
            }.values.toList()..sort((a, b) => a.id.compareTo(b.id));
        return state.copyWith(
          quests: _mergeCustom(apiQuests),
          hasMore: quests.length >= _pageSize,
          isFetchingMore: false,
          status: QuestStatus.loaded,
        );
      },
    );
  }

  /// Optimistically completes a quest and syncs with the repository.
  Future<Failure?> complete(QuestEntity quest) async {
    if (quest.isCompleted) {
      return null;
    }
    final previousQuests = state.quests;
    final optimistic = quest.copyWith(isCompleted: true);
    state = state.copyWith(
      quests: [
        for (final item in state.quests)
          if (item.id == quest.id) optimistic else item,
      ],
    );
    final result = await _completeQuestUseCase(quest);
    return result.fold(
      (failure) {
        state = state.copyWith(
          quests: previousQuests,
          message: failure.message,
        );
        return failure;
      },
      (updated) {
        state = state.copyWith(
          quests: [
            for (final item in state.quests)
              if (item.id == updated.id) updated else item,
          ],
        );
        return null;
      },
    );
  }

  /// Finds a loaded quest by id.
  QuestEntity? byId(int id) {
    for (final quest in state.quests) {
      if (quest.id == id) {
        return quest;
      }
    }
    return null;
  }
}
