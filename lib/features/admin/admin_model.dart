class AdministratorModel {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final bool active;
  final DateTime? createdAt;

  const AdministratorModel({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    required this.active,
    this.createdAt,
  });

  AdministratorModel copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    bool clearPhone = false,
    bool? active,
    DateTime? createdAt,
  }) {
    return AdministratorModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: clearPhone ? null : (phone ?? this.phone),
      active: active ?? this.active,
      createdAt: createdAt ?? this.createdAt,
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

    return AdministratorModel(
      id: id,
      name: map['name'] as String? ?? '',
      email: map['email'] as String? ?? '',
      phone: map['phone'] as String?,
      active: map['active'] as bool? ?? true,
      createdAt: parsedCreatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'active': active,
      if (createdAt != null) 'createdAt': createdAt,
    };
  }
}
