import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/models.dart';
import 'package:hive/hive.dart';
import '../utils/constants.dart';

class SyncService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  User? get currentUser => _auth.currentUser;

  Future<User?> signUpWithEmail(String email, String password) async {
    try {
      final UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential.user;
    } catch (e) {
      debugPrint('Error signing up with email: $e');
      rethrow;
    }
  }

  Future<User?> signInWithEmail(String email, String password) async {
    try {
      final UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential.user;
    } catch (e) {
      debugPrint('Error signing in with email: $e');
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      debugPrint('Error sending password reset email: $e');
      rethrow;
    }
  }

  // Backup Hive data to Firestore
  Future<void> backupData() async {
    if (currentUser == null) return;

    final userId = currentUser!.uid;
    final userDoc = _firestore.collection('users').doc(userId);
    final batch = _firestore.batch();

    // 1. Sections & Habits (Scalable sub-collection)
    final sectionBox = await Hive.openBox<LifeSection>(AppConstants.sectionBoxName);
    final sections = sectionBox.values.toList();
    
    // Clear old sections conceptually by updating the 'lastBackup' 
    // or we can just overwrite them. Batch size limit is 500.
    int count = 0;
    for (var s in sections) {
      final sData = {
        'id': s.id,
        'title': s.title,
        'type': s.type.index,
        'order': s.order,
        'habits': s.habits.map((h) => {
          'title': h.title,
          'reminderMinute': h.reminderMinute,
          'order': h.order,
          'completionDates': h.completionDates.map((d) => d.toIso8601String()).toList(),
          'reminderTimes': h.reminderTimes,
          'subTasks': h.subTasks.map((st) => {
            'title': st.title,
            'type': st.type.index,
            'targetValue': st.targetValue,
            'currentValue': st.currentValue,
            'dailyValues': st.dailyValues,
          }).toList(),
        }).toList(),
      };
      batch.set(userDoc.collection('sections').doc(s.id), sData);
      count++;
      if (count >= 400) { // Commit in small chunks to stay safe
        await batch.commit();
        count = 0;
      }
    }

    // 2. Money Entries (Scalable sub-collection)
    final moneyBox = await Hive.openBox<MoneyEntry>(AppConstants.moneyBoxName);
    final moneyEntries = moneyBox.values.toList();
    for (var e in moneyEntries) {
      final eData = {
        'id': e.id,
        'amount': e.amount,
        'title': e.title,
        'date': e.date.toIso8601String(),
        'type': e.type.index,
        'status': e.status.index,
        'category': e.category,
      };
      batch.set(userDoc.collection('money_entries').doc(e.id), eData);
      count++;
      if (count >= 450) {
        await batch.commit();
        count = 0;
      }
    }

    // 3. Money Settings & Metadata
    final settingsBox = await Hive.openBox('money_settings_primitive');
    final lifeSettingsBox = await Hive.openBox(AppConstants.settingsBoxName);
    final bundledGoals = lifeSettingsBox.get('bundledGoals', defaultValue: []);

    final metadata = {
      'lastBackup': FieldValue.serverTimestamp(),
      'moneySettings': {
        'monthlyBudget': settingsBox.get('pref_budget_v5', defaultValue: 5000.0),
        'dailyTarget': settingsBox.get('pref_daily_v5', defaultValue: 140.0),
        'entertainmentAllocation': settingsBox.get('pref_binodon_v5', defaultValue: 500.0),
        'emergencyAllocation': settingsBox.get('pref_emergency_v5', defaultValue: 1000.0),
        'totalInvestment': settingsBox.get('pref_investment_v5', defaultValue: 0.0),
      },
      'bundledGoals': bundledGoals,
      'milestones': {
        'lastGrowthMilestoneDate': lifeSettingsBox.get('lastGrowthMilestoneDate'),
        'lastCelebratedProgress': lifeSettingsBox.get('lastCelebratedProgress'),
        'personalBestProgress': lifeSettingsBox.get('personalBestProgress'),
      }
    };

    batch.set(userDoc, metadata, SetOptions(merge: true));
    await batch.commit();
    
    debugPrint('Backup successful for user: $userId (Scalable sub-collections used)');
  }

  // Restore data from Firestore to Hive
  Future<bool> restoreData() async {
    if (currentUser == null) return false;

    final userId = currentUser!.uid;
    final userDoc = _firestore.collection('users').doc(userId);
    debugPrint('🔄 [SyncService] Starting scalable restore for user: $userId');
    
    try {
      final doc = await userDoc.get();

      if (!doc.exists) {
        debugPrint('ℹ️ [SyncService] No backup found for user: $userId');
        return false;
      }

      final metadata = doc.data();
      if (metadata == null) return false;

      // 1. Restore Sections from Sub-collection
      final sectionsSnapshot = await userDoc.collection('sections').get();
      if (sectionsSnapshot.docs.isNotEmpty) {
        final sectionBox = await Hive.openBox<LifeSection>(AppConstants.sectionBoxName);
        await sectionBox.clear();
        debugPrint('📦 [SyncService] Restoring ${sectionsSnapshot.docs.length} sections from sub-collection...');

        for (var sDoc in sectionsSnapshot.docs) {
          try {
            final sMap = sDoc.data();
            final section = LifeSection(
              id: sMap['id'] ?? sDoc.id,
              title: sMap['title'],
              type: SectionType.values[((sMap['type'] as num?)?.toInt() ?? 0).clamp(0, SectionType.values.length - 1)],
              habits: [],
              order: (sMap['order'] as num?)?.toInt(),
            );

            final List<dynamic> habitsData = sMap['habits'] ?? [];
            for (var hMap in habitsData) {
              final habit = Habit(
                title: hMap['title'] ?? "Untitled",
                subTasks: [],
                reminderHour: (hMap['reminderHour'] as num?)?.toInt(),
                reminderMinute: (hMap['reminderMinute'] as num?)?.toInt(),
                completionDates: (hMap['completionDates'] as List?)
                    ?.map((d) => DateTime.parse(d))
                    .toList(),
                reminderTimes: (hMap['reminderTimes'] as List?)
                    ?.map((t) => Map<String, int>.from(t as Map))
                    .toList(),
                order: (hMap['order'] as num?)?.toInt(),
              );

              final List<dynamic> subTasksData = hMap['subTasks'] ?? [];
              for (var stMap in subTasksData) {
                final subTaskIdType = (stMap['type'] as num?)?.toInt() ?? 0;
                final subTask = SubTask(
                  title: stMap['title'] ?? "Untitled",
                  type: SubTaskType.values[subTaskIdType.clamp(0, SubTaskType.values.length - 1)],
                  targetValue: (stMap['targetValue'] as num?)?.toInt() ?? 1,
                );
                subTask.currentValue = (stMap['currentValue'] as num?)?.toInt() ?? 0;
                
                if (stMap['dailyValues'] != null) {
                   final Map rawMap = stMap['dailyValues'] as Map;
                   subTask.dailyValues = rawMap.map((k, v) => MapEntry(k.toString(), (v as num).toInt()));
                }
                habit.subTasks.add(subTask);
              }
              section.habits.add(habit);
            }
            await sectionBox.add(section);
          } catch (e) {
            debugPrint('⚠️ [SyncService] Error restoring section doc: $e');
          }
        }
      }

      // 2. Restore Money Entries from Sub-collection
      final moneySnapshot = await userDoc.collection('money_entries').get();
      if (moneySnapshot.docs.isNotEmpty) {
        final moneyBox = await Hive.openBox<MoneyEntry>(AppConstants.moneyBoxName);
        await moneyBox.clear();
        debugPrint('💰 [SyncService] Restoring ${moneySnapshot.docs.length} money entries...');

        for (var eDoc in moneySnapshot.docs) {
          try {
            final eMap = eDoc.data();
            final entry = MoneyEntry(
              id: eMap['id'] ?? eDoc.id,
              amount: (eMap['amount'] as num?)?.toDouble() ?? 0.0,
              title: eMap['title'] ?? "Untitled",
              date: DateTime.parse(eMap['date'] ?? DateTime.now().toIso8601String()),
              type: MoneyEntryType.values[((eMap['type'] as num?)?.toInt() ?? 0).clamp(0, MoneyEntryType.values.length - 1)],
              status: MoneyEntryStatus.values[((eMap['status'] as num?)?.toInt() ?? 0).clamp(0, MoneyEntryStatus.values.length - 1)],
              category: eMap['category'] ?? "General",
            );
            await moneyBox.add(entry);
          } catch (e) {
            debugPrint('⚠️ [SyncService] Error restoring money entry doc: $e');
          }
        }
      }

      // 3. Restore Money Settings & Bundled Goals from Metadata
      if (metadata['moneySettings'] != null) {
        final Map<String, dynamic> settings = Map<String, dynamic>.from(metadata['moneySettings']);
        final settingsBox = await Hive.openBox('money_settings_primitive');
        await settingsBox.clear();
        
        await settingsBox.put('pref_budget_v5', (settings['monthlyBudget'] as num?)?.toDouble() ?? 5000.0);
        await settingsBox.put('pref_daily_v5', (settings['dailyTarget'] as num?)?.toDouble() ?? 140.0);
        await settingsBox.put('pref_binodon_v5', (settings['entertainmentAllocation'] as num?)?.toDouble() ?? 500.0);
        await settingsBox.put('pref_emergency_v5', (settings['emergencyAllocation'] as num?)?.toDouble() ?? 1000.0);
        await settingsBox.put('pref_investment_v5', (settings['totalInvestment'] as num?)?.toDouble() ?? 0.0);
      }

      if (metadata['bundledGoals'] != null) {
        final lifeSettingsBox = await Hive.openBox(AppConstants.settingsBoxName);
        await lifeSettingsBox.put('bundledGoals', metadata['bundledGoals']);
        
        // Restore milestones if they exist
        if (metadata['milestones'] != null) {
          final milestones = Map<String, dynamic>.from(metadata['milestones']);
          if (milestones['lastGrowthMilestoneDate'] != null) {
            await lifeSettingsBox.put('lastGrowthMilestoneDate', milestones['lastGrowthMilestoneDate']);
          }
          if (milestones['lastCelebratedProgress'] != null) {
            await lifeSettingsBox.put('lastCelebratedProgress', milestones['lastCelebratedProgress']);
          }
          if (milestones['personalBestProgress'] != null) {
            await lifeSettingsBox.put('personalBestProgress', milestones['personalBestProgress']);
          }
        }
      }

      return true;
    } catch (e) {
      debugPrint('❌ [SyncService] CRITICAL restore error: $e');
      return false;
    }
  }
}
