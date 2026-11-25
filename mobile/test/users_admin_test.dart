import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uniduni_mobile/core/api.dart';
import 'package:uniduni_mobile/core/users_service.dart';
import 'package:uniduni_mobile/features/users_admin.dart';

class UsersApi extends UniduniApi {
  UsersApi() {
    user = {
      'id': 1,
      'nome': 'Admin',
      'email': 'admin@example.invalid',
      'tipoUsuario': 'Administrador',
    };
  }
  final users = <Map<String, dynamic>>[
    {
      'id': 1,
      'nome': 'Admin',
      'email': 'admin@example.invalid',
      'telefone': '',
      'tipoUsuario': 'Administrador',
    },
    {
      'id': 2,
      'nome': 'Cliente',
      'email': 'cliente@example.invalid',
      'telefone': '',
      'tipoUsuario': 'Cliente',
    },
  ];
  int calls = 0;
  bool conflict = false;
  final saved = <Map>[];
  @override
  Future<dynamic> request(String method, String path, {Object? body}) async {
    calls++;
    if (method == 'GET') {
      if (path == '/api/Usuarios') {
        return users.map((u) => Map<String, dynamic>.from(u)).toList();
      }
      return Map<String, dynamic>.from(
        users.singleWhere((u) => path.endsWith('/${u['id']}')),
      );
    }
    if (method == 'DELETE') {
      users.removeWhere((u) => path.endsWith('/${u['id']}'));
      return null;
    }
    final data = Map<String, dynamic>.from(body as Map);
    if (conflict) {
      conflict = false;
      throw const ApiException('Email já cadastrado.', statusCode: 409);
    }
    saved.add(data);
    final id = method == 'POST' ? 3 : int.parse(path.split('/').last);
    final result = {...data, 'id': id}..remove('senha');
    users.removeWhere((u) => u['id'] == id);
    users.add(result);
    return result;
  }
}

void main() {
  test('protege perfis e própria conta; edição própria atualiza sessão ou limpa após nova senha', () async {
    final api = UsersApi();
    addTearDown(api.dispose);
    final service = UsersService(api);
    await expectLater(service.deactivate(1), throwsA(isA<ApiException>()));
    await expectLater(
      service.save({'tipoUsuario': 'Cliente'}, id: 1),
      throwsA(isA<ApiException>()),
    );
    expect(api.calls, 0);
    await service.save({
      'nome': 'Admin atualizado',
      'email': 'a@example.invalid',
      'telefone': '',
      'tipoUsuario': 'Administrador',
      'senha': null,
    }, id: 1);
    expect(api.user!['nome'], 'Admin atualizado');
    await service.save({
      'nome': 'Admin atualizado',
      'email': 'a@example.invalid',
      'telefone': '',
      'tipoUsuario': 'Administrador',
      'senha': 'nova-senha-123',
    }, id: 1);
    expect(api.user, isNull);
    final calls = api.calls;
    for (final role in ['Cliente', 'Funcionario']) {
      api.user = {'tipoUsuario': role};
      await expectLater(service.list(), throwsA(isA<ApiException>()));
      await expectLater(service.get(2), throwsA(isA<ApiException>()));
      await expectLater(service.save({}), throwsA(isA<ApiException>()));
      await expectLater(service.deactivate(2), throwsA(isA<ApiException>()));
    }
    expect(api.calls, calls);
  });

  testWidgets(
    'cadastro valida senhas, preserva formulário após conflito e exige confirmação para desativar',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 1.5;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
        tester.platformDispatcher.clearTextScaleFactorTestValue();
      });
      final api = UsersApi()..conflict = true;
      addTearDown(api.dispose);
      await tester.pumpWidget(MaterialApp(home: UsersAdminPage(api: api)));
      await tester.pumpAndSettle();
      Future<void> tap(String label) async {
        final f = find.text(label).last;
        await Scrollable.ensureVisible(tester.element(f), alignment: .2);
        await tester.pumpAndSettle();
        await tester.tap(f);
        await tester.pumpAndSettle();
      }

      await tap('Cadastrar usuário');
      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'Nova conta');
      await tester.enterText(fields.at(1), 'nova@example.invalid');
      await tester.enterText(fields.at(3), 'senha-valida-123');
      await tester.enterText(fields.at(4), 'diferente');
      await tap('Salvar usuário');
      expect(find.text('As senhas precisam ser iguais.'), findsOneWidget);
      expect(api.saved, isEmpty);
      await tester.enterText(fields.at(4), 'senha-valida-123');
      await tap('Salvar usuário');
      expect(find.text('Email já cadastrado.'), findsOneWidget);
      expect(find.text('Nova conta'), findsOneWidget);
      await tap('Salvar usuário');
      expect(api.saved.single['tipoUsuario'], 'Cliente');
      expect(api.users.any((u) => u['nome'] == 'Nova conta'), isTrue);
      ScaffoldMessenger.of(tester.element(find.byType(UsersAdminPage)))
          .clearSnackBars();
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, 'nova@');
      await tester.pumpAndSettle();
      await tap('Desativar conta');
      await tester.tap(find.text('Voltar'));
      await tester.pumpAndSettle();
      expect(api.users.length, 3);
      await tap('Desativar conta');
      await tester.tap(find.text('Desativar'));
      await tester.pumpAndSettle();
      expect(api.users.length, 2);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'própria conta mantém perfil e redefine senha somente após confirmação',
    (tester) async {
      final api = UsersApi();
      addTearDown(api.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: UserFormPage(api: api, user: api.users.first),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<DropdownButtonFormField<String>>(
              find.byType(DropdownButtonFormField<String>),
            )
            .onChanged,
        isNull,
      );
      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(3), 'senha-nova-123');
      await tester.enterText(fields.at(4), 'senha-nova-123');
      Future<void> save() async {
        await Scrollable.ensureVisible(
          tester.element(find.text('Salvar usuário')),
          alignment: .2,
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('Salvar usuário'));
        await tester.pumpAndSettle();
      }

      await save();
      await tester.tap(find.text('Voltar'));
      await tester.pumpAndSettle();
      expect(api.saved, isEmpty);
      await save();
      await tester.tap(find.text('Salvar e redefinir'));
      await tester.pumpAndSettle();
      expect(api.user, isNull);
      expect(api.saved.length, 1);
      expect(tester.takeException(), isNull);
    },
  );
}
