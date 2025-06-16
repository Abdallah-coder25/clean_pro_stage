enum UserRole { admin, cleaner }

class User {
  final String id;
  final String username;
  final String name;
  final UserRole role;

  const User({
    required this.id,
    required this.username,
    required this.name,
    required this.role,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'name': name,
      'role': role.toString(),
    };
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      username: json['username'],
      name: json['name'],
      role: UserRole.values.firstWhere(
        (e) => e.toString() == json['role'],
        orElse: () => UserRole.cleaner,
      ),
    );
  }
}
