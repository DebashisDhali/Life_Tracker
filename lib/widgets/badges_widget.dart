import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/life_provider.dart';
import '../utils/constants.dart';

class BadgesWidget extends StatelessWidget {
  const BadgesWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final badges = Provider.of<LifeProvider>(context).earnedBadges;

    if (badges.isEmpty) {
      return Column(
        children: [
           Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Trophies", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                IconButton(
                  icon: const Icon(Icons.info_outline, size: 20, color: Colors.grey),
                  onPressed: () => _showBadgeInfo(context),
                  tooltip: "See All Badges",
                ),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 16.0),
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor.withOpacity(0.5),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.1)),
        ),
        child: Column(
          children: [
            Icon(Icons.emoji_events_outlined, color: Colors.grey[300], size: 30),
            const SizedBox(height: 8),
            Text(
              "Your Trophy Cabinet is Empty",
              style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color, fontSize: 14, fontWeight: FontWeight.bold),
            ),
            Text(
              "Complete habits to earn your first badge!",
              textAlign: TextAlign.center,
              style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color, fontSize: 12),
            ),
            ],
          ),
          ),
        ],
      );
    }

    return SizedBox(
      height: 85,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        itemCount: badges.length,
        itemBuilder: (context, index) {
          final badge = badges[index];
          
          List<Color> gradientColors;
          IconData icon = Icons.emoji_events_rounded;
          bool isRecord = badge.contains("High") || badge.contains("Elite");

          if (badge.contains("Elite")) {
            gradientColors = [const Color(0xFFFFD700), const Color(0xFFFFA500)];
          } else if (badge.contains("Productive")) {
            gradientColors = [const Color(0xFF4CAF50), const Color(0xFF2E7D32)];
          } else if (badge.contains("High")) {
            gradientColors = [const Color(0xFF6A1B9A), const Color(0xFF4527A0)];
            icon = Icons.auto_awesome_rounded;
          } else if (badge.contains("Master")) {
            gradientColors = [const Color(0xFFFFD700), const Color(0xFFFF8C00)];
          } else if (badge.contains("Expert")) {
            gradientColors = [const Color(0xFFB0BEC5), const Color(0xFF607D8B)];
          } else if (badge.contains("Consistent")) {
            gradientColors = [const Color(0xFFCD7F32), const Color(0xFF8D6E63)];
          } else {
            gradientColors = [const Color(0xFF64B5F6), const Color(0xFF1E88E5)];
          }

          return Container(
            margin: const EdgeInsets.only(right: 20.0),
            width: 65,
            child: Column(
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: gradientColors,
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: gradientColors.first.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: Icon(icon, size: 22, color: Colors.white),
                    ),
                    if (isRecord)
                      const Positioned(
                        right: 0,
                        top: 0,
                        child: Icon(Icons.star_rounded, size: 16, color: Colors.amber),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  badge,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                    fontWeight: FontWeight.bold,
                    fontSize: 9,
                    letterSpacing: 0.1,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showBadgeInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
             children: [
               Icon(Icons.emoji_events_rounded, color: Colors.amber),
               SizedBox(width: 10),
               Text("Badge Guide"),
             ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Daily Performance
                const Text("Daily Milestones", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                const SizedBox(height: 8),
                _buildBadgeItem(context, "Perfect Day", "100% completion of all habits", AppColors.sectionMoneyDark),
                _buildBadgeItem(context, "Elite Day", "90% completion of daily tasks", const Color(0xFFFFD700)),
                _buildBadgeItem(context, "Productive Day", "75% completion of daily tasks", const Color(0xFF4CAF50)),
                
                const Divider(height: 24),
                
                // Growth
                const Text("Growth & Records", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                const SizedBox(height: 8),
                _buildBadgeItem(context, "All-Time High", "Breaking your personal best record", const Color(0xFF6A1B9A)),
                _buildBadgeItem(context, "Level Up", "Surpassing yesterday's performance", Colors.orange),

                const Divider(height: 24),

                // Financial
                const Text("Financial Excellence", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                const SizedBox(height: 8),
                _buildBadgeItem(context, "Budget Master", "Staying within monthly budget (Awarded at month end)", const Color(0xFF00ACC1)),
                _buildBadgeItem(context, "On Track", "Daily spending within limit", Colors.green),

                const Divider(height: 24),

                // Streaks
                const Text("Consistency Streaks", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                const SizedBox(height: 8),
                _buildBadgeItem(context, "Consistent", "7 Day Streak in any section", const Color(0xFFCD7F32)),
                _buildBadgeItem(context, "Expert", "21 Day Streak in any section", const Color(0xFFB0BEC5)),
                _buildBadgeItem(context, "Master", "60 Day Streak in any section", const Color(0xFFFFD700)),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Got it"))
          ],
        );
      },
    );
  }

  Widget _buildBadgeItem(BuildContext context, String title, String desc, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.star, size: 16, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 13)),
                Text(desc, style: TextStyle(fontSize: 12, color: Theme.of(context).textTheme.bodyMedium?.color)),
              ],
            ),
          )
        ],
      ),
    );
  }
}
