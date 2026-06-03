import 'package:hive/hive.dart';

import '../domain/quest_entity.dart';

class QuestModel extends QuestEntity {
  const QuestModel({
    required super.id,
    required super.title,
    required super.description,
    required super.isCompleted,
    required super.assignedTo,
    required super.difficulty,
    required super.category,
    required super.xpReward,
  });

  factory QuestModel.fromTodo(Map<String, dynamic> json) {
    return QuestModel.fromJson(json);
  }

  factory QuestModel.fromJson(Map<String, dynamic> json) {
    final id = (json['id'] as num?)?.toInt() ?? 0;
    final difficulty = QuestDifficulty.fromIndex(id % 3);
    final category = QuestCategory.fromIndex(id % 4);
    final title = json['todo']?.toString() ?? 'Untitled quest';
    return QuestModel(
      id: id,
      title: title,
      description:
          'A ${difficulty.label.toLowerCase()} ${category.label.toLowerCase()} quest assigned by the realm: $title',
      isCompleted: json['completed'] as bool? ?? false,
      assignedTo: (json['userId'] as num?)?.toInt() ?? 0,
      difficulty: difficulty,
      category: category,
      xpReward: difficulty.xpReward,
    );
  }

  factory QuestModel.fromEntity(QuestEntity entity) {
    return QuestModel(
      id: entity.id,
      title: entity.title,
      description: entity.description,
      isCompleted: entity.isCompleted,
      assignedTo: entity.assignedTo,
      difficulty: entity.difficulty,
      category: entity.category,
      xpReward: entity.xpReward,
    );
  }

  QuestModel copyWithModel({bool? isCompleted}) {
    return QuestModel.fromEntity(copyWith(isCompleted: isCompleted));
  }
}

class QuestModelAdapter extends TypeAdapter<QuestModel> {
  @override
  final int typeId = 1;

  @override
  QuestModel read(BinaryReader reader) {
    return QuestModel(
      id: reader.readInt(),
      title: reader.readString(),
      description: reader.readString(),
      isCompleted: reader.readBool(),
      assignedTo: reader.readInt(),
      difficulty: QuestDifficulty.fromLabel(reader.readString()),
      category: QuestCategory.fromLabel(reader.readString()),
      xpReward: reader.readInt(),
    );
  }

  @override
  void write(BinaryWriter writer, QuestModel obj) {
    writer
      ..writeInt(obj.id)
      ..writeString(obj.title)
      ..writeString(obj.description)
      ..writeBool(obj.isCompleted)
      ..writeInt(obj.assignedTo)
      ..writeString(obj.difficulty.label)
      ..writeString(obj.category.label)
      ..writeInt(obj.xpReward);
  }
}
