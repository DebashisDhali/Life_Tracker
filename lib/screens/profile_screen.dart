import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/life_provider.dart';
import '../providers/money_provider.dart';
import '../providers/theme_provider.dart';
import '../services/notification_service.dart';
import '../utils/constants.dart';
import 'manage_habits_screen.dart';
import 'money_screen.dart';
import '../widgets/finance_settings_dialog.dart';
import '../widgets/no_internet_widget.dart';
import '../widgets/premium_alert.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/constants.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isProcessing = false;

  Future<void> _handleAction(Future<dynamic> Function() action, String successMessage, String errorMessage) async {
    setState(() => _isProcessing = true);
    try {
      final result = await action();
      if (mounted) {
        bool isSuccess = result is bool ? result : true;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isSuccess ? successMessage : errorMessage),
            backgroundColor: isSuccess ? Colors.green : Colors.orange,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        _showConnectivityError(context, () {});
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _confirmSync(LifeProvider life) async {
    PremiumAlert.show(
      context,
      title: 'Sync to Cloud?',
      message: 'This will OVERWRITE your Firebase backup with current local data.\n\nIf your app shows no data, this will erase your cloud backup.',
      confirmLabel: 'Yes, Overwrite',
      isDestructive: true,
      icon: Icons.cloud_upload_rounded,
      onConfirm: () => _handleAction(
        () => life.backupToCloud(),
        'Data synced successfully!',
        'Sync failed. Please try again.',
      ),
    );
  }

  Future<void> _confirmRestore(LifeProvider life) async {
    PremiumAlert.show(
      context,
      title: 'Restore from Cloud?',
      message: 'This will replace all local data with your Firebase backup.\n\nYour current local data will be lost.',
      confirmLabel: 'Yes, Restore',
      icon: Icons.cloud_download_rounded,
      onConfirm: () async {
        setState(() => _isProcessing = true);
        try {
          final success = await life.restoreFromCloud();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(success ? '✅ Data restored successfully!' : '❌ No backup found in cloud.'),
                backgroundColor: success ? Colors.green : Colors.orange,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            );
            if (success) {
              Navigator.of(context).popUntil((route) => route.isFirst);
            }
          }
        } catch (e) {
          if (mounted) _showConnectivityError(context, () {});
        } finally {
          if (mounted) setState(() => _isProcessing = false);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final money = context.watch<MoneyProvider>();
    final life = context.watch<LifeProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    
    return Stack(
      children: [
        Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: RefreshIndicator(
            onRefresh: () async {
              await life.restoreFromCloud();
            },
            color: AppColors.sectionSkillDark,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
              // Pinned App Bar (title bar only, no fixed height)
              SliverAppBar(
                pinned: true,
                floating: false,
                expandedHeight: 0,
                toolbarHeight: 0,
                backgroundColor: themeProvider.isDarkMode
                    ? Colors.grey[900]
                    : AppColors.sectionSkillDark,
              ),

              // Profile Header — sizes itself to content, no overflow
              SliverToBoxAdapter(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        themeProvider.isDarkMode
                            ? Colors.grey[900]!
                            : AppColors.sectionSkillDark,
                        themeProvider.isDarkMode
                            ? Colors.black
                            : AppColors.sectionSkill,
                      ],
                    ),
                  ),
                  child: SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Profile Avatar
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.15),
                                  blurRadius: 16,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                life.userInitial,
                                style: TextStyle(
                                  fontSize: 36,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.sectionSkillDark,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          // User Name
                          Text(
                            life.userName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 3),
                          // Email
                          Text(
                            life.userEmail ?? 'Not logged in',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white.withOpacity(0.75),
                            ),
                          ),
                          const SizedBox(height: 10),
                          // Status badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.white.withOpacity(0.25)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  life.isLoggedIn ? Icons.verified_rounded : Icons.person_outline,
                                  color: Colors.white,
                                  size: 13,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  life.isLoggedIn ? 'Cloud Sync Active' : 'Not Logged In',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
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
              ),


              // Settings Content
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),

                      // Theme Section
                      _buildSectionTitle('Appearance'),
                      const SizedBox(height: 12),
                      _buildSettingsCard([
                        SwitchListTile(
                          title: const Text(
                            'Dark Mode',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Text(
                            themeProvider.isDarkMode ? 'Easy on the eyes' : 'Bright and clear',
                            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                          ),
                          secondary: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: (themeProvider.isDarkMode ? Colors.purpleAccent : Colors.orangeAccent).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                             child: Icon(
                              themeProvider.isDarkMode ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                              color: themeProvider.isDarkMode ? Colors.purpleAccent : Colors.orangeAccent,
                            ),
                          ),
                          value: themeProvider.isDarkMode,
                          onChanged: (value) {
                            themeProvider.toggleTheme();
                          },
                        ),
                      ]),
                      const SizedBox(height: 24),
                      
                      // Account Section
                      _buildSectionTitle('Account'),
                      const SizedBox(height: 12),
                       _buildSettingsCard([
                        _buildSettingsTile(
                          icon: Icons.cloud_download_rounded,
                          title: 'Restore from Cloud',
                          subtitle: 'Pull your saved data from Firebase',
                          onTap: () => _confirmRestore(life),
                        ),
                        const Divider(height: 1),
                        _buildSettingsTile(
                          icon: Icons.cloud_sync_rounded,
                          title: 'Sync to Cloud',
                          subtitle: 'Backup local data (overwrites cloud)',
                          onTap: () => _confirmSync(life),
                        ),
                      ]),
                      const SizedBox(height: 24),

                      // Habits & Goals
                      _buildSectionTitle('Habits & Goals'),
                      const SizedBox(height: 12),
                      _buildSettingsCard([
                        _buildSettingsTile(
                          icon: Icons.edit_note_rounded,
                          title: 'Manage Habits',
                          subtitle: 'Add, edit, or remove habits',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const ManageHabitsScreen()),
                            );
                          },
                        ),
                      ]),
                      const SizedBox(height: 24),

                      // Money Settings
                      _buildSectionTitle('Money Management'),
                      const SizedBox(height: 12),
                      _buildSettingsCard([
                        _buildSettingsTile(
                          icon: Icons.account_balance_wallet_rounded,
                          title: 'Financial Goals',
                          subtitle: 'Budget: ৳${money.settings.monthlyBudget.toStringAsFixed(0)} • Daily: ৳${money.settings.dailyTarget.toStringAsFixed(0)}',
                          onTap: () {
                             showDialog(
                              context: context,
                              builder: (context) => const FinanceSettingsDialog(),
                            );
                          },
                        ),
                      ]),
                      const SizedBox(height: 24),

                      // Notifications
                      _buildSectionTitle('Notifications'),
                      const SizedBox(height: 12),
                      _buildSettingsCard([
                        _buildSettingsTile(
                          icon: Icons.bedtime_rounded,
                          title: 'Sleep Time',
                          subtitle: _formatTime(life.sleepHour, life.sleepMinute),
                          onTap: () => _showSleepTimePicker(context, life),
                        ),
                        const Divider(height: 1),
                        _buildSettingsTile(
                          icon: Icons.wb_sunny_rounded,
                          title: 'Wake Time',
                          subtitle: _formatTime(life.wakeHour, life.wakeMinute),
                          onTap: () => _showWakeTimePicker(context, life),
                        ),
                      ]),
                      const SizedBox(height: 24),

                      // Data Management
                      _buildSectionTitle('Data Management'),
                      const SizedBox(height: 12),
                      _buildSettingsCard([
                        _buildSettingsTile(
                          icon: Icons.refresh_rounded,
                          title: 'Reset All Data',
                          subtitle: 'Clear all habits and start fresh',
                          iconColor: Colors.orange,
                          onTap: () => _showResetDialog(context, money, life),
                        ),
                      ]),
                      const SizedBox(height: 24),

                      _buildSettingsCard([
                        _buildSettingsTile(
                          icon: Icons.logout_rounded,
                          title: 'Logout',
                          subtitle: 'Sign out from your account',
                          iconColor: Colors.red,
                          onTap: () {
                            PremiumAlert.show(
                              context,
                              title: 'Logout',
                              message: 'Are you sure you want to sign out from your account?',
                              confirmLabel: 'Logout',
                              isDestructive: true,
                              icon: Icons.logout_rounded,
                              onConfirm: () async {
                                await life.logout();
                              },
                            );
                          },
                        ),
                      ]),
                      const SizedBox(height: 32),
                      // Account info card at bottom
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Theme.of(context).dividerColor.withOpacity(0.1),
                          ),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Icon(Icons.account_circle_outlined,
                                  size: 16,
                                  color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.5)),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    life.userEmail ?? 'Not logged in',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.6),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (life.lastBackupTime != null) ...[
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(Icons.cloud_done_outlined,
                                    size: 16,
                                    color: Colors.green.withOpacity(0.7)),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Last synced: ${_formatBackupTime(life.lastBackupTime!)}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.green.withOpacity(0.8),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Center(
                        child: Text(
                          'Life Tracker v1.0.0',
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.4),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
        
        // Loading Overlay
        if (_isProcessing)
          Container(
            color: Colors.black.withOpacity(0.5),
            child: Center(
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.sectionSkillDark),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Processing...',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).textTheme.titleMedium?.color,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  String _formatBackupTime(DateTime time) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final timeStr = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    if (time.isAfter(today)) return 'Today $timeStr';
    if (time.isAfter(yesterday)) return 'Yesterday $timeStr';
    return '${time.day}/${time.month}/${time.year} $timeStr';
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).textTheme.titleSmall?.color,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildSettingsCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? iconColor,
  }) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: (iconColor ?? AppColors.sectionSkillDark).withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          color: iconColor ?? AppColors.sectionSkillDark,
          size: 24,
        ),
      ),
      title: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: Theme.of(context).textTheme.bodyMedium,
      ),
      trailing: Icon(
        Icons.chevron_right_rounded,
        color: Colors.grey[400],
      ),
    );
  }

  String _formatTime(int hour, int minute) {
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '${displayHour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} $period';
  }

  Future<void> _showSleepTimePicker(BuildContext context, LifeProvider life) async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: life.sleepHour, minute: life.sleepMinute),
    );
    if (time != null) {
      life.updateSleepTime(time.hour, time.minute);
    }
  }

  Future<void> _showWakeTimePicker(BuildContext context, LifeProvider life) async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: life.wakeHour, minute: life.wakeMinute),
    );
    if (time != null) {
      life.updateWakeTime(time.hour, time.minute);
    }
  }

  Future<void> _showResetDialog(BuildContext context, MoneyProvider money, LifeProvider life) async {
    PremiumAlert.show(
      context,
      title: 'Reset All Data?',
      message: 'This will delete all your habits, progress, and money entries. This action cannot be undone!',
      confirmLabel: 'Reset Everything',
      isDestructive: true,
      icon: Icons.warning_amber_rounded,
      onConfirm: () async {
        await money.resetData();
        await life.resetData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('All data has been reset'),
              backgroundColor: Colors.orange,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
    );
  }

  void _showConnectivityError(BuildContext context, VoidCallback onRetry) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: NoInternetWidget(
          onRetry: () {
            Navigator.pop(context);
            onRetry();
          },
        ),
      ),
    );
  }
}
