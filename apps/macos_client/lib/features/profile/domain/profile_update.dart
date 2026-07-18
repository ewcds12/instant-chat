class ProfileUpdate {
  const ProfileUpdate({
    required this.username,
    required this.displayName,
    this.gender,
    this.region,
  });

  final String username;
  final String displayName;
  final String? gender;
  final String? region;

  Map<String, Object?> toJson() => {
    'username': username,
    'display_name': displayName,
    'gender': gender,
    'region': region,
  };
}
