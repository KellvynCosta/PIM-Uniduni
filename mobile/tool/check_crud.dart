import 'dart:convert';
import 'dart:io';

import 'package:uniduni_mobile/core/api.dart';

Future<void> main(List<String> args) async {
  final fixture = jsonDecode(await File(args.single).readAsString());
  final prefix = fixture['prefix'] as String;
  if (!prefix.startsWith('pim-ui-') ||
      fixture['email'] != '$prefix-admin@example.invalid') {
    throw const ApiException('Use somente contas temporárias da revisão.');
  }
  final api = UniduniApi();
  var checks = 0;
  void check(bool condition, String description) {
    if (!condition) throw StateError(description);
    checks++;
    stdout.writeln('OK: $description');
  }

  try {
    await api.login(fixture['email'], fixture['senha']);
    final categories = await api.categories();
    final clothes = categories.firstWhere((c) => c['nome'] == 'Roupas');
    final data = <String, dynamic>{
      'nome': '$prefix Body mobile',
      'descricao': 'Produto temporário do teste Flutter.',
      'preco': 49.9,
      'categoriaId': clothes['id'],
      'genero': 'Unissex',
      'imagem': '',
      'guiaMedidas': 'Tamanho P.',
      'ativo': true,
      'variacaoInicial': {
        'cor': 'Azul',
        'tamanho': 'P',
        'estoqueInicial': 4,
        'estoqueMinimo': 2,
      },
    };
    await api.saveProduct(data);
    final product = (await api.adminProducts()).singleWhere(
      (p) => p['nome'] == data['nome'],
    );
    final id = product['id'] as int;
    check(
      (await api.catalog()).any((p) => p['id'] == id),
      'Cadastro Dart aparece no catálogo público compartilhado com o site',
    );
    data.remove('variacaoInicial');
    data['nome'] = '$prefix Body mobile editado';
    data['preco'] = 59.9;
    await api.saveProduct(data, id: id);
    final edited = await api.adminProduct(id);
    check(
      edited['nome'] == data['nome'] && edited['preco'] == 59.9,
      'Edição de nome e preço persistida',
    );
    check(
      edited['variacoes'][0]['estoque'] == 4,
      'Edição preserva o saldo físico',
    );
    await api.logout();
    await api.login(fixture['funcionarioEmail'], fixture['senha']);
    data['descricao'] = 'Descrição atualizada pelo funcionário no Flutter.';
    await api.saveProduct(data, id: id);
    check(
      (await api.adminProduct(id))['descricao'] == data['descricao'],
      'Funcionário pode editar o produto',
    );
    await api.deactivateProduct(id);
    check(
      !(await api.catalog()).any((p) => p['id'] == id),
      'Desativação remove somente do catálogo público',
    );
    check(
      (await api.adminProduct(id))['ativo'] == false,
      'Registro inativo permanece na administração',
    );
    data['ativo'] = true;
    await api.saveProduct(data, id: id);
    check(
      (await api.catalog()).any((p) => p['id'] == id),
      'Reativação devolve o produto ao catálogo',
    );
    await api.logout();
    await api.login(fixture['clienteEmail'], fixture['senha']);
    check(!api.isTeam, 'Cliente não tem perfil de equipe');
    try {
      await api.request('DELETE', '/api/Produtos/$id');
      throw StateError('Cliente conseguiu excluir.');
    } on ApiException catch (e) {
      check(
        e.statusCode == 403,
        'API rejeita tentativa de exclusão pelo cliente',
      );
    }
    try {
      await api.adminProducts();
      throw StateError('Cliente acessou a administração.');
    } on ApiException catch (e) {
      check(
        e.statusCode == 403,
        'API rejeita consulta administrativa pelo cliente',
      );
    }
    await api.logout();
    stdout.writeln('CRUD Dart: $checks verificações passaram.');
  } finally {
    api.dispose();
  }
}
