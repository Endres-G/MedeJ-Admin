class CondominiumModel {
  final String id;
  final String name;
  final String address;
  final bool active;
  final DateTime? createdAt;

  const CondominiumModel({
    required this.id,
    required this.name,
    required this.address,
    required this.active,
    this.createdAt,
  });

  CondominiumModel copyWith({
    String? id,
    String? name,
    String? address,
    bool? active,
    DateTime? createdAt,
  }) {
    return CondominiumModel(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      active: active ?? this.active,
      createdAt: createdAt ?? this.createdAt,
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

    return CondominiumModel(
      id: id,
      name: map['name'] as String? ?? '',
      address: map['address'] as String? ?? '',
      active: map['active'] as bool? ?? true,
      createdAt: parsedCreatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'address': address,
      'active': active,
      if (createdAt != null) 'createdAt': createdAt,
    };
  }
}
