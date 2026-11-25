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
  final admin = UniduniApi(), client = UniduniApi();
  int checks = 0;
  int? orderId;
  void check(bool condition, String message) {
    if (!condition) throw StateError(message);
    checks++;
    stdout.writeln('OK: $message');
  }

  try {
    await admin.login(fixture['email'], fixture['senha']);
    final category = (await admin.categories()).firstWhere(
      (c) => c['nome'] == 'Roupas',
    );
    await admin.saveProduct({
      'nome': '$prefix Compra mobile',
      'descricao': 'Produto temporário do teste de compras Flutter.',
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
      (p) => p['nome'] == '$prefix Compra mobile',
    );
    final id = product['id'] as int;
    final variation = product['variacoes'][0]['id'] as int;
    await client.login(fixture['clienteEmail'], fixture['senha']);
    final shop = ShoppingService(client);
    await shop.add(variation, 1);
    await shop.add(variation, 1);
    check(
      (await shop.cart())['itens'][0]['quantidade'] == 2,
      'Inclusões somam quantidades no carrinho persistido',
    );
    var order = await shop.checkout();
    orderId = order['id'];
    check(
      order['total'] == 59.8 && order['status'] == 'Pendente',
      'Pedido calcula total e inicia pendente',
    );
    check(
      ((await shop.cart())['itens'] as List).isEmpty,
      'Finalização limpa o carrinho',
    );
    var stock = (await admin.adminProduct(id))['variacoes'][0];
    check(
      stock['estoque'] == 8 && stock['reservado'] == 2,
      'Finalização reserva sem baixar físico',
    );
    order = await shop.pay(orderId!, 'Cartao', 'Recusado');
    check(order['status'] == 'Recusado', 'Cartão recusado fica no histórico');
    stock = (await admin.adminProduct(id))['variacoes'][0];
    check(
      stock['reservado'] == 0 && stock['estoque'] == 8,
      'Recusa libera reserva',
    );
    order = await shop.pay(orderId, 'Pix', 'Pendente');
    final pending = (order['pagamentos'] as List).first;
    check(
      pending['codigoPix'].toString().startsWith('SIMULACAO'),
      'Pix pendente possui identificador fictício',
    );
    order = Map<String, dynamic>.from(
      await client.request(
        'POST',
        '/api/compras/pedidos/$orderId/pagamentos/${pending['id']}/resolver',
        body: {'resultado': 'Aprovado'},
      ),
    );
    check(
      order['status'] == 'Pago' &&
          order['codigoRetirada'].toString().length == 8,
      'Aprovação fornece código ao comprador',
    );
    stock = (await admin.adminProduct(id))['variacoes'][0];
    check(
      stock['estoque'] == 6 && stock['reservado'] == 0,
      'Aprovação baixa físico e encerra reserva',
    );
    check(
      (await client.request('GET', '/api/compras/pedidos') as List).any(
        (p) => p['id'] == orderId,
      ),
      'Pedido aparece na consulta compartilhada com o site',
    );
    order = Map<String, dynamic>.from(
      await client.request(
        'POST',
        '/api/compras/pedidos/$orderId/cancelar',
        body: {'motivo': 'Encerramento do teste temporário Flutter.'},
      ),
    );
    check(
      order['status'] == 'Cancelado' &&
          (order['pagamentos'] as List).any(
            (pg) => pg['status'] == 'Estornado',
          ),
      'Cancelamento registra estorno simulado',
    );
    stock = (await admin.adminProduct(id))['variacoes'][0];
    check(
      stock['estoque'] == 8 && stock['reservado'] == 0,
      'Cancelamento restaura os saldos',
    );
    stdout.writeln('Compras Dart: $checks verificações passaram.');
  } finally {
    // Se uma verificação falhar após finalizar, encerra somente o pedido deste teste.
    if (orderId != null) {
      try {
        await client.request(
          'POST',
          '/api/compras/pedidos/$orderId/cancelar',
          body: {'motivo': 'Limpeza segura do teste temporário Flutter.'},
        );
      } catch (_) {}
    }
    admin.dispose();
    client.dispose();
  }
}
