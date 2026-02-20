import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/life_provider.dart';
import '../models/models.dart';
import '../utils/constants.dart';
import '../widgets/premium_button.dart';
import '../widgets/premium_alert.dart';

class ManageHabitsScreen extends StatelessWidget {
  const ManageHabitsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final life = context.watch<LifeProvider>();
    final sections = life.sections;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Manage Habits & Categories', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Theme.of(context).cardColor,
        foregroundColor: Theme.of(context).textTheme.titleLarge?.color,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await life.restoreFromCloud();
        },
        color: AppColors.sectionSkillDark,
        child: ReorderableListView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          itemCount: sections.length,
          onReorder: (oldIndex, newIndex) => life.reorderSections(oldIndex, newIndex),
          itemBuilder: (context, index) {
            final section = sections[index];
            return _buildCategoryExpansionTile(context, life, section, index);
          },
        ),
      ),
      floatingActionButton: PremiumFAB(
        onPressed: () => _showAddCategoryDialog(context, life),
        label: "New Category",
        icon: Icons.add_rounded,
        colors: const [AppColors.sectionSkillDark, AppColors.sectionSkill],
      ),
    );
  }

  Widget _buildCategoryExpansionTile(BuildContext context, LifeProvider life, LifeSection section, int index) {
    return Container(
      key: ValueKey('sec_${section.id}'),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ExpansionTile(
        shape: const RoundedRectangleBorder(side: BorderSide.none),
        collapsedShape: const RoundedRectangleBorder(side: BorderSide.none),
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: ReorderableDragStartListener(
          index: index,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).dividerColor.withOpacity(0.05),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.drag_indicator_rounded, color: Theme.of(context).textTheme.bodySmall?.color, size: 20),
          ),
        ),
        title: Text(
          section.displayName,
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Theme.of(context).textTheme.titleLarge?.color),
        ),
        subtitle: Text(
          "${section.habits.length} habits tracking",
          style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color, fontSize: 12),
        ),
        childrenPadding: const EdgeInsets.all(12),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(Icons.edit_note_rounded, color: Colors.blue[400], size: 22),
              onPressed: () => _showEditCategoryDialog(context, life, section),
              tooltip: 'Edit Category',
            ),
            IconButton(
              icon: Icon(Icons.delete_outline_rounded, color: Colors.red[300], size: 22),
              onPressed: () => _confirmDeleteCategory(context, life, section),
              tooltip: 'Remove Category',
            ),
            const Icon(Icons.expand_more_rounded, color: Colors.grey),
          ],
        ),
        children: [
          const Divider(height: 1),
          const SizedBox(height: 8),
          if (section.habits.isEmpty)
             const Padding(
               padding: EdgeInsets.symmetric(vertical: 12),
               child: Text("No habits yet", style: TextStyle(color: Colors.grey, fontSize: 13, fontStyle: FontStyle.italic)),
             )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: section.habits.length,
              itemBuilder: (context, hIndex) {
                 final habit = section.habits[hIndex];
                 return _buildHabitItem(context, life, section, habit);
              },
            ),
          const SizedBox(height: 8),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: PremiumAddButton(
              onTap: () => _showAddHabitDialog(context, life, section),
              label: "Add New Habit",
              color: AppColors.sectionSkillDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHabitItem(BuildContext context, LifeProvider life, LifeSection section, Habit habit) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).dividerColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.1)),
      ),
      child: ExpansionTile(
        title: Text(
          habit.title,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
        ),
        leading: Icon(Icons.auto_awesome_mosaic_rounded, color: Colors.blue[300], size: 20),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(Icons.edit_rounded, color: Colors.blue[300], size: 18),
              onPressed: () => _showEditHabitDialog(context, life, section, habit),
            ),
            IconButton(
              icon: Icon(Icons.delete_outline_rounded, color: Colors.red[200], size: 18),
              onPressed: () => PremiumAlert.show(
                context,
                title: "Delete Habit?",
                message: "Removing \"${habit.title}\" will delete all its data. Continue?",
                confirmLabel: "Delete",
                isDestructive: true,
                icon: Icons.delete_outline_rounded,
                onConfirm: () => life.deleteHabit(section, habit),
              ),
            ),
          ],
        ),
        children: [
          const Divider(height: 1),
          // Sub-tasks list inside habit
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                if (habit.subTasks.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text("No tasks added yet", style: TextStyle(color: Colors.grey, fontSize: 12)),
                  )
                else
                  ...habit.subTasks.map((st) => _buildSubTaskItem(context, life, section, habit, st)).toList(),
                
                const SizedBox(height: 8),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: PremiumAddButton(
                    onTap: () => _showSubTaskDialog(context, life, section, habit),
                    label: "Add New Task",
                    color: Colors.blue[700]!,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubTaskItem(BuildContext context, LifeProvider life, LifeSection section, Habit habit, SubTask st) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: (st.type == SubTaskType.checkbox 
                  ? Colors.blue 
                  : (st.type == SubTaskType.timer ? Colors.purple : Colors.orange)
              ).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              st.type == SubTaskType.checkbox 
                  ? Icons.check_box_rounded 
                  : (st.type == SubTaskType.timer ? Icons.timer_rounded : Icons.plus_one_rounded),
              size: 16,
              color: (st.type == SubTaskType.checkbox 
                  ? Colors.blue 
                  : (st.type == SubTaskType.timer ? Colors.purple : Colors.orange)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  st.title, 
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  st.type == SubTaskType.checkbox 
                      ? "Unit: Checkmark" 
                      : (st.type == SubTaskType.timer ? "Goal: ${st.targetValue} mins" : "Goal: ${st.targetValue} units"),
                  style: TextStyle(fontSize: 10, color: Colors.grey[500], fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(Icons.edit_note_rounded, color: Colors.blue[400], size: 20),
                onPressed: () => _showSubTaskDialog(context, life, section, habit, subTask: st),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: Icon(Icons.delete_sweep_rounded, color: Colors.red[200], size: 20),
                onPressed: () => PremiumAlert.show(
                  context,
                  title: "Remove Task?",
                  message: "Delete \"${st.title}\" from this habit?",
                  confirmLabel: "Remove",
                  isDestructive: true,
                  icon: Icons.delete_sweep_rounded,
                  onConfirm: () => life.deleteSubTask(section, habit, st),
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Categories Dialogs
  void _showAddCategoryDialog(BuildContext context, LifeProvider life) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text("New Category", style: TextStyle(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            hintText: "Enter category name...",
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: Theme.of(context).dividerColor.withOpacity(0.05),
          ),
          textCapitalization: TextCapitalization.words,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.sectionSkillDark,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                life.addSection(controller.text.trim());
                Navigator.pop(ctx);
              }
            },
            child: const Text("Create", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showEditCategoryDialog(BuildContext context, LifeProvider life, LifeSection section) {
    final controller = TextEditingController(text: section.displayName);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text("Edit Category", style: TextStyle(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            hintText: "Enter category name...",
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: Theme.of(context).dividerColor.withOpacity(0.05),
          ),
          textCapitalization: TextCapitalization.words,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.sectionSkillDark,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                life.updateSection(section, controller.text.trim());
                Navigator.pop(ctx);
              }
            },
            child: const Text("Update", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteCategory(BuildContext context, LifeProvider life, LifeSection section) {
    PremiumAlert.show(
      context,
      title: "Delete ${section.displayName}?",
      message: "All habits and history within this category will be lost forever. Are you sure?",
      confirmLabel: "Delete Forever",
      isDestructive: true,
      icon: Icons.delete_forever_rounded,
      onConfirm: () => life.deleteSection(section),
    );
  }

  // Habits Dialogs
  void _showAddHabitDialog(BuildContext context, LifeProvider life, LifeSection section) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text("New Habit", style: TextStyle(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            hintText: "Enter habit name...",
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: Theme.of(context).dividerColor.withOpacity(0.05),
          ),
          textCapitalization: TextCapitalization.words,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.sectionSkillDark,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                life.addHabit(section, controller.text.trim());
                Navigator.pop(ctx);
              }
            },
            child: const Text("Add", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showEditHabitDialog(BuildContext context, LifeProvider life, LifeSection section, Habit habit) {
    final controller = TextEditingController(text: habit.title);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text("Edit Habit", style: TextStyle(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            hintText: "Enter habit name...",
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: Theme.of(context).dividerColor.withOpacity(0.05),
          ),
          textCapitalization: TextCapitalization.words,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.sectionSkillDark,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                life.updateHabitTitle(section, habit, controller.text.trim());
                Navigator.pop(ctx);
              }
            },
            child: const Text("Update", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // SubTask Dialog
  void _showSubTaskDialog(BuildContext context, LifeProvider life, LifeSection section, Habit habit, {SubTask? subTask}) {
    final titleController = TextEditingController(text: subTask?.title ?? "");
    final targetController = TextEditingController(text: subTask?.targetValue.toString() ?? "1");
    SubTaskType selectedType = subTask?.type ?? SubTaskType.checkbox;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text(subTask == null ? "New Task" : "Edit Task", style: const TextStyle(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: "Task Title",
                    hintText: "e.g., Push-ups, Read Pages...",
                    helperText: "Specific task within this habit",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 20),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text("Task Type:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Theme.of(context).textTheme.bodyLarge?.color)),
                ),
                  const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      ChoiceChip(
                        label: const Text("Checkbox"),
                        selected: selectedType == SubTaskType.checkbox,
                        selectedColor: AppColors.sectionSkillDark.withOpacity(0.2),
                        checkmarkColor: AppColors.sectionSkillDark,
                        onSelected: (val) => setDialogState(() => selectedType = SubTaskType.checkbox),
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text("Number Input"),
                        selected: selectedType == SubTaskType.input,
                        selectedColor: AppColors.sectionSkillDark.withOpacity(0.2),
                        checkmarkColor: AppColors.sectionSkillDark,
                        onSelected: (val) => setDialogState(() => selectedType = SubTaskType.input),
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text("Timer (Duration)"),
                        selected: selectedType == SubTaskType.timer,
                        selectedColor: AppColors.sectionSkillDark.withOpacity(0.2),
                        checkmarkColor: AppColors.sectionSkillDark,
                        onSelected: (val) => setDialogState(() => selectedType = SubTaskType.timer),
                      ),
                    ],
                  ),
                ),
                if (selectedType == SubTaskType.input || selectedType == SubTaskType.timer) ...[
                  const SizedBox(height: 16),
                  TextField(
                    controller: targetController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: selectedType == SubTaskType.timer ? "Target Duration (minutes)" : "Target Value (Daily Goal)",
                      hintText: selectedType == SubTaskType.timer ? "e.g., 30 for 30 mins" : "e.g., 50 for 50 pushups",
                      helperText: selectedType == SubTaskType.timer 
                          ? "A timer will be shown for this task" 
                          : "Enter the number you want to achieve daily",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.sectionSkillDark,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                if (titleController.text.trim().isNotEmpty) {
                  final title = titleController.text.trim();
                  final target = int.tryParse(targetController.text) ?? 1;
                  
                  if (subTask == null) {
                    life.addSubTask(section, habit, title, selectedType, target);
                  } else {
                    life.updateSubTaskDetails(section, habit, subTask, title, target);
                    subTask.type = selectedType;
                    section.save();
                  }
                  Navigator.pop(ctx);
                }
              },
              child: Text(subTask == null ? "Add" : "Update", style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
