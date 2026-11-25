import 'api.dart';

class ShoppingService {
  ShoppingService(this.api);
  final UniduniApi api;
  Future<List<Map<String, dynamic>>> orders({bool team = false}) async {
    if (team && !api.isTeam) {
      throw const ApiException('Acesso restrito à equipe.');
    }
    return (await api.request(
      'GET',
      '/api/compras/pedidos${team ? '?equipe=true' : ''}',
    ) as List).cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> advance(
    int id,
    String status, {
    String? code,
  }) async {
    if (!api.isTeam) throw const ApiException('Acesso restrito à equipe.');
    return Map<String, dynamic>.from(
      await api.request(
        'POST',
        '/api/compras/pedidos/$id/andamento',
        body: {'status': status, 'codigo': code?.trim()},
      ),
    );
  }

  Future<Map<String, dynamic>> summary({DateTime? start, DateTime? end}) async {
    if (api.user?['tipoUsuario'] != 'Administrador') {
      throw const ApiException('Total vendido é exclusivo do Administrador.');
    }
    if (start != null && end != null && start.isAfter(end)) {
      throw const ApiException(
        'A data inicial não pode ser posterior à final.',
      );
    }
    final query = <String, String>{
      if (start != null)
        'inicio': DateTime(
          start.year,
          start.month,
          start.day,
        ).toUtc().toIso8601String(),
      if (end != null)
        'fim': DateTime(
          end.year,
          end.month,
          end.day + 1,
        ).toUtc().toIso8601String(),
    };
    final path = Uri(
      path: '/api/compras/resumo',
      queryParameters: query.isEmpty ? null : query,
    ).toString();
    return Map<String, dynamic>.from(await api.request('GET', path));
  }

  Future<Map<String, dynamic>> cart() async => Map<String, dynamic>.from(
    await api.request('GET', '/api/compras/carrinho'),
  );
  Future<void> quantity(int id, int value) async {
    await api.request(
      'PUT',
      '/api/compras/carrinho',
      body: {'variacaoId': id, 'quantidade': value},
    );
  }

  Future<void> add(int id, int value) async {
    final current = await cart();
    final item = (current['itens'] as List)
        .where((i) => i['variacaoId'] == id)
        .firstOrNull;
    await quantity(id, value + (item?['quantidade'] as int? ?? 0));
  }

  Future<Map<String, dynamic>> checkout() async {
    final result = await api.request(
      'POST',
      '/api/compras/pedidos',
      body: {'operacaoId': api.operation('checkout')},
    );
    api.completeOperation('checkout');
    return Map<String, dynamic>.from(result);
  }

  Future<Map<String, dynamic>> pay(int id, String method, String result) async {
    final key = 'payment-$id-$method-$result';
    final data = await api.request(
      'POST',
      '/api/compras/pedidos/$id/pagamentos',
      body: {
        'operacaoId': api.operation(key),
        'metodo': method,
        'resultado': result,
      },
    );
    api.completeOperation(key);
    return Map<String, dynamic>.from(data);
  }
}
