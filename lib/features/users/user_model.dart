class UserModel {
  final String id;
  final String name;
  final String email;
  final String? apartmentId;
  final bool active;

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
    this.mustChangePassword = false,
    this.createdAt,
  });

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
    bool? mustChangePassword,
    DateTime? createdAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      apartmentId: clearApartmentId ? null : (apartmentId ?? this.apartmentId),
      active: active ?? this.active,
      mustChangePassword: mustChangePassword ?? this.mustChangePassword,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
