class CondominiumModel {
  final String id;
  final String name;
  final String address;
  final bool active;
  final DateTime? createdAt;
  final DateTime? deletedAt;

  const CondominiumModel({
    required this.id,
    required this.name,
    required this.address,
    required this.active,
    this.createdAt,
    this.deletedAt,
  });

  bool get isDeleted => deletedAt != null;

  CondominiumModel copyWith({
    String? id,
    String? name,
    String? address,
    bool? active,
    DateTime? createdAt,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
  }) {
    return CondominiumModel(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      active: active ?? this.active,
      createdAt: createdAt ?? this.createdAt,
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
    );
  }

  factory CondominiumModel.fromMap(String id, Map<String, dynamic> map) {
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

    return CondominiumModel(
      id: id,
      name: map['name'] as String? ?? '',
      address: map['address'] as String? ?? '',
      active: map['active'] as bool? ?? true,
      createdAt: parsedCreatedAt,
      deletedAt: parsedDeletedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'address': address,
      'active': active,
      if (createdAt != null) 'createdAt': createdAt,
      if (deletedAt != null) 'deletedAt': deletedAt,
    };
  }
}
