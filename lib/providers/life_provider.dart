import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../models/models.dart';
import '../services/notification_service.dart';
import '../services/sync_service.dart';
import '../utils/constants.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'money_provider.dart';

class LifeProvider with ChangeNotifier {
  Box<LifeSection>? _sectionBox;
  List<LifeSection> _sections = [];
  DateTime _viewingDate = DateTime.now();
  MoneyProvider? _moneyProvider;
  Box? _settingsBox;
  bool _hasJustCrossedGrowthThreshold = false;
  final SyncService _syncService = SyncService();
  List<Map<String, dynamic>> _bundledGoals = [];
  List<Map<String, dynamic>> get bundledGoals => _bundledGoals;

  TimeOfDay _wakeUpTime = const TimeOfDay(hour: 6, minute: 0);
  TimeOfDay _sleepTime = const TimeOfDay(hour: 22, minute: 0);

  // Cache for habit lookup: "sectionId|habitTitle" -> Habit
  final Map<String, Habit> _habitLookupCache = {};
  
  // Memoization caches
  double? _memoTodayProgress;
  final Map<String, int> _memoSectionStreaks = {};
  List<String>? _memoBadges;
  final Map<String, double> _memoDayProgress = {}; // "yyyy-MM-dd" -> progress

  TimeOfDay get wakeUpTime => _wakeUpTime;
  TimeOfDay get sleepTime => _sleepTime;

  // Convenience getters for UI
  int get wakeHour => _wakeUpTime.hour;
  int get wakeMinute => _wakeUpTime.minute;
  int get sleepHour => _sleepTime.hour;
  int get sleepMinute => _sleepTime.minute;

  bool get hasJustCrossedGrowthThreshold => _hasJustCrossedGrowthThreshold;

  List<LifeSection> get sections => _sections;
  DateTime get viewingDate => _viewingDate;
  
  bool get isViewingToday {
    final now = DateTime.now();
    return _viewingDate.year == now.year && 
           _viewingDate.month == now.month && 
           _viewingDate.day == now.day;
  }
  


  // Alias for backward compatibility with some widgets
  bool get isToday => isViewingToday;

  void setViewingDate(DateTime date) {
    _viewingDate = date;
    _clearMemoContext();
    notifyListeners();
  }

  bool get isLoading => _sectionBox == null || _settingsBox == null;

  String _milestoneMessage = "";
  String get milestoneMessage => _milestoneMessage;

  double _toDouble(dynamic val) {
    if (val is int) return val.toDouble();
    if (val is double) return val;
    return 0.0;
  }

  double get personalBest {
    if (_settingsBox == null) return 0.0;
    double storedPB = _toDouble(_settingsBox!.get('personalBestProgress'));
    double todayProgress = todayCompletionPercentage;
    // Return the absolute highest between recorded PB and Today's progress
    return todayProgress > storedPB ? todayProgress : storedPB;
  }

  void updateMoneyProvider(MoneyProvider mp) {
    // Check for growth milestone (Silent update on start/sync)
    _checkGrowthMilestone(fromUserAction: false);
    notifyListeners();
  }

  double get todayCompletionPercentage {
    if (_memoTodayProgress != null) return _memoTodayProgress!;
    _memoTodayProgress = _getSubTaskProgressOn(_viewingDate);
    return _memoTodayProgress!;
  }

  double getSectionProgress(LifeSection section) {
    return _getSectionProgressOn(section, _viewingDate);
  }

  double _getSectionProgressOn(LifeSection section, DateTime date) {
    // If section has no habits, return 0.0 immediately
    if (section.habits.isEmpty) return 0.0;
    
    int totalSubTasks = 0;
    double totalProgress = 0;
    final day = DateTime(date.year, date.month, date.day);
    
    for (var habit in section.habits) {
      // Skip habits with no subtasks
      if (habit.subTasks.isEmpty) continue;
      
      // Fallback for historical data
      bool habitWasFullyCompleted = habit.completionDates.any((d) => 
        d.year == day.year && d.month == day.month && d.day == day.day
      );

      for (var subTask in habit.subTasks) {
        totalSubTasks++;
        if (habitWasFullyCompleted) {
          totalProgress += 1.0;
        } else {
          totalProgress += subTask.progressOn(day);
        }
      }
    }
    
    // If no subtasks exist at all, return 0.0
    if (totalSubTasks == 0) return 0.0;
    
    double progress = totalProgress / totalSubTasks;
    if (section.type == SectionType.money && _moneyProvider != null) {
      // Only include Adherence in the "Growth" score if the user has actively tracked something (progress > 0).
      if (progress > 0) {
         double adherence = _moneyProvider!.getExpenseAdherence(day);
         return ((progress * 0.5) + (adherence * 0.5)).clamp(0.0, 1.0);
      } else {
         return 0.0;
      }
    }
    return progress;
  }

  Future<void> init() async {
    // If not logged in, we don't load or create any data. App remains empty.
    if (!isLoggedIn) {
      _sections = [];
      notifyListeners();
      return;
    }

    _sectionBox = await Hive.openBox<LifeSection>(AppConstants.sectionBoxName);
    
    // Clear in-memory list before loading from box to ensure fresh state
    _sections.clear();

    if (_sectionBox!.isEmpty) {
      // Only create default data if we are SURE there's no data in box
      debugPrint('📋 [LifeProvider] Box is empty, creating default data...');
      await _createDefaultData();
    } else {
      debugPrint('📋 [LifeProvider] Loading ${_sectionBox!.length} sections from box...');
      _sections = _sectionBox!.values.toList();
      _sortSections();

      // Migration: Ensure all existing sections have a title and order
      bool changed = false;
      for (int i = 0; i < _sections.length; i++) {
        var s = _sections[i];
        if (s.title == null) {
          s.title = s.displayName;
          changed = true;
        }
        if (s.order == null) {
          s.order = i;
          changed = true;
        }
        if (changed) s.save();
        changed = false;
      }
    }
    
    // Open settings box
    _settingsBox = await Hive.openBox(AppConstants.settingsBoxName);
    
    // Load Wake/Sleep times
    final wakeH = _settingsBox?.get('wake_hour', defaultValue: 6);
    final wakeM = _settingsBox?.get('wake_minute', defaultValue: 0);
    final sleepH = _settingsBox?.get('sleep_hour', defaultValue: 22);
    final sleepM = _settingsBox?.get('sleep_minute', defaultValue: 0);
    _wakeUpTime = TimeOfDay(hour: wakeH, minute: wakeM);
    _sleepTime = TimeOfDay(hour: sleepH, minute: sleepM);

    _syncPersonalBest();
    
    // Load Bundled Goals
    final storedGoals = _settingsBox?.get('bundledGoals');
    if (storedGoals != null) {
      _bundledGoals = (storedGoals as List).map((i) => Map<String, dynamic>.from(i)).toList();
    }

    // Notify listeners early so the UI can stop showing the "Initializing" screen
    notifyListeners();

    // Setup all reminders and system alerts with active-hour filtering
    await _setupDefaultReminders();
    await rescheduleAllNotifications();
    
    _rebuildHabitCache();
    _clearMemoContext();
    notifyListeners();
  }

