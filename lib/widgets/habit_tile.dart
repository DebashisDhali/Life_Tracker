import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/life_provider.dart';
import '../services/notification_service.dart';
import 'subtask_tile.dart';

class HabitTile extends StatelessWidget {
  final Habit habit;
  final Color baseColor;
  final LifeSection section;

  const HabitTile({super.key, required this.habit, required this.baseColor, required this.section});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<LifeProvider>(context);
    final viewingDate = provider.viewingDate;
    final progress = habit.progressOn(viewingDate);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              HapticFeedback.lightImpact();
              provider.toggleHabitExpansion(section, habit);
            },
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  // Progress Indicator
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 44,
                        height: 44,
                        child: CircularProgressIndicator(
                          value: progress,
                          backgroundColor: Theme.of(context).brightness == Brightness.dark 
                            ? Colors.white.withOpacity(0.05) 
                            : Colors.grey[200],
                          color: baseColor,
                          strokeWidth: 4,
                        ),
                      ),
                      Icon(
                        progress == 1.0 ? Icons.check_circle : Icons.circle_outlined,
                        color: progress == 1.0 
                          ? baseColor 
                          : (Theme.of(context).brightness == Brightness.dark ? Colors.white24 : Colors.grey[400]),
                        size: 22,
                      ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  // Habit Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          habit.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).textTheme.bodyLarge?.color,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(Icons.check_circle_outline, size: 12, color: Colors.grey[500]),
                            const SizedBox(width: 3),
                            Text(
                              '${(progress * 100).toStringAsFixed(0)}% done',
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context).textTheme.bodySmall?.color,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Reminder Icon + Expand Icon (fixed width to prevent overflow)
                  _buildReminderButton(context, provider),
                  const SizedBox(width: 4),
                  Icon(
                    habit.isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: baseColor,
                    size: 24,
                  ),
                ],
              ),
            ),
          ),
          // Subtasks
          if (habit.isExpanded) ...[
            Divider(height: 1, color: Theme.of(context).dividerColor.withOpacity(0.1)),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Column(
                children: habit.subTasks
                    .map((subTask) => SubTaskTile(
                          subTask: subTask,
                          habit: habit,
                          section: section,
                        ))
                    .toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildReminderButton(BuildContext context, LifeProvider provider) {
    if (!provider.isToday) return const SizedBox.shrink(); 
    
    final bool hasSingleReminder = habit.reminderHour != null;
    final bool hasMultipleReminders = habit.reminderTimes != null && habit.reminderTimes!.isNotEmpty;
    final bool hasAnyReminder = hasSingleReminder || hasMultipleReminders;
    
    String timeStr = '';
    if (hasSingleReminder) {
      timeStr = '${habit.reminderHour!.toString().padLeft(2, '0')}:${habit.reminderMinute!.toString().padLeft(2, '0')}';
    } else if (hasMultipleReminders) {
      timeStr = '${habit.reminderTimes!.length} times';
    }

    return InkWell(
      onTap: () async {
        if (hasMultipleReminders && habit.title.contains("Water")) {
           ScaffoldMessenger.of(context).showSnackBar(
             const SnackBar(content: Text('Auto-schedule set for Water Intake')),
           );
           return;
        }
        
        final TimeOfDay? picked = await showTimePicker(
          context: context,
          initialTime: hasSingleReminder 
              ? TimeOfDay(hour: habit.reminderHour!, minute: habit.reminderMinute!)
              : const TimeOfDay(hour: 8, minute: 0),
          helpText: 'Set Daily Reminder',
        );

        if (picked != null) {
          try {
            await provider.updateHabitReminder(section, habit, picked.hour, picked.minute);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Reminder set for ${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}'),
                  backgroundColor: Colors.green,
                  duration: const Duration(seconds: 2),
                ),
              );
            }
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Failed to set reminder: $e'),
                  backgroundColor: Colors.red,
                  action: SnackBarAction(
                    label: 'Grant Permission',
                    textColor: Colors.white,
                    onPressed: () => NotificationService().init(),
                  ),
                ),
              );
            }
          }
        }
      },
      onLongPress: hasAnyReminder ? () {
         // Clear both
         habit.reminderTimes = [];
         provider.updateHabitReminder(section, habit, null, null);
         ScaffoldMessenger.of(context).showSnackBar(
           const SnackBar(content: Text('All reminders cleared'), duration: Duration(seconds: 1)),
         );
      } : null,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            hasAnyReminder ? Icons.notifications_active : Icons.notifications_none_rounded,
            color: hasAnyReminder ? baseColor : Colors.grey[400],
            size: 20,
          ),
          if (hasAnyReminder)
            Text(
              timeStr,
              style: TextStyle(fontSize: 10, color: baseColor, fontWeight: FontWeight.bold),
            ),
        ],
      ),
    );
  }
}
