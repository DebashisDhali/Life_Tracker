// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'models.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SubTaskAdapter extends TypeAdapter<SubTask> {
  @override
  final int typeId = 1;

  @override
  SubTask read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SubTask(
      title: fields[0] as String,
      type: fields[1] as SubTaskType,
      targetValue: fields[2] as int,
      currentValue: fields[3] as int,
      dailyValues: (fields[4] as Map?)?.cast<String, int>(),
    );
  }

  @override
  void write(BinaryWriter writer, SubTask obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.title)
      ..writeByte(1)
      ..write(obj.type)
      ..writeByte(2)
      ..write(obj.targetValue)
      ..writeByte(3)
      ..write(obj.currentValue)
      ..writeByte(4)
      ..write(obj.dailyValues);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SubTaskAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class HabitAdapter extends TypeAdapter<Habit> {
  @override
  final int typeId = 2;

  @override
  Habit read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Habit(
      title: fields[0] as String,
      subTasks: (fields[1] as List).cast<SubTask>(),
      completionDates: (fields[2] as List?)?.cast<DateTime>(),
      isExpanded: fields[3] as bool,
      reminderHour: fields[4] as int?,
      reminderMinute: fields[5] as int?,
      reminderTimes: (fields[7] as List?)
          ?.map((dynamic e) => (e as Map).cast<String, int>())
          ?.toList(),
      order: fields[8] as int?,
    );
  }

  @override
  void write(BinaryWriter writer, Habit obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.title)
      ..writeByte(1)
      ..write(obj.subTasks)
      ..writeByte(2)
      ..write(obj.completionDates)
      ..writeByte(3)
      ..write(obj.isExpanded)
      ..writeByte(4)
      ..write(obj.reminderHour)
      ..writeByte(5)
      ..write(obj.reminderMinute)
      ..writeByte(7)
      ..write(obj.reminderTimes)
      ..writeByte(8)
      ..write(obj.order);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HabitAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class MoneyEntryAdapter extends TypeAdapter<MoneyEntry> {
  @override
  final int typeId = 5;

  @override
  MoneyEntry read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MoneyEntry(
      id: fields[0] as String,
      title: fields[1] as String,
      amount: fields[2] as double,
      date: fields[3] as DateTime,
      dueDate: fields[4] as DateTime?,
      type: fields[5] as MoneyEntryType,
      status: fields[6] as MoneyEntryStatus,
      category: fields[7] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, MoneyEntry obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.amount)
      ..writeByte(3)
      ..write(obj.date)
      ..writeByte(4)
      ..write(obj.dueDate)
      ..writeByte(5)
      ..write(obj.type)
      ..writeByte(6)
      ..write(obj.status)
      ..writeByte(7)
      ..write(obj.category);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MoneyEntryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class MoneySettingsAdapter extends TypeAdapter<MoneySettings> {
  @override
  final int typeId = 9;

  @override
  MoneySettings read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MoneySettings(
      monthlyBudget: fields[0] as double,
      entertainmentAllocation: fields[1] as double,
      emergencyAllocation: fields[2] as double,
      dailyTarget: fields[3] as double,
      totalInvestment: fields[4] as double,
    );
  }

  @override
  void write(BinaryWriter writer, MoneySettings obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.monthlyBudget)
      ..writeByte(1)
      ..write(obj.entertainmentAllocation)
      ..writeByte(2)
      ..write(obj.emergencyAllocation)
      ..writeByte(3)
      ..write(obj.dailyTarget)
      ..writeByte(4)
      ..write(obj.totalInvestment);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MoneySettingsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class LifeSectionAdapter extends TypeAdapter<LifeSection> {
  @override
  final int typeId = 7;

  @override
  LifeSection read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return LifeSection(
      id: fields[0] as String,
      type: fields[1] as SectionType,
      habits: (fields[2] as List).cast<Habit>(),
      moneyEntries: (fields[3] as List?)?.cast<MoneyEntry>(),
      title: fields[4] as String?,
      order: fields[5] as int?,
    );
  }

  @override
  void write(BinaryWriter writer, LifeSection obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.type)
      ..writeByte(2)
      ..write(obj.habits)
      ..writeByte(3)
      ..write(obj.moneyEntries)
      ..writeByte(4)
      ..write(obj.title)
      ..writeByte(5)
      ..write(obj.order);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LifeSectionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class SubTaskTypeAdapter extends TypeAdapter<SubTaskType> {
  @override
  final int typeId = 0;

  @override
  SubTaskType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return SubTaskType.checkbox;
      case 1:
        return SubTaskType.input;
      case 2:
        return SubTaskType.timer;
      default:
        return SubTaskType.checkbox;
    }
  }

  @override
  void write(BinaryWriter writer, SubTaskType obj) {
    switch (obj) {
      case SubTaskType.checkbox:
        writer.writeByte(0);
        break;
      case SubTaskType.input:
        writer.writeByte(1);
        break;
      case SubTaskType.timer:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SubTaskTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class MoneyEntryTypeAdapter extends TypeAdapter<MoneyEntryType> {
  @override
  final int typeId = 3;

  @override
  MoneyEntryType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return MoneyEntryType.income;
      case 1:
        return MoneyEntryType.expense;
      default:
        return MoneyEntryType.income;
    }
  }

  @override
  void write(BinaryWriter writer, MoneyEntryType obj) {
    switch (obj) {
      case MoneyEntryType.income:
        writer.writeByte(0);
        break;
      case MoneyEntryType.expense:
        writer.writeByte(1);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MoneyEntryTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class MoneyEntryStatusAdapter extends TypeAdapter<MoneyEntryStatus> {
  @override
  final int typeId = 4;

  @override
  MoneyEntryStatus read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return MoneyEntryStatus.pending;
      case 1:
        return MoneyEntryStatus.completed;
      default:
        return MoneyEntryStatus.pending;
    }
  }

  @override
  void write(BinaryWriter writer, MoneyEntryStatus obj) {
    switch (obj) {
      case MoneyEntryStatus.pending:
        writer.writeByte(0);
        break;
      case MoneyEntryStatus.completed:
        writer.writeByte(1);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MoneyEntryStatusAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class SectionTypeAdapter extends TypeAdapter<SectionType> {
  @override
  final int typeId = 6;

  @override
  SectionType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return SectionType.body;
      case 1:
        return SectionType.mind;
      case 2:
        return SectionType.money;
      case 3:
        return SectionType.skill;
      case 4:
        return SectionType.relationship;
      case 5:
        return SectionType.dharma;
      case 6:
        return SectionType.bcs;
      case 7:
        return SectionType.custom;
      default:
        return SectionType.body;
    }
  }

  @override
  void write(BinaryWriter writer, SectionType obj) {
    switch (obj) {
      case SectionType.body:
        writer.writeByte(0);
        break;
      case SectionType.mind:
        writer.writeByte(1);
        break;
      case SectionType.money:
        writer.writeByte(2);
        break;
      case SectionType.skill:
        writer.writeByte(3);
        break;
      case SectionType.relationship:
        writer.writeByte(4);
        break;
      case SectionType.dharma:
        writer.writeByte(5);
        break;
      case SectionType.bcs:
        writer.writeByte(6);
        break;
      case SectionType.custom:
        writer.writeByte(7);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SectionTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
