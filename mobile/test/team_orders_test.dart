import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uniduni_mobile/core/api.dart';
import 'package:uniduni_mobile/core/shopping_service.dart';
import 'package:uniduni_mobile/features/shopping.dart';
import 'package:uniduni_mobile/features/sales_summary.dart';

import 'shopping_test.dart' show BuyApi;

class TeamApi extends BuyApi {
  final paths = <String>[];
  TeamApi({String role = 'Funcionario'}) {
    user = {'id': 2, 'tipoUsuario': role};
    status = 'Pago';
    paymentStatus = 'Aprovado';
  }
  @override
  Map<String, dynamic> order() => {
    ...super.order(),
    'cliente': 'Cliente da loja',
    'codigoRetirada': null,
    if (status == 'Retirado') 'retiradoEm': '2026-10-26T15:00:00Z',
    if (status == 'Retirado') 'retiradoPor': 2,
  };
  @override
  Future<dynamic> request(String method, String path, {Object? body}) async {
    paths.add(path);
    if (path.contains('/resumo')) {
      return {'totalVendido': 89.8, 'quantidadeVendas': 1};
    }
    if (path == '/api/compras/pedidos?equipe=true') return [order()];
    if (path.endsWith('/andamento')) {
      final data = body as Map;
      if (data['status'] == 'Retirado' && data['codigo'] != '1234ABCD') {
        throw const ApiException(
          'Código de retirada incorreto.',
          statusCode: 400,
        );
      }
      status = data['status'];
      return order();
    }
    return super.request(method, path, body: body);
  }
}

void main() {
  test(
    'resumo usa início inclusivo e fim exclusivo e bloqueia perfis',
    () async {
      final api = TeamApi(role: 'Administrador');
      addTearDown(api.dispose);
      final shop = ShoppingService(api);
      final start = DateTime(2026, 10, 1), end = DateTime(2026, 10, 26);
      await shop.summary(start: start, end: end);
      final uri = Uri.parse(api.paths.single);
      expect(uri.queryParameters['inicio'], start.toUtc().toIso8601String());
      expect(
        uri.queryParameters['fim'],
        DateTime(2026, 10, 27).toUtc().toIso8601String(),
      );
      await expectLater(
        shop.summary(start: end, end: start),
        throwsA(isA<ApiException>()),
      );
      api.user!['tipoUsuario'] = 'Funcionario';
      await expectLater(shop.summary(), throwsA(isA<ApiException>()));
      api.user!['tipoUsuario'] = 'Cliente';
      await expectLater(shop.orders(team: true), throwsA(isA<ApiException>()));
      await expectLater(
        shop.advance(1, 'EmPreparacao'),
        throwsA(isA<ApiException>()),
      );
      expect(api.paths.length, 1);
    },
  );
  testWidgets(
    'equipe prepara e retira por código, sem pagar por outro cliente',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 1.5;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
        tester.platformDispatcher.clearTextScaleFactorTestValue();
      });
      final api = TeamApi();
      addTearDown(api.dispose);
      await tester.pumpWidget(
        MaterialApp(home: OrderPage(api: api, id: 1, team: true)),
      );
      await tester.pumpAndSettle();
      Future<void> tap(String text) async {
        final finder = find.text(text);
        await Scrollable.ensureVisible(tester.element(finder), alignment: .2);
        await tester.pumpAndSettle();
        await tester.tap(finder);
        await tester.pumpAndSettle();
      }

      expect(find.text('1234ABCD'), findsNothing);
      expect(find.text('Simular pagamento'), findsNothing);
      await tap('Iniciar preparação');
      expect(api.status, 'EmPreparacao');
      await tap('Marcar pronto para retirada');
      expect(api.status, 'Pronto');
      await tap('Confirmar retirada');
      expect(
        find.text('Informe o código apresentado pelo cliente.'),
        findsOneWidget,
      );
      Future<void> code(String value) async {
        final field = find.byType(TextField);
        await Scrollable.ensureVisible(tester.element(field));
        await tester.pumpAndSettle();
        await tester.enterText(field, value);
        await tester.testTextInput.receiveAction(TextInputAction.done);
        await tester.pumpAndSettle();
      }

      await code('INCORRETO');
      await tap('Confirmar retirada');
      await tester.tap(find.text('Confirmar entrega'));
      await tester.pumpAndSettle();
      expect(find.text('Código de retirada incorreto.'), findsOneWidget);
      expect(api.status, 'Pronto');
      await code('1234ABCD');
      await tap('Confirmar retirada');
      await tester.tap(find.text('Confirmar entrega'));
      await tester.pumpAndSettle();
      expect(api.status, 'Retirado');
      expect(find.text('Cancelar pedido'), findsNothing);
      expect(find.textContaining('operador 2'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('lista da equipe filtra por cliente e situação', (tester) async {
    final api = TeamApi();
    addTearDown(api.dispose);
    await tester.pumpWidget(
      MaterialApp(home: OrdersPage(api: api, team: true)),
    );
    await tester.pumpAndSettle();
    expect(find.text('Pedido #1'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'inexistente');
    await tester.pumpAndSettle();
    expect(
      find.text('Nenhum pedido encontrado nesta consulta.'),
      findsOneWidget,
    );
    await tester.enterText(find.byType(TextField), 'Cliente');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Retirado').last);
    await tester.pumpAndSettle();
    expect(find.text('Pedido #1'), findsNothing);
  });
  testWidgets('total vendido mostra valor e não consulta com perfil restrito', (
    tester,
  ) async {
    final api = TeamApi(role: 'Administrador');
    addTearDown(api.dispose);
    await tester.pumpWidget(MaterialApp(home: SalesSummaryPage(api: api)));
    await tester.pumpAndSettle();
    expect(find.text('R\$ 89,80'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    api.user!['tipoUsuario'] = 'Funcionario';
    api.paths.clear();
    await tester.pumpWidget(MaterialApp(home: SalesSummaryPage(api: api)));
    await tester.pumpAndSettle();
    expect(find.text('Acesso exclusivo do Administrador.'), findsOneWidget);
    expect(api.paths, isEmpty);
  });
}
