import '../domain/post_entity.dart';

class PostModel extends PostEntity {
  const PostModel({
    required super.id,
    required super.userId,
    required super.title,
    required super.body,
  });

  factory PostModel.fromJson(Map<String, dynamic> json) {
    return PostModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      userId: (json['userId'] as num?)?.toInt() ?? 0,
      title: json['title']?.toString() ?? '',
      body: json['body']?.toString() ?? '',
    );
  }

  factory PostModel.fromEntity(PostEntity entity) {
    return PostModel(
      id: entity.id,
      userId: entity.userId,
      title: entity.title,
      body: entity.body,
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'userId': userId, 'title': title, 'body': body};
  }
}
