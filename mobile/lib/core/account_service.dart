import 'api.dart';

class AccountService {
  AccountService(this.api);
  final UniduniApi api;

  Future<void> register({
    required String name,
    required String email,
    required String password,
    String phone = '',
  }) async {
    await api.request(
      'POST',
      '/api/Usuarios/cadastro',
      body: {
        'nome': name.trim(),
        'email': email.trim(),
        'telefone': phone.trim(),
        'senha': password,
      },
    );
  }

  Future<void> changePassword(String current, String next) async {
    final id = api.user?['id'];
    if (id == null) {
      throw const ApiException('Entre na sua conta para alterar a senha.');
    }
    await api.request(
      'PUT',
      '/api/Usuarios/alterar-senha/$id',
      body: {'senhaAtual': current, 'novaSenha': next},
    );
    api.forgetSession();
  }
}
