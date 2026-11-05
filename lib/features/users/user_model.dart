enum UserRole {
  admin('admin'),
  user('user');

  final String value;
  const UserRole(this.value);

  bool get isAdmin => this == UserRole.admin;

  String get shortLabel => switch (this) {
    UserRole.admin => 'Admin',
    UserRole.user => 'Comum',
  };

  String get label => switch (this) {
    UserRole.admin => 'Administrador',
    UserRole.user => 'Comum / Operacional',
  };

  String get description => switch (this) {
    UserRole.admin =>
      'Acessa o painel administrativo MedeJá Admin para gerenciar a plataforma.',
    UserRole.user =>
      'Acessa apenas o aplicativo mobile MedeJá para registrar leituras (bloqueado no painel Admin).',
  };

  static UserRole fromMap(
    Map<String, dynamic> map, {
    UserRole fallback = UserRole.user,
  }) {
    final rawRole = (map['role'] as String?)?.trim().toLowerCase();
    if (rawRole == 'admin' || rawRole == 'administrator') {
      return UserRole.admin;
    }
    if (rawRole == 'user' ||
        rawRole == 'common' ||
        rawRole == 'comum' ||
        rawRole == 'operator') {
      return UserRole.user;
    }

    final rawIsAdmin = map['isAdmin'];
    if (rawIsAdmin is bool) {
      return rawIsAdmin ? UserRole.admin : UserRole.user;
    }

    return fallback;
  }
}

class UserModel {
  final String id;
  final String name;
  final String email;
  final String? apartmentId;
  final bool active;

  /// Perfil de autorização da conta (`admin` ou `user` comum/operacional).
  final UserRole role;

  /// Indica que a conta foi criada com senha temporária e deve redefinir
  /// a senha no primeiro login pelo aplicativo mobile MedeJá.
  final bool mustChangePassword;
  final DateTime? createdAt;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.apartmentId,
    required this.active,
    this.role = UserRole.user,
    this.mustChangePassword = false,
    this.createdAt,
  });

  bool get isAdmin => role.isAdmin;

  factory UserModel.fromMap(String id, Map<String, dynamic> map) {
    final rawCreatedAt = map['createdAt'];
    DateTime? parsedCreatedAt;
    if (rawCreatedAt is DateTime) {
      parsedCreatedAt = rawCreatedAt;
    } else if (rawCreatedAt != null) {
      try {
        parsedCreatedAt = (rawCreatedAt as dynamic).toDate() as DateTime?;
      } catch (_) {
        parsedCreatedAt = null;
      }
    }

    return UserModel(
      id: id,
      name: map['name'] as String? ?? '',
      email: map['email'] as String? ?? '',
      apartmentId: map['apartmentId'] as String?,
      active: map['active'] as bool? ?? true,
      role: UserRole.fromMap(map, fallback: UserRole.user),
      mustChangePassword: map['mustChangePassword'] as bool? ?? false,
      createdAt: parsedCreatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'apartmentId': apartmentId,
      'active': active,
      'role': role.value,
      'isAdmin': isAdmin,
      'mustChangePassword': mustChangePassword,
      if (createdAt != null) 'createdAt': createdAt,
    };
  }

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? apartmentId,
    bool clearApartmentId = false,
    bool? active,
    UserRole? role,
    bool? mustChangePassword,
    DateTime? createdAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      apartmentId: clearApartmentId ? null : (apartmentId ?? this.apartmentId),
      active: active ?? this.active,
      role: role ?? this.role,
      mustChangePassword: mustChangePassword ?? this.mustChangePassword,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
