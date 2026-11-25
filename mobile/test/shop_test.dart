import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uniduni_mobile/core/api.dart';
import 'package:uniduni_mobile/main.dart';

class FakeApi extends UniduniApi {
  bool fail = false;
  @override
  Future<List<Map<String, dynamic>>> catalog() async {
    if (fail) throw const ApiException('Falha de teste');
    return [
      {
        'id': 1,
        'nome': 'Body Azul',
        'descricao': 'Body para bebê',
        'preco': 44.9,
        'categoriaNome': 'Roupas',
        'imagem': 'body.png',
        'guiaMedidas': 'P: 0 a 3 meses.',
        'variacoes': [
          {'cor': 'Azul', 'tamanho': 'P', 'disponivel': 5},
        ],
      },
    ];
  }

  @override
  Future<void> login(String email, String password) async {
    user = {'nome': 'Cliente', 'email': email, 'tipoUsuario': 'Cliente'};
  }

  @override
  Future<void> logout() async {
    user = null;
  }
}

void main() {
  testWidgets('conta permanece legível em tela estreita com texto ampliado', (
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
    final loader = FontLoader('Nunito')
      ..addFont(rootBundle.load('assets/Nunito-Variable.ttf'));
    await loader.load();
    final icons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await icons.load();
    final api = FakeApi();
    addTearDown(api.dispose);
    await tester.pumpWidget(UniduniApp(api: api));
    await tester.runAsync(
      () => precacheImage(
        const AssetImage('assets/uniduni-logo.png'),
        tester.element(find.byType(ShopPage)),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Minha conta'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.ensureVisible(find.text('Entrar na minha conta'));
    await tester.pumpAndSettle();
    expect(find.text('Entrar na minha conta').hitTestable(), findsOneWidget);
    await expectLater(
      find.byType(ShopPage),
      matchesGoldenFile('goldens/conta-texto-ampliado.png'),
    );
  });
  testWidgets('busca filtra o catálogo e detalhe mostra disponibilidade', (
    tester,
  ) async {
    final api = FakeApi();
    addTearDown(api.dispose);
    await tester.pumpWidget(UniduniApp(api: api));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'inexistente');
    await tester.pumpAndSettle();
    expect(
      find.text(
        'Nenhuma peça encontrada. Experimente outra busca ou categoria.',
      ),
      findsOneWidget,
    );
    await tester.enterText(find.byType(TextField).first, 'Body');
    await tester.pumpAndSettle();
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Ver detalhes'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ver detalhes'));
    await tester.pumpAndSettle();
    expect(find.text('Detalhes da peça'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('5 unidades disponíveis'), 250);
    expect(find.text('5 unidades disponíveis'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('falha permite tentar novamente e login altera a conta', (
    tester,
  ) async {
    final api = FakeApi()..fail = true;
    addTearDown(api.dispose);
    await tester.pumpWidget(UniduniApp(api: api));
    await tester.pumpAndSettle();
    expect(find.text('Falha de teste'), findsOneWidget);
    api.fail = false;
    await tester.ensureVisible(find.text('Tentar novamente'));
    await tester.tap(find.text('Tentar novamente'));
    await tester.pumpAndSettle();
    expect(find.text('1 produtos encontrados'), findsOneWidget);
    await tester.tap(find.text('Minha conta'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Entrar na minha conta'));
    await tester.pumpAndSettle();
    expect(find.text('Informe seu e-mail.'), findsOneWidget);
    await tester.enterText(
      find.byType(TextFormField).at(0),
      'teste@example.invalid',
    );
    await tester.enterText(find.byType(TextFormField).at(1), 'senha');
    await tester.ensureVisible(find.text('Entrar na minha conta'));
    await tester.tap(find.text('Entrar na minha conta'));
    await tester.pumpAndSettle();
    expect(find.text('Olá, Cliente.'), findsOneWidget);
    await tester.tap(find.text('Sair da conta'));
    await tester.pumpAndSettle();
    expect(find.text('Bom ter você por aqui.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
