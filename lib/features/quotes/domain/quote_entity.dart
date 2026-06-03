class QuoteEntity {
  const QuoteEntity({
    required this.id,
    required this.body,
    required this.author,
    required this.tags,
    required this.favoritesCount,
  });

  final int id;
  final String body;
  final String author;
  final List<String> tags;
  final int favoritesCount;
}
