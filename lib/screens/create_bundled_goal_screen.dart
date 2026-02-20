import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/life_provider.dart';
import '../utils/constants.dart';
import '../widgets/premium_button.dart';

class CreateBundledGoalScreen extends StatefulWidget {
  const CreateBundledGoalScreen({Key? key}) : super(key: key);

  @override
  State<CreateBundledGoalScreen> createState() => _CreateBundledGoalScreenState();
}

class _CreateBundledGoalScreenState extends State<CreateBundledGoalScreen> {
  final _titleController = TextEditingController();
  int _targetDays = 7;
  final List<String> _selectedHabitIds = [];

  @override
  Widget build(BuildContext context) {
    final life = Provider.of<LifeProvider>(context);
    final sections = life.sections;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Create Challenge", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title Input
            Text("Challenge Title", style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.titleLarge?.color)),
            const SizedBox(height: 12),
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                hintText: "e.g., 7 Days Ultimate Growth",
                filled: true,
                fillColor: Theme.of(context).cardColor,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Days Input
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Target Duration", style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.titleLarge?.color)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: AppColors.sectionSkill.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                  child: Text("$_targetDays Days", style: const TextStyle(color: AppColors.sectionSkillDark, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            Slider(
              value: _targetDays.toDouble(),
              min: 3,
              max: 90,
              divisions: 87,
              activeColor: AppColors.sectionSkill,
              onChanged: (val) => setState(() => _targetDays = val.toInt()),
            ),
            
            const SizedBox(height: 32),
            
            // Habit Selection
            Text("Select Habits to Include", style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.titleLarge?.color)),
            const SizedBox(height: 16),
            
            ...sections.map((section) {
              if (section.habits.isEmpty) return const SizedBox.shrink();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Text(section.displayName, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodySmall?.color)),
                  ),
                  ...section.habits.map((habit) {
                    final habitId = "${section.id}|${habit.title}";
                    final isSelected = _selectedHabitIds.contains(habitId);
                    
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: isSelected ? AppColors.sectionSkill : Colors.transparent, width: 1.5),
                      ),
                      child: CheckboxListTile(
                        value: isSelected,
                        title: Text(habit.title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                        activeColor: AppColors.sectionSkill,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        onChanged: (val) {
                          setState(() {
                            if (val == true) {
                              _selectedHabitIds.add(habitId);
                            } else {
                              _selectedHabitIds.remove(habitId);
                            }
                          });
                        },
                      ),
                    );
                  }).toList(),
                  const SizedBox(height: 16),
                ],
              );
            }).toList(),
            
            const SizedBox(height: 40),
            
            // Create Button
            PremiumButton(
              onPressed: () {
                if (_titleController.text.isNotEmpty && _selectedHabitIds.isNotEmpty) {
                  life.addBundledGoal(_titleController.text, _selectedHabitIds, _targetDays);
                  Navigator.pop(context);
                }
              },
              label: "Start Challenge",
              icon: Icons.rocket_launch_rounded,
              gradientColors: const [AppColors.sectionSkillDark, AppColors.sectionSkill],
              width: double.infinity,
            ),
          ],
        ),
      ),
    );
  }
}
