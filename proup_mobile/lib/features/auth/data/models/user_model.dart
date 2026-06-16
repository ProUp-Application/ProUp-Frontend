class ProfileModel {
  const ProfileModel({
    this.targetSector,
    this.experienceLevel,
    this.careerGoals,
    this.preferredJobType,
    this.location,
  });

  final String? targetSector;
  final String? experienceLevel;
  final String? careerGoals;
  final String? preferredJobType;
  final String? location;

  factory ProfileModel.fromJson(Map<String, dynamic> json) => ProfileModel(
        targetSector: json['targetSector'] as String?,
        experienceLevel: json['experienceLevel'] as String?,
        careerGoals: json['careerGoals'] as String?,
        preferredJobType: json['preferredJobType'] as String?,
        location: json['location'] as String?,
      );

  Map<String, dynamic> toJson() => {
        if (targetSector != null) 'targetSector': targetSector,
        if (experienceLevel != null) 'experienceLevel': experienceLevel,
        if (careerGoals != null) 'careerGoals': careerGoals,
        if (preferredJobType != null) 'preferredJobType': preferredJobType,
        if (location != null) 'location': location,
      };
}

class UserModel {
  const UserModel({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    this.profile,
  });

  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final ProfileModel? profile;

  String get fullName => '$firstName $lastName';

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: json['id'] as String,
        email: json['email'] as String,
        firstName: json['firstName'] as String? ?? '',
        lastName: json['lastName'] as String? ?? '',
        profile: json['profile'] is Map<String, dynamic>
            ? ProfileModel.fromJson(json['profile'] as Map<String, dynamic>)
            : null,
      );
}

class AuthResult {
  const AuthResult({required this.user, required this.accessToken, this.refreshToken});

  final UserModel user;
  final String accessToken;
  final String? refreshToken;

  factory AuthResult.fromJson(Map<String, dynamic> json) => AuthResult(
        user: UserModel.fromJson(json['user'] as Map<String, dynamic>),
        accessToken: json['accessToken'] as String,
        refreshToken: json['refreshToken'] as String?,
      );
}
