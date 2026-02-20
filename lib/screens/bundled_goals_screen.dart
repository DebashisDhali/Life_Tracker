import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/life_provider.dart';
import '../utils/constants.dart';
import 'create_bundled_goal_screen.dart';
import '../widgets/premium_button.dart';
import '../widgets/premium_alert.dart';

class BundledGoalsScreen extends StatelessWidget {
  const BundledGoalsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<LifeProvider>(
      builder: (context, life, child) {
        final goals = life.bundledGoals;
        
        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: AppBar(
            title: const Text("Multi-day Challenges", style: TextStyle(fontWeight: FontWeight.bold)),
            centerTitle: true,
            backgroundColor: Colors.transparent,
            elevation: 0,
          ),
          body: RefreshIndicator(
            onRefresh: () async {
              await life.restoreFromCloud();
            },
            color: AppColors.sectionSkillDark,
            child: goals.isEmpty 
              ? SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: SizedBox(
                    height: MediaQuery.of(context).size.height - AppBar().preferredSize.height - 100,
                    child: _buildEmptyState(context),
                  ),
                )
              : ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  itemCount: goals.length,
                  itemBuilder: (context, index) {
                    final goal = goals[index];
                    return _buildGoalCard(context, life, goal);
                  },
                ),
          ),
          floatingActionButton: PremiumFAB(
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateBundledGoalScreen()));
            },
            label: "New Challenge",
            icon: Icons.add_rounded,
            colors: const [AppColors.sectionSkillDark, AppColors.sectionSkill],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.emoji_events_outlined, size: 80, color: Colors.grey.withOpacity(0.3)),
          const SizedBox(height: 24),
          const Text(
            "No active challenges yet",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey),
          ),
          const SizedBox(height: 12),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 48),
            child: Text(
              "Group your favorite habits into a challenge and earn rewards for consistency!",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalCard(BuildContext context, LifeProvider life, Map<String, dynamic> goal) {
    final int streak = life.calculateBundledGoalStreak(goal);
    final int target = goal['targetDays'] as int;
    final double progress = (streak / target).clamp(0.0, 1.0);
    final bool isAchieved = goal['isAchieved'] ?? false;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.all(20),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    goal['title'],
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ),
                if (isAchieved)
                  const Icon(Icons.verified_rounded, color: Colors.green, size: 24),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isAchieved ? "Goal Achieved!" : "$streak / $target days streak",
                      style: TextStyle(
                        color: isAchieved ? Colors.green : AppColors.sectionSkillDark,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text("${(progress * 100).toInt()}%"),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    backgroundColor: Theme.of(context).dividerColor.withOpacity(0.05),
                    color: isAchieved ? Colors.green : AppColors.sectionSkillDark,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  children: List<String>.from(goal['habitIdentifiers']).map((id) {
                    final parts = id.split('|');
                    final sectionId = parts[0];
                    final habitTitle = parts.length > 1 ? parts[1] : id;

                    bool isCompletedToday = false;
                    try {
                        final section = life.sections.firstWhere((s) => s.id == sectionId);
                        final habit = section.habits.firstWhere((h) => h.title == habitTitle);
                        isCompletedToday = habit.isCompletedToday();
                    } catch (_) {}

                    return Chip(
                      label: Text(habitTitle, style: TextStyle(
                        fontSize: 11, 
                        fontWeight: isCompletedToday ? FontWeight.bold : FontWeight.normal,
                        color: isCompletedToday ? Colors.white : Theme.of(context).textTheme.bodySmall?.color
                      )),
                      backgroundColor: isCompletedToday 
                          ? Colors.green[600] 
                          : Theme.of(context).dividerColor.withOpacity(0.05),
                      padding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                      avatar: isCompletedToday 
                          ? const Icon(Icons.check_circle, size: 14, color: Colors.white) 
                          : null,
                      side: BorderSide(
                        color: isCompletedToday ? Colors.green[600]! : Colors.transparent,
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () {
                  PremiumAlert.show(
                    context,
                    title: "Abandon Challenge?",
                    message: "Your progress for this challenge will be lost.",
                    confirmLabel: "Abandon",
                    isDestructive: true,
                    icon: Icons.heart_broken_rounded,
                    onConfirm: () => life.deleteBundledGoal(goal['id']),
                  );
                },
                child: const Text("Remove", style: TextStyle(color: Colors.grey, fontSize: 12)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
