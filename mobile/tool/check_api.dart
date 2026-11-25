import 'dart:io';
import 'dart:convert';

import 'package:uniduni_mobile/core/api.dart';

Future<void> main(List<String> args) async {
  final api = UniduniApi();
  try {
    final products = await api.catalog();
    for (final product in products) {
      if (product['nome'] is! String ||
          product['preco'] is! num ||
          product['variacoes'] is! List) {
        throw const ApiException('Resposta de catálogo incompatível.');
      }
    }
    stdout.writeln(
      'API acessível pelo cliente Dart: ${products.length} produtos.',
    );
    // Arquivo opcional criado pelo preparador de contas temporárias dos testes.
    if (args.isNotEmpty) {
      final fixture = jsonDecode(await File(args.single).readAsString());
      if (!(fixture['prefix'] as String).startsWith('pim-ui-')) {
        throw const ApiException(
          'Use somente as contas temporárias de revisão.',
        );
      }
      for (final key in ['clienteEmail', 'funcionarioEmail', 'email']) {
        await api.login(fixture[key], fixture['senha']);
        final me = await api.request('GET', '/api/Usuarios/me');
        if (me['id'] != api.user?['id']) {
          throw const ApiException(
            'Sessão não corresponde ao usuário autenticado.',
          );
        }
        stdout.writeln('Login e sessão Dart validados: ${me['tipoUsuario']}.');
        await api.logout();
        if (api.user != null) {
          throw const ApiException('Logout não limpou a sessão.');
        }
      }
    }
  } finally {
    api.dispose();
  }
}