  /// Loads data from already-open Hive boxes WITHOUT creating default data.
  /// Used after restore to safely reload data into memory.
  Future<void> _reloadFromOpenBoxes() async {
    _sections.clear();
    if (_sectionBox != null && _sectionBox!.isOpen) {
      debugPrint('🔁 [LifeProvider] Reloading from open box. Count: ${_sectionBox!.length}');
      _sections = _sectionBox!.values.toList();
      _sortSections();
      _rebuildHabitCache();
    }
    _clearMemoContext();
    _settingsBox = await Hive.openBox(AppConstants.settingsBoxName);
    final wakeH = _settingsBox?.get('wake_hour', defaultValue: 6);
    final wakeM = _settingsBox?.get('wake_minute', defaultValue: 0);
    final sleepH = _settingsBox?.get('sleep_hour', defaultValue: 22);
    final sleepM = _settingsBox?.get('sleep_minute', defaultValue: 0);
    _wakeUpTime = TimeOfDay(hour: wakeH, minute: wakeM);
    _sleepTime = TimeOfDay(hour: sleepH, minute: sleepM);
    _syncPersonalBest();
    _rebuildHabitCache();
    _clearMemoContext();
    notifyListeners();
  }

  void _rebuildHabitCache() {
    _habitLookupCache.clear();
    for (var section in _sections) {
      for (var habit in section.habits) {
        _habitLookupCache["${section.id}|${habit.title}"] = habit;
      }
    }
  }

  void _clearMemoContext() {
    _memoTodayProgress = null;
    _memoSectionStreaks.clear();
    _memoBadges = null;
    _memoDayProgress.clear();
  }

  void _onDataChanged() {
    _clearMemoContext();
    notifyListeners();
  }

  Future<void> _setupSystemReminders() async {
    final ns = NotificationService();
    
    // Morning Intentions (Wake time + 30 mins)
    int morningHour = (_wakeUpTime.hour + (_wakeUpTime.minute + 30 >= 60 ? 1 : 0)) % 24;
    int morningMin = (_wakeUpTime.minute + 30) % 60;

    await ns.scheduleSystemReminder(
      id: 1001,
      title: "Rise & Shine! ☀️",
      body: "Good morning! Open your Life Tracker and plan your day for success.",
      hour: morningHour,
      minute: morningMin,
    );

    // Evening Streak Protection (Sleep time - 1.5 hours)
    int eveningTotalMins = (_sleepTime.hour * 60 + _sleepTime.minute) - 90;
    if (eveningTotalMins < 0) eveningTotalMins += 24 * 60;
    
    int eveningHour = (eveningTotalMins ~/ 60) % 24;
    int eveningMin = eveningTotalMins % 60;

    await ns.scheduleSystemReminder(
      id: 1002,
      title: "Streak at Risk? 🔥",
      body: "Don't let your progress slip! Check your habits and finish today strong.",
      hour: eveningHour,
      minute: eveningMin,
    );
  }

  Future<void> _setupDefaultReminders() async {
    final notificationService = NotificationService();


    for (var section in _sections) {
      for (var habit in section.habits) {
        // Skip if user already has some reminders (don't override)
        if ((habit.reminderHour != null) || (habit.reminderTimes != null && habit.reminderTimes!.isNotEmpty)) {
           continue; 
        }

        final title = habit.title.toLowerCase();
        
        // 1. Workout / Active Reminders (Wake time + 1 hour)
        if (title.contains("workout") || title.contains("active")) {
          habit.reminderHour = (_wakeUpTime.hour + 1) % 24;
          habit.reminderMinute = _wakeUpTime.minute;
        }
        // 2. Learning / Study Reminders (Afternoon - 6 hours after wake)
        else if (title.contains("learning") || title.contains("study") || title.contains("skill")) {
          int learnMins = (_wakeUpTime.hour * 60 + _wakeUpTime.minute) + (6 * 60);
          habit.reminderHour = (learnMins ~/ 60) % 24;
          habit.reminderMinute = learnMins % 60;
        }
        // 3. Money / Expenses (1 hour before sleep)
        else if (title.contains("expense")) {
          int moneyMins = (_sleepTime.hour * 60 + _sleepTime.minute) - 60;
          if (moneyMins < 0) moneyMins += 24 * 60;
          habit.reminderHour = (moneyMins ~/ 60) % 24;
          habit.reminderMinute = moneyMins % 60;
        }
        // 4. Mindfulness / Planning (30 mins before sleep)
        else if (title.contains("plan") || title.contains("mindfulness") || title.contains("clarity")) {
          int mindMins = (_sleepTime.hour * 60 + _sleepTime.minute) - 30;
          if (mindMins < 0) mindMins += 24 * 60;
          habit.reminderHour = (mindMins ~/ 60) % 24;
          habit.reminderMinute = mindMins % 60;
        }

        if (habit.reminderHour != null) {
          section.save();
          try {
            await notificationService.scheduleHabitReminder(
              habit,
              wakeMinutes: _wakeUpTime.hour * 60 + _wakeUpTime.minute,
              sleepMinutes: _sleepTime.hour * 60 + _sleepTime.minute,
            );
          } catch (e) {
            debugPrint('Error in _setupDefaultReminders: $e');
          }
        }
      }
    }
  }

  void _syncPersonalBest() {
    if (_settingsBox == null) return;
    
    // Reset verify
    double highestInHistory = 0.0;
    final now = DateTime.now();
    
    // Scan last 365 days to ensure we have the absolute truth based on current logic
    for (int i = 0; i <= 365; i++) {
        final date = now.subtract(Duration(days: i));
        
        double dayProgress = _getSubTaskProgressOn(date);
        
        if (dayProgress > highestInHistory) {
            highestInHistory = dayProgress;
        }
    }

    _settingsBox!.put('personalBestProgress', highestInHistory);
  }

  void acknowledgeGrowthMilestone() {
    _hasJustCrossedGrowthThreshold = false;
    _milestoneMessage = "";
    notifyListeners();
  }

  double getYesterdayProgress() {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return _getSubTaskProgressOn(yesterday);
  }

