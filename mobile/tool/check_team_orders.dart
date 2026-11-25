import 'dart:convert';
import 'dart:io';

import 'package:uniduni_mobile/core/api.dart';
import 'package:uniduni_mobile/core/shopping_service.dart';

Future<void> main(List<String> args) async {
  final fixture = jsonDecode(await File(args.single).readAsString());
  final prefix = fixture['prefix'] as String;
  if (!prefix.startsWith('pim-ui-') ||
      fixture['email'] != '$prefix-admin@example.invalid') {
    throw StateError('Fixture inválido.');
  }
  final admin = UniduniApi(), client = UniduniApi(), staff = UniduniApi();
  final created = <int>[];
  int checks = 0;
  void check(bool condition, String message) {
    if (!condition) throw StateError(message);
    checks++;
    stdout.writeln('OK: $message');
  }

  Future<void> denied(
    Future<dynamic> Function() operation,
    String message, {
    int? code,
  }) async {
    try {
      await operation();
      throw StateError('Operação permitida indevidamente: $message');
    } on ApiException catch (e) {
      check(
        code == null
            ? e.statusCode != null && e.statusCode! >= 400
            : e.statusCode == code,
        message,
      );
    }
  }

  try {
    await admin.login(fixture['email'], fixture['senha']);
    await client.login(fixture['clienteEmail'], fixture['senha']);
    await staff.login(fixture['funcionarioEmail'], fixture['senha']);
    final manager = ShoppingService(admin),
        crew = ShoppingService(staff),
        customer = ShoppingService(client);
    final baseline = (await manager.summary())['totalVendido'] as num;
    final category = (await admin.categories()).firstWhere(
      (c) => c['nome'] == 'Roupas',
    );
    await admin.saveProduct({
      'nome': '$prefix Atendimento mobile',
      'descricao': 'Produto exclusivo da integração de retirada Flutter.',
      'preco': 29.9,
      'genero': 'Unissex',
      'imagem': '',
      'categoriaId': category['id'],
      'guiaMedidas': '',
      'ativo': true,
      'variacaoInicial': {
        'cor': 'Azul',
        'tamanho': 'P',
        'estoqueInicial': 8,
        'estoqueMinimo': 2,
      },
    });
    final product = (await admin.adminProducts()).singleWhere(
      (p) => p['nome'] == '$prefix Atendimento mobile',
    );
    final id = product['id'] as int;
    final variation = product['variacoes'][0]['id'] as int;
    await customer.add(variation, 2);
    var order = await customer.checkout();
    final orderId = order['id'] as int;
    created.add(orderId);
    order = await customer.pay(orderId, 'Pix', 'Aprovado');
    final code = order['codigoRetirada'] as String;
    check(
      (await crew.orders(team: true)).any((p) => p['id'] == orderId),
      'Equipe lista o pedido comprado pelo cliente',
    );
    final teamView = await staff.request(
      'GET',
      '/api/compras/pedidos/$orderId',
    );
    check(
      teamView['codigoRetirada'] == null,
      'Código não é revelado à equipe pela API',
    );
    await denied(
      () => client.request('GET', '/api/compras/pedidos?equipe=true'),
      'Cliente não lista pedidos da equipe',
      code: 403,
    );
    await denied(
      () => client.request(
        'POST',
        '/api/compras/pedidos/$orderId/andamento',
        body: {'status': 'EmPreparacao'},
      ),
      'Cliente não altera o atendimento',
      code: 403,
    );
    await denied(
      () => staff.request('GET', '/api/compras/resumo'),
      'Funcionário não consulta total vendido',
      code: 403,
    );
    await denied(
      () => client.request('GET', '/api/compras/resumo'),
      'Cliente não consulta total vendido',
      code: 403,
    );
    await denied(
      () => crew.advance(orderId, 'Pronto'),
      'Servidor impede pular preparação',
    );
    order = await crew.advance(orderId, 'EmPreparacao');
    check(order['status'] == 'EmPreparacao', 'Funcionário inicia preparação');
    await denied(
      () => client.request(
        'POST',
        '/api/compras/pedidos/$orderId/cancelar',
        body: {'motivo': 'Cliente tenta cancelar após preparação.'},
      ),
      'Cliente não cancela após preparação',
      code: 403,
    );
    order = await crew.advance(orderId, 'Pronto');
    check(order['status'] == 'Pronto', 'Funcionário marca pronto');
    await denied(
      () => crew.advance(orderId, 'Retirado', code: 'INCORRETO'),
      'Código incorreto não conclui retirada',
      code: 400,
    );
    order = await crew.advance(orderId, 'Retirado', code: code);
    check(
      order['status'] == 'Retirado' &&
          order['retiradoEm'] != null &&
          order['retiradoPor'] == staff.user!['id'],
      'Retirada registra operador e horário',
    );
    await crew.advance(orderId, 'Retirado', code: code);
    var stock = (await admin.adminProduct(id))['variacoes'][0];
    check(
      stock['estoque'] == 6 && stock['reservado'] == 0,
      'Retirada repetida não duplica baixa',
    );
    var total = (await manager.summary())['totalVendido'] as num;
    check(
      (total - baseline - 59.8).abs() < .001,
      'Total vendido inclui a venda retirada',
    );
    await denied(
      () => staff.request(
        'POST',
        '/api/compras/pedidos/$orderId/cancelar',
        body: {'motivo': 'Tentativa de cancelar após retirada.'},
      ),
      'Equipe não cancela pedido retirado',
    );
    await customer.add(variation, 1);
    var second = await customer.checkout();
    final secondId = second['id'] as int;
    created.add(secondId);
    await customer.pay(secondId, 'Cartao', 'Aprovado');
    await crew.advance(secondId, 'EmPreparacao');
    second = Map<String, dynamic>.from(
      await staff.request(
        'POST',
        '/api/compras/pedidos/$secondId/cancelar',
        body: {'motivo': 'Cancelamento pela equipe antes da retirada.'},
      ),
    );
    check(
      second['status'] == 'Cancelado' &&
          (second['pagamentos'] as List).any(
            (pg) => pg['status'] == 'Estornado',
          ),
      'Equipe cancela durante preparação e registra estorno',
    );
    stock = (await admin.adminProduct(id))['variacoes'][0];
    check(
      stock['estoque'] == 6 && stock['reservado'] == 0,
      'Estorno restaura somente as unidades do pedido cancelado',
    );
    total = (await manager.summary())['totalVendido'];
    check(
      (total - baseline - 59.8).abs() < .001,
      'Total vendido exclui pagamento estornado',
    );
    final future = DateTime.now().add(const Duration(days: 365));
    check(
      (await manager.summary(start: future, end: future))['totalVendido'] == 0,
      'Consulta por dia futuro não inclui as vendas do teste',
    );
    stdout.writeln('Atendimento Dart: $checks verificações passaram.');
  } finally {
    // Encerra pedidos ainda canceláveis. Retiradas usam SOMENTE o produto exclusivo do fixture.
    for (final id in created) {
      try {
        await staff.request(
          'POST',
          '/api/compras/pedidos/$id/cancelar',
          body: {'motivo': 'Limpeza da integração temporária de atendimento.'},
        );
      } catch (_) {}
    }
    admin.dispose();
    client.dispose();
    staff.dispose();
  }
}
