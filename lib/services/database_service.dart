import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/task.dart';
import '../utils/constants.dart';

class TaskLimitException implements Exception {
  const TaskLimitException();

  @override
  String toString() => 'You have already planned three tasks for that day.';
}

class TaskSlotException implements Exception {
  const TaskSlotException();

  @override
  String toString() => 'There is already a task planned for that time slot.';
}

class DatabaseService {
  DatabaseService._();

  static final DatabaseService instance = DatabaseService._();
  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    final databasePath = kIsWeb
        ? 'task_per_day.db'
        : join(await getDatabasesPath(), 'task_per_day.db');
    _database = await openDatabase(
      databasePath,
      version: 1,
      onConfigure: (db) async => db.execute('PRAGMA foreign_keys = ON'),
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE users (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            email TEXT NOT NULL UNIQUE COLLATE NOCASE,
            password_hash TEXT NOT NULL,
            full_name TEXT NOT NULL,
            created_at TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE tasks (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id INTEGER NOT NULL,
            title TEXT NOT NULL,
            time_slot TEXT NOT NULL CHECK(time_slot IN ('Morning', 'Afternoon', 'Evening')),
            date TEXT NOT NULL,
            is_completed INTEGER NOT NULL DEFAULT 0,
            completed_at TEXT,
            FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE CASCADE,
            UNIQUE(user_id, date, time_slot)
          )
        ''');
        await db.execute(
          'CREATE INDEX tasks_user_date_idx ON tasks(user_id, date)',
        );
      },
    );
    return _database!;
  }

  Future<List<Task>> tasksForDate(int userId, DateTime date) async {
    try {
      final db = await database;
      final rows = await db.query(
        'tasks',
        where: 'user_id = ? AND date = ?',
        whereArgs: [userId, Task.dateKey(date)],
        orderBy:
            "CASE time_slot WHEN 'Morning' THEN 0 WHEN 'Afternoon' THEN 1 ELSE 2 END",
      );
      return rows.map(Task.fromMap).toList();
    } catch (error) {
      debugPrint('Could not load tasks for date: $error');
      rethrow;
    }
  }

  Future<List<Task>> allTasks(int userId) async {
    try {
      final db = await database;
      final rows = await db.query(
        'tasks',
        where: 'user_id = ?',
        whereArgs: [userId],
        orderBy: 'date DESC, time_slot ASC',
      );
      return rows.map(Task.fromMap).toList();
    } catch (error) {
      debugPrint('Could not load task history: $error');
      rethrow;
    }
  }

  Future<Task> saveTask({
    required int userId,
    required String title,
    required String timeSlot,
    required DateTime date,
    int? taskId,
  }) async {
    final db = await database;
    final dateString = Task.dateKey(date);
    try {
      return await db.transaction((transaction) async {
        final sameSlot = await transaction.query(
          'tasks',
          columns: ['id'],
          where: 'user_id = ? AND date = ? AND time_slot = ? AND id != ?',
          whereArgs: [userId, dateString, timeSlot, taskId ?? -1],
          limit: 1,
        );
        if (sameSlot.isNotEmpty) throw const TaskSlotException();

        if (taskId == null) {
          final existingTasks = await transaction.query(
            'tasks',
            columns: ['id'],
            where: 'user_id = ? AND date = ?',
            whereArgs: [userId, dateString],
          );
          if (existingTasks.length >= AppStrings.maxTasksPerDay) {
            throw const TaskLimitException();
          }
          final id = await transaction.insert('tasks', {
            'user_id': userId,
            'title': title.trim(),
            'time_slot': timeSlot,
            'date': dateString,
            'is_completed': 0,
          });
          final row = (await transaction.query(
            'tasks',
            where: 'id = ? AND user_id = ?',
            whereArgs: [id, userId],
          ))
              .single;
          return Task.fromMap(row);
        }

        final changed = await transaction.update(
          'tasks',
          {'title': title.trim(), 'time_slot': timeSlot},
          where: 'id = ? AND user_id = ? AND date = ?',
          whereArgs: [taskId, userId, dateString],
        );
        if (changed == 0) throw StateError('Task no longer exists.');
        final row = (await transaction.query(
          'tasks',
          where: 'id = ? AND user_id = ?',
          whereArgs: [taskId, userId],
        ))
            .single;
        return Task.fromMap(row);
      });
    } catch (error) {
      if (error is TaskLimitException || error is TaskSlotException) rethrow;
      debugPrint('Could not save task: $error');
      rethrow;
    }
  }

  Future<void> setTaskCompleted({
    required int userId,
    required int taskId,
    required bool completed,
  }) async {
    try {
      final db = await database;
      await db.update(
        'tasks',
        {
          'is_completed': completed ? 1 : 0,
          'completed_at': completed ? DateTime.now().toIso8601String() : null,
        },
        where: 'id = ? AND user_id = ?',
        whereArgs: [taskId, userId],
      );
    } catch (error) {
      debugPrint('Could not update task completion: $error');
      rethrow;
    }
  }

  Future<void> deleteTask({required int userId, required int taskId}) async {
    try {
      final db = await database;
      await db.delete(
        'tasks',
        where: 'id = ? AND user_id = ?',
        whereArgs: [taskId, userId],
      );
    } catch (error) {
      debugPrint('Could not delete task: $error');
      rethrow;
    }
  }

  // ═══════════════════════════════════════════════════════════
  // ✨ NEW METHODS FOR SCHEDULE-AHEAD FEATURE
  // ═══════════════════════════════════════════════════════════

  /// Get all tasks (completed + pending) for a date range.
  Future<List<Task>> tasksForDateRange({
    required int userId,
    required DateTime start,
    required DateTime end,
  }) async {
    try {
      final db = await database;
      final rows = await db.query(
        'tasks',
        where: 'user_id = ? AND date >= ? AND date <= ?',
        whereArgs: [
          userId,
          Task.dateKey(start),
          Task.dateKey(end),
        ],
        orderBy:
            "date ASC, CASE time_slot WHEN 'Morning' THEN 0 WHEN 'Afternoon' THEN 1 ELSE 2 END",
      );
      return rows.map(Task.fromMap).toList();
    } catch (error) {
      debugPrint('Could not load tasks for range: $error');
      rethrow;
    }
  }

  /// Get upcoming tasks grouped by date (excluding today).
  /// Only returns future dates that have at least one task.
  Future<Map<DateTime, List<Task>>> getUpcomingGrouped({
    required int userId,
    int daysAhead = 30,
  }) async {
    try {
      final today = DateTime.now();
      final todayKey = DateTime(today.year, today.month, today.day);
      final end = todayKey.add(Duration(days: daysAhead));

      final all = await tasksForDateRange(
        userId: userId,
        start: todayKey.add(const Duration(days: 1)),
        end: end,
      );

      final Map<DateTime, List<Task>> grouped = {};
      for (final task in all) {
        final key =
            DateTime(task.date.year, task.date.month, task.date.day);
        grouped.putIfAbsent(key, () => []).add(task);
      }
      return grouped;
    } catch (error) {
      debugPrint('Could not load upcoming tasks: $error');
      return {};
    }
  }

  /// Get the count of tasks scheduled for a specific date.
  Future<int> taskCountForDate(int userId, DateTime date) async {
    try {
      final db = await database;
      final result = await db.rawQuery(
        'SELECT COUNT(*) as count FROM tasks WHERE user_id = ? AND date = ?',
        [userId, Task.dateKey(date)],
      );
      return Sqflite.firstIntValue(result) ?? 0;
    } catch (error) {
      debugPrint('Could not count tasks: $error');
      return 0;
    }
  }

  /// Get the total count of upcoming (future) tasks.
  Future<int> upcomingTaskCount(int userId) async {
    try {
      final db = await database;
      final today = DateTime.now();
      final todayKey = DateTime(today.year, today.month, today.day);
      final result = await db.rawQuery(
        'SELECT COUNT(*) as count FROM tasks WHERE user_id = ? AND date > ?',
        [userId, Task.dateKey(todayKey)],
      );
      return Sqflite.firstIntValue(result) ?? 0;
    } catch (error) {
      debugPrint('Could not count upcoming tasks: $error');
      return 0;
    }
  }
}