  void _checkGrowthMilestone({bool fromUserAction = false}) {
    // Only check if it's today
    if (!isViewingToday || _settingsBox == null) return;

    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final lastAchievedDate = _settingsBox!.get('lastGrowthMilestoneDate');
    
    // Safety check for lastCelebratedProgress
    final rawCelebrated = _settingsBox!.get('lastCelebratedProgress');
    final lastCelebratedProgress = rawCelebrated == null ? -1.0 : _toDouble(rawCelebrated);

    double todayProgress = todayCompletionPercentage;
    double yesterdayProgress = getYesterdayProgress();

    // Check for "Higher than Yesterday"
    // AND must be higher than what we last celebrated (to avoid double trigger if task is toggled)
    if (todayProgress > yesterdayProgress && 
        todayProgress > (lastCelebratedProgress + 0.001) && 
        todayProgress > 0.01) {
        
      bool firstTimeToday = lastAchievedDate != todayStr;
      
      // If we already celebrated today, only celebrate again if significant jump (e.g. +10%)
      bool significantJump = (todayProgress - lastCelebratedProgress) >= 0.10;

      if (firstTimeToday || significantJump) {
        // ONLY trigger UI celebration if this was a direct user action (toggling a task)
        // This prevents the "Sudden Congratulation" on login or app start.
        if (fromUserAction) {
          _hasJustCrossedGrowthThreshold = true;
          _milestoneMessage = todayProgress >= 1.0 
              ? "PERFECT DAY! 🏆\nYou've achieved 100% Growth!"
              : "Growth Alert! 🚀\nYou've surpassed yesterday's progress!";
        }
        
        // Persist the milestone even if silent, so we don't trigger on next startup
        _settingsBox!.put('lastGrowthMilestoneDate', todayStr);
        _settingsBox!.put('lastMilestoneType', 'Growth');
        _settingsBox!.put('lastCelebratedProgress', todayProgress);
        
        if (fromUserAction) notifyListeners();
      }
    }
  }

  Future<void> _createDefaultData() async {
    final defaultSections = [
      // 🏃 BODY - Physical Health
      LifeSection(
        id: 'body',
        type: SectionType.body,
        habits: [
          Habit(
            title: 'Morning Workout',
            subTasks: [
              SubTask(title: 'Push-ups', type: SubTaskType.input, targetValue: 30, dailyValues: {}),
              SubTask(title: 'Squats', type: SubTaskType.input, targetValue: 40, dailyValues: {}),
              SubTask(title: 'Plank (seconds)', type: SubTaskType.input, targetValue: 180, dailyValues: {}),
            ],
          ),
          Habit(
            title: 'Healthy Habits',
            subTasks: [
              SubTask(title: 'Fruits/Veggies', type: SubTaskType.input, targetValue: 5, dailyValues: {}),
              SubTask(title: 'Sleep 7+ hours', type: SubTaskType.checkbox, dailyValues: {}),
            ],
          ),
          Habit(
            title: 'Active Lifestyle',
            subTasks: [
              SubTask(title: 'Walk/Run (minutes)', type: SubTaskType.input, targetValue: 30, dailyValues: {}),
              SubTask(title: 'Stretch', type: SubTaskType.checkbox, dailyValues: {}),
            ],
          ),
        ],
      ),
      
      // 🧠 MIND - Mental Growth
      LifeSection(
        id: 'mind',
        type: SectionType.mind,
        habits: [
          Habit(
            title: 'Daily Learning',
            subTasks: [
              SubTask(title: 'Read (pages)', type: SubTaskType.input, targetValue: 20, dailyValues: {}),
              SubTask(title: 'Learn new concept', type: SubTaskType.checkbox, dailyValues: {}),
              SubTask(title: 'Watch educational video', type: SubTaskType.checkbox, dailyValues: {}),
            ],
          ),
          Habit(
            title: 'Mindfulness',
            subTasks: [
              SubTask(title: 'Meditation (minutes)', type: SubTaskType.input, targetValue: 10, dailyValues: {}),
              SubTask(title: 'Deep breathing', type: SubTaskType.checkbox, dailyValues: {}),
              SubTask(title: 'Journaling', type: SubTaskType.checkbox, dailyValues: {}),
            ],
          ),
          Habit(
            title: 'Mental Clarity',
            subTasks: [
              SubTask(title: 'Plan tomorrow', type: SubTaskType.checkbox, dailyValues: {}),
              SubTask(title: 'Review goals', type: SubTaskType.checkbox, dailyValues: {}),
            ],
          ),
        ],
      ),
      
      // 💰 MONEY - Financial Health
      LifeSection(
        id: 'money',
        type: SectionType.money,
        habits: [
          Habit(
            title: 'Expense Tracking',
            subTasks: [
              SubTask(title: 'Log morning spends', type: SubTaskType.checkbox, dailyValues: {}),
              SubTask(title: 'Log evening spends', type: SubTaskType.checkbox, dailyValues: {}),
              SubTask(title: 'Verify daily balance', type: SubTaskType.checkbox, dailyValues: {}),
            ],
          ),
          Habit(
            title: 'Financial Goals',
            subTasks: [
              SubTask(title: 'Add to savings', type: SubTaskType.checkbox, dailyValues: {}),
            ],
          ),
        ],
      ),
      
      // 🎯 SKILL - Professional Growth
      LifeSection(
        id: 'skill',
        type: SectionType.skill,
        habits: [
          Habit(
            title: 'Skill Practice',
            subTasks: [
              SubTask(title: 'Code/Work (minutes)', type: SubTaskType.input, targetValue: 120, dailyValues: {}),
              SubTask(title: 'Side project progress', type: SubTaskType.checkbox, dailyValues: {}),
              SubTask(title: 'Learn new tool/tech', type: SubTaskType.checkbox, dailyValues: {}),
            ],
          ),
          Habit(
            title: 'Professional Development',
            subTasks: [
              SubTask(title: 'Online course (minutes)', type: SubTaskType.input, targetValue: 30, dailyValues: {}),
              SubTask(title: 'Practice exercises', type: SubTaskType.input, targetValue: 3, dailyValues: {}),
            ],
          ),
          Habit(
            title: 'Creative Work',
            subTasks: [
              SubTask(title: 'Create something', type: SubTaskType.checkbox, dailyValues: {}),
              SubTask(title: 'Share knowledge', type: SubTaskType.checkbox, dailyValues: {}),
            ],
          ),
        ],
      ),
      
      // 👥 RELATIONSHIP - Social Connections
      LifeSection(
        id: 'relationship',
        type: SectionType.relationship,
        habits: [
          Habit(
            title: 'Family Time',
            subTasks: [
              SubTask(title: 'Call parents/family', type: SubTaskType.checkbox, dailyValues: {}),
              SubTask(title: 'Quality time together', type: SubTaskType.checkbox, dailyValues: {}),
              SubTask(title: 'Help family member', type: SubTaskType.checkbox, dailyValues: {}),
            ],
          ),
          Habit(
            title: 'Social Connection',
            subTasks: [
              SubTask(title: 'Message friends', type: SubTaskType.input, targetValue: 3, dailyValues: {}),
              SubTask(title: 'Meaningful conversation', type: SubTaskType.checkbox, dailyValues: {}),
            ],
          ),
          Habit(
            title: 'Relationship Care',
            subTasks: [
              SubTask(title: 'Express gratitude', type: SubTaskType.checkbox, dailyValues: {}),
              SubTask(title: 'Active listening', type: SubTaskType.checkbox, dailyValues: {}),
            ],
          ),
        ],
      ),
      
      // 🙏 DHARMA - Purpose & Spirituality
      LifeSection(
        id: 'dharma',
        type: SectionType.dharma,
        habits: [
          Habit(
            title: 'Spiritual Practice',
            subTasks: [
              SubTask(title: 'Prayer/Worship', type: SubTaskType.checkbox, dailyValues: {}),
              SubTask(title: 'Read spiritual text', type: SubTaskType.checkbox, dailyValues: {}),
              SubTask(title: 'Reflect on purpose', type: SubTaskType.checkbox, dailyValues: {}),
            ],
          ),
          Habit(
            title: 'Gratitude & Service',
            subTasks: [
              SubTask(title: 'Gratitude journal', type: SubTaskType.checkbox, dailyValues: {}),
              SubTask(title: 'Help someone', type: SubTaskType.checkbox, dailyValues: {}),
              SubTask(title: 'Act of kindness', type: SubTaskType.checkbox, dailyValues: {}),
            ],
          ),
          Habit(
            title: 'Inner Growth',
            subTasks: [
              SubTask(title: 'Self-reflection', type: SubTaskType.checkbox, dailyValues: {}),
              SubTask(title: 'Practice patience', type: SubTaskType.checkbox, dailyValues: {}),
            ],
          ),
        ],
      ),
      
      // 📚 BCS - Exam Preparation
      LifeSection(
        id: 'bcs',
        type: SectionType.bcs,
        habits: [
          Habit(
            title: 'Subject Wise Study',
            subTasks: [
              SubTask(title: 'Bangla Literature', type: SubTaskType.checkbox, dailyValues: {}),
              SubTask(title: 'English Grammar', type: SubTaskType.checkbox, dailyValues: {}),
              SubTask(title: 'General Science', type: SubTaskType.checkbox, dailyValues: {}),
              SubTask(title: 'Bangladesh Affairs', type: SubTaskType.checkbox, dailyValues: {}),
            ],
          ),
          Habit(
            title: 'Daily Practice',
            subTasks: [
              SubTask(title: 'Solve Math Problems', type: SubTaskType.input, targetValue: 20, dailyValues: {}),
              SubTask(title: 'Vocabulary (words)', type: SubTaskType.input, targetValue: 15, dailyValues: {}),
              SubTask(title: 'Current Affairs Reading', type: SubTaskType.checkbox, dailyValues: {}),
            ],
          ),
          Habit(
            title: 'Exam Strategy',
            subTasks: [
              SubTask(title: 'Previous Year Question', type: SubTaskType.checkbox, dailyValues: {}),
              SubTask(title: 'Model Test', type: SubTaskType.checkbox, dailyValues: {}),
            ],
          ),
        ],
      ),
    ];

    _sections = defaultSections;
    notifyListeners(); // Show empty/default sections immediately

    int order = 0;
    for (var section in _sections) {
      section.title = section.displayName;
      section.order = order++;
      await _sectionBox!.add(section);
    }
  }

