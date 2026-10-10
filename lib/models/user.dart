class AppUser {
  const AppUser({
    required this.id,
    required this.email,
    required this.fullName,
    required this.createdAt,
  });

  final int id;
  final String email;
  final String fullName;
  final DateTime createdAt;

  factory AppUser.fromMap(Map<String, Object?> map) => AppUser(
        id: map['id'] as int,
        email: map['email'] as String,
        fullName: map['full_name'] as String,
        createdAt: DateTime.parse(map['created_at'] as String),
      );
}
