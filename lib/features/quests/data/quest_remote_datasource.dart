import '../../../core/network/dio_client.dart';
import 'quest_model.dart';

class QuestRemoteDataSource {
  const QuestRemoteDataSource(this._dioClient);

  final DioClient _dioClient;

  /// Fetches DummyJSON todos and maps them to quest models.
  Future<List<QuestModel>> getQuests({
    required int limit,
    required int skip,
    int? userId,
  }) async {
    final path = userId == null ? '/todos' : '/todos/user/$userId';
    final response = await _dioClient.dummyDio.get<Map<String, dynamic>>(
      path,
      queryParameters: userId == null ? {'limit': limit, 'skip': skip} : null,
    );
    final data = response.data ?? <String, dynamic>{};
    final todos = (data['todos'] as List<dynamic>? ?? const <dynamic>[])
        .whereType<Map<String, dynamic>>();
    return todos.map(QuestModel.fromJson).toList(growable: false);
  }

  /// Calls DummyJSON PUT /todos/{id}.
  Future<QuestModel> completeQuest(QuestModel quest) async {
    final response = await _dioClient.dummyDio.put<Map<String, dynamic>>(
      '/todos/${quest.id}',
      data: {'completed': true},
    );
    if (response.data == null) {
      return quest.copyWithModel(isCompleted: true);
    }
    return QuestModel.fromTodo(response.data!).copyWithModel(isCompleted: true);
  }
}
