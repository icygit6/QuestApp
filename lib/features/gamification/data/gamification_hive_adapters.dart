import 'package:hive/hive.dart';

import '../domain/achievement.dart';
import '../domain/daily_record.dart';

class AchievementAdapter extends TypeAdapter<Achievement> {
  @override
  final int typeId = 2;

  @override
  Achievement read(BinaryReader reader) {
    return Achievement(
      id: reader.readString(),
      title: reader.readString(),
      description: reader.readString(),
      isUnlocked: reader.readBool(),
      unlockedAt: reader.readBool()
          ? DateTime.parse(reader.readString())
          : null,
    );
  }

  @override
  void write(BinaryWriter writer, Achievement obj) {
    writer
      ..writeString(obj.id)
      ..writeString(obj.title)
      ..writeString(obj.description)
      ..writeBool(obj.isUnlocked)
      ..writeBool(obj.unlockedAt != null);
    if (obj.unlockedAt != null) {
      writer.writeString(obj.unlockedAt!.toIso8601String());
    }
  }
}

class DailyRecordAdapter extends TypeAdapter<DailyRecord> {
  @override
  final int typeId = 3;

  @override
  DailyRecord read(BinaryReader reader) {
    return DailyRecord(
      dateKey: reader.readString(),
      completedCount: reader.readInt(),
    );
  }

  @override
  void write(BinaryWriter writer, DailyRecord obj) {
    writer
      ..writeString(obj.dateKey)
      ..writeInt(obj.completedCount);
  }
}
