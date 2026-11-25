// Capturas da interface real em renderização Flutter com dados de demonstração.
// Não substitui execução por toque em aparelho físico.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uniduni_mobile/core/api.dart';
import 'package:uniduni_mobile/main.dart';
import 'package:uniduni_mobile/features/account.dart';
import 'package:uniduni_mobile/features/shopping.dart';
import 'package:uniduni_mobile/features/products_admin.dart';
import 'package:uniduni_mobile/features/stock.dart';
import 'package:uniduni_mobile/features/users_admin.dart';
import 'package:uniduni_mobile/features/sales_summary.dart';

class CaptureApi extends UniduniApi {
  void profile(String role) {
    user = {
      'id': 1,
      'nome': 'Equipe Uniduni',
      'email': 'demonstracao@uniduni.invalid',
      'telefone': '',
      'tipoUsuario': role,
    };
  }

  final products = <Map<String, dynamic>>[
    {
      'id': 21,
      'nome': 'Sapatinho Bebê Feminino',
      'descricao': 'Sapatinho confortável para bebê',
      'preco': 59.9,
      'imagem': 'sapatilha-feminina-uniduni.png',
      'categoriaId': 2,
      'categoriaNome': 'Calçados',
      'genero': 'Feminino',
      'ativo': true,
      'guiaMedidas': 'Numeração 18.',
      'variacoes': [
        {
          'id': 4,
          'cor': 'Rosa',
          'tamanho': '18',
          'ativo': true,
          'estoque': 6,
          'reservado': 0,
          'disponivel': 6,
          'estoqueMinimo': 3,
          'versao': 'AAAAAAAAAAA=',
        },
      ],
    },
    {
      'id': 19,
      'nome': 'Body Bebê Azul',
      'descricao': 'Body confortável e macio',
      'preco': 44.9,
      'imagem': 'body-azul.jpg',
      'categoriaId': 1,
      'categoriaNome': 'Roupas',
      'genero': 'Masculino',
      'ativo': true,
      'guiaMedidas': 'P: 0 a 3 meses. RN: recém-nascido.',
      'variacoes': [
        {
          'id': 1,
          'cor': 'Azul',
          'tamanho': 'P',
          'ativo': true,
          'estoque': 10,
          'reservado': 0,
          'disponivel': 10,
          'estoqueMinimo': 3,
          'versao': 'AAAAAAAAAAA=',
        },
        {
          'id': 2,
          'cor': 'Azul',
          'tamanho': 'RN',
          'ativo': true,
          'estoque': 15,
          'reservado': 0,
          'disponivel': 15,
          'estoqueMinimo': 3,
          'versao': 'AAAAAAAAAAA=',
        },
      ],
    },
    {
      'id': 20,
      'nome': 'Camiseta Preta',
      'descricao': 'Conforto para o dia a dia',
      'preco': 79.9,
      'imagem': 'camiseta-preta.jpg',
      'categoriaId': 1,
      'categoriaNome': 'Roupas',
      'genero': 'Unissex',
      'ativo': true,
      'guiaMedidas': 'Tamanho P.',
      'variacoes': [
        {
          'id': 3,
          'cor': 'Preto',
          'tamanho': 'P',
          'ativo': true,
          'estoque': 8,
          'reservado': 0,
          'disponivel': 8,
          'estoqueMinimo': 3,
          'versao': 'AAAAAAAAAAA=',
        },
      ],
    },
  ];
  Map<String, dynamic> order() => {
    'id': 1,
    'usuarioId': 1,
    'cliente': 'Cliente de demonstração',
    'status': 'Pendente',
    'total': 89.8,
    'criadoEm': '2026-10-28T12:00:00Z',
    'reservaAte': '2026-10-28T12:30:00Z',
    'codigoRetirada': null,
    'itens': [
      {
        'nome': 'Body Bebê Azul',
        'imagem': 'body-azul.jpg',
        'cor': 'Azul',
        'tamanho': 'P',
        'quantidade': 2,
        'precoUnitario': 44.9,
        'subtotal': 89.8,
      },
    ],
    'pagamentos': [],
    'eventos': [
      {
        'descricao': 'Pedido criado e itens reservados.',
        'criadoEm': '2026-10-28T12:00:00Z',
      },
    ],
  };
  @override
  Future<List<Map<String, dynamic>>> catalog() async => products;
  @override
  Future<List<Map<String, dynamic>>> adminProducts() async => products;
  @override
  Future<Map<String, dynamic>> adminProduct(int id) async =>
      products.firstWhere((p) => p['id'] == id);
  @override
  Future<List<Map<String, dynamic>>> categories() async => [
    {'id': 1, 'nome': 'Roupas'},
  ];
  @override
  Future<dynamic> request(String method, String path, {Object? body}) async {
    if (path.endsWith('/carrinho')) {
      return {
        'total': 89.8,
        'itens': [
          {
            'variacaoId': 1,
            'nome': 'Body Bebê Azul',
            'imagem': 'body-azul.jpg',
            'cor': 'Azul',
            'tamanho': 'P',
            'quantidade': 2,
            'preco': 44.9,
            'subtotal': 89.8,
            'disponivel': 10,
            'ativo': true,
          },
        ],
      };
    }
    if (path.startsWith('/api/compras/resumo')) {
      return {'totalVendido': 89.8, 'quantidadeVendas': 1, 'simulado': true};
    }
    if (path.startsWith('/api/Estoque')) return <Map<String, dynamic>>[];
    if (path == '/api/Usuarios') {
      return [
        user!,
        {
          'id': 2,
          'nome': 'Cliente de demonstração',
          'email': 'cliente@uniduni.invalid',
          'telefone': '',
          'tipoUsuario': 'Cliente',
        },
      ];
    }
    if (path.startsWith('/api/compras/pedidos/')) return order();
    if (path.startsWith('/api/compras/pedidos')) return [order()];
    throw StateError('Rota não preparada para captura: $path');
  }
}

