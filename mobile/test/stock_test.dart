import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uniduni_mobile/core/api.dart';
import 'package:uniduni_mobile/core/stock_service.dart';
import 'package:uniduni_mobile/features/stock.dart';

class StockApi extends UniduniApi {
  StockApi() {
    user = {'id': 1, 'tipoUsuario': 'Funcionario'};
  }
  int physical = 4, calls = 0;
  String version = 'version1';
  bool fail = false, conflict = false;
  final bodies = <Map>[];
  Map<String, dynamic> product() => {
    'id': 1,
    'nome': 'Body azul',
    'ativo': true,
    'variacoes': [
      {
        'id': 2,
        'cor': 'Azul',
        'tamanho': 'P',
        'ativo': true,
        'estoque': physical,
        'reservado': 2,
        'disponivel': physical - 2,
        'estoqueMinimo': 2,
        'versao': version,
      },
    ],
  };
  @override
  Future<List<Map<String, dynamic>>> adminProducts() async => [product()];
  @override
  Future<Map<String, dynamic>> adminProduct(int id) async => product();
  @override
  Future<dynamic> request(String method, String path, {Object? body}) async {
    calls++;
    if (path.endsWith('/alertas')) {
      return physical <= 4
          ? [
              {'id': 2},
            ]
          : [];
    }
    if (path.contains('/historico')) {
      return [
        {
          'produto': 'Body azul',
          'cor': 'Azul',
          'tamanho': 'P',
          'tipo': 'Entrada',
          'criadaEm': '2026-10-27T12:00:00Z',
          'saldoAnterior': 4,
          'saldoAtual': 7,
          'reservadoAnterior': 2,
          'reservadoAtual': 2,
          'responsavel': 'Equipe',
          'justificativa': 'Reposição recebida',
        },
      ];
    }
    bodies.add(Map.from(body as Map));
    if (fail) {
      fail = false;
      throw const ApiException('Conexão interrompida.');
    }
    if (conflict) {
      conflict = false;
      version = 'version2';
      throw const ApiException(
        'Estoque atualizado por outra operação.',
        statusCode: 409,
      );
    }
    physical = body['tipo'] == 'Entrada'
        ? physical + (body['quantidade'] as int)
        : body['quantidade'];
    return {'movimentoId': 1};
  }
}

void main() {
  test(
    'reutiliza operação na falha e bloqueia cliente antes da consulta',
    () async {
      final api = StockApi()..fail = true;
      addTearDown(api.dispose);
      final service = StockService(api);
      await expectLater(
        service.move(2, 'v1', 'Entrada', 3, 'Reposição'),
        throwsA(isA<ApiException>()),
      );
      await service.move(2, 'v1', 'Entrada', 3, 'Reposição');
      expect(api.bodies[0]['operacaoId'], api.bodies[1]['operacaoId']);
      await service.move(2, 'v2', 'Entrada', 3, 'Reposição');
      expect(api.bodies[2]['operacaoId'], isNot(api.bodies[1]['operacaoId']));
      final calls = api.calls;
      api.user!['tipoUsuario'] = 'Cliente';
      await expectLater(service.alerts(), throwsA(isA<ApiException>()));
      await expectLater(service.history(), throwsA(isA<ApiException>()));
      await expectLater(
        service.move(2, 'v2', 'Ajuste', 0, 'Contagem'),
        throwsA(isA<ApiException>()),
      );
      expect(api.calls, calls);
    },
  );

  testWidgets('ajuste valida reservado e exige nova revisão após conflito', (
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
    final api = StockApi()..conflict = true;
    addTearDown(api.dispose);
    await tester.pumpWidget(
      MaterialApp(home: StockMovePage(api: api, productId: 1, variationId: 2)),
    );
    await tester.pumpAndSettle();
    Future<void> tap(String text) async {
      final f = find.text(text).last;
      await Scrollable.ensureVisible(tester.element(f), alignment: .2);
      await tester.pumpAndSettle();
      await tester.tap(f);
      await tester.pumpAndSettle();
    }

    await tap('Entrada de unidades');
    await tester.tap(find.text('Ajustar saldo físico').last);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(0), '1');
    await tester.enterText(
      find.byType(TextFormField).at(1),
      'Contagem de estoque',
    );
    await tap('Revisar movimentação');
    expect(
      find.text('O saldo não pode ser menor que o reservado.'),
      findsOneWidget,
    );
    expect(api.bodies, isEmpty);
    await tester.enterText(find.byType(TextFormField).at(0), '5');
    await tap('Revisar movimentação');
    await tester.tap(find.text('Confirmar'));
    await tester.pumpAndSettle();
    expect(find.text('Estoque atualizado por outra operação.'), findsOneWidget);
    await tap('Atualizar saldos');
    await tap('Revisar movimentação');
    await tester.tap(find.text('Confirmar'));
    await tester.pumpAndSettle();
    expect(api.bodies.last['versao'], 'version2');
    expect(api.bodies.last['quantidade'], 5);
    expect(tester.takeException(), isNull);
  });

  testWidgets('lista filtra alertas e consulta histórico da combinação', (
    tester,
  ) async {
    final api = StockApi();
    addTearDown(api.dispose);
    await tester.pumpWidget(MaterialApp(home: StockPage(api: api)));
    await tester.pumpAndSettle();
    expect(find.text('Estoque baixo • Reposição recomendada'), findsOneWidget);
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ver histórico'));
    await tester.pumpAndSettle();
    expect(find.text('Responsável: Equipe'), findsOneWidget);
    expect(find.text('Saldo físico: 4 → 7'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
