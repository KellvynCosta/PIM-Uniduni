import 'api.dart';

class UsersService {
  UsersService(this.api);
  final UniduniApi api;
  void guard() {
    if (api.user?['tipoUsuario'] != 'Administrador') {
      throw const ApiException(
        'Gestão de usuários é exclusiva do Administrador.',
      );
    }
  }

  Future<List<Map<String, dynamic>>> list() async {
    guard();
    return (await api.request('GET', '/api/Usuarios') as List)
        .cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> get(int id) async {
    guard();
    return Map<String, dynamic>.from(
      await api.request('GET', '/api/Usuarios/$id'),
    );
  }

  Future<void> save(Map<String, dynamic> data, {int? id}) async {
    guard();
    final own = id != null && id == api.user?['id'];
    if (own && data['tipoUsuario'] != 'Administrador') {
      throw const ApiException(
        'Você não pode remover o próprio acesso de administrador.',
      );
    }
    final result = await api.request(
      id == null ? 'POST' : 'PUT',
      '/api/Usuarios${id == null ? '' : '/$id'}',
      body: data,
    );
    if (own) {
      if ((data['senha'] as String?)?.isNotEmpty == true) {
        api.forgetSession();
      } else {
        api.user = Map<String, dynamic>.from(result);
      }
    }
  }

  Future<void> deactivate(int id) async {
    guard();
    if (id == api.user?['id']) {
      throw const ApiException('Você não pode desativar a própria conta.');
    }
    await api.request('DELETE', '/api/Usuarios/$id');
  }
}
