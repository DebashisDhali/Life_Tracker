import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import '../models/models.dart';
import '../utils/constants.dart';

class MoneyProvider with ChangeNotifier {
  Box<MoneyEntry>? _moneyBox;
  Box? _settingsBox; // Removed <MoneySettings> type to allow primitive storage
  List<MoneyEntry> _entries = [];
  MoneySettings _settings = MoneySettings(
    monthlyBudget: 5000, 
    dailyTarget: 140,
    entertainmentAllocation: 500,
    emergencyAllocation: 1000,
    totalInvestment: 0,
  );

  // Memoization caches
  double? _memoTotalExpense;
  double? _memoTotalPayable;
  double? _memoTotalReceivable;
  double? _memoMonthlyRemaining;
  final Map<String, double> _memoDayAdherence = {}; // "yyyy-MM-dd" -> score

  List<MoneyEntry> get entries => _entries;
  MoneySettings get settings => _settings;

  bool get isLoading => _moneyBox == null || _settingsBox == null;

  // Persistence keys for individual settings
  static const String _kBudget = 'pref_budget_v5';
  static const String _kDaily = 'pref_daily_v5';
  static const String _kBinodon = 'pref_binodon_v5';
  static const String _kEmergency = 'pref_emergency_v5';
  static const String _kInvestment = 'pref_investment_v5';

  void _onDataChanged() {
    _memoTotalExpense = null;
    _memoTotalPayable = null;
    _memoTotalReceivable = null;
    _memoMonthlyRemaining = null;
    _memoDayAdherence.clear();
    notifyListeners();
  }

  double get totalExpense {
    if (_memoTotalExpense != null) return _memoTotalExpense!;
    _memoTotalExpense = _entries
        .where((e) => e.type == MoneyEntryType.expense && e.status == MoneyEntryStatus.completed)
        .fold<double>(0.0, (sum, e) => sum + (e.amount ?? 0.0));
    return _memoTotalExpense!;
  }
  
  double get totalPayable {
    if (_memoTotalPayable != null) return _memoTotalPayable!;
    _memoTotalPayable = _entries
        .where((e) => e.type == MoneyEntryType.expense && e.status == MoneyEntryStatus.pending)
        .fold<double>(0.0, (sum, e) => sum + (e.amount ?? 0.0));
    return _memoTotalPayable!;
  }

  double get totalReceivable {
    if (_memoTotalReceivable != null) return _memoTotalReceivable!;
    _memoTotalReceivable = _entries
        .where((e) => e.type == MoneyEntryType.income && e.status == MoneyEntryStatus.pending)
        .fold<double>(0.0, (sum, e) => sum + (e.amount ?? 0.0));
    return _memoTotalReceivable!;
  }

  double get generalMonthlyExpense {
    final now = DateTime.now();
    return _entries
        .where((e) => e.type == MoneyEntryType.expense && 
                      e.status == MoneyEntryStatus.completed &&
                      (e.category ?? 'General') == 'General' &&
                      e.date.year == now.year && e.date.month == now.month)
        .fold<double>(0.0, (sum, e) => sum + (e.amount ?? 0.0));
  }

  double get monthlyRemaining {
    if (_memoMonthlyRemaining != null) return _memoMonthlyRemaining!;
    double mainBalance = settings.monthlyBudget - generalMonthlyExpense;
    _memoMonthlyRemaining = mainBalance + entertainmentBalance + emergencyBalance;
    return _memoMonthlyRemaining!;
  }

  double getExpenseAdherence(DateTime date) {
    final key = "${date.year}-${date.month}-${date.day}";
    if (_memoDayAdherence.containsKey(key)) return _memoDayAdherence[key]!;

    final dayEntries = _entries.where((e) => 
                      e.date.year == date.year && e.date.month == date.month && e.date.day == date.day);
    
    // If no expense recorded, we assume 100% adherence (1.0)
    if (dayEntries.isEmpty) {
      _memoDayAdherence[key] = 1.0;
      return 1.0;
    }

    final dayExpense = dayEntries
        .where((e) => e.type == MoneyEntryType.expense && e.status == MoneyEntryStatus.completed && (e.category ?? 'General') == 'General')
        .fold<double>(0.0, (sum, e) => sum + (e.amount ?? 0.0));
    
    double score = 1.0;
    if (settings.dailyTarget > 0 && dayExpense > settings.dailyTarget) {
      double overAmount = dayExpense - settings.dailyTarget;
      double penalty = overAmount / settings.dailyTarget; 
      score = (1.0 - penalty).clamp(0.0, 1.0); 
    }
    
    _memoDayAdherence[key] = score;
    return score;
  }

  double getMonthlyAdherenceFor(DateTime date) {
    if (settings.monthlyBudget <= 0) return 1.0;
    
    double expense = getMonthlyExpenseFor(date);
    if (expense <= settings.monthlyBudget) return 1.0;
    
    double overAmount = expense - settings.monthlyBudget;
    double penalty = overAmount / settings.monthlyBudget;
    return (1.0 - penalty).clamp(0.0, 1.0);
  }

  double getMonthlyAdherence() {
    return getMonthlyAdherenceFor(DateTime.now());
  }

  double get todaysTotalExpense {
    final now = DateTime.now();
    return _entries
        .where((e) => e.type == MoneyEntryType.expense && 
                      e.status == MoneyEntryStatus.completed &&
                      isSameDay(e.date, now))
        .fold(0.0, (sum, e) => sum + e.amount);
  }

  double get todaysGeneralExpense {
    final now = DateTime.now();
    return _entries
        .where((e) => e.type == MoneyEntryType.expense && 
                      e.status == MoneyEntryStatus.completed &&
                      (e.category ?? 'General') == 'General' &&
                      isSameDay(e.date, now))
        .fold(0.0, (sum, e) => sum + e.amount);
  }

