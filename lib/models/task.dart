class Task {
  const Task({
    required this.id,
    required this.userId,
    required this.title,
    required this.timeSlot,
    required this.date,
    required this.isCompleted,
    this.completedAt,
  });

  final int id;
  final int userId;
  final String title;
  final String timeSlot;
  final DateTime date;
  final bool isCompleted;
  final DateTime? completedAt;

  factory Task.fromMap(Map<String, Object?> map) => Task(
        id: map['id'] as int,
        userId: map['user_id'] as int,
        title: map['title'] as String,
        timeSlot: map['time_slot'] as String,
        date: DateTime.parse(map['date'] as String),
        isCompleted: (map['is_completed'] as int) == 1,
        completedAt: map['completed_at'] == null
            ? null
            : DateTime.parse(map['completed_at'] as String),
      );

  Map<String, Object?> toInsertMap() => {
        'user_id': userId,
        'title': title.trim(),
        'time_slot': timeSlot,
        'date': dateKey(date),
        'is_completed': isCompleted ? 1 : 0,
        'completed_at': completedAt?.toIso8601String(),
      };

  static String dateKey(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}
