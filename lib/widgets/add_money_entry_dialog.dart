import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../providers/money_provider.dart';
import '../models/models.dart';
import '../utils/constants.dart';
import 'premium_alert.dart';

class AddMoneyEntryDialog extends StatefulWidget {
  final MoneyEntry? entry;
  const AddMoneyEntryDialog({super.key, this.entry});

  @override
  State<AddMoneyEntryDialog> createState() => _AddMoneyEntryDialogState();
}

class _AddMoneyEntryDialogState extends State<AddMoneyEntryDialog> {
  final _formKey = GlobalKey<FormState>();
  late String _title;
  late double _amount;
  late MoneyEntryType _type;
  late MoneyEntryStatus _status;
  late DateTime _date;
  late String _category;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _title = widget.entry?.title ?? '';
    _amount = widget.entry?.amount ?? 0;
    _type = widget.entry?.type ?? MoneyEntryType.expense;
    _status = widget.entry?.status ?? MoneyEntryStatus.completed;
    _date = widget.entry?.date ?? DateTime.now();
    _category = widget.entry?.category ?? 'General';
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(widget.entry == null ? 'New Money Entry' : 'Edit Money Entry', style: const TextStyle(fontWeight: FontWeight.bold)),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                initialValue: _title,
                textCapitalization: TextCapitalization.words,
                validator: (val) => val == null || val.isEmpty ? 'Please enter a title' : null,
                onSaved: (val) => _title = val!,
                decoration: InputDecoration(
                  labelText: 'Title / Person Name',
                  hintText: 'e.g. Lunch, Salary, Rahim...',
                  helperText: 'What is this transaction for?',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.edit_note),
                  filled: true,
                  fillColor: Theme.of(context).dividerColor.withOpacity(0.05),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: _amount > 0 ? _amount.toStringAsFixed(0) : '',
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (val) => val == null || double.tryParse(val) == null ? 'Invalid amount' : null,
                onSaved: (val) => _amount = double.parse(val!),
                decoration: InputDecoration(
                  labelText: 'Amount (৳)',
                  hintText: '0',
                  helperText: 'The total value of this entry',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.payments_outlined),
                  filled: true,
                  fillColor: Theme.of(context).dividerColor.withOpacity(0.05),
                ),
              ),
              const SizedBox(height: 16),
              Text('Category', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Theme.of(context).textTheme.bodySmall?.color)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _category,
                isExpanded: true,
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Theme.of(context).dividerColor.withOpacity(0.05),
                  prefixIcon: const Icon(Icons.category_outlined),
                ),
                items: const [
                  DropdownMenuItem(value: 'General', child: Text('Main Budget (General)', overflow: TextOverflow.ellipsis)),
                  DropdownMenuItem(value: 'Entertainment', child: Text('Binodon Fund (বিনোদন)', overflow: TextOverflow.ellipsis)),
                  DropdownMenuItem(value: 'Emergency', child: Text('Emergency Fund (জরুরি)', overflow: TextOverflow.ellipsis)),
                  DropdownMenuItem(value: 'Investment', child: Text('Investment (শেয়ার/সঞ্চয়)', overflow: TextOverflow.ellipsis)),
                ],
                onChanged: (val) {
                   setState(() => _category = val!);
                },
              ),
              const SizedBox(height: 20),
              Text('Transaction Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Theme.of(context).textTheme.bodySmall?.color)),
              const SizedBox(height: 12),
              _buildTypeSelectionGrid(),
              const SizedBox(height: 20),
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _date,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2030),
                    builder: (context, child) {
                      return Theme(
                        data: Theme.of(context).copyWith(
                          colorScheme: Theme.of(context).colorScheme.copyWith(
                            primary: AppColors.sectionMoneyDark,
                          ),
                        ),
                        child: child!,
                      );
                    },
                  );
                  if (picked != null) setState(() => _date = picked);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.1)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_month, color: AppColors.sectionMoneyDark, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Date: ${DateFormat('MMM d, yyyy').format(_date)}', 
                          style: const TextStyle(fontSize: 14),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Icon(Icons.arrow_drop_down, color: Colors.grey),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      actions: [
        if (widget.entry != null)
          IconButton(
            onPressed: () {
              Navigator.pop(context);
              final provider = Provider.of<MoneyProvider>(context, listen: false);
              // Reuse existing delete confirmation logic if possible, 
              // but for now, we'll implement a quick delete from here 
              // as the user requested it specifically.
              _showDeleteConfirmation(context, provider, widget.entry!);
            },
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
            tooltip: 'Delete Entry',
          ),
        const Spacer(),
        TextButton(
          onPressed: () => Navigator.pop(context), 
          child: Text('Cancel', style: TextStyle(color: Colors.grey.shade600))
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.sectionMoneyDark,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: _isSaving ? null : () async {
            if (_formKey.currentState!.validate()) {
              _formKey.currentState!.save();
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              final navigator = Navigator.of(context);
              
              setState(() => _isSaving = true);
              
              try {
                final provider = Provider.of<MoneyProvider>(context, listen: false);
                
                if (widget.entry != null) {
                  // Update existing entry
                  widget.entry!.title = _title;
                  widget.entry!.amount = _amount;
                  widget.entry!.date = _date;
                  widget.entry!.type = _type;
                  widget.entry!.status = _status;
                  widget.entry!.category = _category;
                  await provider.updateEntry(widget.entry!);
                } else {
                  // Add new entry
                  final entry = MoneyEntry(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    title: _title,
                    amount: _amount,
                    date: _date,
                    type: _type,
                    status: _status,
                    category: _category,
                  );
                  
                  if (provider.isLoading) {
                     throw Exception("Money system is still initializing. Please wait.");
                  }

                  await provider.addEntry(entry);
                }
                
                if (mounted) {
                  String msg = widget.entry != null 
                      ? 'Entry Updated'
                      : (_status == MoneyEntryStatus.completed 
                          ? 'Saved to History' 
                          : 'Added to Ledger (Debo)');
                  
                  scaffoldMessenger.showSnackBar(
                    SnackBar(
                      content: Text(msg),
                      backgroundColor: AppColors.sectionMoneyDark,
                      duration: const Duration(seconds: 2),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  );
                  navigator.pop();
                }
              } catch (e) {
                if (mounted) {
                  setState(() => _isSaving = false);
                  scaffoldMessenger.showSnackBar(
                    SnackBar(
                      content: Text('Error: ${e.toString()}'), 
                      backgroundColor: Colors.red, 
                      behavior: SnackBarBehavior.floating
                    ),
                  );
                }
              }
            }
          },
          child: _isSaving 
            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : const Text('Save Entry', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ),
      ],
    );
  }

  Widget _buildTypeSelectionGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Where should this go?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Theme.of(context).textTheme.bodySmall?.color)),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildStatusOption(null, 'History', Icons.history, isHistory: true)),
            const SizedBox(width: 8),
            Expanded(child: _buildStatusOption(MoneyEntryType.expense, 'Debo', Icons.call_made_rounded)),
            const SizedBox(width: 8),
            Expanded(child: _buildStatusOption(MoneyEntryType.income, 'Pabo', Icons.call_received_rounded)),
          ],
        ),
        if (_status == MoneyEntryStatus.pending)
          Padding(
            padding: const EdgeInsets.only(top: 8.0, left: 4),
            child: Text(
              _type == MoneyEntryType.expense 
                ? 'Listed as "Debo" (দেবো) - You owe someone'
                : 'Listed as "Pabo" (পাবো) - Someone owes you',
              style: TextStyle(fontSize: 11, color: _type == MoneyEntryType.expense ? Colors.orange : Colors.blue, fontWeight: FontWeight.bold),
            ),
          ),
      ],
    );
  }

  Widget _buildStatusOption(MoneyEntryType? type, String label, IconData icon, {bool isHistory = false}) {
    bool isSelected;
    if (isHistory) {
      isSelected = _status == MoneyEntryStatus.completed;
    } else {
      isSelected = _status == MoneyEntryStatus.pending && _type == type;
    }
    
    final color = isHistory 
        ? AppColors.sectionMoneyDark 
        : (type == MoneyEntryType.income ? Colors.blue : Colors.orange);
    
    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() {
          if (isHistory) {
            _status = MoneyEntryStatus.completed;
            _type = MoneyEntryType.expense; // Default for history
          } else {
            _status = MoneyEntryStatus.pending;
            _type = type!;
          }
        });
      },
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? color : (Theme.of(context).brightness == Brightness.dark ? Colors.white.withOpacity(0.05) : Theme.of(context).dividerColor.withOpacity(0.05)),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSelected ? color : (Theme.of(context).brightness == Brightness.dark ? Colors.white.withOpacity(0.1) : Theme.of(context).dividerColor.withOpacity(0.1)), width: 1.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: isSelected ? Colors.white : AppColors.textSecondary),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label, 
                style: TextStyle(
                  color: isSelected ? Colors.white : AppColors.textSecondary, 
                  fontSize: 12, 
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, MoneyProvider provider, MoneyEntry entry) {
    PremiumAlert.show(
      context,
      title: 'Delete Entry?',
      message: 'Are you sure you want to permanently delete "${entry.title}"? This cannot be undone.',
      confirmLabel: 'Delete',
      isDestructive: true,
      icon: Icons.delete_forever_rounded,
      onConfirm: () => provider.deleteEntry(entry),
    );
  }
}
