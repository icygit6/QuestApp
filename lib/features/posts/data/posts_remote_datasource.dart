import '../../../core/network/dio_client.dart';
import 'comment_model.dart';
import 'post_model.dart';

class PostsRemoteDataSource {
  const PostsRemoteDataSource(this._dioClient);

  final DioClient _dioClient;

  Future<List<PostModel>> getPosts() async {
    final response = await _dioClient.jsonPlaceholderDio.get<List<dynamic>>(
      '/posts',
    );
    final data = response.data ?? const <dynamic>[];
    final posts = data.whereType<Map<String, dynamic>>();
    return posts.map(PostModel.fromJson).toList(growable: false);
  }

  Future<PostModel> getPostDetail(int id) async {
    final response = await _dioClient.jsonPlaceholderDio
        .get<Map<String, dynamic>>('/posts/$id');
    return PostModel.fromJson(response.data ?? <String, dynamic>{});
  }

  Future<PostModel> createPost({
    required String title,
    required String body,
    required int userId,
  }) async {
    final response = await _dioClient.jsonPlaceholderDio
        .post<Map<String, dynamic>>(
      '/posts',
      data: {'title': title, 'body': body, 'userId': userId},
    );
    return PostModel.fromJson(response.data ?? <String, dynamic>{});
  }

  Future<List<CommentModel>> getComments(int postId) async {
    final response = await _dioClient.jsonPlaceholderDio.get<List<dynamic>>(
      '/posts/$postId/comments',
    );
    final data = response.data ?? const <dynamic>[];
    return data
        .whereType<Map<String, dynamic>>()
        .map(CommentModel.fromJson)
        .toList(growable: false);
  }
}
