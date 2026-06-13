class AuthUserDto {
  const AuthUserDto({
    required this.id,
    required this.fullName,
    required this.email,
  });

  final String id;
  final String fullName;
  final String email;

  factory AuthUserDto.fromJson(Map<String, dynamic> json) {
    return AuthUserDto(
      id: json['id'] as String,
      fullName: json['fullName'] as String,
      email: json['email'] as String,
    );
  }
}