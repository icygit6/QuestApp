import 'auth_provider_type.dart';

/// Authenticated QuestBoard user.
class UserEntity {
  const UserEntity({
    required this.id,
    required this.username,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.image,
    this.token,
    this.refreshToken,
    this.provider = AuthProviderType.dummy,
  });

  final int id;
  final String username;
  final String email;
  final String firstName;
  final String lastName;
  final String image;
  final String? token;
  final String? refreshToken;
  final AuthProviderType provider;

  String get displayName {
    final fullName = '$firstName $lastName'.trim();
    return fullName.isEmpty ? username : fullName;
  }
}
