import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/money_provider.dart';
import '../models/models.dart';
import '../utils/constants.dart';
import '../screens/money_screen.dart';

class MoneyLedgerSection extends StatelessWidget {
  const MoneyLedgerSection({super.key});

  @override
  Widget build(BuildContext context) {
    final money = context.watch<MoneyProvider>();
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 15, offset: const Offset(0, 5)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Text(
                  'Financial Snapshot', 
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              InkWell(
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const MoneyScreen()));
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: AppColors.sectionMoneyDark.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text('Open Ledger', style: TextStyle(color: AppColors.sectionMoneyDark, fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildSnapshotItem(
                  context, 
                  'Budget Left', 
                  money.monthlyRemaining, 
                  AppColors.sectionMoneyDark, 
                  Icons.account_balance_wallet_rounded
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSnapshotItem(
                  context, 
                  'Today\'s Spent', 
                  money.todaysTotalExpense, 
                  money.todaysTotalExpense > money.settings.dailyTarget ? Colors.red : Colors.green, 
                  Icons.receipt_long_rounded
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildSnapshotItem(
                  context, 
                  'Total Pabo', 
                  money.totalReceivable, 
                  Colors.blue, 
                  Icons.call_received_rounded
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSnapshotItem(
                  context, 
                  'Total Debo', 
                  money.totalPayable, 
                  Colors.orange, 
                  Icons.call_made_rounded
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(height: 1),
          const SizedBox(height: 16),
          if (money.entries.isEmpty)
             const Center(child: Text("Start tracking your expenses!", style: TextStyle(color: Colors.grey, fontSize: 11)))
          else
            ...money.entries.take(3).map((entry) => _buildMiniEntry(entry)),
        ],
      ),
    );
  }

  Widget _buildSnapshotItem(BuildContext context, String label, double amount, Color color, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(color: AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5), maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 2),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  '${amount.toStringAsFixed(0)} ৳',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMiniEntry(MoneyEntry entry) {
    final isIncome = entry.type == MoneyEntryType.income;
    final now = DateTime.now();
    final isToday = entry.date.year == now.year && entry.date.month == now.month && entry.date.day == now.day;
    final yesterday = now.subtract(const Duration(days: 1));
    final isYesterday = entry.date.year == yesterday.year && entry.date.month == yesterday.month && entry.date.day == yesterday.day;
    
    String dateLabel = isToday ? 'Today' : (isYesterday ? 'Yesterday' : DateFormat('MMM d').format(entry.date));

    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: (isIncome ? Colors.green : Colors.red).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Icon(
              isIncome ? Icons.keyboard_arrow_down_rounded : Icons.keyboard_arrow_up_rounded,
              size: 10,
              color: isIncome ? Colors.green : Colors.red,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.title,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                Text(
                  dateLabel,
                  style: TextStyle(fontSize: 9, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '${entry.amount.toStringAsFixed(0)} ৳',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
