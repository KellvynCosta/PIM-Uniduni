import 'dart:convert';
import 'dart:io';

import 'package:uniduni_mobile/core/api.dart';
import 'package:uniduni_mobile/core/users_service.dart';

Future<void> main(List<String> args) async {
  final fixture = jsonDecode(await File(args.single).readAsString());
  final prefix = fixture['prefix'] as String;
  if (!prefix.startsWith('pim-ui-') ||
      fixture['email'] != '$prefix-admin@example.invalid') {
    throw StateError('Use somente contas temporárias da revisão.');
  }
  final admin = UniduniApi(),
      staff = UniduniApi(),
      client = UniduniApi(),
      created = UniduniApi();
  int checks = 0;
  void check(bool valid, String text) {
    if (!valid) throw StateError(text);
    checks++;
    stdout.writeln('OK: $text');
  }

  Future<void> denied(
    Future<dynamic> Function() run,
    int status,
    String text,
  ) async {
    try {
      await run();
      throw StateError(text);
    } on ApiException catch (e) {
      check(e.statusCode == status, text);
    }
  }

  try {
    await admin.login(fixture['email'], fixture['senha']);
    await staff.login(fixture['funcionarioEmail'], fixture['senha']);
    await client.login(fixture['clienteEmail'], fixture['senha']);
    final service = UsersService(admin);
    final ownId = admin.user!['id'] as int;
    final data = <String, dynamic>{
      'nome': 'Conta temporária mobile',
      'email': '$prefix-mobile@example.invalid',
      'telefone': '(11) 99999-0000',
      'tipoUsuario': 'Cliente',
      'senha': fixture['senha'],
    };
    await service.save(data);
    final account = (await service.list()).singleWhere(
      (u) => u['email'] == data['email'],
    );
    final id = account['id'] as int;
    check(
      account['tipoUsuario'] == 'Cliente' && !account.containsKey('senha'),
      'Cadastro compartilhado sem expor senha',
    );
    await created.login(data['email'], fixture['senha']);
    check(
      created.user!['id'] == id,
      'Conta criada no mobile faz login na API comum ao site',
    );
    await denied(() => service.save(data), 409, 'Email duplicado é rejeitado');
    data['nome'] = 'Conta mobile editada';
    data['tipoUsuario'] = 'Funcionario';
    data['senha'] = null;
    await service.save(data, id: id);
    check(
      (await service.get(id))['nome'] == data['nome'],
      'Nome e perfil editados persistem no banco',
    );
    check(
      (await created.request('GET', '/api/Usuarios/me'))['tipoUsuario'] ==
          'Funcionario',
      'Mudança de perfil vale na sessão existente',
    );
    final newPassword = '${fixture['senha']}X';
    data['senha'] = newPassword;
    await service.save(data, id: id);
    await denied(
      () => created.request('GET', '/api/Usuarios/me'),
      401,
      'Redefinição revoga sessão anterior',
    );
    await denied(
      () => created.login(data['email'], fixture['senha']),
      401,
      'Senha anterior deixa de autenticar',
    );
    await created.login(data['email'], newPassword);
    check(created.user!['id'] == id, 'Nova senha autentica corretamente');
    final own = await service.get(ownId);
    await denied(
      () => admin.request(
        'PUT',
        '/api/Usuarios/$ownId',
        body: {...own, 'tipoUsuario': 'Cliente'},
      ),
      400,
      'Servidor impede remover o próprio perfil de Administrador',
    );
    await denied(
      () => admin.request('DELETE', '/api/Usuarios/$ownId'),
      400,
      'Servidor impede desativação da própria conta',
    );
    for (final api in [staff, client]) {
      await denied(
        () => api.request('GET', '/api/Usuarios'),
        403,
        'Servidor bloqueia listagem para ${api.user!['tipoUsuario']}',
      );
      await denied(
        () => api.request('PUT', '/api/Usuarios/$id', body: data),
        403,
        'Servidor bloqueia edição por ${api.user!['tipoUsuario']}',
      );
      await denied(
        () => api.request('POST', '/api/Usuarios', body: data),
        403,
        'Servidor bloqueia cadastro interno por ${api.user!['tipoUsuario']}',
      );
      await denied(
        () => api.request('DELETE', '/api/Usuarios/$id'),
        403,
        'Servidor bloqueia desativação por ${api.user!['tipoUsuario']}',
      );
    }
    await service.deactivate(id);
    check(
      !(await service.list()).any((u) => u['id'] == id),
      'Conta desativada sai da lista ativa',
    );
    await denied(
      () => created.request('GET', '/api/Usuarios/me'),
      401,
      'Desativação revoga a sessão ativa',
    );
    await denied(
      () => created.login(data['email'], newPassword),
      401,
      'Conta desativada não faz login',
    );
    await service.save({
      ...own,
      'nome': 'Administrador atualizado no mobile',
      'senha': null,
    }, id: ownId);
    check(
      admin.user!['nome'] == 'Administrador atualizado no mobile',
      'Edição própria atualiza os dados locais da conta',
    );
    await service.save({...own, 'senha': newPassword}, id: ownId);
    check(admin.user == null, 'Redefinição própria limpa a sessão local');
    await admin.login(fixture['email'], newPassword);
    check(
      admin.user!['id'] == ownId,
      'Administrador entra novamente com a nova senha',
    );
    stdout.writeln('Usuários Dart: $checks verificações passaram.');
  } finally {
    admin.dispose();
    staff.dispose();
    client.dispose();
    created.dispose();
  }
}
