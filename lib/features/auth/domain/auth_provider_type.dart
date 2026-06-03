enum AuthProviderType { dummy, favqs, backendless }

extension AuthProviderTypeX on AuthProviderType {
  String get label {
    return switch (this) {
      AuthProviderType.dummy => 'QuestBoard',
      AuthProviderType.favqs => 'FavQs',
      AuthProviderType.backendless => 'Backendless',
    };
  }

  bool get supportsRegistration => this != AuthProviderType.favqs;

  String get storageValue => name;

  static AuthProviderType fromStorage(String? value) {
    return AuthProviderType.values.firstWhere(
      (type) => type.storageValue == value,
      orElse: () => AuthProviderType.dummy,
    );
  }
}
