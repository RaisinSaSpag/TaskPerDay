import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/task.dart';
import '../models/user.dart';
import '../services/database_service.dart';
import '../utils/constants.dart';
import '../widgets/floating_nav_bar.dart';
import 'home_screen.dart';
import 'history_screen.dart';
import 'settings_screen.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({required this.user, super.key});

  final AppUser user;

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  Map<DateTime, List<Task>> _groups = {};
  int _totalUpcoming = 0;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final groups = await DatabaseService.instance
          .getUpcomingGrouped(userId: widget.user.id, daysAhead: 60);
      final total = await DatabaseService.instance
          .upcomingTaskCount(widget.user.id);
      if (!mounted) return;
      setState(() {
        _groups = groups;
        _totalUpcoming = total;
        _loading = false;
        _error = null;
      });
    } catch (error) {
      debugPrint('Schedule load error: $error');
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Could not load your schedule. Please try again.';
      });
    }
  }

 void _navigate(int index) {
  if (index == 2) return;

  late Widget screen;
  switch (index) {
    case 0:
      screen = HomeScreen(user: widget.user);
      break;
    case 1:
      screen = HistoryScreen(user: widget.user);
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

  String _dateHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final diff = date.difference(today).inDays;
    if (diff == 1) return 'Tomorrow';
    if (diff < 7) return DateFormat('EEEE').format(date);
    return DateFormat('EEEE, MMM d').format(date);
  }

  String _dateRelative(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final diff = date.difference(today).inDays;
    if (diff == 1) return 'In 1 day';
    return 'In $diff days';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Schedule',
                style: TextStyle(fontWeight: FontWeight.w700)),
            Text(
              _totalUpcoming == 0
                  ? 'Nothing planned yet'
                  : '$_totalUpcoming upcoming task${_totalUpcoming > 1 ? 's' : ''}',
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 12),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _load,
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
          ),
        ],
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
                          style: const TextStyle(
                              color: AppColors.textSecondary)),
                      TextButton(
                          onPressed: _load, child: const Text('Retry')),
                    ],
                  ),
                )
              : _groups.isEmpty
                  ? const _EmptySchedule()
                  : RefreshIndicator(
                      onRefresh: _load,
                      color: AppColors.accentTeal,
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                        children: [
                          _SummaryCard(total: _totalUpcoming),
                          const SizedBox(height: 24),
                          ..._groups.entries.map((entry) {
                            final date = entry.key;
                            final tasks = entry.value;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 22),
                              child: _DayGroup(
                                date: date,
                                tasks: tasks,
                                header: _dateHeader(date),
                                relative: _dateRelative(date),
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
      bottomNavigationBar:
          FloatingNavBar(currentIndex: 2, onTap: _navigate),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// SUMMARY CARD
// ═══════════════════════════════════════════════════════════
class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.total});

  final int total;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.badgeTomorrow.withValues(alpha: 0.18),
              AppColors.badgeThisWeek.withValues(alpha: 0.08),
            ],
          ),
          borderRadius: BorderRadius.circular(AppSizes.cardRadius),
          border: Border.all(
              color: AppColors.badgeTomorrow.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.badgeTomorrow.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.auto_awesome_rounded,
                  color: AppColors.badgeTomorrow, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Planning ahead',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    total == 0
                        ? 'Nothing scheduled yet.'
                        : 'You have $total task${total > 1 ? 's' : ''} coming up.',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}

// ═══════════════════════════════════════════════════════════
// DAY GROUP
// ═══════════════════════════════════════════════════════════
class _DayGroup extends StatelessWidget {
  const _DayGroup({
    required this.date,
    required this.tasks,
    required this.header,
    required this.relative,
  });

  final DateTime date;
  final List<Task> tasks;
  final String header;
  final String relative;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.badgeThisWeek.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    relative.toUpperCase(),
                    style: const TextStyle(
                      color: AppColors.badgeThisWeek,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  header,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                const Spacer(),
                Text(
                  '${tasks.length} task${tasks.length > 1 ? 's' : ''}',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          ...tasks.map((task) => _ScheduleTaskRow(task: task)),
        ],
      );
}

// ═══════════════════════════════════════════════════════════
// INDIVIDUAL TASK ROW
// ═══════════════════════════════════════════════════════════
class _ScheduleTaskRow extends StatelessWidget {
  const _ScheduleTaskRow({required this.task});

  final Task task;

  IconData get _icon => switch (task.timeSlot) {
        'Morning' => Icons.wb_sunny_outlined,
        'Afternoon' => Icons.wb_cloudy_outlined,
        _ => Icons.nightlight_outlined,
      };

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withValues(alpha: 0.13),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(_icon,
                  color: AppColors.primaryBlue, size: 17),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    task.timeSlot,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            if (task.isCompleted)
              const Icon(Icons.check_circle,
                  color: AppColors.success, size: 20),
          ],
        ),
      );
}

// ═══════════════════════════════════════════════════════════
// EMPTY STATE
// ═══════════════════════════════════════════════════════════
class _EmptySchedule extends StatelessWidget {
  const _EmptySchedule();

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(36),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.event_available_rounded,
                size: 56,
                color: AppColors.textSecondary.withValues(alpha: 0.7),
              ),
              const SizedBox(height: 18),
              Text(
                'Nothing planned ahead',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              const Text(
                'Plan tomorrow today.\nTap the date strip on Home to pick a future day.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      );
}