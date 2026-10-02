import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:proup_mobile/core/errors/app_exception.dart';
import 'package:proup_mobile/core/network/api_client.dart';
import 'package:proup_mobile/features/profile/data/user_repository.dart';

class _FakeApi extends Fake implements ApiClient {
  _FakeApi(this._handler);
  final Future<Response<T>> Function<T>(String path) _handler;

  @override
  Future<Response<T>> get<T>(String path, {Map<String, dynamic>? queryParameters}) => _handler<T>(path);
}

Response<T> _ok<T>(String path, Object data) =>
    Response<T>(requestOptions: RequestOptions(path: path), data: data as T, statusCode: 200);

void main() {
  group('Selector de profesiones (registro / perfil)', () {
    test('servidor caído → usa el catálogo local y el combo no queda vacío', () async {
      final repo = UserRepository(_FakeApi(<T>(_) async => throw const NetworkException('Sin conexión')));
      final list = await repo.getProfessions();
      expect(list, hasLength(18));
      expect(list.first.id, 'administracion');
    });

    test('servidor responde lista vacía → usa el catálogo local', () async {
      final repo = UserRepository(_FakeApi(<T>(p) async => _ok<T>(p, {'professions': []})));
      expect(await repo.getProfessions(), hasLength(18));
    });

    test('servidor OK → usa la lista del servidor', () async {
      final repo = UserRepository(_FakeApi(<T>(p) async => _ok<T>(p, {
            'professions': [
              {'id': 'sistemas', 'label': 'Ingeniería de Sistemas / Software'},
            ],
          })));
      final list = await repo.getProfessions();
      expect(list.single.id, 'sistemas');
    });

    test('IDs del catálogo local son únicos', () {
      final ids = UserRepository.fallbackProfessions.map((p) => p.id).toSet();
      expect(ids, hasLength(UserRepository.fallbackProfessions.length));
    });
  });
}