  void _sortSections() {
    _sections.sort((a, b) {
      int orderA = a.order ?? a.type.index;
      int orderB = b.order ?? b.type.index;
      return orderA.compareTo(orderB);
    });
  }

  Future<void> addSection(String title) async {
    final newSection = LifeSection(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: SectionType.custom,
      habits: [],
      title: title,
      order: _sections.length,
    );
    await _sectionBox!.add(newSection);
    _sections.add(newSection);
    _sortSections();
    _rebuildHabitCache();
    _onDataChanged();
    _triggerAutoBackup();
  }

  Future<void> updateSection(LifeSection section, String newTitle) async {
    section.title = newTitle;
    await section.save();
    _onDataChanged();
    _triggerAutoBackup();
  }

  Future<void> deleteSection(LifeSection section) async {
    await section.delete();
    _sections.remove(section);
    // Maintain order for remaining sections
    for (int i = 0; i < _sections.length; i++) {
      _sections[i].order = i;
      await _sections[i].save();
    }
    _rebuildHabitCache();
    _onDataChanged();
    _triggerAutoBackup();
  }

  Future<void> reorderSections(int oldIndex, int newIndex) async {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final section = _sections.removeAt(oldIndex);
    _sections.insert(newIndex, section);
    
    // Update order field in Hive
    for (int i = 0; i < _sections.length; i++) {
      _sections[i].order = i;
      await _sections[i].save();
    }
    _onDataChanged();
    _triggerAutoBackup();
  }

  void toggleSectionExpansion(LifeSection section, bool isExpanded) {
    if (isExpanded) {
      // Close all others
      for (var s in _sections) {
        if (s != section) {
          s.isExpanded = false;
        }
      }
    }
    section.isExpanded = isExpanded;
    section.isExpanded = isExpanded;
    notifyListeners();
  }

  void collapseAllSections() {
    for (var s in _sections) {
      s.isExpanded = false;
    }
    notifyListeners();
  }

  void toggleHabitExpansion(LifeSection section, Habit habit) {
    habit.isExpanded = !habit.isExpanded;
    section.save(); // Save the section, as habit is embedded
    notifyListeners();
    _triggerAutoBackup();
  }
  void updateSubTask(LifeSection section, Habit habit, SubTask subTask, int newValue) {
    subTask.setForDate(_viewingDate, newValue);
    section.save(); // Save section
    _checkHabitCompletion(section, habit);
    _checkGrowthMilestone(fromUserAction: true); // Check for growth milestone
    _triggerAutoBackup(); // Auto-backup
  }

  void toggleSubTask(LifeSection section, Habit habit, SubTask subTask) {
    if (subTask.type == SubTaskType.checkbox) {
      final current = subTask.getForDate(_viewingDate);
      subTask.setForDate(_viewingDate, current == 0 ? 1 : 0);
      section.save(); // Save section
      _checkHabitCompletion(section, habit);
      _checkGrowthMilestone(fromUserAction: true); // Check for growth milestone
      _triggerAutoBackup(); // Auto-backup
    }
  }

  void _checkHabitCompletion(LifeSection section, Habit habit) {
      _updateHabitStatus(section, habit);
  }

