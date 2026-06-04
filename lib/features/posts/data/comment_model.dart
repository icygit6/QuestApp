import '../domain/comment_entity.dart';

class CommentModel extends CommentEntity {
  const CommentModel({
    required super.id,
    required super.postId,
    required super.name,
    required super.email,
    required super.body,
  });

  factory CommentModel.fromJson(Map<String, dynamic> json) {
    return CommentModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      postId: (json['postId'] as num?)?.toInt() ?? 0,
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      body: json['body']?.toString() ?? '',
    );
  }
}
