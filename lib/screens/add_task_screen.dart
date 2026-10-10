import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/task.dart';
import '../utils/constants.dart';
import '../widgets/gradient_button.dart';

Future<bool?> showAddTaskSheet({
  required BuildContext context,
  required Future<void> Function(String title, String slot, DateTime date)
      onSave,
  Task? task,
  String? initialSlot,
  DateTime? initialDate,
}) =>
    showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddTaskScreen(
        onSave: onSave,
        task: task,
        initialSlot: initialSlot,
        initialDate: initialDate,
      ),
    );

class AddTaskScreen extends StatefulWidget {
  const AddTaskScreen({
    required this.onSave,
    this.task,
    this.initialSlot,
    this.initialDate,
    super.key,
  });

  final Future<void> Function(String title, String slot, DateTime date)
      onSave;
  final Task? task;
  final String? initialSlot;
  final DateTime? initialDate;

  @override
  State<AddTaskScreen> createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen> {
  late final TextEditingController _titleController =
      TextEditingController(text: widget.task?.title ?? '');
  late String _selectedSlot =
      widget.task?.timeSlot ?? widget.initialSlot ?? AppStrings.slots.first;
  late DateTime _selectedDate =
      widget.task?.date ?? widget.initialDate ?? DateTime.now();
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate.isBefore(today) ? today : _selectedDate,
      firstDate: today,
      lastDate: today.add(const Duration(days: 365)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppColors.accentTeal,
            onPrimary: Colors.black,
            surface: AppColors.surface,
            onSurface: AppColors.textPrimary,
          ),
        ),
        child: child ?? const SizedBox(),
      ),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  void _quickPick(int daysAhead) {
    final now = DateTime.now();
    setState(() {
      _selectedDate =
          DateTime(now.year, now.month, now.day).add(Duration(days: daysAhead));
    });
  }

  String _dateLabel() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target =
        DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
    final diff = target.difference(today).inDays;

    if (diff == 0) return 'Today';
    if (diff == 1) return 'Tomorrow';
    if (diff < 7) return 'In $diff days';
    return DateFormat('EEEE, MMM d, y').format(_selectedDate);
  }

  String _dateSub() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target =
        DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
    final diff = target.difference(today).inDays;
    if (diff == 0) return DateFormat('EEEE, MMM d').format(_selectedDate);
    return DateFormat('EEEE, MMM d, y').format(_selectedDate);
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      setState(() => _error = 'Add a title for your task.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.onSave(title, _selectedSlot, _selectedDate);
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target =
        DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
    final isToday = target == today;
    final isTomorrow = target == today.add(const Duration(days: 1));

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(22, 12, 22, 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.textSecondary.withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                Row(
                  children: [
                    Icon(
                      widget.task == null
                          ? Icons.add_circle_outline_rounded
                          : Icons.edit_outlined,
                      color: AppColors.accentTeal,
                      size: 22,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      widget.task == null ? 'Add New Task' : 'Edit Task',
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _titleController,
                  autofocus: true,
                  maxLength: 120,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    hintText: 'What matters today?',
                    labelText: 'Task title',
                  ),
                  onSubmitted: (_) => _save(),
                ),
                const SizedBox(height: 12),
                const Text(
                  'TIME SLOT',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 9,
                  children: AppStrings.slots.map((slot) {
                    final selected = _selectedSlot == slot;
                    return ChoiceChip(
                      label: Text(slot),
                      selected: selected,
                      onSelected: (_) => setState(() => _selectedSlot = slot),
                      selectedColor:
                          AppColors.primaryBlue.withValues(alpha: 0.25),
                      labelStyle: TextStyle(
                        color: selected
                            ? AppColors.accentTeal
                            : AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                      side: BorderSide(
                        color: selected
                            ? AppColors.accentTeal.withValues(alpha: 0.6)
                            : AppColors.border,
                      ),
                    );
                  }).toList(),
                ),

                // ✨ NEW: WHEN section
                const SizedBox(height: 20),
                const Text(
                  'WHEN',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _quickChip(
                      label: 'Today',
                      isSelected: isToday,
                      onTap: () => _quickPick(0),
                    ),
                    const SizedBox(width: 8),
                    _quickChip(
                      label: 'Tomorrow',
                      isSelected: isTomorrow,
                      onTap: () => _quickPick(1),
                    ),
                    const SizedBox(width: 8),
                    _quickChip(
                      label: 'Pick',
                      isSelected: !isToday && !isTomorrow,
                      onTap: _pickDate,
                      icon: Icons.calendar_month_rounded,
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Selected date preview
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppColors.accentTeal.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today_rounded,
                          color: AppColors.accentTeal, size: 18),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _dateLabel(),
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _dateSub(),
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: _pickDate,
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          minimumSize: const Size(0, 32),
                          foregroundColor: AppColors.accentTeal,
                        ),
                        child: const Text(
                          'Change',
                          style: TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                ),

                if (_error != null) ...[
                  const SizedBox(height: 10),
                  Text(_error!,
                      style: const TextStyle(color: AppColors.danger)),
                ],
                const SizedBox(height: 22),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed:
                            _saving ? null : () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          side: const BorderSide(color: AppColors.border),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GradientButton(
                        label: 'Save',
                        onPressed: _save,
                        isLoading: _saving,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _quickChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    IconData? icon,
  }) =>
      Expanded(
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(vertical: 11),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primaryBlue.withValues(alpha: 0.25)
                  : AppColors.card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? AppColors.accentTeal.withValues(alpha: 0.6)
                    : AppColors.border,
                width: 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon,
                      size: 14,
                      color: isSelected
                          ? AppColors.accentTeal
                          : AppColors.textSecondary),
                  const SizedBox(width: 5),
                ],
                Text(
                  label,
                  style: TextStyle(
                    color: isSelected
                        ? AppColors.accentTeal
                        : AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}