  void _updateHabitStatus(LifeSection section, Habit habit) {
    final date = _viewingDate;
    final day = DateTime(date.year, date.month, date.day);
    bool allCompleted = habit.subTasks.every((s) => s.isCompletedOn(day));
    
    // Check if habit was already completed on this date
    bool alreadyCompleted = habit.completionDates.any(
      (d) => d.year == day.year && d.month == day.month && d.day == day.day
    );

    if (allCompleted && !alreadyCompleted) {
      habit.completionDates.add(day);
    } else if (!allCompleted && alreadyCompleted) {
      habit.completionDates.removeWhere(
        (d) => d.year == day.year && d.month == day.month && d.day == day.day
      );
    }
    section.save();
    _checkBundledGoalsAchievement();
    _onDataChanged();
    _triggerAutoBackup();
  }

  double _getSubTaskProgressOn(DateTime date) {
    if (_sections.isEmpty) return 0.0;
    
    final dateKey = "${date.year}-${date.month}-${date.day}";
    if (_memoDayProgress.containsKey(dateKey)) return _memoDayProgress[dateKey]!;

    double totalProgress = 0;
    for (var section in _sections) {
      totalProgress += _getSectionProgressOn(section, date);
    }
    final result = totalProgress / _sections.length;
    _memoDayProgress[dateKey] = result;
    return result;
  }

  Map<DateTime, double> getWeeklyProgress() {
    Map<DateTime, double> weekly = {};
    DateTime focusDay = _viewingDate;
    for (int i = 6; i >= 0; i--) {
      DateTime day = DateTime(focusDay.year, focusDay.month, focusDay.day).subtract(Duration(days: i));
      weekly[day] = _getSubTaskProgressOn(day);
    }
    return weekly;
  }

  Map<DateTime, double> getMonthlyProgress() {
    Map<DateTime, double> monthly = {};
    DateTime focusDay = _viewingDate;
    for (int i = 29; i >= 0; i--) { // Last 30 days relative to viewing date
      DateTime day = DateTime(focusDay.year, focusDay.month, focusDay.day).subtract(Duration(days: i));
      monthly[day] = _getSubTaskProgressOn(day);
    }
    return monthly;
  }

  Map<DateTime, double> getYearlyProgress() {
    Map<DateTime, double> yearly = {};
    DateTime focusDay = _viewingDate;
    
    for (int i = 11; i >= 0; i--) {
      // Calculate average for each month leading up to viewing month
      DateTime firstDayOfMonth = DateTime(focusDay.year, focusDay.month - i, 1);
      int daysInMonth = DateTime(firstDayOfMonth.year, firstDayOfMonth.month + 1, 0).day;
      
      double totalMonthProgress = 0;
      int daysToCount = 0;
      
      for (int d = 1; d <= daysInMonth; d++) {
        DateTime day = DateTime(firstDayOfMonth.year, firstDayOfMonth.month, d);
        if (day.isAfter(focusDay)) break; // Don't count days after focus date
        
        totalMonthProgress += _getSubTaskProgressOn(day);
        daysToCount++;
      }
      
      double monthlyAverage = daysToCount > 0 ? totalMonthProgress / daysToCount : 0.0;
      
      // Removed Money Adherence factor to avoid confusion ("ulta palta")
      // Now strictly reflects Habit Consistency.
      yearly[firstDayOfMonth] = monthlyAverage;
    }
    return yearly;
  }

  int get activityStreak {
    return _calculateActivityStreak();
  }

  int _calculateActivityStreak() {
    // Logic: Count consecutive days where progress > 0.
    
    DateTime now = DateTime.now();
    DateTime today = DateTime(now.year, now.month, now.day);
    
    // Check Today's progress
    double todayVal = _getSubTaskProgressOn(today);
    
    DateTime startCheckDate = today;
    
    // "Day Stack 0 kn thake??" -> Fix:
    // If today hasn't started (progress 0), check if yesterday was valid.
    // If yesterday was valid, the streak is alive (just waiting for today).
    // So distinct from "broken streak".
    if (todayVal <= 0) {
      DateTime yesterday = today.subtract(const Duration(days: 1));
      double yesterdayVal = _getSubTaskProgressOn(yesterday);
      if (yesterdayVal > 0) {
        // Continue counting from yesterday
        startCheckDate = yesterday;
      } else {
         // Streak broken or 0
         return 0;
      }
    }
    
    int streak = 0;
    DateTime checkDate = startCheckDate;
    
    while (true) {
      double val = _getSubTaskProgressOn(checkDate);
      if (val > 0) {
        streak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
        
        // Safety check (2 years max)
        if (streak > 730) break;
      } else {
        break;
      }
    }
    
    return streak;
  }


  int calculateSectionStreak(LifeSection section) {
    if (_memoSectionStreaks.containsKey(section.id)) {
      return _memoSectionStreaks[section.id]!;
    }

    if (section.habits.isEmpty) {
      _memoSectionStreaks[section.id] = 0;
      return 0;
    }
    
    Set<String> completedDateStrings = {};
    for (var habit in section.habits) {
        for (var date in habit.completionDates) {
             completedDateStrings.add("${date.year}-${date.month}-${date.day}");
        }
    }

    if (completedDateStrings.isEmpty) {
      _memoSectionStreaks[section.id] = 0;
      return 0;
    }
    
    int streak = 0;
    DateTime checkDate = DateTime(_viewingDate.year, _viewingDate.month, _viewingDate.day);
    
    bool todayCompleted = completedDateStrings.contains("${checkDate.year}-${checkDate.month}-${checkDate.day}");
    DateTime yesterday = checkDate.subtract(const Duration(days: 1));
    bool yesterdayCompleted = completedDateStrings.contains("${yesterday.year}-${yesterday.month}-${yesterday.day}");

    if (!todayCompleted && !yesterdayCompleted) {
        _memoSectionStreaks[section.id] = 0;
        return 0;
    }
    
    DateTime currentStreakDate = todayCompleted ? checkDate : yesterday;
    
    while (true) {
       if (completedDateStrings.contains("${currentStreakDate.year}-${currentStreakDate.month}-${currentStreakDate.day}")) {
         streak++;
         currentStreakDate = currentStreakDate.subtract(const Duration(days: 1));
       } else {
         break;
       }
       // Safety break (approx 10 years)
       if (streak > 3650) break;
    }

    _memoSectionStreaks[section.id] = streak;
    return streak;
  }

