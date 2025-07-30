class User {
  final int? id;
  final String name;
  final String email;
  final DateTime createdAt;
  final DateTime updatedAt;

  const User({
    this.id,
    required this.name,
    required this.email,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is User &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          email == other.email;

  @override
  int get hashCode => id.hashCode ^ name.hashCode ^ email.hashCode;

  @override
  String toString() {
    return 'User{id: $id, name: $name, email: $email}';
  }
}
