import 'package:hive/hive.dart';

part 'models.g.dart';

@HiveType(typeId: 0)
enum SubTaskType {
  @HiveField(0)
  checkbox,
  @HiveField(1)
  input,
  @HiveField(2)
  timer,
}

@HiveType(typeId: 1)
class SubTask extends HiveObject {
  @HiveField(0)
  String title;

  @HiveField(1)
  SubTaskType type;

  @HiveField(2)
  int targetValue; // 1 for checkbox, >1 for input

  @HiveField(3)
  int currentValue; // This will now act as a fallback or "last used" value

  @HiveField(4)
  Map<String, int>? dailyValues; // yyyy-MM-dd -> value

  SubTask({
    required this.title,
    required this.type,
    this.targetValue = 1,
    this.currentValue = 0,
    this.dailyValues,
  }) {
    dailyValues ??= {};
  }



  int getForDate(DateTime date) {
    final key = "${date.year}-${date.month}-${date.day}";
    return dailyValues?[key] ?? 0;
  }

  void setForDate(DateTime date, int value) {
    final key = "${date.year}-${date.month}-${date.day}";
    dailyValues ??= {};
    dailyValues![key] = value;
    currentValue = value; // Update legacy field too
  }

  int get todayValue => getForDate(DateTime.now());

  bool isCompletedOn(DateTime date) => getForDate(date) >= targetValue;

  double progressOn(DateTime date) {
    if (targetValue <= 0) return 0.0;
    return (getForDate(date) / targetValue).clamp(0.0, 1.0);
  }

  bool get isCompleted => isCompletedOn(DateTime.now());
}



@HiveType(typeId: 2)
class Habit extends HiveObject {
  @HiveField(0)
  String title;

  @HiveField(1)
  List<SubTask> subTasks;

  @HiveField(2)
  List<DateTime> completionDates;

  // For UI state, not necessarily persisted but helpful if app restarts
  @HiveField(3)
  bool isExpanded;

  @HiveField(4)
  int? reminderHour;

  @HiveField(5)
  int? reminderMinute;

  @HiveField(7)
  List<Map<String, int>>? reminderTimes;

  @HiveField(8)
  int? order;

  Habit({
    required this.title,
    required this.subTasks,
    List<DateTime>? completionDates,
    this.isExpanded = false,
    this.reminderHour,
    this.reminderMinute,
    this.reminderTimes,
    this.order,
  }) : completionDates = completionDates ?? [] {
    reminderTimes ??= [];
  }

  bool isCompletedOn(DateTime date) {
    if (completionDates.isEmpty) return false;
    final year = date.year;
    final month = date.month;
    final day = date.day;
    for (var i = 0; i < completionDates.length; i++) {
      final d = completionDates[i];
      if (d.year == year && d.month == month && d.day == day) return true;
    }
    return false;
  }

  bool isCompletedToday() {
    return isCompletedOn(DateTime.now());
  }
  
  double progressOn(DateTime date) {
    if (subTasks.isEmpty) return 0.0;
    double totalProgress = 0;
    for (var s in subTasks) {
      totalProgress += s.progressOn(date);
    }
    return totalProgress / subTasks.length;
  }

  double get progress => progressOn(DateTime.now());
}

@HiveType(typeId: 3)
enum MoneyEntryType {
  @HiveField(0)
  income, // Was receivable
  @HiveField(1)
  expense, // Was payable
}

@HiveType(typeId: 4)
enum MoneyEntryStatus {
  @HiveField(0)
  pending,
  @HiveField(1)
  completed, // Was paid
}

@HiveType(typeId: 5)
class MoneyEntry extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String title; // Was personName

  @HiveField(2)
  double amount;

  @HiveField(3)
  DateTime date;

  @HiveField(4)
  DateTime? dueDate;

  @HiveField(5)
  MoneyEntryType type;

  @HiveField(6)
  MoneyEntryStatus status;

  @HiveField(7)
  String? category; // 'General', 'Entertainment', 'Emergency'

  MoneyEntry({
    required this.id,
    required this.title,
    required this.amount,
    required this.date,
    this.dueDate,
    required this.type,
    this.status = MoneyEntryStatus.pending,
    this.category = 'General',
  });
}

@HiveType(typeId: 9)
class MoneySettings extends HiveObject {
  @HiveField(0)
  double monthlyBudget;

  @HiveField(1)
  double entertainmentAllocation;

  @HiveField(2)
  double emergencyAllocation;

  @HiveField(3)
  double dailyTarget;

  @HiveField(4)
  double totalInvestment;

  MoneySettings({
    this.monthlyBudget = 0,
    this.entertainmentAllocation = 0,
    this.emergencyAllocation = 0,
    this.dailyTarget = 0,
    this.totalInvestment = 0,
  });
}

@HiveType(typeId: 6)
enum SectionType {
  @HiveField(0)
  body,
  @HiveField(1)
  mind,
  @HiveField(2)
  money,
  @HiveField(3)
  skill,
  @HiveField(4)
  relationship,
  @HiveField(5)
  dharma,
  @HiveField(6)
  bcs,
  @HiveField(7)
  custom,
}

@HiveType(typeId: 7)
class LifeSection extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  SectionType type;

  @HiveField(2)
  List<Habit> habits;
  
  @HiveField(3)
  List<MoneyEntry> moneyEntries;

  @HiveField(4)
  String? title;

  @HiveField(5)
  int? order;

  LifeSection({
    required this.id,
    required this.type,
    required this.habits,
    List<MoneyEntry>? moneyEntries,
    this.title,
    this.order,
    this.isExpanded = false,
  }) : moneyEntries = moneyEntries ?? [];

  // UI State - Not persisted
  bool isExpanded;

  String get displayName {
    if (type == SectionType.custom && title != null) return title!;
    switch (type) {
      case SectionType.body: return title ?? 'Body';
      case SectionType.mind: return title ?? 'Mind';
      case SectionType.money: return title ?? 'Money';
      case SectionType.skill: return title ?? 'Skill';
      case SectionType.relationship: return title ?? 'Relationship';
      case SectionType.dharma: return title ?? 'Dharma';
      case SectionType.bcs: return title ?? 'BCS';
      case SectionType.custom: return title ?? 'Custom';
    }
  }
}