  List<String> get earnedBadges {
    // Only calculate for today to avoid confusion? 
    // Or we show historic badges? Let's show current status or earned "milestones"
    
    // For now, we are calculating "What badges do I have RIGHT NOW based on current performance/stats"
    // Ideally, badges should be permanent unlocks. 
    // But based on current simple architecture, they are dynamic status symbols.

    List<String> badges = [];
    double progress = todayCompletionPercentage;
    
    // 1. Daily Performance Badges
    if (progress >= 0.90) {
      badges.add("Elite Day"); // 90%+
    } else if (progress >= 0.75) {
      badges.add("Productive Day"); // 75%+
    }



    // 3. Financial Badge (Strict: Only on Last Day of Month if budget met)
    if (_moneyProvider != null) {
       final now = DateTime.now();
       final lastDay = DateTime(now.year, now.month + 1, 0).day;
       
       // Only award "Budget Master" if it's the end of the month OR if looking at past completed months (not implemented yet)
       // For now: Show "On Track" maybe? No, user asked for "Budget Master" at end of month.
       
       if (now.day == lastDay) {
          if (_moneyProvider!.getMonthlyAdherence() >= 1.0 && _moneyProvider!.monthlyExpense > 0) {
            badges.add("Budget Master");
          }
       }
    }

    // 4. Streak Badges (Section Wise)
    for (var section in _sections) {
      int s = calculateSectionStreak(section);
      if (s >= 60) {
        badges.add("${section.displayName} Master");
      } else if (s >= 21) {
        badges.add("${section.displayName} Expert");
      } else if (s >= 7) {
        badges.add("${section.displayName} Consistent");
      }
      

    }
    return badges;
  }

  Future<void> resetData() async {
    if (_sectionBox != null) {
      await _sectionBox!.clear(); // Clear content instead of deleting box file
      await _createDefaultData(); // Re-create defaults
    }
    if (_settingsBox != null) {
      await _settingsBox!.clear();
    }
    _rebuildHabitCache();
    _onDataChanged(); // Clears memo context and notifies
    await backupToCloud(); // Immediately sync the reset state to cloud
  }
  // --- CRUD for Habits ---
  
  void addHabit(LifeSection section, String title) {
    final newHabit = Habit(title: title, subTasks: []);
    section.habits.add(newHabit);
    section.save();
    _rebuildHabitCache();
    _onDataChanged();
    _triggerAutoBackup();
  }

  void updateHabitTitle(LifeSection section, Habit habit, String newTitle) {
    habit.title = newTitle;
    section.save();
    _rebuildHabitCache();
    _onDataChanged();
    _triggerAutoBackup();
  }

  void deleteHabit(LifeSection section, Habit habit) {
    section.habits.remove(habit);
    section.save();
    _rebuildHabitCache();
    _onDataChanged();
    _triggerAutoBackup();
  }

  Future<void> reorderHabits(LifeSection section, int oldIndex, int newIndex) async {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final habit = section.habits.removeAt(oldIndex);
    section.habits.insert(newIndex, habit);
    await section.save();
    _onDataChanged();
    _triggerAutoBackup();
  }

  // --- CRUD for SubTasks ---

  void addSubTask(LifeSection section, Habit habit, String title, SubTaskType type, int targetValue) {
    final newSubTask = SubTask(
      title: title, 
      type: type, 
      targetValue: targetValue
    );
    habit.subTasks.add(newSubTask);
    section.save();
    _checkHabitCompletion(section, habit);
    _onDataChanged();
    _triggerAutoBackup();
  }

  void updateSubTaskDetails(LifeSection section, Habit habit, SubTask subTask, String title, int targetValue) {
    subTask.title = title;
    subTask.targetValue = targetValue;
    section.save();
    _checkHabitCompletion(section, habit);
    _checkGrowthMilestone(fromUserAction: true);
    _triggerAutoBackup();
  }

  void deleteSubTask(LifeSection section, Habit habit, SubTask subTask) {
    habit.subTasks.remove(subTask);
    section.save();
    _checkHabitCompletion(section, habit);
    _checkGrowthMilestone(fromUserAction: true);
    _triggerAutoBackup();
  }

  Future<void> updateHabitReminder(LifeSection section, Habit habit, int? hour, int? minute) async {
    habit.reminderHour = hour;
    habit.reminderMinute = minute;
    
    // If setting a single reminder, we keep it in primary fields for simple UI, 
    // but we could also add it to the list. 
    // To support multiple via code, we use reminderTimes list.
    
    section.save();
    
    final notificationService = NotificationService();
    try {
      await notificationService.scheduleHabitReminder(habit);
    } catch (e) {
      debugPrint('SCHEDULING ERROR: $e');
      rethrow;
    }
    
    notifyListeners();
    _triggerAutoBackup();
  }

  Future<void> updateWakeSleepTime({TimeOfDay? wake, TimeOfDay? sleep}) async {
    if (wake != null) {
      _wakeUpTime = wake;
      await _settingsBox?.put('wake_hour', wake.hour);
      await _settingsBox?.put('wake_minute', wake.minute);
    }
    if (sleep != null) {
      _sleepTime = sleep;
      await _settingsBox?.put('sleep_hour', sleep.hour);
      await _settingsBox?.put('sleep_minute', sleep.minute);
    }
    
    // Auto-reschedule everything
    await rescheduleAllNotifications();
    notifyListeners();
    _triggerAutoBackup();
  }

  Future<void> setupWaterSchedule() async {
    final ns = NotificationService();
    
    // Find the water habit
    Habit? waterHabit;
    LifeSection? waterSection;
    for (var s in _sections) {
      for (var h in s.habits) {
        if (h.title.toLowerCase().contains('water')) {
          waterHabit = h;
          waterSection = s;
          break;
        }
      }
      if (waterHabit != null) break;
    }
    
    if (waterHabit == null) {
      // If water habit doesn't exist, create it in the Body section
      waterSection = _sections.firstWhere((s) => s.type == SectionType.body, orElse: () => _sections.first); // Fallback to first section
      waterHabit = Habit(
        title: "Water Intake (250ml)",
        subTasks: [
          SubTask(title: "Cups (250ml each)", type: SubTaskType.input, targetValue: 12),
        ],
      );
      waterSection.habits.add(waterHabit);
    } else {
      // Ensure subtask details are correct if habit already exists
      waterHabit.title = "Water Intake (250ml)";
      if (waterHabit.subTasks.isEmpty) {
        waterHabit.subTasks.add(SubTask(title: "Cups (250ml each)", type: SubTaskType.input, targetValue: 12));
      } else {
        waterHabit.subTasks[0].targetValue = 12;
        waterHabit.subTasks[0].title = "Cups (250ml each)";
      }
    }

    // Calculate intervals between wake and sleep
    // Total active minutes
    int wakeMinutes = _wakeUpTime.hour * 60 + _wakeUpTime.minute;
    int sleepMinutes = _sleepTime.hour * 60 + _sleepTime.minute;
    
    if (sleepMinutes <= wakeMinutes) sleepMinutes += 24 * 60; // Crosses midnight
    
    int totalMinutes = sleepMinutes - wakeMinutes;
    int interval = 90; // Default 1.5 hours
    int count = (totalMinutes / interval).floor();
    if (count < 4) count = 8; // Safety fallback, ensure at least 8 reminders

    List<Map<String, int>> newTimes = [];
    for (int i = 0; i < count; i++) {
        int m = wakeMinutes + (i * (totalMinutes / count)).round();
        int h = (m ~/ 60) % 24;
        int min = m % 60;
        newTimes.add({'hour': h, 'minute': min});
    }

    waterHabit.reminderTimes = newTimes;
    // Set primary reminder to the first one for display purposes
    if (newTimes.isNotEmpty) {
      waterHabit.reminderHour = newTimes[0]['hour'];
      waterHabit.reminderMinute = newTimes[0]['minute'];
    } else {
      waterHabit.reminderHour = null;
      waterHabit.reminderMinute = null;
    }
    
    // Save the section containing water habit
    if (waterSection != null) {
       waterSection.save();
    }
    
    await ns.scheduleHabitReminder(
      waterHabit,
      wakeMinutes: _wakeUpTime.hour * 60 + _wakeUpTime.minute,
      sleepMinutes: _sleepTime.hour * 60 + _sleepTime.minute,
    );
    notifyListeners();
    _triggerAutoBackup();
  }

