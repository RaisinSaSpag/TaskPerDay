import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/task.dart';
import '../models/user.dart';
import '../services/database_service.dart';
import '../utils/constants.dart';
import '../widgets/floating_nav_bar.dart';
import 'home_screen.dart';
import 'schedule_screen.dart';
import 'settings_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({required this.user, super.key});

  final AppUser user;

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<Task> _tasks = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final tasks = await DatabaseService.instance.allTasks(widget.user.id);
      if (!mounted) return;
      setState(() {
        _tasks = tasks;
        _loading = false;
        _error = null;
      });
    } catch (error) {
      debugPrint('History loading error: $error');
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Could not load your history. Please try again.';
      });
    }
  }

  Future<void> _delete(Task task) async {
    try {
      await DatabaseService.instance
          .deleteTask(userId: widget.user.id, taskId: task.id);
      await _load();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not delete this task.')),
      );
    }
  }

  Map<String, List<Task>> _groupTasks() {
    final groups = <String, List<Task>>{};
    for (final task in _tasks) {
      groups.putIfAbsent(Task.dateKey(task.date), () => []).add(task);
    }
    return groups;
  }

  String _dateLabel(DateTime date) {
    final today = DateTime.now();
    final dateOnly = DateTime(date.year, date.month, date.day);
    final todayOnly = DateTime(today.year, today.month, today.day);
    final difference = todayOnly.difference(dateOnly).inDays;
    if (difference == 0) return 'Today';
    if (difference == 1) return 'Yesterday';
    if (difference < 7 && difference > 0) {
      return DateFormat('EEEE').format(date);
    }
    return DateFormat('MMMM d, yyyy').format(date);
  }

  int _streak() {
    final completed = <String, int>{};
    for (final task in _tasks.where((task) => task.isCompleted)) {
      completed.update(Task.dateKey(task.date), (count) => count + 1,
          ifAbsent: () => 1);
    }
    final today = DateTime.now();
    var date = DateTime(today.year, today.month, today.day);
    if ((completed[Task.dateKey(date)] ?? 0) < 3) {
      date = date.subtract(const Duration(days: 1));
    }
    var streak = 0;
    while ((completed[Task.dateKey(date)] ?? 0) >= 3) {
      streak++;
      date = date.subtract(const Duration(days: 1));
    }
    return streak;
  }

  void _navigate(int index) {
  if (index == 1) return;

  late Widget screen;
  switch (index) {
    case 0:
      screen = HomeScreen(user: widget.user);
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

  Navigator.of(context).pushAndRemoveUntil(
    MaterialPageRoute(builder: (_) => screen),
    (route) => false,
  );
}

  @override
  Widget build(BuildContext context) {
    final completedCount = _tasks.where((task) => task.isCompleted).length;
    final activeDays =
        _tasks.map((task) => Task.dateKey(task.date)).toSet().length;
    final groups = _groupTasks();
    return Scaffold(
      appBar: AppBar(
        title: const Text('History',
            style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.accentTeal))
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_error!,
                          style:
                              const TextStyle(color: AppColors.textSecondary)),
                      TextButton(onPressed: _load, child: const Text('Retry')),
                    ],
                  ),
                )
              : groups.isEmpty
                  ? const _EmptyHistory()
                  : RefreshIndicator(
                      onRefresh: _load,
                      color: AppColors.accentTeal,
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                        children: [
                          _StatsCard(
                            completed: completedCount,
                            activeDays: activeDays,
                            streak: _streak(),
                          ),
                          const SizedBox(height: 25),
                          ...groups.entries.map((entry) {
                            final date = DateTime.parse(entry.key);
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 22),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 10),
                                    child: Text(
                                      _dateLabel(date),
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleSmall
                                          ?.copyWith(
                                            color: AppColors.textSecondary,
                                            fontWeight: FontWeight.w700,
                                          ),
                                    ),
                                  ),
                                  ...entry.value.map((task) => Padding(
                                        padding:
                                            const EdgeInsets.only(bottom: 9),
                                        child: Dismissible(
                                          key: ValueKey(task.id),
                                          direction:
                                              DismissDirection.endToStart,
                                          confirmDismiss: (_) async {
                                            await _delete(task);
                                            return false;
                                          },
                                          background: Container(
                                            alignment: Alignment.centerRight,
                                            padding: const EdgeInsets.only(
                                                right: 18),
                                            decoration: BoxDecoration(
                                              color: AppColors.danger
                                                  .withValues(alpha: 0.15),
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                            ),
                                            child: const Icon(
                                                Icons.delete_outline,
                                                color: AppColors.danger),
                                          ),
                                          child: _HistoryTaskCard(task: task),
                                        ),
                                      )),
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
      bottomNavigationBar: FloatingNavBar(currentIndex: 1, onTap: _navigate),
    );
  }
}

class _StatsCard extends StatelessWidget {
  const _StatsCard({
    required this.completed,
    required this.activeDays,
    required this.streak,
  });

  final int completed;
  final int activeDays;
  final int streak;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 19, horizontal: 12),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(AppSizes.cardRadius),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            _StatItem(value: '$completed', label: 'Completed'),
            _StatItem(value: '$activeDays', label: 'Active days'),
            _StatItem(value: '$streak', label: 'Streak'),
          ],
        ),
      );
}

class _StatItem extends StatelessWidget {
  const _StatItem({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) => Expanded(
        child: Column(
          children: [
            Text(value,
                style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 22,
                    color: AppColors.accentTeal)),
            const SizedBox(height: 5),
            Text(label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 11)),
          ],
        ),
      );
}

class _HistoryTaskCard extends StatelessWidget {
  const _HistoryTaskCard({required this.task});

  final Task task;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Icon(
              task.isCompleted
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked_rounded,
              color: task.isCompleted
                  ? AppColors.success
                  : AppColors.textSecondary,
              size: 21,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    style: TextStyle(
                      color: task.isCompleted
                          ? AppColors.textSecondary
                          : AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                      decoration:
                          task.isCompleted ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '${task.timeSlot}${task.completedAt == null ? '' : '  ·  ${DateFormat('h:mm a').format(task.completedAt!.toLocal())}'}',
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory();

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(36),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.auto_awesome_outlined,
                  size: 48,
                  color: AppColors.textSecondary.withValues(alpha: 0.7)),
              const SizedBox(height: 15),
              Text('Your story starts today',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              const Text(
                'Complete a task and your progress will show up here.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      );
}
