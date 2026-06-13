import 'auth_user_dto.dart';

class AuthSessionDto {
  const AuthSessionDto({
    required this.accessToken,
    required this.refreshToken,
    required this.user,
  });

  final String accessToken;
  final String refreshToken;
  final AuthUserDto user;

  factory AuthSessionDto.fromJson(Map<String, dynamic> json) {
    return AuthSessionDto(
      accessToken: json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String,
      user: AuthUserDto.fromJson(json['user'] as Map<String, dynamic>),
    );
  }
}