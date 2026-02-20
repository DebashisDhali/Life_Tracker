import 'package:flutter/material.dart';
import '../utils/constants.dart';

class AchievementDetailsScreen extends StatelessWidget {
  const AchievementDetailsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("App Badges & Awards"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Theme.of(context).textTheme.titleLarge?.color,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoCard(
              context,
              title: "Daily Awards",
              description: "Earn these by completing your habits every day.",
              achievements: [
                _AchievementInfo(
                  name: "Elite Day",
                  requirement: "Complete 90% or more of all daily habits.",
                  color: AppColors.gold,
                  icon: Icons.auto_awesome,
                ),
                _AchievementInfo(
                  name: "Productive Day",
                  requirement: "Complete 70% to 89% of all daily habits.",
                  color: Colors.green,
                  icon: Icons.trending_up,
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildInfoCard(
              context,
              title: "Section Streaks",
              description: "Maintain a daily streak in specific life areas to earn these titles.",
              achievements: [
                _AchievementInfo(
                  name: "Category Master",
                  requirement: "Maintain a 60-day streak in any category.",
                  color: AppColors.gold,
                  icon: Icons.workspace_premium,
                ),
                _AchievementInfo(
                  name: "Category Expert",
                  requirement: "Maintain a 21-day streak in any category.",
                  color: AppColors.silver,
                  icon: Icons.star_rounded,
                ),
                _AchievementInfo(
                  name: "Category Consistent",
                  requirement: "Maintain a 7-day streak in any category.",
                  color: AppColors.bronze,
                  icon: Icons.check_circle_rounded,
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildInfoCard(
              context,
              title: "Multi-day Challenges",
              description: "Group habits together and maintain consistency for several days.",
              achievements: [
                _AchievementInfo(
                  name: "Challenge Conqueror",
                  requirement: "Complete all habits in a multi-day challenge for the full duration.",
                  color: Colors.blueAccent,
                  icon: Icons.rocket_launch,
                ),
              ],
            ),
            const SizedBox(height: 32),
            Center(
              child: Text(
                "Keep growing every day!",
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontStyle: FontStyle.italic,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(
    BuildContext context, {
    required String title,
    required String description,
    required List<_AchievementInfo> achievements,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).textTheme.titleLarge?.color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: TextStyle(
              fontSize: 13,
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
          ),
          const SizedBox(height: 20),
          ...achievements.map((a) => _buildAchievementRow(context, a)).toList(),
        ],
      ),
    );
  }

  Widget _buildAchievementRow(BuildContext context, _AchievementInfo a) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: a.color.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(a.icon, color: a.color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  a.name,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  a.requirement,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).textTheme.bodySmall?.color,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AchievementInfo {
  final String name;
  final String requirement;
  final Color color;
  final IconData icon;

  _AchievementInfo({
    required this.name,
    required this.requirement,
    required this.color,
    required this.icon,
  });
}
