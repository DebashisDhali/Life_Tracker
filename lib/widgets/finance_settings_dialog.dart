import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/money_provider.dart';
import '../utils/constants.dart';

class FinanceSettingsDialog extends StatefulWidget {
  const FinanceSettingsDialog({super.key});

  @override
  State<FinanceSettingsDialog> createState() => _FinanceSettingsDialogState();
}

class _FinanceSettingsDialogState extends State<FinanceSettingsDialog> {
  late TextEditingController _budgetController;
  late TextEditingController _dailyController;
  late TextEditingController _binodonController;
  late TextEditingController _emergencyController;
  late TextEditingController _investmentController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final money = Provider.of<MoneyProvider>(context, listen: false);
    _budgetController = TextEditingController(text: money.settings.monthlyBudget.toStringAsFixed(0));
    _dailyController = TextEditingController(text: money.settings.dailyTarget.toStringAsFixed(0));
    _binodonController = TextEditingController(text: money.settings.entertainmentAllocation.toStringAsFixed(0));
    _emergencyController = TextEditingController(text: money.settings.emergencyAllocation.toStringAsFixed(0));
    _investmentController = TextEditingController(text: money.settings.totalInvestment.toStringAsFixed(0));
  }

  @override
  void dispose() {
    _budgetController.dispose();
    _dailyController.dispose();
    _binodonController.dispose();
    _emergencyController.dispose();
    _investmentController.dispose();
    super.dispose();
  }

  Future<void> _saveSettings() async {
    final money = Provider.of<MoneyProvider>(context, listen: false);
    setState(() => _isSaving = true);

    try {
      double parse(String val, double fallback) {
        final sanitized = val.replaceAll(RegExp(r'[^0-9.]'), '');
        final parsed = double.tryParse(sanitized);
        return parsed ?? fallback;
      }

      final budget = parse(_budgetController.text, 5000);
      final daily = parse(_dailyController.text, 140);
      final binodon = parse(_binodonController.text, 500);
      final emergency = parse(_emergencyController.text, 1000);
      final investment = parse(_investmentController.text, 0);

      await money.updateSettings(budget, daily, binodon, emergency, investment);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Finance targets updated!"),
            backgroundColor: AppColors.sectionMoneyDark,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: const Text('Finance Settings', style: TextStyle(fontWeight: FontWeight.bold)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Set your monthly and daily spending goals",
              style: TextStyle(fontSize: 12, color: Theme.of(context).textTheme.bodySmall?.color),
            ),
            const SizedBox(height: 20),
            _buildInput('Monthly Budget Limit', _budgetController, Icons.account_balance_rounded, 'Max total spending per month'),
            _buildInput('Daily Spending Target', _dailyController, Icons.timer_rounded, 'Target limit for each day'),
            _buildInput('Binodon Fund', _binodonController, Icons.movie_rounded, 'Monthly allocation for fun/movies'),
            _buildInput('Emergency Fund', _emergencyController, Icons.health_and_safety_rounded, 'Reserved for unexpected needs'),
            _buildInput('Initial Investment', _investmentController, Icons.trending_up_rounded, 'Initial capital for tracking balance'),
          ],
        ),
      ),
      actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel', style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color)),
        ),
        ElevatedButton(
          onPressed: _isSaving ? null : _saveSettings,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.sectionMoneyDark,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: _isSaving 
            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : const Text('Update Settings'),
        ),
      ],
    );
  }

  Widget _buildInput(String label, TextEditingController controller, IconData icon, String helper) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          helperText: helper,
          prefixIcon: Icon(icon, size: 20),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        keyboardType: TextInputType.number,
      ),
    );
  }
}
