import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uniduni_mobile/core/api.dart';
import 'package:uniduni_mobile/core/shopping_service.dart';
import 'package:uniduni_mobile/features/shopping.dart';

class BuyApi extends UniduniApi {
  int qty = 2;
  bool failCheckout = false;
  final operations = <String>[];
  String status = 'Pendente', paymentStatus = '';
  BuyApi() {
    user = {'id': 1, 'tipoUsuario': 'Cliente'};
  }
  Map<String, dynamic> order() => {
    'id': 1,
    'usuarioId': 1,
    'status': status,
    'total': 89.8,
    'criadoEm': '2026-10-23T15:00:00Z',
    'reservaAte': status == 'Pendente' ? '2026-10-23T15:30:00Z' : null,
    'codigoRetirada': '1234ABCD',
    'itens': [
      {
        'nome': 'Body Azul',
        'cor': 'Azul',
        'tamanho': 'P',
        'quantidade': 2,
        'precoUnitario': 44.9,
        'subtotal': 89.8,
      },
    ],
    'pagamentos': paymentStatus.isEmpty
        ? []
        : [
            {
              'id': 9,
              'metodo': 'Pix',
              'status': paymentStatus,
              'valor': 89.8,
              'codigoPix': 'SIMULACAO-SEM-VALOR',
              'atualizadoEm': '2026-10-23T15:01:00Z',
            },
          ],
    'eventos': [],
  };
  @override
  Future<dynamic> request(String method, String path, {Object? body}) async {
    final data = body as Map?;
    if (path.endsWith('/carrinho')) {
      if (method == 'PUT') qty = data!['quantidade'];
      return {
        'itens': qty == 0
            ? []
            : [
                {
                  'variacaoId': 5,
                  'nome': 'Body Azul',
                  'cor': 'Azul',
                  'tamanho': 'P',
                  'quantidade': qty,
                  'preco': 44.9,
                  'subtotal': 44.9 * qty,
                  'disponivel': 5,
                  'ativo': true,
                },
              ],
        'total': 44.9 * qty,
      };
    }
    if (path == '/api/compras/pedidos' && method == 'POST') {
      operations.add(data!['operacaoId']);
      if (failCheckout) {
        failCheckout = false;
        throw const ApiException('Conexão interrompida.');
      }
      qty = 0;
      return order();
    }
    if (path.endsWith('/pagamentos')) {
      paymentStatus = data!['resultado'];
      status = paymentStatus == 'Aprovado'
          ? 'Pago'
          : paymentStatus == 'Recusado'
          ? 'Recusado'
          : 'Pendente';
    }
    if (path.endsWith('/resolver')) {
      paymentStatus = data!['resultado'];
      status = 'Pago';
    }
    if (path.endsWith('/cancelar')) {
      status = 'Cancelado';
      paymentStatus = 'Estornado';
    }
    return order();
  }
}

void main() {
  test(
    'finalização repete identificador após falha e renova após sucesso',
    () async {
      final api = BuyApi()..failCheckout = true;
      addTearDown(api.dispose);
      final shop = ShoppingService(api);
      await expectLater(shop.checkout(), throwsA(isA<ApiException>()));
      await shop.checkout();
      expect(api.operations[0], api.operations[1]);
      await shop.checkout();
      expect(api.operations[2], isNot(api.operations[1]));
      expect(
        api.operations[0],
        matches(
          RegExp(
            r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
          ),
        ),
      );
    },
  );
  testWidgets('quantidade, finalização, Pix pendente, aprovação e estorno', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 1.5;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      tester.platformDispatcher.clearTextScaleFactorTestValue();
    });
    final api = BuyApi();
    addTearDown(api.dispose);
    await tester.pumpWidget(MaterialApp(home: CartPage(api: api)));
    await tester.pumpAndSettle();
    Future<void> tap(String text) async {
      final finder = find.text(text);
      if (finder.evaluate().isEmpty) {
        await tester.scrollUntilVisible(
          finder,
          250,
          scrollable: find
              .byWidgetPredicate(
                (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
              )
              .last,
        );
      }
      await Scrollable.ensureVisible(tester.element(finder), alignment: .2);
      await tester.pumpAndSettle();
      await tester.tap(finder);
      await tester.pumpAndSettle();
    }

    await tester.tap(find.byTooltip('Aumentar quantidade de Body Azul'));
    await tester.pumpAndSettle();
    expect(api.qty, 3);
    await tester.tap(find.byTooltip('Diminuir quantidade de Body Azul'));
    await tester.pumpAndSettle();
    expect(api.qty, 2);
    await tap('Finalizar pedido');
    expect(api.qty, 0);
    expect(find.text('Pedido #1'), findsOneWidget);
    final result = find.byType(DropdownButtonFormField<String>).at(1);
    await Scrollable.ensureVisible(tester.element(result));
    await tester.pumpAndSettle();
    await tester.tap(result);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Deixar pendente').last);
    await tester.pumpAndSettle();
    await tap('Simular pagamento');
    expect(api.paymentStatus, 'Pendente');
    expect(find.text('SIMULACAO-SEM-VALOR'), findsOneWidget);
    await tap('Aprovar tentativa');
    expect(api.status, 'Pago');
    expect(find.text('1234ABCD'), findsOneWidget);
    await tap('Cancelar pedido');
    await tester.tap(find.text('Confirmar cancelamento'));
    await tester.pumpAndSettle();
    expect(
      find.text('Informe um motivo com pelo menos 5 caracteres.'),
      findsOneWidget,
    );
    await tester.enterText(find.byType(TextFormField), 'Cancelamento de teste');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confirmar cancelamento'));
    await tester.pumpAndSettle();
    expect(api.status, 'Cancelado');
    expect(api.paymentStatus, 'Estornado');
    expect(find.text('Cancelar pedido'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
