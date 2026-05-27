class User {
  final int id;
  final String email;
  final String name;
  final String role;
  final String? avatar;

  User({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    this.avatar,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      email: json['email'] as String,
      name: json['name'] as String,
      role: json['role'] as String,
      avatar: json['avatar'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'role': role,
      'avatar': avatar,
    };
  }

  User copyWith({String? avatar}) {
    return User(
      id: id,
      email: email,
      name: name,
      role: role,
      avatar: avatar ?? this.avatar,
    );
  }
}
