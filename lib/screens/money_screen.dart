import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/money_provider.dart';
import '../providers/life_provider.dart';
import '../models/models.dart';
import '../utils/constants.dart';
import '../widgets/add_money_entry_dialog.dart';
import '../widgets/finance_settings_dialog.dart';
import '../widgets/premium_button.dart';
import '../widgets/premium_alert.dart';

class MoneyScreen extends StatefulWidget {
  const MoneyScreen({super.key});

  @override
  State<MoneyScreen> createState() => _MoneyScreenState();
}

class _MoneyScreenState extends State<MoneyScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {}); // Update header when tab changes
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final moneyProvider = Provider.of<MoneyProvider>(context);
    final historyEntries = moneyProvider.entries.where((e) => e.status == MoneyEntryStatus.completed).toList();
    final ledgerEntries = moneyProvider.entries.where((e) => e.status == MoneyEntryStatus.pending).toList();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Finance Manager', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Theme.of(context).cardColor,
        elevation: 0,
        foregroundColor: Theme.of(context).textTheme.titleLarge?.color,
        actions: [
          IconButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => const FinanceSettingsDialog(),
              );
            },
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Finance Settings',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          _buildContextualHeader(moneyProvider),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              height: 45,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark 
                  ? Colors.white.withOpacity(0.05) 
                  : Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2)),
                  ],
                ),
                labelColor: AppColors.sectionMoneyDark,
                unselectedLabelColor: AppColors.textSecondary,
                labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                tabs: const [
                  Tab(text: 'History'),
                  Tab(text: 'Ledger (Pabo/Debo)'),
                ],
              ),
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildHistoryView(historyEntries, moneyProvider),
                _buildLedgerView(ledgerEntries, moneyProvider),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: PremiumFAB(
        onPressed: () => showDialog(
          context: context, 
          barrierColor: Colors.black.withValues(alpha: 0.6),
          builder: (_) => const AddMoneyEntryDialog()
        ),
        label: "Add Record",
        icon: Icons.add_rounded,
        colors: const [AppColors.sectionMoneyDark, AppColors.sectionMoney],
      ),
    );
  }

  Widget _buildContextualHeader(MoneyProvider provider) {
    final isHistory = _tabController.index == 0;
    final headerColor = isHistory ? AppColors.sectionMoneyDark : Colors.indigo.shade700;
    
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [headerColor, headerColor.withValues(alpha: 0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: headerColor.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            isHistory ? 'BUDGET REMAINING' : 'TOTAL PABO / DEBO',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7), 
              fontSize: 11, 
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              isHistory 
                ? '${provider.monthlyRemaining.toStringAsFixed(0)} ৳'
                : '${(provider.totalReceivable - provider.totalPayable).toStringAsFixed(0)} ৳',
              style: const TextStyle(
                color: Colors.white, 
                fontSize: 38, 
                fontWeight: FontWeight.bold, 
                letterSpacing: 0.5
              ),
            ),
          ),
          if (isHistory) ...[
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'Investment: ${provider.investmentTotal.toStringAsFixed(0)} ৳',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _buildHeaderItem(
                  'Spent Today',
                  provider.todaysTotalExpense,
                  Icons.today_rounded,
                  Colors.white.withValues(alpha: 0.9),
                ),
              ),
              Container(width: 1, height: 40, color: Colors.white.withValues(alpha: 0.15)),
              Expanded(
                child: _buildHeaderItem(
                  'This Month',
                  provider.monthlyExpense,
                  Icons.calendar_month_rounded,
                  Colors.white.withValues(alpha: 0.9),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderItem(String label, double amount, IconData icon, Color color) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label.toUpperCase(), 
                style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 10, fontWeight: FontWeight.bold),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            '${amount.toStringAsFixed(0)} ৳',
            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryView(List<MoneyEntry> entries, MoneyProvider provider) {
    return RefreshIndicator(
      onRefresh: () async {
        await Provider.of<LifeProvider>(context, listen: false).restoreFromCloud();
      },
      color: AppColors.sectionMoneyDark,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            sliver: SliverToBoxAdapter(child: _buildBudgetTrackingCards(provider)),
          ),
          SliverToBoxAdapter(child: const SizedBox(height: 16)),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: _buildSliverTransactionList(entries, provider, 'No transactions found'),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 80)), // Space for FAB
        ],
      ),
    );
  }

  Widget _buildBudgetTrackingCards(MoneyProvider provider) {
    final daily = provider.settings.dailyTarget;
    final todaySpent = provider.todaysGeneralExpense;
    final isOverDaily = todaySpent > daily;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _buildTrackingCard(
                'Today\'s Budget',
                '$todaySpent / $daily ৳',
                todaySpent / daily,
                isOverDaily ? Colors.red : Colors.green,
                isOverDaily ? Icons.warning_rounded : Icons.check_circle_rounded,
                isOverDaily ? 'Limit Crossed!' : 'Under Control',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildTrackingCard(
                'Monthly Budget',
                '${provider.monthlyExpense.toInt()} / ${provider.settings.monthlyBudget.toInt()} ৳',
                provider.monthlyExpense / provider.settings.monthlyBudget,
                Colors.blue,
                Icons.calendar_month,
                '${((provider.settings.monthlyBudget - provider.monthlyExpense)).toInt()} Remaining',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildMiniAllocationCard(
                'Binodon Fund',
                provider.entertainmentBalance,
                provider.settings.entertainmentAllocation,
                Colors.purple,
                Icons.movie_filter_rounded
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMiniAllocationCard(
                'Emergency Fund',
                provider.emergencyBalance,
                provider.settings.emergencyAllocation,
                Colors.orange,
                Icons.health_and_safety_rounded
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildInvestmentCard(MoneyProvider provider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.indigo.shade400, Colors.indigo.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.indigo.withValues(alpha: 0.2), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.trending_up_rounded, color: Colors.white),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Total Investment', style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold)),
                Text('${provider.investmentTotal.toStringAsFixed(0)} ৳', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrackingCard(String title, String value, double progress, Color color, IconData icon, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title, 
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value, 
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              backgroundColor: color.withValues(alpha: 0.1),
              color: color,
              minHeight: 4,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle, 
            style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildMiniAllocationCard(String title, double remaining, double total, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title, 
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${remaining.toInt()} ৳ Left', 
                  style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverTransactionList(List<MoneyEntry> entries, MoneyProvider provider, String emptyMsg) {
    if (entries.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.only(top: 60),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(color: Colors.grey.withValues(alpha: 0.05), shape: BoxShape.circle),
                  child: Icon(Icons.receipt_long_rounded, size: 64, color: Colors.grey.shade300),
                ),
                const SizedBox(height: 16),
                Text(emptyMsg, style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final entry = entries[index];
          final isHistory = entry.status == MoneyEntryStatus.completed;
          final isIncome = entry.type == MoneyEntryType.income;
          
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) => AddMoneyEntryDialog(entry: entry),
                  );
                },
                onLongPress: () => _confirmDelete(context, provider, entry),
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      _buildTypeIndicator(entry),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              entry.title, 
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Theme.of(context).textTheme.bodyLarge?.color),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Text(DateFormat('MMM d').format(entry.date), style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                                if ((entry.category ?? 'General') != 'General' && isHistory) ...[
                                  Container(width: 3, height: 3, margin: const EdgeInsets.symmetric(horizontal: 6), decoration: BoxDecoration(color: Colors.grey.shade300, shape: BoxShape.circle)),
                                  Text(
                                    entry.category ?? 'General', 
                                    style: TextStyle(
                                      fontSize: 10, 
                                      color: ((entry.category ?? 'General') == 'Entertainment' ? Colors.purple : ((entry.category ?? 'General') == 'Emergency' ? Colors.orange : Colors.indigo)).withValues(alpha: 0.8), 
                                      fontWeight: FontWeight.bold
                                    )
                                  ),
                                ],
                                if (!isHistory) ...[
                                  Container(width: 3, height: 3, margin: const EdgeInsets.symmetric(horizontal: 6), decoration: BoxDecoration(color: Colors.grey.shade300, shape: BoxShape.circle)),
                                  Text(
                                    isIncome ? 'I will Get' : 'I will Give',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: isIncome ? Colors.blue : Colors.orange,
                                      fontWeight: FontWeight.bold
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${isIncome ? '+' : '-'}${entry.amount.toStringAsFixed(0)} ৳',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: isIncome ? AppColors.income : AppColors.expense,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          if (!isHistory) 
                            _buildStatusLabel(entry)
                          else
                            const Icon(Icons.check_circle_rounded, size: 14, color: Colors.green),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
        childCount: entries.length,
      ),
    );
  }

  Widget _buildStatusLabel(MoneyEntry entry) {
     return Container(
        margin: const EdgeInsets.only(top: 2),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
        decoration: BoxDecoration(
          color: (entry.type == MoneyEntryType.income ? Colors.blue : Colors.orange).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          entry.type == MoneyEntryType.income ? 'Receivable' : 'Payable',
          style: TextStyle(fontSize: 8, color: entry.type == MoneyEntryType.income ? Colors.blue : Colors.orange, fontWeight: FontWeight.bold),
        ),
     );
  }

  Widget _buildTypeIndicator(MoneyEntry entry) {
    final color = entry.type == MoneyEntryType.income ? AppColors.income : AppColors.expense;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(
        entry.type == MoneyEntryType.income ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
        color: color,
        size: 20,
      ),
    );
  }

  void _showDetailedEntry(BuildContext context, MoneyProvider provider, MoneyEntry entry) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Borrowed from / Debo',
                  style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold),
                ),
                IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
              ],
            ),
            const SizedBox(height: 4),
            Text(entry.title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark 
                  ? Colors.white.withOpacity(0.05) 
                  : Colors.grey.shade100, 
                borderRadius: BorderRadius.circular(16)
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Amount', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                  Text(
                    '${entry.amount.toStringAsFixed(0)} ৳',
                    style: const TextStyle(
                      fontSize: 24, 
                      fontWeight: FontWeight.bold, 
                      color: AppColors.expense
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.sectionMoneyDark,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                onPressed: () {
                  // When settling, we update the date to 'Today' 
                  // so it properly reflects in today's cash flow.
                  provider.updateEntryStatus(entry, MoneyEntryStatus.completed, updateDate: true);
                  Navigator.pop(context);
                },
                child: Text(
                  entry.type == MoneyEntryType.income ? 'I Received Money (Settle)' : 'I Paid them (Settle)', 
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)
                ),
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: TextButton(
                onPressed: () {
                   Navigator.pop(context);
                   _confirmDelete(context, provider, entry);
                },
                child: const Text('Delete Permanently', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLedgerView(List<MoneyEntry> entries, MoneyProvider provider) {
    if (entries.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: Colors.indigo.withValues(alpha: 0.05), shape: BoxShape.circle),
              child: Icon(Icons.rule_folder_rounded, size: 64, color: Colors.indigo.shade200),
            ),
            const SizedBox(height: 16),
            const Text('Your ledger is empty', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500)),
          ],
        ),
      );
    }

    final deboEntries = entries.where((e) => e.type == MoneyEntryType.expense).toList();
    final paboEntries = entries.where((e) => e.type == MoneyEntryType.income).toList();

    return RefreshIndicator(
      onRefresh: () async {
        await Provider.of<LifeProvider>(context, listen: false).restoreFromCloud();
      },
      color: AppColors.sectionMoneyDark,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverToBoxAdapter(child: _buildLedgerSummaryCards(provider)),
          ),
          if (paboEntries.isNotEmpty) ...[
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverToBoxAdapter(child: _buildSectionHeader('I will Get (পাবো)', Colors.blue)),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 12)),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: _buildSliverTransactionList(paboEntries, provider, 'No receivables'),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
          if (deboEntries.isNotEmpty) ...[
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverToBoxAdapter(child: _buildSectionHeader('I will Give (দেবো)', Colors.orange)),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 12)),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: _buildSliverTransactionList(deboEntries, provider, 'No payables'),
            ),
          ],
          if (deboEntries.isEmpty && paboEntries.isEmpty) 
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle_outline_rounded, size: 48, color: Colors.green.withValues(alpha: 0.3)),
                    const SizedBox(height: 12),
                    const Text('No pending entries!', style: TextStyle(color: Colors.grey, fontSize: 13)),
                  ],
                ),
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
    );
  }

  Widget _buildLedgerSummaryCards(MoneyProvider provider) {
    return Row(
      children: [
        Expanded(
          child: _buildMiniSummaryCard(
            'TOTAL PABO', 
            provider.totalReceivable, 
            Colors.blue, 
            Icons.call_received_rounded
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildMiniSummaryCard(
            'TOTAL DEBO', 
            provider.totalPayable, 
            Colors.orange, 
            Icons.call_made_rounded
          ),
        ),
      ],
    );
  }

  Widget _buildMiniSummaryCard(String label, double amount, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.12), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: 8),
          Text(label, style: TextStyle(color: AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              '${amount.toStringAsFixed(0)} ৳',
              style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, Color color) {
    return Row(
      children: [
        Container(width: 4, height: 16, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 8),
        Text(
          title, 
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Theme.of(context).textTheme.titleLarge?.color)
        ),
      ],
    );
  }

  void _confirmDelete(BuildContext context, MoneyProvider provider, MoneyEntry entry) {
    PremiumAlert.show(
      context,
      title: 'Delete Record?',
      message: 'This will permanently delete the "${entry.title}" entry.',
      confirmLabel: 'Delete',
      isDestructive: true,
      icon: Icons.delete_sweep_rounded,
      onConfirm: () => provider.deleteEntry(entry),
    );
  }
}


