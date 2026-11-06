class AdministratorModel {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final bool active;
  final DateTime? createdAt;
  final DateTime? deletedAt;

  const AdministratorModel({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    required this.active,
    this.createdAt,
    this.deletedAt,
  });

  bool get isDeleted => deletedAt != null;

  AdministratorModel copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    bool clearPhone = false,
    bool? active,
    DateTime? createdAt,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
  }) {
    return AdministratorModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: clearPhone ? null : (phone ?? this.phone),
      active: active ?? this.active,
      createdAt: createdAt ?? this.createdAt,
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
    );
  }

  factory AdministratorModel.fromMap(String id, Map<String, dynamic> map) {
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

    final rawDeletedAt = map['deletedAt'];
    DateTime? parsedDeletedAt;
    if (rawDeletedAt is DateTime) {
      parsedDeletedAt = rawDeletedAt;
    } else if (rawDeletedAt != null) {
      try {
        parsedDeletedAt = (rawDeletedAt as dynamic).toDate() as DateTime?;
      } catch (_) {
        parsedDeletedAt = null;
      }
    }

    return AdministratorModel(
      id: id,
      name: map['name'] as String? ?? '',
      email: map['email'] as String? ?? '',
      phone: map['phone'] as String?,
      active: map['active'] as bool? ?? true,
      createdAt: parsedCreatedAt,
      deletedAt: parsedDeletedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'active': active,
      if (createdAt != null) 'createdAt': createdAt,
      if (deletedAt != null) 'deletedAt': deletedAt,
    };
  }
}
