import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode});
  final String message;
  final int? statusCode;
  @override
  String toString() => message;
}

class UniduniApi {
  UniduniApi({String? baseUrl})
    : origin = Uri.parse(
        baseUrl ??
            const String.fromEnvironment(
              'API_URL',
              defaultValue: 'http://127.0.0.1:5288',
            ),
      ) {
    if (!['http', 'https'].contains(origin.scheme) ||
        origin.host.isEmpty ||
        origin.userInfo.isNotEmpty ||
        origin.hasQuery ||
        origin.hasFragment ||
        (origin.path.isNotEmpty && origin.path != '/')) {
      throw const ApiException(
        'Informe a origem da API, sem caminho ou credenciais.',
      );
    }
    _client.connectionTimeout = const Duration(seconds: 15);
  }
  final Uri origin;
  final _client = HttpClient();
  String? _token;
  Map<String, dynamic>? user;
  final _operations = <String, String>{};
  String operation(
    String key,
  ) => _operations.putIfAbsent('${user?['id']}-$key', () {
    final random = Random.secure();
    final bytes = List.generate(16, (_) => random.nextInt(256));
    bytes[6] = (bytes[6] & 15) | 64;
    bytes[8] = (bytes[8] & 63) | 128;
    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
  });
  void completeOperation(String key) =>
      _operations.remove('${user?['id']}-$key');
  void Function()? onSessionExpired;
  bool get isTeam =>
      ['Administrador', 'Funcionario'].contains(user?['tipoUsuario']);

  Future<List<Map<String, dynamic>>> adminProducts() async =>
      (await request('GET', '/api/Produtos/administracao') as List)
          .cast<Map<String, dynamic>>();
  Future<Map<String, dynamic>> adminProduct(int id) async =>
      Map<String, dynamic>.from(
        await request('GET', '/api/Produtos/administracao/$id'),
      );
  Future<List<Map<String, dynamic>>> categories() async =>
      (await request('GET', '/api/Categorias') as List)
          .cast<Map<String, dynamic>>();
  Future<void> saveProduct(Map<String, dynamic> data, {int? id}) async {
    if (!isTeam) {
      throw const ApiException(
        'Entre com uma conta da equipe para gerenciar produtos.',
      );
    }
    await request(
      id == null ? 'POST' : 'PUT',
      '/api/Produtos${id == null ? '' : '/$id'}',
      body: data,
    );
  }

  Future<void> deactivateProduct(int id) async {
    if (!isTeam) {
      throw const ApiException(
        'Entre com uma conta da equipe para gerenciar produtos.',
      );
    }
    await request('DELETE', '/api/Produtos/$id');
  }

  Uri image(String filename) => origin.resolveUri(
    Uri(
      pathSegments: [
        'images',
        filename.isEmpty ? 'produto-padrao.svg' : filename,
      ],
    ),
  );

  Future<dynamic> request(String method, String path, {Object? body}) async {
    final uri = origin.resolve(path);
    if (uri.origin != origin.origin) {
      throw const ApiException('Destino de API inválido.');
    }
    try {
      final req = await _client.openUrl(method, uri);
      req.followRedirects = false;
      req.headers.set(HttpHeaders.acceptHeader, 'application/json');
      if (_token != null) {
        req.headers.set(HttpHeaders.authorizationHeader, 'Bearer $_token');
      }
      if (body != null) {
        req.headers.contentType = ContentType.json;
        req.write(jsonEncode(body));
      }
      final res = await req.close().timeout(const Duration(seconds: 20));
      final text = await utf8.decoder
          .bind(res)
          .join()
          .timeout(const Duration(seconds: 20));
      dynamic data;
      try {
        data = text.isEmpty ? null : jsonDecode(text);
      } on FormatException {
        data = text;
      }
      if (res.statusCode == 401 && _token != null) {
        _token = null;
        user = null;
        _operations.clear();
        onSessionExpired?.call();
        throw const ApiException(
          'Sua sessão expirou. Entre novamente.',
          statusCode: 401,
        );
      }
      if (res.statusCode < 200 || res.statusCode >= 300) {
        if (res.statusCode == 429) {
          throw const ApiException('Muitas tentativas. Aguarde um minuto.');
        }
        final errors = data is Map ? data['errors'] : null;
        throw ApiException(
          errors is Map
              ? errors.values.expand((v) => v is List ? v : [v]).join(' ')
              : data is Map && data['mensagem'] is String
              ? data['mensagem'] as String
              : data is String && data.length < 500
              ? data
              : 'Não foi possível concluir a operação. Tente novamente.',
          statusCode: res.statusCode,
        );
      }
      return data;
    } on SocketException {
      throw const ApiException(
        'Não foi possível conectar à loja. Confira a API e a conexão USB.',
      );
    } on TimeoutException {
      throw const ApiException(
        'A loja demorou para responder. Tente novamente.',
      );
    } on HttpException {
      throw const ApiException('A conexão foi interrompida. Tente novamente.');
    }
  }

  Future<List<Map<String, dynamic>>> catalog() async =>
      (await request('GET', '/api/Produtos') as List)
          .cast<Map<String, dynamic>>();

  Future<void> login(String email, String password) async {
    final data = await request(
      'POST',
      '/api/Usuarios/login',
      body: {'email': email.trim(), 'senha': password},
    );
    _token = data['token'] as String;
    _operations.clear();
    user = Map<String, dynamic>.from(data['usuario']);
  }

  Future<void> logout() async {
    // Em falha de rede, preserva a sessão para permitir nova tentativa de revogação.
    await request('POST', '/api/Usuarios/logout');
    forgetSession();
  }

  // Usado após uma resposta que confirma a revogação das sessões no servidor.
  void forgetSession() {
    _token = null;
    user = null;
    _operations.clear();
  }

  void dispose() => _client.close(force: true);
}
