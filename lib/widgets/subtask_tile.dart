import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/life_provider.dart';
import '../utils/constants.dart';
import 'celebration_overlay.dart';
import 'premium_alert.dart';
import 'timer_dialog.dart';
import '../screens/auth_screen.dart';

class SubTaskTile extends StatefulWidget {
  final SubTask subTask;
  final Habit habit;
  final LifeSection section;

  const SubTaskTile({Key? key, required this.subTask, required this.habit, required this.section})
      : super(key: key);

  @override
  State<SubTaskTile> createState() => _SubTaskTileState();
}
class _SubTaskTileState extends State<SubTaskTile> {
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  void _playCelebration() {
    CelebrationHelper.show(context, widget.subTask.title);
  }

  Future<bool> _checkAuth() async {
    final provider = Provider.of<LifeProvider>(context, listen: false);
    if (!provider.isLoggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please login to save your progress! 🔒"),
          backgroundColor: Colors.orange,
        ),
      );
      await Navigator.push(context, MaterialPageRoute(builder: (_) => const AuthScreen()));
      return provider.isLoggedIn;
    }
    return true;
  }

  void _openTimerDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => TimerDialog(
        subTask: widget.subTask,
        habit: widget.habit,
        section: widget.section,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final subTask = widget.subTask;
    final habit = widget.habit;
    final section = widget.section;
    final provider = Provider.of<LifeProvider>(context);
    final viewingDate = provider.viewingDate;
    final todayValue = subTask.getForDate(viewingDate);
    final isCompleted = subTask.isCompletedOn(viewingDate);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(left: 16.0, right: 12.0, bottom: 10.0),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.02) : Colors.black.withOpacity(0.01),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 1. Completion Button (The "Tick Mark" the user is looking for)
              if (subTask.type == SubTaskType.checkbox)
                Transform.scale(
                  scale: 1.1,
                  child: Checkbox(
                    value: isCompleted,
                    activeColor: Colors.green[600], // More vibrant green for "Tick"
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                    onChanged: provider.isViewingToday ? (val) async {
                      if (!await _checkAuth()) return;
                      final wasCompleted = isCompleted;
                      HapticFeedback.lightImpact();
                      Provider.of<LifeProvider>(context, listen: false)
                          .toggleSubTask(section, habit, subTask);
                      
                      if (!wasCompleted && val == true) {
                        _playCelebration();
                      }
                    } : null,
                  ),
                )
              else
                // For Input tasks, show a "Check" button directly in the main row
                // This is likely the "tik mark complete button" the user missed
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: InkWell(
                    onTap: provider.isViewingToday ? () async {
                      if (!await _checkAuth()) return;
                      final wasCompleted = isCompleted;
                      HapticFeedback.mediumImpact();
                      Provider.of<LifeProvider>(context, listen: false)
                          .updateSubTask(section, habit, subTask, subTask.targetValue);
                      
                      if (!wasCompleted) {
                        _playCelebration();
                      }
                    } : null,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isCompleted 
                            ? Colors.green.withOpacity(0.15) 
                            : Colors.grey.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        isCompleted ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                        size: 20,
                        color: isCompleted ? Colors.green[600] : Colors.grey[400],
                      ),
                    ),
                  ),
                ),

              const SizedBox(width: 4),

              // 2. Title
              Expanded(
                child: Text(
                  subTask.title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    decoration: isCompleted ? TextDecoration.lineThrough : null,
                    color: isCompleted 
                        ? Theme.of(context).textTheme.bodySmall?.color 
                        : Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
              ),
              
              // 3. Timer (Icon only if needed)
              if (subTask.type == SubTaskType.timer || (subTask.type == SubTaskType.input && 
                  (subTask.title.toLowerCase().contains('min') || subTask.title.toLowerCase().contains('sec'))))
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: Icon(Icons.timer_outlined, 
                    color: isDark ? Colors.blue[300] : Colors.blue[700], 
                    size: 18),
                  onPressed: provider.isViewingToday ? () async {
                    if (!await _checkAuth()) return;
                    _openTimerDialog();
                  } : null,
                ),
            ],
          ),
          
          if (subTask.type == SubTaskType.input || subTask.type == SubTaskType.timer) ...[
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              child: Row(
                children: [
                  // Input controls — scrollable horizontally if needed
                  Flexible(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: _buildInputControls(context, todayValue, isCompleted, provider.isViewingToday),
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (!isCompleted)
                    Flexible(
                      child: Text(
                        'Tap to edit',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10,
                          color: Theme.of(context).primaryColor.withOpacity(0.4),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                  else
                    Flexible(
                      child: Text(
                        'Done!',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.green[400],
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInputControls(BuildContext context, int todayValue, bool isCompleted, bool isToday) {
    bool canDecrement = todayValue > 0;
    bool canIncrement = todayValue < widget.subTask.targetValue;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Decrement button
        Material(
          color: (isToday && canDecrement) ? Colors.red.withOpacity(0.05) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: (isToday && canDecrement) ? () async {
              if (!await _checkAuth()) return;
              HapticFeedback.lightImpact();
              Provider.of<LifeProvider>(context, listen: false)
                  .updateSubTask(widget.section, widget.habit, widget.subTask, todayValue - 1);
            } : null,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Icon(
                Icons.remove_rounded, 
                color: (isToday && canDecrement) ? Colors.redAccent : Theme.of(context).disabledColor, 
                size: 24
              ),
            ),
          ),
        ),
        
        const SizedBox(width: 4),
        
        // Tappable count display
        GestureDetector(
          onTap: isToday ? () async {
            if (!await _checkAuth()) return;
            HapticFeedback.lightImpact();
            _showDirectInputDialog(context, todayValue);
          } : null,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark 
                ? Colors.white.withOpacity(0.08) 
                : Theme.of(context).primaryColor.withOpacity(0.05),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: Theme.of(context).primaryColor.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Text(
              '$todayValue/${widget.subTask.targetValue}',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w900,
                color: Theme.of(context).brightness == Brightness.dark 
                  ? Colors.white 
                  : Theme.of(context).primaryColor,
              ),
            ),
          ),
        ),
        
        // Increment button - Hide once goal is reached
        if (!isCompleted) ...[
          const SizedBox(width: 4),
          Material(
            color: (isToday && canIncrement) ? Theme.of(context).primaryColor.withOpacity(0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              onTap: (isToday && canIncrement) ? () async {
                 if (!await _checkAuth()) return;
                 final wasCompleted = isCompleted;
                 HapticFeedback.lightImpact();
                 Provider.of<LifeProvider>(context, listen: false)
                      .updateSubTask(widget.section, widget.habit, widget.subTask, todayValue + 1);
                 
                 if (!wasCompleted && todayValue + 1 >= widget.subTask.targetValue) {
                   _playCelebration();
                 }
              } : null,
               borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Icon(
                  Icons.add_rounded, 
                  color: (isToday && canIncrement) ? Theme.of(context).primaryColor : Theme.of(context).disabledColor, 
                  size: 24
                ),
              ),
            ),
          ),
        ],

        const SizedBox(width: 8),

      ],
    );
  }

  void _showDirectInputDialog(BuildContext context, int todayValue) {
    final controller = TextEditingController(text: todayValue.toString());
    
    showDialog(
      context: context,
      builder: (ctx) => Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 40),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 24, offset: const Offset(0, 12)),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(widget.subTask.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('Target: ${widget.subTask.targetValue}', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                  const SizedBox(height: 20),
                  TextField(
                    controller: controller,
                    autofocus: true,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      hintText: '0',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                      suffixText: '/ ${widget.subTask.targetValue}',
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            int? newValue = int.tryParse(controller.text);
                            if (newValue != null && newValue >= 0 && newValue <= widget.subTask.targetValue) {
                              Provider.of<LifeProvider>(context, listen: false)
                                  .updateSubTask(widget.section, widget.habit, widget.subTask, newValue);
                              Navigator.pop(ctx);
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.sectionSkillDark,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('Set Value', style: TextStyle(color: Colors.white)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