void main() {
  testWidgets(
    'renderiza interfaces para documentação com dados demonstrativos',
    (tester) async {
      tester.view.physicalSize = const Size(390, 900);
      tester.view.devicePixelRatio = 1;
      final font = FontLoader('Nunito')
        ..addFont(rootBundle.load('assets/Nunito-Variable.ttf'));
      await font.load();
      final icons = FontLoader('MaterialIcons')
        ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
      await icons.load();
      final api = CaptureApi();
      addTearDown(() {
        api.dispose();
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      await tester.runAsync(() async {
        final logoBytes = File('assets/uniduni-logo.png').readAsBytesSync();
        final logoCodec = await ui.instantiateImageCodec(logoBytes);
        final logoFrame = await logoCodec.getNextFrame();
        final logoKey = await const AssetImage('assets/uniduni-logo.png')
            .obtainKey(ImageConfiguration.empty);
        PaintingBinding.instance.imageCache.putIfAbsent(
          logoKey,
          () => OneFrameImageStreamCompleter(
            Future.value(ImageInfo(image: logoFrame.image)),
          ),
        );
        logoCodec.dispose();
        for (final p in api.products) {
          final bytes = File('../frontend (VS Code)/images/${p['imagem']}')
              .readAsBytesSync();
          final codec = await ui.instantiateImageCodec(bytes);
          final frame = await codec.getNextFrame();
          PaintingBinding.instance.imageCache.putIfAbsent(
            NetworkImage(api.image(p['imagem']).toString()),
            () => OneFrameImageStreamCompleter(
              Future.value(ImageInfo(image: frame.image)),
            ),
          );
          codec.dispose();
        }
      });
      final directory = Directory(
        '../output/documentos/Uniduni_PIM_IV_evolucao/figuras',
      )..createSync(recursive: true);
      final boundary = GlobalKey();
      Widget shell(Widget home) => MaterialApp(
        debugShowCheckedModeBanner: false,
        locale: const Locale('pt', 'BR'),
        supportedLocales: const [Locale('pt', 'BR')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        theme: ThemeData(
          useMaterial3: true,
          fontFamily: 'Nunito',
          scaffoldBackgroundColor: const Color(0xfffaf8ff),
          colorScheme: ColorScheme.fromSeed(seedColor: teal, primary: teal),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
        home: home,
      );
      Future<void> save(String name) async {
        await tester.runAsync(() async {
          final render =
              boundary.currentContext!.findRenderObject()
                  as RenderRepaintBoundary;
          final image = await render.toImage(pixelRatio: 2);
          final data = await image.toByteData(format: ui.ImageByteFormat.png);
          File('${directory.path}/$name.png')
              .writeAsBytesSync(data!.buffer.asUint8List());
          image.dispose();
        });
        expect(tester.takeException(), isNull);
      }

      Future<void> capture(String name, Widget child) async {
        await tester.pumpWidget(RepaintBoundary(key: boundary, child: child));
        await tester.pumpAndSettle();
        await save(name);
      }

      await capture('mobile_catalogo', UniduniApp(api: api));
      await tester.tap(find.text('Minha conta'));
      await tester.pumpAndSettle();
      await save('mobile_login');
      await capture(
        'mobile_cadastro',
        shell(AccountFormPage(api: api, register: true)),
      );
      api.profile('Cliente');
      await capture(
        'mobile_produto',
        shell(
          ProductPage(
            api: api,
            product: api.products.firstWhere((p) => p['id'] == 19),
          ),
        ),
      );
      await capture('mobile_carrinho', shell(CartPage(api: api)));
      await capture('mobile_pedido', shell(OrderPage(api: api, id: 1)));
      api.profile('Administrador');
      await capture('mobile_produtos', shell(ProductsAdminPage(api: api)));
      await capture('mobile_estoque', shell(StockPage(api: api)));
      await capture('mobile_usuarios', shell(UsersAdminPage(api: api)));
      await capture('mobile_total', shell(SalesSummaryPage(api: api)));
    },
  );
}
