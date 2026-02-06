/// Kullanıcı rolleri
enum UserRole {
  operator,
  admin,
}

/// Kullanıcı modeli
class User {
  final UserRole role;
  final String? name;
  final bool isDeveloper;

  User({required this.role, this.name, this.isDeveloper = false});

  bool get isAdmin => role == UserRole.admin;
  bool get isOperator => role == UserRole.operator;
}
