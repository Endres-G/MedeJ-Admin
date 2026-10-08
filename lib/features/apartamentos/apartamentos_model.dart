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

  factory ApartmentModel.fromMap(String id, Map<String, dynamic> map) {
    return ApartmentModel(
      id: id,
      name: map['name'] as String? ?? '',
      active: map['active'] as bool? ?? true,
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as dynamic).toDate()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {'name': name, 'active': active, 'createdAt': createdAt};
  }
}