  void updateWakeTime(int hour, int minute) {
    _wakeUpTime = TimeOfDay(hour: hour, minute: minute);
    _settingsBox?.put('wake_hour', hour);
    _settingsBox?.put('wake_minute', minute);
    // Should re-calculate water schedule if it depends on wake time
    rescheduleAllNotifications(); 
    notifyListeners();
    _triggerAutoBackup();
  }

  void updateSleepTime(int hour, int minute) {
    _sleepTime = TimeOfDay(hour: hour, minute: minute);
    _settingsBox?.put('sleep_hour', hour);
    _settingsBox?.put('sleep_minute', minute);
    // Should re-calculate water schedule if it depends on sleep time
    rescheduleAllNotifications();
    notifyListeners();
    _triggerAutoBackup();
  }

  bool _isTimeWithinActiveHours(int h, int m) {
    int current = h * 60 + m;
    int wake = _wakeUpTime.hour * 60 + _wakeUpTime.minute;
    int sleep = _sleepTime.hour * 60 + _sleepTime.minute;
    
    // Buffer: We allow up to the exact minute of sleep
    if (sleep > wake) {
      return current >= wake && current <= sleep;
    } else {
      // Sleep crosses midnight (e.g., wake 6am, sleep 1am)
      return current >= wake || current <= sleep;
    }
  }

  Future<void> rescheduleAllNotifications() async {
    final ns = NotificationService();
    
    // 1. Setup System Reminders (Morning/Evening)
    await _setupSystemReminders();
    
    // 2. Setup Water Intake
    await setupWaterSchedule();
    
    // 3. Setup all other habits
    for (var section in _sections) {
      for (var habit in section.habits) {
        // Skip water as it's handled separately with custom intervals
        if (habit.title.toLowerCase().contains('water')) continue;

        bool hasValidTime = false;
        
        // Check primary reminder
        if (habit.reminderHour != null && habit.reminderMinute != null) {
          if (_isTimeWithinActiveHours(habit.reminderHour!, habit.reminderMinute!)) {
            hasValidTime = true;
          }
        }
        
        // Check secondary times
        if (habit.reminderTimes != null && habit.reminderTimes!.isNotEmpty) {
          for (var t in habit.reminderTimes!) {
            if (_isTimeWithinActiveHours(t['hour']!, t['minute']!)) {
              hasValidTime = true;
              break;
            }
          }
        }

        if (hasValidTime) {
          try {
            await ns.scheduleHabitReminder(
              habit,
              wakeMinutes: _wakeUpTime.hour * 60 + _wakeUpTime.minute,
              sleepMinutes: _sleepTime.hour * 60 + _sleepTime.minute,
            );
          } catch (e) {
            debugPrint('Background rescheduling failed for ${habit.title}: $e');
          }
        } else if (habit.reminderHour != null || (habit.reminderTimes != null && habit.reminderTimes!.isNotEmpty)) {
           // If user has set a time but it's outside active hours, cancel previous ones
           await ns.cancelHabitReminder(habit);
           debugPrint('🚫 Reminder for ${habit.title} skipped (outside active hours)');
        }
      }
    }
  }

  // --- Sync Methods ---
  
  bool get isLoggedIn => _syncService.currentUser != null;
  String? get userEmail => _syncService.currentUser?.email;
  User? get currentUser => _syncService.currentUser;

  String get userName {
    final email = userEmail;
    if (email == null || email.isEmpty) return "User";
    final prefix = email.split('@').first;
    if (prefix.isEmpty) return "User";
    return prefix[0].toUpperCase() + prefix.substring(1);
  }

  String get userInitial {
    final email = userEmail;
    if (email == null || email.isEmpty) return "U";
    return email[0].toUpperCase();
  }


  Future<void> registerWithEmail(String email, String password) async {
    final user = await _syncService.signUpWithEmail(email, password);
    if (user != null) {
      await _syncService.restoreData();
      
      // Re-initialize both providers with new account data
      if (_moneyProvider != null) {
        await _moneyProvider!.init();
      }
      await init();
      notifyListeners();
    }
  }

