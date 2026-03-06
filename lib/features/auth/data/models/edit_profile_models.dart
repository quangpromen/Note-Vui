class EditProfileRequest {
  final String fullName;
  final String? avatarUrl;

  const EditProfileRequest({required this.fullName, this.avatarUrl});

  Map<String, dynamic> toJson() {
    return {
      'fullName': fullName,
      if (avatarUrl != null) 'avatarUrl': avatarUrl,
    };
  }
}
