import '../../domain/entities/auth_session.dart';
import '../../domain/entities/auth_user.dart';
import '../dtos/auth_session_dto.dart';
import '../dtos/auth_user_dto.dart';

extension AuthUserDtoMapper on AuthUserDto {
  AuthUser toDomain() {
    return AuthUser(
      id: id, 
      fullName: fullName, 
      email: email,
    );
  }
}

extension AuthSessionDtoMapper on AuthSessionDto {
  AuthSession toDomain() {
    return AuthSession(
      accessToken: accessToken, 
      refreshToken: refreshToken, 
      user:user.toDomain(),
    );
  }
}