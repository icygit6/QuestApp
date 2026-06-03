/// Quest difficulty derived from DummyJSON todo id.
enum QuestDifficulty {
  easy('Easy', 50),
  medium('Medium', 100),
  hard('Hard', 200);

  const QuestDifficulty(this.label, this.xpReward);

  final String label;
  final int xpReward;

  static QuestDifficulty fromIndex(int index) {
    return switch (index) {
      0 => QuestDifficulty.easy,
      1 => QuestDifficulty.medium,
      _ => QuestDifficulty.hard,
    };
  }

  static QuestDifficulty fromLabel(String label) {
    return QuestDifficulty.values.firstWhere(
      (difficulty) => difficulty.label == label,
      orElse: () => QuestDifficulty.easy,
    );
  }
}

/// Quest category derived from DummyJSON todo id.
enum QuestCategory {
  combat('Combat'),
  exploration('Exploration'),
  crafting('Crafting'),
  social('Social');

  const QuestCategory(this.label);

  final String label;

  static QuestCategory fromIndex(int index) {
    return switch (index) {
      0 => QuestCategory.combat,
      1 => QuestCategory.exploration,
      2 => QuestCategory.crafting,
      _ => QuestCategory.social,
    };
  }

  static QuestCategory fromLabel(String label) {
    return QuestCategory.values.firstWhere(
      (category) => category.label == label,
      orElse: () => QuestCategory.combat,
    );
  }
}

/// Domain entity for a task transformed into an RPG quest.
class QuestEntity {
  const QuestEntity({
    required this.id,
    required this.title,
    required this.description,
    required this.isCompleted,
    required this.assignedTo,
    required this.difficulty,
    required this.category,
    required this.xpReward,
  });

  final int id;
  final String title;
  final String description;
  final bool isCompleted;
  final int assignedTo;
  final QuestDifficulty difficulty;
  final QuestCategory category;
  final int xpReward;

  int get estimatedMinutes {
    return switch (difficulty) {
      QuestDifficulty.easy => 15,
      QuestDifficulty.medium => 30,
      QuestDifficulty.hard => 60,
    };
  }

  QuestEntity copyWith({
    int? id,
    String? title,
    String? description,
    bool? isCompleted,
    int? assignedTo,
    QuestDifficulty? difficulty,
    QuestCategory? category,
    int? xpReward,
  }) {
    return QuestEntity(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      isCompleted: isCompleted ?? this.isCompleted,
      assignedTo: assignedTo ?? this.assignedTo,
      difficulty: difficulty ?? this.difficulty,
      category: category ?? this.category,
      xpReward: xpReward ?? this.xpReward,
    );
  }
}