  Future<void> loginWithEmail(String email, String password) async {
    final user = await _syncService.signInWithEmail(email, password);
    if (user != null) {
      debugPrint('👤 [LifeProvider] Login successful, starting restoration...');
      
      // Restore data from Firestore into Hive boxes
      await _syncService.restoreData();
      
      // Close boxes so Hive flushes everything
      if (_sectionBox != null && _sectionBox!.isOpen) await _sectionBox!.close();
      if (_settingsBox != null && _settingsBox!.isOpen) await _settingsBox!.close();
      
      // Reopen boxes fresh
      _sectionBox = await Hive.openBox<LifeSection>(AppConstants.sectionBoxName);
      debugPrint('👤 [LifeProvider] Box reopened after login. Count: ${_sectionBox!.length}');

      // Reload money provider
      if (_moneyProvider != null) {
        await _moneyProvider!.init();
      }
      
      // Use safe reload (no default data creation)
      await _reloadFromOpenBoxes();
      
      notifyListeners();
      debugPrint('✅ [LifeProvider] Login restore complete. Sections in memory: ${_sections.length}');
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    await _syncService.sendPasswordResetEmail(email);
  }

  Future<bool> restoreFromCloud() async {
    debugPrint('🚀 [LifeProvider] Manual restoration triggered...');
    final success = await _syncService.restoreData();
    if (success) {
      debugPrint('🔄 [LifeProvider] Restoration success, reloading boxes...');
      
      // Close boxes so Hive flushes all writes from restoreData
      if (_sectionBox != null && _sectionBox!.isOpen) await _sectionBox!.close();
      if (_settingsBox != null && _settingsBox!.isOpen) await _settingsBox!.close();
      
      // Reopen fresh
      _sectionBox = await Hive.openBox<LifeSection>(AppConstants.sectionBoxName);
      debugPrint('🔄 [LifeProvider] Box reopened. Count: ${_sectionBox!.length}');

      if (_moneyProvider != null) {
        await _moneyProvider!.init();
      }
      
      // Use safe reload — does NOT call _createDefaultData()
      await _reloadFromOpenBoxes();
      
      notifyListeners();
      debugPrint('✅ [LifeProvider] Manual Restore complete. Sections in memory: ${_sections.length}');
    } else {
      debugPrint('❌ [LifeProvider] Restoration failed or no data found in Firebase.');
    }
    return success;
  }

  Future<void> backupToCloud() async {
    debugPrint('📤 [LifeProvider] Manual backup triggered...');
    await _syncService.backupData();
    debugPrint('✅ [LifeProvider] Manual Backup complete.');
  }

  Future<void> logout() async {
    // Backup current data before logout so nothing is lost
    if (isLoggedIn) {
      try {
        await _syncService.backupData();
        debugPrint('💾 [LifeProvider] Data backed up before logout.');
      } catch (e) {
        debugPrint('⚠️ [LifeProvider] Backup before logout failed: $e');
      }
    }

    await _syncService.signOut();
    
    // Clear and CLOSE all boxes so next user starts completely fresh
    if (_sectionBox != null && _sectionBox!.isOpen) {
      await _sectionBox!.clear();
      await _sectionBox!.close();
      _sectionBox = null;
    }
    if (_settingsBox != null && _settingsBox!.isOpen) {
      await _settingsBox!.clear();
      await _settingsBox!.close();
      _settingsBox = null;
    }
    // Also clear money box
    try {
      final moneyBox = await Hive.openBox<MoneyEntry>(AppConstants.moneyBoxName);
      await moneyBox.clear();
      await moneyBox.close();
    } catch (_) {}

    _sections.clear();
    _milestoneMessage = "";
    _hasJustCrossedGrowthThreshold = false;
    
    if (_moneyProvider != null) {
      await _moneyProvider!.clearData();
    }
    
    notifyListeners();
    debugPrint('🔓 [LifeProvider] Logout complete. All boxes cleared and closed.');
  }

  // --- Auto Sync Helper ---
  
  bool _isSyncing = false;
  DateTime? _lastBackupTime;
  DateTime? get lastBackupTime => _lastBackupTime;
  
  Timer? _syncTimer;

  void _triggerAutoBackup() {
    if (!isLoggedIn) return;
    
    // Debounce: Cancel previous timer if it exists
    _syncTimer?.cancel();
    
    // Set a new timer for 30 seconds
    _syncTimer = Timer(const Duration(seconds: 30), () async {
      if (_isSyncing) return;
      
      _isSyncing = true;
      try {
        await _syncService.backupData();
        _lastBackupTime = DateTime.now();
        debugPrint('✅ Auto-sync completed at $_lastBackupTime');
      } catch (e) {
        debugPrint('❌ Auto-sync failed: $e');
      } finally {
        _isSyncing = false;
      }
    });
  }

  // --- Bundled Goals Logic ---

  Future<void> addBundledGoal(String title, List<String> habitIdentifiers, int targetDays) async {
    final goal = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'title': title,
      'habitIdentifiers': habitIdentifiers, // List of "sectionId|habitTitle"
      'targetDays': targetDays,
      'startDate': DateTime.now().toIso8601String(),
      'isAchieved': false,
    };
    _bundledGoals.add(goal);
    await _settingsBox?.put('bundledGoals', _bundledGoals);
    _onDataChanged();
    _triggerAutoBackup();
  }

  Future<void> deleteBundledGoal(String id) async {
    _bundledGoals.removeWhere((g) => g['id'] == id);
    await _settingsBox?.put('bundledGoals', _bundledGoals);
    _onDataChanged();
    _triggerAutoBackup();
  }

  int calculateBundledGoalStreak(Map<String, dynamic> goal) {
    final habitIdentifiers = List<String>.from(goal['habitIdentifiers']);
    if (habitIdentifiers.isEmpty) return 0;

    DateTime? startDate;
    if (goal['startDate'] != null) {
      try {
        final parsed = DateTime.parse(goal['startDate']);
        startDate = DateTime(parsed.year, parsed.month, parsed.day);
      } catch (_) {}
    }

    int streak = 0;
    DateTime now = DateTime.now();
    DateTime checkDate = DateTime(now.year, now.month, now.day);
    
    // Check backwards from today or yesterday
    bool todayCompleted = _areHabitsCompletedOn(habitIdentifiers, checkDate);
    DateTime yesterday = checkDate.subtract(const Duration(days: 1));
    bool yesterdayCompleted = _areHabitsCompletedOn(habitIdentifiers, yesterday);

    // If there's a start date, filter completions before it
    if (startDate != null) {
      if (checkDate.isBefore(startDate)) todayCompleted = false;
      if (yesterday.isBefore(startDate)) yesterdayCompleted = false;
    }

    if (!todayCompleted && !yesterdayCompleted) return 0;
    
    DateTime currentStreakDate = todayCompleted ? checkDate : yesterday;
    
    while(true) {
      if (startDate != null && currentStreakDate.isBefore(startDate)) {
        break;
      }

      if (_areHabitsCompletedOn(habitIdentifiers, currentStreakDate)) {
        streak++;
        currentStreakDate = currentStreakDate.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }
    return streak;
  }

  bool _areHabitsCompletedOn(List<String> identifiers, DateTime date) {
    for (var id in identifiers) {
      final habit = _habitLookupCache[id];
      if (habit == null || !habit.isCompletedOn(date)) {
        return false;
      }
    }
    return true;
  }

  void _checkBundledGoalsAchievement() {
    bool changed = false;
    for (var goal in _bundledGoals) {
      if (goal['isAchieved'] == true) continue;
      
      int currentStreak = calculateBundledGoalStreak(goal);
      if (currentStreak >= goal['targetDays']) {
        goal['isAchieved'] = true;
        _milestoneMessage = "CHALLENGE ACHIEVED!\n${goal['title']}\nCongratulations on $currentStreak days!";
        _hasJustCrossedGrowthThreshold = true;
        changed = true;
      }
    }
    if (changed) {
      _settingsBox?.put('bundledGoals', _bundledGoals);
      _triggerAutoBackup();
    }
  }
}
