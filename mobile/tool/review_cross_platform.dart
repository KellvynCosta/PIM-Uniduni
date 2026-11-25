import 'dart:convert';
import 'dart:io';

import 'package:uniduni_mobile/core/api.dart';
import 'package:uniduni_mobile/core/shopping_service.dart';

// Revisão manual no navegador entre preparar e conferir. Usa somente o fixture.
Future<void> main(List<String> args) async {
  final fixtureFile = File(args[0]);
  final fixture = jsonDecode(await fixtureFile.readAsString());
  final prefix = fixture['prefix'] as String;
  if (!prefix.startsWith('pim-ui-') ||
      fixture['email'] != '$prefix-admin@example.invalid') {
    throw StateError('Fixture inválido.');
  }
  final evidence = File('${fixtureFile.parent.path}/revisao-integrada.json');
  final admin = UniduniApi(), client = UniduniApi();
  void check(bool valid, String text) {
    if (!valid) throw StateError(text);
    stdout.writeln('OK: $text');
  }

  try {
    await admin.login(fixture['email'], fixture['senha']);
    await client.login(fixture['clienteEmail'], fixture['senha']);
    final manager = ShoppingService(admin), customer = ShoppingService(client);
    if (args[1] == 'preparar') {
      if (await evidence.exists()) {
        throw StateError('Conclua a revisão anterior primeiro.');
      }
      final baseline = (await manager.summary())['totalVendido'];
      final category = (await admin.categories()).firstWhere(
        (c) => c['nome'] == 'Roupas',
      );
      final name = '$prefix Revisão entre plataformas';
      await admin.saveProduct({
        'nome': name,
        'descricao': 'Peça exclusiva da revisão integrada.',
        'preco': 29.9,
        'genero': 'Unissex',
        'imagem': '',
        'categoriaId': category['id'],
        'guiaMedidas': 'P: tamanho demonstrativo.',
        'ativo': true,
        'variacaoInicial': {
          'cor': 'Azul',
          'tamanho': 'P',
          'estoqueInicial': 8,
          'estoqueMinimo': 2,
        },
      });
      final product = (await admin.adminProducts()).singleWhere(
        (p) => p['nome'] == name,
      );
      final vid = product['variacoes'][0]['id'] as int;
      await customer.add(vid, 2);
      var order = await customer.checkout();
      order = await customer.pay(order['id'], 'Pix', 'Aprovado');
      await evidence.writeAsString(
        jsonEncode({
          'prefix': prefix,
          'orderId': order['id'],
          'productId': product['id'],
          'code': order['codigoRetirada'],
          'baseline': baseline,
        }),
      );
      check(
        order['status'] == 'Pago' && order['total'] == 59.8,
        'Compra pelos serviços Flutter aprovada para atendimento no site',
      );
    } else if (args[1] == 'conferir') {
      final data = jsonDecode(await evidence.readAsString());
      if (data['prefix'] != prefix) {
        throw StateError('Evidência pertence a outro fixture.');
      }
      final order = await client.request(
        'GET',
        '/api/compras/pedidos/${data['orderId']}',
      );
      final product = await admin.adminProduct(data['productId']);
      check(
        order['status'] == 'Retirado' &&
            order['retiradoPor'] != null &&
            order['retiradoEm'] != null,
        'Serviços Flutter recebem retirada e responsável registrados no navegador',
      );
      check(
        (await customer.orders()).any(
          (p) => p['id'] == data['orderId'] && p['status'] == 'Retirado',
        ),
        'Lista pessoal de pedidos recebe situação atualizada',
      );
      final v = product['variacoes'][0];
      check(
        v['estoque'] == 6 && v['reservado'] == 0 && v['disponivel'] == 6,
        'Saldo físico e reserva permanecem corretos após retirada pelo site',
      );
      final total = (await manager.summary())['totalVendido'] as num;
      check(
        (total - (data['baseline'] as num) - 59.8).abs() < .001,
        'Resumo mobile inclui a venda atendida no site',
      );
      await evidence.delete();
    } else {
      throw StateError('Use preparar ou conferir.');
    }
  } finally {
    admin.dispose();
    client.dispose();
  }
}