  bool isSameDay(DateTime d1, DateTime d2) {
    return d1.year == d2.year && d1.month == d2.month && d1.day == d2.day;
  }

  double getMonthlyExpenseFor(DateTime date) {
    return _entries
        .where((e) => e.type == MoneyEntryType.expense && 
                      e.status == MoneyEntryStatus.completed &&
                      e.date.year == date.year && e.date.month == date.month)
        .fold(0.0, (sum, e) => sum + e.amount);
  }

  double get monthlyExpense {
    return getMonthlyExpenseFor(DateTime.now());
  }

  double get investmentTotal {
    double entryInvestments = _entries
        .where((e) => (e.category ?? 'General') == 'Investment' && e.status == MoneyEntryStatus.completed)
        .fold(0.0, (sum, e) {
          // If Category is Investment:
          // Expense = Buying an asset (Increases portfolio value)
          // Income = Selling an asset or getting dividends (Decreases principal or keeps same? 
          // Let's assume Income from Investment is "Portfolio Exit", so it decreases current investment balance)
          if (e.type == MoneyEntryType.expense) return sum + (e.amount ?? 0.0);
          if (e.type == MoneyEntryType.income) return sum - (e.amount ?? 0.0);
          return sum;
        });
    return settings.totalInvestment + entryInvestments;
  }

  double get entertainmentBalance {
    double spent = _entries
        .where((e) => (e.category ?? 'General') == 'Entertainment' && e.type == MoneyEntryType.expense && e.status == MoneyEntryStatus.completed)
        .fold<double>(0.0, (sum, e) => sum + (e.amount ?? 0.0));
    return settings.entertainmentAllocation - spent;
  }

  double get emergencyBalance {
    double spent = _entries
        .where((e) => (e.category ?? 'General') == 'Emergency' && e.type == MoneyEntryType.expense && e.status == MoneyEntryStatus.completed)
        .fold<double>(0.0, (sum, e) => sum + (e.amount ?? 0.0));
    return settings.emergencyAllocation - spent;
  }

  Future<void> init() async {
    _moneyBox = await Hive.openBox<MoneyEntry>(AppConstants.moneyBoxName);
    _settingsBox = await Hive.openBox('money_settings_primitive');
    
    _entries = _moneyBox!.values.toList();
    _sortEntries();
    
    final budget = _settingsBox!.get(_kBudget) ?? 5000.0;
    final daily = _settingsBox!.get(_kDaily) ?? 140.0;
    final binodon = _settingsBox!.get(_kBinodon) ?? 500.0;
    final emergency = _settingsBox!.get(_kEmergency) ?? 1000.0;
    final investment = _settingsBox!.get(_kInvestment) ?? 0.0;

    _settings = MoneySettings(
      monthlyBudget: _toDouble(budget),
      dailyTarget: _toDouble(daily),
      entertainmentAllocation: _toDouble(binodon),
      emergencyAllocation: _toDouble(emergency),
      totalInvestment: _toDouble(investment),
    );
    
    notifyListeners();
  }

  void _sortEntries() {
    _entries.sort((a, b) => b.date.compareTo(a.date));
  }

  double _toDouble(dynamic val) {
    if (val is int) return val.toDouble();
    if (val is double) return val;
    return 0.0;
  }

  Future<void> updateSettings(double budget, double daily, double binodon, double emergency, double investment) async {
    if (_settingsBox == null) return;
    
    await _settingsBox!.put(_kBudget, budget);
    await _settingsBox!.put(_kDaily, daily);
    await _settingsBox!.put(_kBinodon, binodon);
    await _settingsBox!.put(_kEmergency, emergency);
    await _settingsBox!.put(_kInvestment, investment);

    _settings = MoneySettings(
      monthlyBudget: budget,
      dailyTarget: daily,
      entertainmentAllocation: binodon,
      emergencyAllocation: emergency,
      totalInvestment: investment,
    );
    
    _onDataChanged();
  }
  Future<void> addEntry(MoneyEntry entry) async {
    await _moneyBox!.add(entry);
    _entries = _moneyBox!.values.toList();
    _sortEntries();
    _onDataChanged();
  }

  Future<void> updateEntry(MoneyEntry entry) async {
    await entry.save();
    _sortEntries();
    _onDataChanged();
  }

  Future<void> updateEntryStatus(MoneyEntry entry, MoneyEntryStatus status, {bool updateDate = false}) async {
    entry.status = status;
    if (updateDate) {
      entry.date = DateTime.now();
    }
    await entry.save();
    _sortEntries();
    _onDataChanged();
  }

  Future<void> deleteEntry(MoneyEntry entry) async {
    await entry.delete();
    _entries = _moneyBox!.values.toList();
    _sortEntries();
    _onDataChanged();
  }

  Future<void> resetData() async {
    if (_moneyBox != null) {
      await _moneyBox!.clear();
      _entries = [];
    }
    if (_settingsBox != null) {
      await _settingsBox!.clear();
      await updateSettings(5000.0, 140.0, 500.0, 1000.0, 0.0);
    }
    _onDataChanged();
  }

  // Clear all data for account isolation (called on logout)
  Future<void> clearData() async {
    if (_moneyBox != null) {
      await _moneyBox!.clear();
      _entries = [];
    }
    if (_settingsBox != null) {
      await _settingsBox!.clear();
    }
    
    // Reset to default settings
    _settings = MoneySettings(
      monthlyBudget: 5000, 
      dailyTarget: 140,
      entertainmentAllocation: 500,
      emergencyAllocation: 1000,
      totalInvestment: 0,
    );
    
    notifyListeners();
  }
}
