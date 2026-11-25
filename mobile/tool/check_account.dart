import 'dart:convert';
import 'dart:io';

import 'package:uniduni_mobile/core/api.dart';
import 'package:uniduni_mobile/core/account_service.dart';

Future<void> main(List<String> args) async {
  final fixture = jsonDecode(await File(args.single).readAsString());
  final prefix = fixture['prefix'] as String;
  if (!prefix.startsWith('pim-ui-') ||
      fixture['email'] != '$prefix-admin@example.invalid') {
    throw StateError('Use somente contas temporárias da revisão.');
  }
  final api = UniduniApi(),
      otherSession = UniduniApi(),
      admin = UniduniApi(),
      staff = UniduniApi();
  int checks = 0;
  void check(bool valid, String message) {
    if (!valid) throw StateError(message);
    checks++;
    stdout.writeln('OK: $message');
  }

  Future<void> denied(
    Future<dynamic> Function() action,
    int status,
    String message,
  ) async {
    try {
      await action();
      throw StateError(message);
    } on ApiException catch (e) {
      check(e.statusCode == status, message);
    }
  }

  final email = '$prefix-mobile@example.invalid',
      password = fixture['senha'] as String;
  try {
    final account = AccountService(api);
    await account.register(
      name: 'Cliente cadastrado pelo mobile',
      email: email,
      password: password,
      phone: '(11) 99999-0000',
    );
    check(
      api.user == null,
      'Cadastro não inicia uma sessão sem confirmação do login',
    );
    await api.login(email, password);
    check(
      api.user!['tipoUsuario'] == 'Cliente' &&
          api.user!['telefone'] == '(11) 99999-0000',
      'Cadastro público cria Cliente com dados persistidos',
    );
    check(
      !api.user!.containsKey('senha'),
      'Resposta de autenticação não expõe senha',
    );
    await denied(
      () =>
          account.register(name: 'Duplicado', email: email, password: password),
      409,
      'Email duplicado é rejeitado',
    );
    await denied(
      () => api.request(
        'PUT',
        '/api/Usuarios/alterar-senha/${api.user!['id']}',
        body: {'senhaAtual': password, 'novaSenha': '123'},
      ),
      400,
      'Servidor rejeita nova senha curta',
    );
    await denied(
      () => account.changePassword('senha-incorreta', '${password}N'),
      400,
      'Senha atual incorreta é rejeitada',
    );
    check(
      (await api.request('GET', '/api/Usuarios/me'))['email'] == email,
      'Erro de senha atual preserva sessão',
    );
    await admin.login(fixture['email'], password);
    await denied(
      () => api.request(
        'PUT',
        '/api/Usuarios/alterar-senha/${admin.user!['id']}',
        body: {'senhaAtual': password, 'novaSenha': '${password}N'},
      ),
      403,
      'Cliente não troca a senha de outra conta',
    );
    await otherSession.login(email, password);
    await account.changePassword(password, '${password}N');
    check(api.user == null, 'Troca confirmada encerra sessão local');
    await denied(
      () => otherSession.request('GET', '/api/Usuarios/me'),
      401,
      'Troca revoga outra sessão da mesma conta',
    );
    await denied(
      () => api.login(email, password),
      401,
      'Senha anterior deixa de funcionar',
    );
    await api.login(email, '${password}N');
    check(
      api.user!['tipoUsuario'] == 'Cliente',
      'Nova senha autentica na mesma API do site',
    );
    await staff.login(fixture['funcionarioEmail'], password);
    for (final member in [staff, admin]) {
      final memberEmail = member.user!['email'];
      final role = member.user!['tipoUsuario'];
      await AccountService(member).changePassword(password, '${password}N');
      check(member.user == null, 'Troca própria encerra sessão de $role');
      await member.login(memberEmail, '${password}N');
      check(
        member.user!['tipoUsuario'] == role,
        'Nova senha mantém perfil de $role',
      );
    }
    stdout.writeln('Conta Dart: $checks verificações passaram.');
  } finally {
    api.dispose();
    otherSession.dispose();
    admin.dispose();
    staff.dispose();
  }
}
