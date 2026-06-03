/// Public profile data loaded from DummyJSON.
class ProfileEntity {
  const ProfileEntity({
    required this.id,
    required this.username,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.image,
    this.phone = '',
  });

  final int id;
  final String username;
  final String email;
  final String firstName;
  final String lastName;
  final String image;
  final String phone;

  String get displayName {
    final fullName = '$firstName $lastName'.trim();
    return fullName.isEmpty ? username : fullName;
  }
}
