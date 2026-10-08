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

  factory CondominiumModel.fromMap(String id, Map<String, dynamic> map) {
    return CondominiumModel(
      id: id,
      name: map['name'] as String? ?? '',
      address: map['address'] as String? ?? '',
      active: map['active'] as bool? ?? true,
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as dynamic).toDate()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'address': address,
      'active': active,
      'createdAt': createdAt,
    };
  }
}
