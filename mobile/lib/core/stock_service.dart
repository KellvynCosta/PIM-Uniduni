import 'dart:convert';

import 'api.dart';

class StockService {
  StockService(this.api);
  final UniduniApi api;
  void guard() {
    if (!api.isTeam) throw const ApiException('Acesso restrito à equipe.');
  }

  Future<List<Map<String, dynamic>>> alerts() async {
    guard();
    return (await api.request('GET', '/api/Estoque/alertas') as List)
        .cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>> history({int? variationId}) async {
    guard();
    final uri = Uri(
      path: '/api/Estoque/historico',
      queryParameters: {
        'limite': '100',
        if (variationId != null) 'variacaoId': '$variationId',
      },
    );
    return (await api.request('GET', uri.toString()) as List)
        .cast<Map<String, dynamic>>();
  }

  Future<void> move(
    int id,
    String version,
    String type,
    int quantity,
    String reason,
  ) async {
    guard();
    final data = {
      'versao': version,
      'tipo': type,
      'quantidade': quantity,
      'justificativa': reason.trim(),
    };
    final key = 'stock-$id-${jsonEncode(data)}';
    await api.request(
      'POST',
      '/api/Estoque/variacoes/$id/movimentacoes',
      body: {...data, 'operacaoId': api.operation(key)},
    );
    api.completeOperation(key);
  }
}
