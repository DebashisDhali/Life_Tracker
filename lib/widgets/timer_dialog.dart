import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/life_provider.dart';
import '../utils/constants.dart';
import 'celebration_overlay.dart';
import 'premium_alert.dart';

class TimerDialog extends StatefulWidget {
  final SubTask subTask;
  final Habit habit;
  final LifeSection section;

  const TimerDialog({
    Key? key,
    required this.subTask,
    required this.habit,
    required this.section,
  }) : super(key: key);

  @override
  State<TimerDialog> createState() => _TimerDialogState();
}

class _TimerDialogState extends State<TimerDialog> with SingleTickerProviderStateMixin {
  late int _secondsRemaining;
  late int _totalSeconds;
  Timer? _timer;
  bool _isRunning = false;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    final title = widget.subTask.title.toLowerCase();
    bool isSeconds = title.contains('(sec') || title.contains(' sec') || title.contains('seconds');
    
    if (widget.subTask.type == SubTaskType.timer) {
      // Explicit Timer Type -> Always Minutes (per UI label)
      _totalSeconds = widget.subTask.targetValue * 60;
    } else {
      // Legacy Input Type -> Infer from title
      _totalSeconds = isSeconds ? widget.subTask.targetValue : widget.subTask.targetValue * 60;
    }

    _secondsRemaining = _totalSeconds;
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  void _toggleTimer() {
    if (_isRunning) {
      _stopTimer();
    } else {
      _startTimer();
    }
    setState(() {
      _isRunning = !_isRunning;
    });
    if (_isRunning) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
    HapticFeedback.mediumImpact();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() {
          _secondsRemaining--;
        });
      } else {
        _onComplete();
      }
    });
  }

  void _stopTimer() {
    _timer?.cancel();
  }

  void _resetTimer() {
    _stopTimer();
    setState(() {
      _secondsRemaining = _totalSeconds;
      _isRunning = false;
    });
    _animationController.reverse();
    HapticFeedback.lightImpact();
  }

  void _confirmCancel() {
    if (!_isRunning && _secondsRemaining == _totalSeconds) {
       Navigator.of(context).pop();
       return;
    }

    PremiumAlert.show(
      context,
      title: 'Cancel Timer?',
      message: 'Your progress for this session will be lost.',
      confirmLabel: 'Discard',
      isDestructive: true,
      icon: Icons.timer_off_rounded,
      onConfirm: () => Navigator.pop(context),
    );
  }

  void _onComplete() {
    _stopTimer();
    HapticFeedback.heavyImpact();
    
    final provider = Provider.of<LifeProvider>(context, listen: false);
    provider.updateSubTask(widget.section, widget.habit, widget.subTask, widget.subTask.targetValue);
    
    Navigator.of(context).pop();
    CelebrationHelper.show(context, widget.subTask.title);
  }

  String _formatTime(int totalSeconds) {
    int minutes = totalSeconds ~/ 60;
    int seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final double progress = _secondsRemaining / _totalSeconds;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xCC1E1E1E) : const Color(0xCCFFFFFF),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 40,
                spreadRadius: 5,
              ),
            ],
          ),
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.sectionSkillDark.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'FOCUS SESSION',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: AppColors.sectionSkillDark,
                        letterSpacing: 2.0,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _confirmCancel,
                    icon: const Icon(Icons.close_rounded),
                    style: IconButton.styleFrom(
                      backgroundColor: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                widget.subTask.title,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 220,
                    height: 220,
                    child: TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0, end: progress),
                      duration: const Duration(seconds: 1),
                      builder: (context, value, _) => CircularProgressIndicator(
                        value: value,
                        strokeWidth: 10,
                        backgroundColor: isDark ? Colors.white10 : Colors.black.withOpacity(0.05),
                        color: AppColors.sectionSkillDark,
                        strokeCap: StrokeCap.round,
                      ),
                    ),
                  ),
                  // Inner glow
                  Container(
                    width: 180,
                    height: 180,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.sectionSkillDark.withOpacity(0.05),
                          blurRadius: 20,
                          spreadRadius: 10,
                        ),
                      ],
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formatTime(_secondsRemaining),
                        style: const TextStyle(
                          fontSize: 54,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'monospace',
                          letterSpacing: -2,
                        ),
                      ),
                      Text(
                        widget.subTask.title.toLowerCase().contains('sec') ? 'SECONDS LEFT' : 'MINUTES LEFT',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                          color: isDark ? Colors.white38 : Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 60),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Reset Button
                  _buildActionButton(
                    icon: Icons.refresh_rounded,
                    onPressed: _resetTimer,
                    color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
                    iconColor: isDark ? Colors.white70 : Colors.black87,
                  ),
                  const SizedBox(width: 32),
                  // Play/Pause Button
                  _buildActionButton(
                    icon: _isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    onPressed: _toggleTimer,
                    color: AppColors.sectionSkillDark,
                    iconColor: Colors.white,
                    isLarge: true,
                  ),
                  const SizedBox(width: 32),
                  // Stop/Cancel Button
                  _buildActionButton(
                    icon: Icons.stop_rounded,
                    onPressed: _confirmCancel,
                    color: isDark ? const Color(0x33F44336) : const Color(0xFFFFEBEE),
                    iconColor: Colors.redAccent,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback onPressed,
    required Color color,
    required Color iconColor,
    bool isLarge = false,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(isLarge ? 40 : 28),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: isLarge ? 84 : 56,
        height: isLarge ? 84 : 56,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: isLarge ? [
            BoxShadow(
              color: AppColors.sectionSkillDark.withOpacity(0.4),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ] : [],
        ),
        child: Icon(
          icon,
          size: isLarge ? 44 : 28,
          color: iconColor,
        ),
      ),
    );
  }
}
