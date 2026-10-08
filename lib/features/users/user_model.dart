class UserModel {
  final String id;
  final String name;
  final String email;
  final String? apartmentId;
  final bool active;
  final DateTime? createdAt;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.apartmentId,
    required this.active,
    this.createdAt,
  });
}
