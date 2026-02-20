import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/life_provider.dart';
import '../models/models.dart';
import '../utils/constants.dart';

import '../screens/profile_screen.dart';
import '../screens/bundled_goals_screen.dart';


class CustomDrawer extends StatelessWidget {
  const CustomDrawer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Theme.of(context).drawerTheme.backgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            _buildDrawerHeader(context),
            const SizedBox(height: 20),
            Expanded(
              child: Consumer<LifeProvider>(
                builder: (context, provider, child) {
                  if (provider.sections.isEmpty) {
                    return const Center(child: Text("Loading..."));
                  }
                  
                  return ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      Text(
                        "SECTIONS",
                        style: TextStyle(
                          color: Theme.of(context).textTheme.bodySmall?.color,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 12),
                      
                      ...provider.sections.map((section) => _buildSectionItem(context, section, provider)),
                      
                      const Divider(height: 40),
                      
                      _buildMenuItem(
                        context,
                        icon: Icons.history_rounded,
                        title: "History",
                        color: Colors.blue,
                        onTap: () async {
                          Navigator.pop(context);
                          final provider = Provider.of<LifeProvider>(context, listen: false);
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: provider.viewingDate,
                            firstDate: DateTime(2024),
                            lastDate: DateTime.now(),
                          );
                          if (picked != null) {
                            provider.setViewingDate(picked);
                          }
                        },
                      ),
                      _buildMenuItem(
                        context,
                        icon: Icons.emoji_events_rounded,
                        title: "Multi-day Challenges",
                        color: Colors.orange,
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const BundledGoalsScreen()));
                        },
                      ),
                      _buildMenuItem(
                        context,
                        icon: Icons.person_rounded,
                        title: "Profile",
                        color: AppColors.sectionSkillDark,
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
                        },
                      ),
                    ],
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Text(
                "v1.0.0 • Life Tracker",
                style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.sectionSkill, width: 2),
            ),
            child: CircleAvatar(
              radius: 28,
              backgroundColor: AppColors.sectionSkill,
              child: Text(
                Provider.of<LifeProvider>(context).userInitial,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  Provider.of<LifeProvider>(context).userName,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.titleLarge?.color,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  "Keep growing everyday",
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (Provider.of<LifeProvider>(context).lastBackupTime != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.cloud_done_rounded, size: 12, color: Colors.green.withOpacity(0.7)),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          'Synced: ${_formatBackupTime(Provider.of<LifeProvider>(context).lastBackupTime!)}',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: Colors.green.withOpacity(0.8),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatBackupTime(DateTime time) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final timeStr = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    if (time.isAfter(today)) return 'Today $timeStr';
    if (time.isAfter(yesterday)) return 'Yesterday $timeStr';
    return '${time.day}/${time.month} $timeStr';
  }

  Widget _buildSectionItem(BuildContext context, LifeSection section, LifeProvider provider) {
    IconData icon;
    Color color;

    switch (section.type) {
      case SectionType.body:
        icon = Icons.fitness_center_rounded;
        color = AppColors.sectionBody;
        break;
      case SectionType.mind:
        icon = Icons.psychology_rounded;
        color = AppColors.sectionMind;
        break;
      case SectionType.money:
        icon = Icons.account_balance_wallet_rounded;
        color = AppColors.sectionMoney;
        break;
      case SectionType.skill:
        icon = Icons.emoji_objects_rounded;
        color = AppColors.sectionSkill;
        break;
      case SectionType.relationship:
        icon = Icons.people_rounded;
        color = AppColors.sectionRelationship;
        break;
      case SectionType.dharma:
        icon = Icons.self_improvement_rounded;
        color = AppColors.sectionDharma;
        break;
      case SectionType.bcs:
        icon = Icons.menu_book_rounded;
        color = AppColors.sectionBCS;
        break;
      case SectionType.custom:
      default:
        icon = Icons.dashboard_customize_rounded;
        color = AppColors.sectionSkill; // Match Indigo
        break;
    }

    double progress = provider.getSectionProgress(section);
    bool isCompleted = progress >= 0.99;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.pop(context);
            // Expand the section corresponding to this item
            provider.toggleSectionExpansion(section, true);
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: section.isExpanded ? color.withOpacity(0.1) : Colors.transparent,
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        section.displayName,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: section.isExpanded ? color : Theme.of(context).textTheme.bodyLarge?.color,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: LinearProgressIndicator(
                          value: progress,
                          backgroundColor: Theme.of(context).brightness == Brightness.dark 
                        ? Colors.white.withOpacity(0.1) 
                        : Colors.grey.withOpacity(0.1),
                          color: color,
                          minHeight: 3,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isCompleted ? color.withOpacity(0.2) : Colors.grey.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isCompleted)
                        Icon(Icons.check_circle_rounded, color: color, size: 14),
                      if (isCompleted) const SizedBox(width: 4),
                      Text(
                        "${(progress * 100).toInt()}%",
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isCompleted ? color : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildMenuItem(BuildContext context, {
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600, 
          color: Theme.of(context).textTheme.bodyLarge?.color
        ),
      ),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }
}
