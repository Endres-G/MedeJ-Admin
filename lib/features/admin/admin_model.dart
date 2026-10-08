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

  factory AdministratorModel.fromMap(String id, Map<String, dynamic> map) {
    return AdministratorModel(
      id: id,
      name: map['name'] as String? ?? '',
      email: map['email'] as String? ?? '',
      phone: map['phone'] as String?,
      active: map['active'] as bool? ?? true,
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as dynamic).toDate()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'active': active,
      'createdAt': createdAt,
    };
  }
}
