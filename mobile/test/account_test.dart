import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uniduni_mobile/core/api.dart';
import 'package:uniduni_mobile/core/account_service.dart';
import 'package:uniduni_mobile/main.dart';
import 'package:uniduni_mobile/features/account.dart';

class AccountApi extends UniduniApi {
  bool duplicate = true, wrong = true;
  final calls = <Map<String, dynamic>>[];
  @override
  Future<List<Map<String, dynamic>>> catalog() async => [];
  @override
  Future<dynamic> request(String method, String path, {Object? body}) async {
    calls.add({'path': path, 'body': body});
    if (path.endsWith('/cadastro') && duplicate) {
      duplicate = false;
      throw const ApiException('Email já cadastrado.', statusCode: 409);
    }
    if (path.contains('/alterar-senha') && wrong) {
      wrong = false;
      throw const ApiException('Senha atual incorreta.', statusCode: 400);
    }
    return null;
  }

  @override
  Future<void> login(String email, String password) async {
    user = {
      'id': 12,
      'nome': 'Cliente',
      'email': email,
      'tipoUsuario': 'Cliente',
    };
  }
}

void main() {
  test('cadastro envia somente dados públicos e troca usa o próprio id em todos os perfis', () async {
    final api = AccountApi()..duplicate = false;
    addTearDown(api.dispose);
    final account = AccountService(api);
    await account.register(
      name: ' Cliente ',
      email: ' cliente@example.invalid ',
      password: 'senha-cliente-123',
    );
    final data = api.calls.single['body'] as Map;
    expect(data.keys, unorderedEquals(['nome', 'email', 'telefone', 'senha']));
    expect(data['nome'], 'Cliente');
    await expectLater(
      account.changePassword('senha-atual', 'senha-nova-123'),
      throwsA(isA<ApiException>()),
    );
    expect(api.calls.length, 1);
    for (final role in ['Cliente', 'Funcionario', 'Administrador']) {
      api.user = {'id': 12, 'tipoUsuario': role};
      api.wrong = true;
      await expectLater(
        account.changePassword('errada', 'senha-nova-123'),
        throwsA(isA<ApiException>()),
      );
      expect(api.user?['id'], 12);
      await account.changePassword('correta', 'senha-nova-123');
      expect(api.user, isNull);
      expect(api.calls.last['path'], '/api/Usuarios/alterar-senha/12');
    }
  });

  testWidgets(
    'cliente se cadastra, entra e troca senha com validação e retorno ao login',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 1.5;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
        tester.platformDispatcher.clearTextScaleFactorTestValue();
      });
      final api = AccountApi();
      addTearDown(api.dispose);
      await tester.pumpWidget(UniduniApp(api: api));
      await tester.pumpAndSettle();
      Future<void> tap(String label) async {
        final f = find.text(label).last;
        await Scrollable.ensureVisible(tester.element(f), alignment: .2);
        await tester.pumpAndSettle();
        await tester.tap(f);
        await tester.pumpAndSettle();
      }

      await tester.tap(find.text('Minha conta'));
      await tester.pumpAndSettle();
      await tap('Criar minha conta');
      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'Cliente');
      await tester.enterText(fields.at(1), 'cliente@example.invalid');
      await tester.enterText(fields.at(3), 'senha-cliente-123');
      await tester.enterText(fields.at(4), 'diferente');
      await tap('Criar conta de cliente');
      expect(find.text('As senhas precisam ser iguais.'), findsOneWidget);
      expect(api.calls, isEmpty);
      await tester.enterText(fields.at(4), 'senha-cliente-123');
      await tap('Criar conta de cliente');
      expect(find.text('Email já cadastrado.'), findsOneWidget);
      expect(find.text('Cliente'), findsOneWidget);
      await tap('Criar conta de cliente');
      expect(
        find.text('Conta criada! Entre com seu e-mail e senha.'),
        findsOneWidget,
      );
      expect(
        tester.widget<TextFormField>(fields.first).controller!.text,
        'cliente@example.invalid',
      );
      await tester.enterText(fields.at(1), 'senha-cliente-123');
      await tap('Entrar na minha conta');
      await tap('Alterar minha senha');
      await tester.enterText(fields.at(0), 'errada');
      await tester.enterText(fields.at(1), 'nova-senha-123');
      await tester.enterText(fields.at(2), 'nova-senha-123');
      await tap('Salvar nova senha');
      expect(find.text('Senha atual incorreta.'), findsOneWidget);
      expect(api.user, isNotNull);
      await tester.enterText(fields.at(0), 'senha-cliente-123');
      await tap('Salvar nova senha');
      expect(api.user, isNull);
      expect(find.text('Senha alterada. Entre novamente.'), findsOneWidget);
      expect(find.text('Entrar na minha conta'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('troca de senha não permite acesso sem sessão', (tester) async {
    final api = AccountApi();
    addTearDown(api.dispose);
    await tester.pumpWidget(MaterialApp(home: AccountFormPage(api: api)));
    expect(find.byType(TextFormField), findsNothing);
    expect(
      find.text('Entre na sua conta para alterar a senha.'),
      findsOneWidget,
    );
  });
}
