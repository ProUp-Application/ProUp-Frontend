import 'package:flutter/foundation.dart';

import '../storage/token_storage.dart';

/// Estado de sesión global. Se usa como `refreshListenable` del router
/// para redirigir automáticamente entre login y la app autenticada.
class AuthNotifier extends ChangeNotifier {
  AuthNotifier(this._tokenStorage);

  final TokenStorage _tokenStorage;

  bool get isAuthenticated => _tokenStorage.hasSession;

  void notifyAuthChanged() => notifyListeners();
}
