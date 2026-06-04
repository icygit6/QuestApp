import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:questboard/features/posts/data/post_model.dart';
import 'package:questboard/features/posts/data/posts_local_datasource.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late Box<String> box;
  late PostsLocalDataSource dataSource;

  setUp(() async {
    tempDir = Directory.systemTemp.createTempSync('qb_user_posts_test');
    Hive.init(tempDir.path);
    box = await Hive.openBox<String>('user_posts_test');
    dataSource = PostsLocalDataSource(box);
  });

  tearDown(() async {
    await Hive.close();
    tempDir.deleteSync(recursive: true);
  });

  test('round-trips a stored post', () async {
    const post = PostModel(id: 1000, userId: 3, title: 'Hi', body: 'There');
    await dataSource.addUserPost(post);

    final stored = dataSource.getUserPosts();
    expect(stored, hasLength(1));
    expect(stored.first.id, 1000);
    expect(stored.first.userId, 3);
    expect(stored.first.title, 'Hi');
    expect(stored.first.body, 'There');
  });

  test('returns posts newest-first by id', () async {
    await dataSource.addUserPost(
      const PostModel(id: 100, userId: 1, title: 'Old', body: 'b'),
    );
    await dataSource.addUserPost(
      const PostModel(id: 300, userId: 1, title: 'New', body: 'b'),
    );
    await dataSource.addUserPost(
      const PostModel(id: 200, userId: 1, title: 'Mid', body: 'b'),
    );

    final ids = dataSource.getUserPosts().map((post) => post.id).toList();
    expect(ids, <int>[300, 200, 100]);
  });

  test('overwrites a post stored under the same id', () async {
    await dataSource.addUserPost(
      const PostModel(id: 5, userId: 1, title: 'First', body: 'b'),
    );
    await dataSource.addUserPost(
      const PostModel(id: 5, userId: 1, title: 'Second', body: 'b'),
    );

    final stored = dataSource.getUserPosts();
    expect(stored, hasLength(1));
    expect(stored.first.title, 'Second');
  });
}
