import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uniduni_mobile/core/api.dart';
import 'package:uniduni_mobile/main.dart';
import 'package:uniduni_mobile/features/products_admin.dart';

class AdminApi extends UniduniApi {
  final products = <Map<String, dynamic>>[];
  bool refuseDelete = false;
  AdminApi({String role = 'Administrador'}) {
    user = {
      'id': 1,
      'nome': 'Equipe',
      'email': 'teste@example.invalid',
      'tipoUsuario': role,
    };
  }
  @override
  Future<List<Map<String, dynamic>>> catalog() async => [];
  @override
  Future<List<Map<String, dynamic>>> categories() async => [
    {'id': 1, 'nome': 'Roupas'},
    {'id': 2, 'nome': 'Calçados'},
  ];
  @override
  Future<List<Map<String, dynamic>>> adminProducts() async =>
      products.map((p) => Map<String, dynamic>.from(p)).toList();
  @override
  Future<Map<String, dynamic>> adminProduct(int id) async =>
      Map<String, dynamic>.from(products.singleWhere((p) => p['id'] == id));
  @override
  Future<void> saveProduct(Map<String, dynamic> data, {int? id}) async {
    if (id == null) {
      products.add({
        ...data,
        'id': 1,
        'categoriaNome': 'Roupas',
        'estoque': data['variacaoInicial']['estoqueInicial'],
        'variacoes': [
          {
            'cor': data['variacaoInicial']['cor'],
            'tamanho': data['variacaoInicial']['tamanho'],
            'ativo': true,
            'estoque': data['variacaoInicial']['estoqueInicial'],
            'reservado': 0,
            'disponivel': data['variacaoInicial']['estoqueInicial'],
            'estoqueMinimo': 3,
          },
        ],
      });
    } else {
      products.singleWhere((p) => p['id'] == id).addAll(data);
    }
  }

  @override
  Future<void> deactivateProduct(int id) async {
    if (refuseDelete) {
      throw const ApiException(
        'O produto possui unidades reservadas e não pode ser desativado.',
      );
    }
    products.singleWhere((p) => p['id'] == id)['ativo'] = false;
  }
}

void main() {
  testWidgets('acesso aparece para equipe e fica ausente para cliente', (
    tester,
  ) async {
    final api = AdminApi(role: 'Funcionario');
    addTearDown(api.dispose);
    await tester.pumpWidget(UniduniApp(api: api));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Minha conta'));
    await tester.pumpAndSettle();
    expect(find.text('Gerenciar produtos'), findsOneWidget);
    api.user!['tipoUsuario'] = 'Cliente';
    await tester.tap(find.text('Catálogo'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Minha conta'));
    await tester.pumpAndSettle();
    expect(find.text('Gerenciar produtos'), findsNothing);
    await tester.pumpWidget(MaterialApp(home: ProductsAdminPage(api: api)));
    await tester.pumpAndSettle();
    expect(find.text('Acesso restrito à equipe da loja.'), findsOneWidget);
  });

  testWidgets('cadastro, edição, confirmação de exclusão e reativação', (
    tester,
  ) async {
    final api = AdminApi();
    addTearDown(api.dispose);
    await tester.pumpWidget(MaterialApp(home: ProductsAdminPage(api: api)));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cadastrar produto'));
    await tester.pumpAndSettle();
    Future<void> reveal(Finder finder) async {
      if (finder.evaluate().isEmpty) {
        final vertical = find
            .byWidgetPredicate(
              (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
            )
            .last;
        await tester.drag(vertical, const Offset(0, 3000));
        await tester.pumpAndSettle();
        await tester.scrollUntilVisible(finder, 250, scrollable: vertical);
      }
      await Scrollable.ensureVisible(tester.element(finder), alignment: 0.3);
      await tester.pumpAndSettle();
    }

    Future<void> field(String label, String value) async {
      final finder = find.widgetWithText(TextFormField, label);
      await reveal(finder);
      await tester.enterText(finder, value);
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
    }

    Future<void> tapText(String text) async {
      await reveal(find.text(text));
      await tester.tap(find.text(text));
      await tester.pumpAndSettle();
    }

    await tapText('Salvar produto');
    await reveal(find.text('Informe Nome do produto.'));
    expect(find.text('Informe Nome do produto.'), findsOneWidget);
    await field('Nome do produto', 'Body mobile');
    await field('Descrição', 'Body confortável para bebê');
    await field('Preço (R\$)', '49,90');
    await field('Cor', 'Azul');
    await field('Estoque inicial', '5');
    await tapText('Salvar produto');
    expect(api.products.single['preco'], 49.9);
    await tapText('Body mobile');
    await tapText('Editar produto');
    await field('Preço (R\$)', '59,90');
    await tapText('Salvar produto');
    expect(api.products.single['preco'], 59.9);
    expect(api.products.single['variacoes'][0]['estoque'], 5);
    await tapText('Body mobile');
    await tapText('Desativar produto');
    await tapText('Voltar');
    expect(api.products.single['ativo'], true);
    api.refuseDelete = true;
    await tapText('Desativar produto');
    await tapText('Desativar');
    expect(
      find.text(
        'O produto possui unidades reservadas e não pode ser desativado.',
      ),
      findsOneWidget,
    );
    expect(api.products.single['ativo'], true);
    api.refuseDelete = false;
    await tapText('Desativar produto');
    await tapText('Desativar');
    expect(find.text('Nenhum produto encontrado.'), findsOneWidget);
    await tapText('Mostrar também os inativos');
    await tapText('Body mobile');
    await tapText('Editar produto');
    await tapText('Ativo no catálogo');
    await tapText('Salvar produto');
    expect(api.products.single['ativo'], true);
    expect(tester.takeException(), isNull);
  });
}
