import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:uniduni_mobile/core/api.dart';

void main() {
  test('sessão vai apenas à API e expiração limpa o usuário', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final api = UniduniApi(baseUrl: 'http://127.0.0.1:${server.port}');
    addTearDown(() async {
      api.dispose();
      await server.close(force: true);
    });
    var calls = 0;
    var expired = false;
    api.onSessionExpired = () => expired = true;
    server.listen((req) async {
      calls++;
      req.response.headers.contentType = ContentType.json;
      if (req.uri.path.endsWith('/login')) {
        final credentials = jsonDecode(await utf8.decoder.bind(req).join());
        expect(credentials['email'], 'cliente@example.invalid');
        req.response.write(
          jsonEncode({
            'token': 'sessao-teste',
            'usuario': {'id': 1, 'nome': 'Cliente', 'tipoUsuario': 'Cliente'},
          }),
        );
      } else {
        expect(
          req.headers.value(HttpHeaders.authorizationHeader),
          'Bearer sessao-teste',
        );
        req.response.statusCode = 401;
      }
      await req.response.close();
    });
    await api.login(' cliente@example.invalid ', 'senha-de-teste');
    expect(api.user?['nome'], 'Cliente');
    await expectLater(
      api.request('GET', 'https://example.invalid/api'),
      throwsA(isA<ApiException>()),
    );
    expect(calls, 1);
    await expectLater(
      api.request('GET', '/api/Usuarios/me'),
      throwsA(isA<ApiException>()),
    );
    expect(expired, true);
    expect(api.user, null);
  });

  test('imagem é construída sem escapar da origem configurada', () {
    final api = UniduniApi(baseUrl: 'http://127.0.0.1:5288');
    addTearDown(api.dispose);
    expect(
      api.image('https://outro.invalid/foto.png').origin,
      api.origin.origin,
    );
    expect(api.image('body azul.png').pathSegments.last, 'body azul.png');
    expect(
      () => UniduniApi(baseUrl: 'http://usuario:senha@localhost'),
      throwsA(isA<ApiException>()),
    );
  });
}
