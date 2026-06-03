/// Local achievement definition and unlock state.
class Achievement {
  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.isUnlocked,
    this.unlockedAt,
  });

  final String id;
  final String title;
  final String description;
  final bool isUnlocked;
  final DateTime? unlockedAt;

  Achievement unlock(DateTime date) {
    if (isUnlocked) {
      return this;
    }
    return copyWith(isUnlocked: true, unlockedAt: date);
  }

  Achievement copyWith({
    String? id,
    String? title,
    String? description,
    bool? isUnlocked,
    DateTime? unlockedAt,
  }) {
    return Achievement(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      unlockedAt: unlockedAt ?? this.unlockedAt,
    );
  }
}
