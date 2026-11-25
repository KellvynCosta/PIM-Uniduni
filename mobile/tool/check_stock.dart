import 'dart:convert';
import 'dart:io';

import 'package:uniduni_mobile/core/api.dart';
import 'package:uniduni_mobile/core/stock_service.dart';
import 'package:uniduni_mobile/core/shopping_service.dart';

Future<void> main(List<String> args) async {
  final fixture = jsonDecode(await File(args.single).readAsString());
  final prefix = fixture['prefix'] as String;
  if (!prefix.startsWith('pim-ui-') ||
      fixture['email'] != '$prefix-admin@example.invalid') {
    throw StateError('Use somente contas temporárias da revisão.');
  }
  final admin = UniduniApi(), staff = UniduniApi(), client = UniduniApi();
  int? orderId;
  int checks = 0;
  void check(bool value, String text) {
    if (!value) throw StateError(text);
    checks++;
    stdout.writeln('OK: $text');
  }

  try {
    await admin.login(fixture['email'], fixture['senha']);
    await staff.login(fixture['funcionarioEmail'], fixture['senha']);
    await client.login(fixture['clienteEmail'], fixture['senha']);
    final category = (await admin.categories()).firstWhere(
      (c) => c['nome'] == 'Roupas',
    );
    await admin.saveProduct({
      'nome': '$prefix Estoque mobile',
      'descricao': 'Produto exclusivo da verificação de estoque.',
      'preco': 29.9,
      'categoriaId': category['id'],
      'genero': 'Unissex',
      'imagem': '',
      'guiaMedidas': 'Tamanho P',
      'ativo': true,
      'variacaoInicial': {
        'cor': 'Azul',
        'tamanho': 'P',
        'estoqueInicial': 4,
        'estoqueMinimo': 2,
      },
    });
    final product = (await admin.adminProducts()).singleWhere(
      (p) => p['nome'] == '$prefix Estoque mobile',
    );
    final id = product['id'] as int;
    final vid = product['variacoes'][0]['id'] as int;
    Future<Map<String, dynamic>> current() async => Map<String, dynamic>.from(
      (await admin.adminProduct(id))['variacoes'][0],
    );
    final stock = StockService(staff);
    var v = await current();
    final oldVersion = v['versao'] as String;
    await stock.move(
      vid,
      oldVersion,
      'Entrada',
      3,
      'Reposição recebida no mobile',
    );
    v = await current();
    check(v['estoque'] == 7, 'Entrada soma unidades no banco compartilhado');
    try {
      await stock.move(
        vid,
        oldVersion,
        'Entrada',
        1,
        'Versão anterior do teste',
      );
      throw StateError('Versão antiga foi aceita');
    } on ApiException catch (e) {
      check(e.statusCode == 409, 'Versão antiga é rejeitada sem sobrescrever');
    }
    final version = v['versao'];
    final operation = staff.operation('stock-replay-check');
    final data = {
      'tipo': 'Entrada',
      'quantidade': 1,
      'justificativa': 'Entrada com repetição controlada',
      'versao': version,
      'operacaoId': operation,
    };
    await staff.request(
      'POST',
      '/api/Estoque/variacoes/$vid/movimentacoes',
      body: data,
    );
    await staff.request(
      'POST',
      '/api/Estoque/variacoes/$vid/movimentacoes',
      body: data,
    );
    check(
      (await current())['estoque'] == 8,
      'Repetição da operação não duplica entrada',
    );
    final shop = ShoppingService(client);
    await shop.quantity(vid, 2);
    orderId = (await shop.checkout())['id'];
    v = await current();
    check(
      v['reservado'] == 2,
      'Pedido reserva unidades da combinação de teste',
    );
    try {
      await stock.move(
        vid,
        v['versao'],
        'Ajuste',
        1,
        'Contagem abaixo da reserva',
      );
      throw StateError('Ajuste inválido foi aceito');
    } on ApiException catch (e) {
      check(e.statusCode == 409, 'API impede saldo menor que o reservado');
    }
    await stock.move(
      vid,
      v['versao'],
      'Ajuste',
      3,
      'Contagem física conferida',
    );
    v = await current();
    check(
      v['estoque'] == 3 && v['disponivel'] == 1 && v['reservado'] == 2,
      'Ajuste define saldo físico e preserva reserva',
    );
    check(
      (await stock.alerts()).any((a) => a['id'] == vid),
      'Alerta considera disponível e mínimo',
    );
    final history = await stock.history(variationId: vid);
    check(
      history.any(
        (m) =>
            m['tipo'] == 'Ajuste' &&
            m['saldoAnterior'] == 8 &&
            m['saldoAtual'] == 3 &&
            m['responsavel'] != null,
      ),
      'Histórico registra saldos, responsável e justificativa',
    );
    check(
      (await client.catalog()).singleWhere((p) => p['id'] == id)['estoque'] ==
          1,
      'Catálogo público do site recebe o saldo atualizado',
    );
    for (final path in ['/api/Estoque/alertas', '/api/Estoque/historico']) {
      try {
        await client.request('GET', path);
        throw StateError('Cliente acessou estoque');
      } on ApiException catch (e) {
        check(e.statusCode == 403, 'API bloqueia cliente em $path');
      }
    }
    try {
      await client.request(
        'POST',
        '/api/Estoque/variacoes/$vid/movimentacoes',
        body: data,
      );
      throw StateError('Cliente movimentou estoque');
    } on ApiException catch (e) {
      check(e.statusCode == 403, 'API bloqueia movimentação por cliente');
    }
    stdout.writeln('Estoque Dart: $checks verificações passaram.');
  } finally {
    if (orderId != null) {
      await client.request(
        'POST',
        '/api/compras/pedidos/$orderId/cancelar',
        body: {'motivo': 'Limpeza da verificação temporária de estoque.'},
      );
    }
    admin.dispose();
    staff.dispose();
    client.dispose();
  }
}
