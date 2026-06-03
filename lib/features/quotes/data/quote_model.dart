import '../domain/quote_entity.dart';

class QuoteModel extends QuoteEntity {
  const QuoteModel({
    required super.id,
    required super.body,
    required super.author,
    required super.tags,
    required super.favoritesCount,
  });

  factory QuoteModel.fromJson(Map<String, dynamic> json) {
    return QuoteModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      body: json['body']?.toString() ?? '',
      author: json['author']?.toString() ?? 'Unknown',
      tags: (json['tags'] as List<dynamic>? ?? const <dynamic>[])
          .map((tag) => tag.toString())
          .toList(growable: false),
      favoritesCount: (json['favorites_count'] as num?)?.toInt() ?? 0,
    );
  }
}
