import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../auth/auth_notifier.dart';
import '../config/environment_config.dart';
import '../network/api_client.dart';
import '../storage/token_storage.dart';
import '../../features/auth/data/auth_repository.dart';
import '../../features/profile/data/user_repository.dart';
import '../../features/analysis/data/analysis_repository.dart';
import '../../features/interview/data/interview_repository.dart';
import '../../features/chat/data/chat_repository.dart';

final getIt = GetIt.instance;

/// Registra todas las dependencias de la app (DI manual con get_it).
Future<void> setupDependencies() async {
  final prefs = await SharedPreferences.getInstance();
  final tokenStorage = TokenStorage(prefs);
  final config = EnvironmentConfig.fromDartDefine();

  getIt
    ..registerSingleton<SharedPreferences>(prefs)
    ..registerSingleton<TokenStorage>(tokenStorage)
    ..registerSingleton<EnvironmentConfig>(config)
    ..registerSingleton<ApiClient>(ApiClient(config: config, tokenStorage: tokenStorage))
    ..registerSingleton<AuthNotifier>(AuthNotifier(tokenStorage))
    ..registerLazySingleton<AuthRepository>(() => AuthRepository(getIt(), getIt(), getIt()))
    ..registerLazySingleton<UserRepository>(() => UserRepository(getIt()))
    ..registerLazySingleton<AnalysisRepository>(() => AnalysisRepository(getIt()))
    ..registerLazySingleton<InterviewRepository>(() => InterviewRepository(getIt()))
    ..registerLazySingleton<ChatRepository>(() => ChatRepository(getIt()));
}
