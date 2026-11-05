class ApartmentModel {
  final String id;
  final String name;
  final bool active;
  final DateTime? createdAt;

  const ApartmentModel({
    required this.id,
    required this.name,
    required this.active,
    this.createdAt,
  });

  ApartmentModel copyWith({
    String? id,
    String? name,
    bool? active,
    DateTime? createdAt,
  }) {
    return ApartmentModel(
      id: id ?? this.id,
      name: name ?? this.name,
      active: active ?? this.active,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory ApartmentModel.fromMap(String id, Map<String, dynamic> map) {
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

    return ApartmentModel(
      id: id,
      name: map['name'] as String? ?? '',
      active: map['active'] as bool? ?? true,
      createdAt: parsedCreatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'active': active,
      if (createdAt != null) 'createdAt': createdAt,
    };
  }
}
