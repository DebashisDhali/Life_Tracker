import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';
import '../providers/life_provider.dart';
import '../utils/constants.dart';

class ReminderSetupScreen extends StatefulWidget {
  const ReminderSetupScreen({Key? key}) : super(key: key);

  @override
  State<ReminderSetupScreen> createState() => _ReminderSetupScreenState();
}

class _ReminderSetupScreenState extends State<ReminderSetupScreen> {
  // Map to store selected times for habits locally before saving
  final Map<Habit, TimeOfDay?> _selectedTimes = {};

  @override
  void initState() {
    super.initState();
    // Pre-populate with existing times if any (though likely none for new users)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final life = context.read<LifeProvider>();
      for (var section in life.sections) {
        for (var habit in section.habits) {
          if (habit.reminderHour != null && habit.reminderMinute != null) {
            _selectedTimes[habit] = TimeOfDay(hour: habit.reminderHour!, minute: habit.reminderMinute!);
          }
        }
      }
      if (mounted) setState(() {});
    });
  }

  Future<void> _completeSetup() async {
    // 1. Save all selected times
    final life = context.read<LifeProvider>();
    for (var entry in _selectedTimes.entries) {
      final habit = entry.key;
      final time = entry.value;
      if (time != null) {
        // Find the section for this habit
        LifeSection? parentSection;
        for (var section in life.sections) {
          if (section.habits.contains(habit)) {
            parentSection = section;
            break;
          }
        }
        
        if (parentSection != null) {
          await life.updateHabitReminder(parentSection, habit, time.hour, time.minute);
        }
      }
    }

    // 2. Mark as done in SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('reminder_setup_complete', true);

    if (mounted) {
      Navigator.of(context).pop(); // Return to Home
    }
  }

  Future<void> _pickTime(Habit habit) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTimes[habit] ?? const TimeOfDay(hour: 8, minute: 0),
    );

    if (picked != null) {
      setState(() {
        _selectedTimes[habit] = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final life = context.watch<LifeProvider>();
    final sections = life.sections;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Set Reminders"),
        centerTitle: true,
        automaticallyImplyLeading: false, // Prevent going back without choosing
        actions: [
          TextButton(
            onPressed: _completeSetup, // "Skip" logic acts same as saving what we have (or nothing)
            child: const Text("Skip", style: TextStyle(color: Colors.grey)),
          )
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              "Stay consistent! Set daily reminders for your habits.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Theme.of(context).textTheme.bodyMedium?.color,
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: sections.length,
              itemBuilder: (context, index) {
                final section = sections[index];
                if (section.habits.isEmpty) return const SizedBox.shrink();

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Text(
                        section.displayName.toUpperCase(),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                    ...section.habits.map((habit) {
                      final time = _selectedTimes[habit];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.03),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ListTile(
                          title: Text(habit.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                          trailing: InkWell(
                            onTap: () => _pickTime(habit),
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: time != null 
                                    ? AppColors.sectionSkillDark.withOpacity(0.1) 
                                    : Theme.of(context).dividerColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: time != null 
                                      ? AppColors.sectionSkillDark 
                                      : Colors.transparent,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.alarm, 
                                    size: 16, 
                                    color: time != null ? AppColors.sectionSkillDark : Colors.grey,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    time != null ? time.format(context) : "Set Time",
                                    style: TextStyle(
                                      color: time != null ? AppColors.sectionSkillDark : Colors.grey[600],
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                    const SizedBox(height: 16),
                  ],
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _completeSetup,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.sectionSkillDark,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text(
                  "Done",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
