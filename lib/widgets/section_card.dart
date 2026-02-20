import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/life_provider.dart';
import '../utils/constants.dart';
import 'habit_tile.dart';
import 'money_ledger_section.dart';
import '../providers/theme_provider.dart';

class SectionCard extends StatefulWidget {
  final LifeSection section;
  final Color baseColor;

  const SectionCard({Key? key, required this.section, required this.baseColor}) : super(key: key);

  @override
  State<SectionCard> createState() => _SectionCardState();
}

class _SectionCardState extends State<SectionCard> {
  final ExpansionTileController _controller = ExpansionTileController();

  @override
  Widget build(BuildContext context) {
    return Consumer<LifeProvider>(
      builder: (context, provider, child) {
        // Safe accordion logic: Check state and animate if needed
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (widget.section.isExpanded) {
             _controller.expand();
          } else {
             _controller.collapse();
          }
        });

        int streak = provider.calculateSectionStreak(widget.section);
        Color streakColor = Colors.grey;
        if (streak >= 60) streakColor = AppColors.gold;
        else if (streak >= 21) streakColor = AppColors.silver;
        else if (streak >= 7) streakColor = AppColors.bronze;

        bool isDark = Provider.of<ThemeProvider>(context).isDarkMode;
        Color startColor = isDark ? Color.lerp(widget.baseColor, Colors.black, 0.7)! : widget.baseColor;
        Color endColor = isDark ? Color.lerp(widget.baseColor, Colors.black, 0.85)! : widget.baseColor.withOpacity(0.85);

        return Container(
          margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [startColor, endColor],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: isDark ? Colors.black.withOpacity(0.3) : widget.baseColor.withOpacity(0.4),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: ExpansionTile(
              controller: _controller,
              initiallyExpanded: widget.section.isExpanded,
              onExpansionChanged: (expanded) {
                 provider.toggleSectionExpansion(widget.section, expanded);
              },
              backgroundColor: Colors.transparent,
              collapsedBackgroundColor: Colors.transparent,
              tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              childrenPadding: const EdgeInsets.only(bottom: 12),
              title: Row(
                children: [
                  // Section Icon
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _getSectionIcon(widget.section.type),
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 14),
                  // Section Name
                  Expanded(
                    child: Text(
                      widget.section.displayName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 19,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  // Streak Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withOpacity(0.4), width: 1.5),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.local_fire_department, color: streakColor, size: 18),
                          const SizedBox(width: 4),
                          Text(
                            '$streak',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 6, left: 50),
                child: Text(
                  '${(provider.getSectionProgress(widget.section) * 100).toStringAsFixed(0)}% Section Growth',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.85),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              iconColor: Colors.white,
              collapsedIconColor: Colors.white,
              children: [
                // Habits List
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.12),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    children: [
                      // Special Money Section Content - Highlighted at top
                      if (widget.section.type == SectionType.money)
                        const MoneyLedgerSection(),
                      
                      // Habits List
                      ...widget.section.habits.map((habit) => HabitTile(
                        habit: habit,
                        baseColor: widget.baseColor,
                        section: widget.section,
                      )).toList(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }
    );
  }

  IconData _getSectionIcon(SectionType type) {
    switch (type) {
      case SectionType.body:
        return Icons.fitness_center;
      case SectionType.mind:
        return Icons.psychology;
      case SectionType.money:
        return Icons.account_balance_wallet;
      case SectionType.skill:
        return Icons.emoji_objects;
      case SectionType.relationship:
        return Icons.people;
      case SectionType.dharma:
        return Icons.self_improvement;
      case SectionType.bcs:
        return Icons.menu_book;
      case SectionType.custom:
      default:
        return Icons.dashboard_customize_rounded;
    }
  }
}
