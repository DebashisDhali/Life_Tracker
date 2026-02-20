import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Added
import '../providers/life_provider.dart';
import '../models/models.dart';
import '../utils/constants.dart';
import '../widgets/section_card.dart';
import '../widgets/weekly_chart.dart';
import '../widgets/badges_widget.dart';
import '../widgets/navigation_drawer.dart'; 
import 'bundled_goals_screen.dart';
import 'auth_screen.dart';
import '../screens/achievement_details_screen.dart';
import '../widgets/celebration_overlay.dart';
import 'reminder_setup_screen.dart'; // Added

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _hasCheckedReminders = false;

  Future<void> _checkReminderSetup(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final bool completed = prefs.getBool('reminder_setup_complete') ?? false;
    
    // Only show if not completed
    if (!completed && mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ReminderSetupScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final life = Provider.of<LifeProvider>(context);

    String greeting = "Hello";
    int hour = DateTime.now().hour;
    if (hour < 12) greeting = "Good Morning";
    else if (hour < 17) greeting = "Good Afternoon";
    else greeting = "Good Evening";

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      drawer: const CustomDrawer(),
      body: GestureDetector(
        onTap: () {
           Provider.of<LifeProvider>(context, listen: false).collapseAllSections();
        },
        child: Consumer<LifeProvider>(
          builder: (context, provider, child) {
            
          // Check for growth milestone
          if (provider.hasJustCrossedGrowthThreshold) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              CelebrationHelper.show(
                context, 
                provider.milestoneMessage.isNotEmpty 
                  ? provider.milestoneMessage 
                  : "Higher Growth!\nYou've surpassed yesterday's progress!"
              );
              provider.acknowledgeGrowthMilestone(); // Prevent repeat
            });
          }

          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          // At this point we are logged in, but if sections are empty, we might be restoring or a new user.
          if (provider.sections.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text("Preparing your dashboard..."),
                ],
              ),
            );
          }

          // ** Notification/Reminder Setup Check **
          // Check only once per session when data is ready
          if (!_hasCheckedReminders) {
             _hasCheckedReminders = true;
             WidgetsBinding.instance.addPostFrameCallback((_) => _checkReminderSetup(context));
          }

          return SafeArea(
            child: RefreshIndicator(
              onRefresh: () async {
                await provider.restoreFromCloud();
              },
              color: AppColors.sectionSkillDark,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 32.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildCustomHeader(context, greeting),

                  const SizedBox(height: 12),
                  
                  _buildDashboardStats(context, provider),

                  Builder(
                    builder: (context) {
                      final completionPlot = provider.todayCompletionPercentage;
                      if (completionPlot != -1.0) {
                        return Column(
                          children: [
                            const SizedBox(height: 24),
                            const WeeklyChart(),
                            
                            const SizedBox(height: 24),
                            
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16.0),
                              child: InkWell(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => const AchievementDetailsScreen()),
                                  );
                                },
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      "Your Achievements",
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(context).textTheme.titleLarge?.color,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        Text(
                                          "View Info",
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: AppColors.sectionSkillDark,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        Icon(Icons.chevron_right_rounded, color: AppColors.sectionSkillDark, size: 18),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            const BadgesWidget(),

                            if (provider.bundledGoals.isNotEmpty) ...[
                              const SizedBox(height: 24),
                              _buildActiveChallengesPreview(context, provider),
                            ],

                            const SizedBox(height: 24),
                            
                            // Only show the expanded section, if any
                            ...provider.sections.where((s) => s.isExpanded).map((section) {
                              Color sectionColor;
                              switch (section.type) {
                                case SectionType.body: sectionColor = AppColors.sectionBody; break;
                                case SectionType.mind: sectionColor = AppColors.sectionMind; break;
                                case SectionType.money: sectionColor = AppColors.sectionMoney; break;
                                case SectionType.skill: sectionColor = AppColors.sectionSkill; break;
                                case SectionType.relationship: sectionColor = AppColors.sectionRelationship; break;
                                case SectionType.dharma: sectionColor = AppColors.sectionDharma; break;
                                case SectionType.bcs: sectionColor = AppColors.sectionBCS; break;
                                case SectionType.custom:
                                default:
                                  sectionColor = AppColors.sectionSkill; break;
                              }
                              
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                                    child: Text(
                                      section.displayName,
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(context).textTheme.titleLarge?.color,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                  SectionCard(
                                    key: ValueKey(section.id),
                                    section: section,
                                    baseColor: sectionColor,
                                  ),
                                ],
                              );
                            }).toList(),
                            
                            if (!provider.sections.any((s) => s.isExpanded))
                              Padding(
                                padding: const EdgeInsets.all(32.0),
                                child: Center(
                                  child: Text(
                                    "Select a category from the menu to view details",
                                    style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                          ],
                        );
                      } else {
                        return Center(
                          child: Column(
                            children: [
                              const SizedBox(height: 60),
                              Icon(Icons.hotel_class_rounded, size: 80, color: Colors.blue.withOpacity(0.5)),
                              const SizedBox(height: 16),
                              const Text(
                                "Today is your REST DAY",
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "Relax, recharge, and enjoy your time off!",
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Theme.of(context).textTheme.bodySmall?.color,
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
        ),
      ),
    );
  }

  Widget _buildCustomHeader(BuildContext context, String greeting) {
    return Consumer<LifeProvider>(
      builder: (context, provider, child) {
        final viewingDate = provider.viewingDate;
        final isToday = provider.isViewingToday;
        
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Row(
            children: [
              InkWell(
                onTap: () {
                  _scaffoldKey.currentState?.openDrawer();
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(Icons.sort_rounded, size: 26, color: Theme.of(context).textTheme.titleLarge?.color),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isToday 
                        ? "$greeting, ${provider.userName}" 
                        : "History: ${DateFormat('MMM d').format(viewingDate)}",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).textTheme.titleLarge?.color,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('EEEE, MMM d, yyyy').format(viewingDate),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).textTheme.bodySmall?.color,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.calendar_month, color: AppColors.sectionSkillDark),
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: viewingDate,
                    firstDate: DateTime(2024),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) {
                    provider.setViewingDate(picked);
                  }
                },
              ),
              if (!isToday)
                IconButton(
                  icon: const Icon(Icons.today, color: Colors.green),
                  tooltip: "Back to Today",
                  onPressed: () => provider.setViewingDate(DateTime.now()),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDashboardStats(BuildContext context, LifeProvider provider) {
    double completion = provider.todayCompletionPercentage;
    bool isOff = completion == -1.0;
    
    String statusText = isOff ? "Rest Mode" : "Let's Start";
    Color statusColor = isOff ? Colors.blue : AppColors.textSecondary;

    if (!isOff) {
      if (completion >= 1.0) {
        statusText = "Perfect Day!";
        statusColor = AppColors.sectionMoneyDark;
      } else if (completion >= 0.75) {
        statusText = "Almost There";
        statusColor = AppColors.sectionSkillDark;
      } else if (completion >= 0.5) {
        statusText = "Good Progress";
        statusColor = AppColors.sectionMindDark;
      } else if (completion > 0) {
        statusText = "Keep Going";
        statusColor = AppColors.sectionBodyDark;
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 40,
              spreadRadius: 0,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            CircularPercentIndicator(
              radius: 45.0,
              lineWidth: 10.0,
              animation: true,
              animateFromLastPercent: true,
              animationDuration: 800,
              percent: isOff ? 0.0 : (completion > 1.0 ? 1.0 : completion),
              center: isOff 
                ? const Icon(Icons.hotel_rounded, color: Colors.blue, size: 24)
                : Text(
                    "${(completion * 100).toStringAsFixed(0)}%",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18.0, color: Theme.of(context).textTheme.titleLarge?.color),
                  ),
              circularStrokeCap: CircularStrokeCap.round,
              progressColor: statusColor,
              backgroundColor: Theme.of(context).dividerColor.withOpacity(0.05),
            ),
            const SizedBox(width: 24),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Daily Goal",
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodySmall?.color,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    statusText,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.titleLarge?.color,
                    ),
                  ),
                  const SizedBox(height: 8),
                   Row(
                     children: [
                       const Icon(Icons.local_fire_department_rounded, size: 16, color: Colors.orangeAccent),
                       const SizedBox(width: 4),
                          Text(
                            "${provider.activityStreak} Day Streak", 
                            style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color, fontSize: 11, fontWeight: FontWeight.w600),
                          ),
                       const SizedBox(width: 12),
                       Container(width: 1, height: 10, color: Theme.of(context).dividerColor),
                       const SizedBox(width: 12),
                       const Icon(Icons.auto_awesome_rounded, size: 14, color: Color(0xFF6A1B9A)),
                       const SizedBox(width: 4),
                       Builder(
                         builder: (context) {
                            final pb = (provider.personalBest * 100).toStringAsFixed(0);
                            return Text(
                              "Best: $pb%",
                              style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color, fontSize: 11, fontWeight: FontWeight.w600),
                            );
                         }
                       ),
                     ],
                   ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveChallengesPreview(BuildContext context, LifeProvider provider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Active Challenges",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.titleLarge?.color,
                ),
              ),
              InkWell(
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const BundledGoalsScreen()));
                },
                child: Text(
                  "See All",
                  style: TextStyle(fontSize: 12, color: AppColors.sectionSkillDark, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: provider.bundledGoals.map((goal) {
                final streak = provider.calculateBundledGoalStreak(goal);
                final target = goal['targetDays'] as int;
                final bool isAchieved = goal['isAchieved'] ?? false;
                
                return InkWell(
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const BundledGoalsScreen()));
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    width: 200,
                    margin: const EdgeInsets.only(right: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.sectionSkill.withOpacity(0.1)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                goal['title'],
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                            ),
                            if (isAchieved) const Icon(Icons.check_circle, color: Colors.green, size: 14),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          isAchieved ? "CHALLENGE COMPLETED!" : "$streak / $target days",
                          style: TextStyle(fontSize: 10, color: isAchieved ? Colors.green : AppColors.textSecondary, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 6),
                        LinearProgressIndicator(
                          value: (streak / target).clamp(0.0, 1.0),
                          backgroundColor: AppColors.sectionSkill.withOpacity(0.05),
                          color: isAchieved ? Colors.green : AppColors.sectionSkill,
                          minHeight: 4,
                        ),
                      ],
                    ),
                  ),
                );
              }).take(3).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
