import 'dart:convert';

import 'package:hive/hive.dart';

import 'post_model.dart';

/// Persists posts created by the user.
///
/// JSONPlaceholder is a mock API: `POST /posts` always echoes back `id: 101`
/// and never actually stores anything, so a freshly created post would vanish
/// on the next refresh. We keep our own copy in a Hive box (`user_posts`) and
/// merge it back in [PostsRepositoryImpl.getPosts] so the post survives.
///
/// Posts are stored as JSON strings keyed by id, so no Hive [TypeAdapter] is
/// needed — [PostModel.toJson] / [PostModel.fromJson] do the (de)serialisation.
class PostsLocalDataSource {
  const PostsLocalDataSource(this._box);

  final Box<String> _box;

  /// All user-created posts, newest first (ids are creation timestamps).
  List<PostModel> getUserPosts() {
    final posts = _box.values
        .map(
          (raw) =>
              PostModel.fromJson(jsonDecode(raw) as Map<String, dynamic>),
        )
        .toList(growable: false);
    return posts..sort((a, b) => b.id.compareTo(a.id));
  }

  Future<void> addUserPost(PostModel post) async {
    await _box.put(post.id.toString(), jsonEncode(post.toJson()));
  }
}
