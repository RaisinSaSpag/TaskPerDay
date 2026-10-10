import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/task.dart';
import '../models/user.dart';
import '../services/database_service.dart';
import '../utils/constants.dart';
import '../widgets/date_strip.dart';
import '../widgets/floating_nav_bar.dart';
import '../widgets/progress_bar.dart';
import '../widgets/streak_badge.dart';
import '../widgets/task_card.dart';
import 'add_task_screen.dart';
import 'history_screen.dart';
import 'schedule_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({required this.user, super.key});

  final AppUser user;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _database = DatabaseService.instance;
  DateTime _selectedDate = DateTime.now();
  List<Task> _dayTasks = [];
  List<Task> _allTasks = [];
  bool _loading = true;
  String? _error;

  int get _completedCount => _dayTasks.where((t) => t.isCompleted).length;

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    try {
      final results = await Future.wait<List<Task>>([
        _database.tasksForDate(widget.user.id, _selectedDate),
        _database.allTasks(widget.user.id),
      ]);
      if (!mounted) return;
      setState(() {
        _dayTasks = results[0];
        _allTasks = results[1];
        _loading = false;
        _error = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Could not load your tasks. Please try again.';
      });
      debugPrint('Home task loading error: $error');
    }
  }

  Task? _taskForSlot(String slot) {
    for (final task in _dayTasks) {
      if (task.timeSlot == slot) return task;
    }
    return null;
  }

  Future<void> _openEditor({Task? task, String? slot}) async {
    await showAddTaskSheet(
      context: context,
      task: task,
      initialSlot: slot,
      initialDate: _selectedDate,
      onSave: (title, selectedSlot, date) async {
        await _database.saveTask(
          userId: widget.user.id,
          title: title,
          timeSlot: selectedSlot,
          date: date,
          taskId: task?.id,
        );
        await _loadTasks();
      },
    );
  }

  Future<void> _toggleTask(Task task, bool completed) async {
    final wasComplete = _dayTasks.length == 3 && _completedCount == 3;
    try {
      await _database.setTaskCompleted(
        userId: widget.user.id,
        taskId: task.id,
        completed: completed,
      );
      await _loadTasks();
      if (!wasComplete &&
          completed &&
          _dayTasks.length == 3 &&
          _completedCount == 3 &&
          mounted) {
        await _showCelebration();
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not update this task.')),
      );
    }
  }

  Future<void> _showCelebration() => showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: AppColors.card,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.celebration_rounded,
                  color: AppColors.warning, size: 48),
              const SizedBox(height: 15),
              Text('That\u2019s a full day.',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              const Text(
                'Three meaningful tasks, all done. Take a moment to be proud.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Nice'),
            ),
          ],
        ),
      );

  Future<void> _showTaskOptions(Task task) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 14, 22, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
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
              const SizedBox(height: 20),
              Text(task.timeSlot.toUpperCase(),
                  style: const TextStyle(
                      color: AppColors.accentTeal,
                      fontSize: 11,
                      letterSpacing: 1.1,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 5),
              Text(task.title,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 5),
              Text(
                DateFormat('EEEE, MMM d, y').format(task.date),
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 16),
              _TaskOptionTile(
                icon: task.isCompleted
                    ? Icons.undo_rounded
                    : Icons.check_circle_outline_rounded,
                label: task.isCompleted ? 'Mark incomplete' : 'Mark complete',
                onTap: () {
                  Navigator.pop(context);
                  _toggleTask(task, !task.isCompleted);
                },
              ),
              _TaskOptionTile(
                icon: Icons.edit_outlined,
                label: 'Edit task',
                onTap: () {
                  Navigator.pop(context);
                  _openEditor(task: task);
                },
              ),
              _TaskOptionTile(
                icon: Icons.delete_outline_rounded,
                label: 'Delete task',
                color: AppColors.danger,
                onTap: () {
                  Navigator.pop(context);
                  _deleteTask(task);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _deleteTask(Task task) async {
    try {
      await _database.deleteTask(userId: widget.user.id, taskId: task.id);
      await _loadTasks();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not delete this task.')),
      );
    }
  }

  int _streak() {
    final completedByDate = <String, int>{};
    for (final task in _allTasks) {
      if (task.isCompleted) {
        final key = Task.dateKey(task.date);
        completedByDate.update(key, (count) => count + 1, ifAbsent: () => 1);
      }
    }
    final today = DateTime.now();
    var cursor = DateTime(today.year, today.month, today.day);
    if ((completedByDate[Task.dateKey(cursor)] ?? 0) < 3) {
      cursor = cursor.subtract(const Duration(days: 1));
    }
    var days = 0;
    while ((completedByDate[Task.dateKey(cursor)] ?? 0) >= 3) {
      days++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return days;
  }

    void _navigate(int index) {
  if (index == 0) return;

  late Widget screen;
  switch (index) {
    case 1:
      screen = HistoryScreen(user: widget.user);
      break;
    case 2:
      screen = ScheduleScreen(user: widget.user);
      break;
    case 3:
      screen = SettingsScreen(user: widget.user);
      break;
    default:
      return;
  }

  Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => screen),
  );
}

  Future<void> _confirmDelete(Task task) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.card,
        title: const Text('Delete task?'),
        content: Text('\u201c${task.title}\u201d will be removed.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child:
                const Text('Delete', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (shouldDelete == true) await _deleteTask(task);
  }

  String _headerLabel() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target =
        DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
    final diff = target.difference(today).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Tomorrow';
    if (diff == -1) return 'Yesterday';
    if (diff < 0) return 'Past';
    return 'Upcoming';
  }

  @override
  Widget build(BuildContext context) {
    final date = DateFormat('EEEE, MMMM d').format(_selectedDate);
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 20,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_headerLabel(),
                style: const TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 20)),
            Text(date,
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 12)),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 17),
            child: Center(child: StreakBadge(streak: _streak())),
          ),
        ],
      ),
      body: Column(
        children: [
          // ✨ Date strip
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
            child: DateStrip(
              selectedDate: _selectedDate,
              userId: widget.user.id,
              onDateSelected: (date) {
                setState(() => _selectedDate = date);
                _loadTasks();
              },
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(
                        color: AppColors.accentTeal))
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(_error!,
                                style: const TextStyle(
                                    color: AppColors.textSecondary)),
                            TextButton(
                                onPressed: _loadTasks,
                                child: const Text('Retry')),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadTasks,
                        color: AppColors.accentTeal,
                        child: ListView(
                          padding:
                              const EdgeInsets.fromLTRB(20, 0, 20, 100),
                          children: [
                            _ProgressCard(
                              completed: _completedCount,
                              total: _dayTasks.length,
                            ),
                            const SizedBox(height: 22),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Your three',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                            fontWeight: FontWeight.w700)),
                                Text('${_dayTasks.length}/3 planned',
                                    style: const TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 12)),
                              ],
                            ),
                            const SizedBox(height: 13),
                            ...AppStrings.slots.map((slot) {
                              final task = _taskForSlot(slot);
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 11),
                                child: Dismissible(
                                  key: ValueKey(task?.id ?? 'empty-$slot'),
                                  direction: task == null
                                      ? DismissDirection.none
                                      : DismissDirection.endToStart,
                                  confirmDismiss: (_) async {
                                    await _confirmDelete(task!);
                                    return false;
                                  },
                                  background: Container(
                                    alignment: Alignment.centerRight,
                                    padding: const EdgeInsets.only(right: 20),
                                    decoration: BoxDecoration(
                                      color: AppColors.danger
                                          .withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(
                                          AppSizes.cardRadius),
                                    ),
                                    child: const Icon(Icons.delete_outline,
                                        color: AppColors.danger),
                                  ),
                                  child: TaskCard(
                                    slot: slot,
                                    task: task,
                                    onTap: task == null
                                        ? () => _openEditor(slot: slot)
                                        : () => _showTaskOptions(task),
                                    onToggle: task == null
                                        ? (_) {}
                                        : (value) => _toggleTask(task, value),
                                  ),
                                ),
                              );
                            }),
                            if (_dayTasks.any((task) => task.isCompleted)) ...[
                              const SizedBox(height: 14),
                              const Text('COMPLETED',
                                  style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 1)),
                              const SizedBox(height: 7),
                              ..._dayTasks
                                  .where((task) => task.isCompleted)
                                  .map((task) => Padding(
                                        padding:
                                            const EdgeInsets.only(top: 7),
                                        child: Row(
                                          children: [
                                            const Icon(Icons.check_circle,
                                                size: 17,
                                                color: AppColors.success),
                                            const SizedBox(width: 9),
                                            Expanded(
                                              child: Text(
                                                task.title,
                                                style: const TextStyle(
                                                  color:
                                                      AppColors.textSecondary,
                                                  decoration: TextDecoration
                                                      .lineThrough,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      )),
                            ],
                          ],
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: _dayTasks.length >= 3
          ? null
          : FloatingActionButton(
              onPressed: () {
                final slot = AppStrings.slots
                    .where((item) => _taskForSlot(item) == null)
                    .firstOrNull;
                _openEditor(slot: slot);
              },
              backgroundColor: AppColors.primaryBlue,
              foregroundColor: Colors.white,
              child: const Icon(Icons.add_rounded, size: 28),
            ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: FloatingNavBar(currentIndex: 0, onTap: _navigate),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({required this.completed, required this.total});

  final int completed;
  final int total;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.primaryBlue.withValues(alpha: 0.19),
              AppColors.accentTeal.withValues(alpha: 0.07),
            ],
          ),
          borderRadius: BorderRadius.circular(AppSizes.cardRadius),
          border:
              Border.all(color: AppColors.primaryBlue.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Daily progress',
                    style: TextStyle(
                        color: AppColors.textSecondary, fontSize: 13)),
                Text('$completed / 3 complete',
                    style: const TextStyle(
                        color: AppColors.accentTeal,
                        fontSize: 12,
                        fontWeight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: 14),
            ProgressBar(value: completed / AppStrings.maxTasksPerDay),
            const SizedBox(height: 10),
            Text(
              total == 3 && completed == 3
                  ? 'All three, all done. Excellent work.'
                  : '$total of 3 meaningful tasks planned',
              style:
                  const TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
          ],
        ),
      );
}

class _TaskOptionTile extends StatelessWidget {
  const _TaskOptionTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color = AppColors.textPrimary,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) => ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(icon, color: color),
        title: Text(label, style: TextStyle(color: color)),
        trailing:
            const Icon(Icons.chevron_right, color: AppColors.textSecondary),
        onTap: onTap,
      );
}