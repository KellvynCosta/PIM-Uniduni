import 'package:flutter/material.dart';

import '../core/api.dart';
import '../core/stock_service.dart';

class StockPage extends StatefulWidget {
  const StockPage({super.key, required this.api});
  final UniduniApi api;
  @override
  State<StockPage> createState() => _StockState();
}

class _StockState extends State<StockPage> {
  List<Map<String, dynamic>> products = [], alerts = [];
  bool loading = true, lowOnly = false;
  String search = '';
  String? error;
  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    if (!widget.api.isTeam) {
      setState(() => loading = false);
      return;
    }
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final data = await Future.wait([
        widget.api.adminProducts(),
        StockService(widget.api).alerts(),
      ]);
      if (mounted) {
        setState(() {
          products = data[0];
          alerts = data[1];
        });
      }
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final rows = <Map<String, dynamic>>[
      for (final p in products)
        if (p['ativo'] == true)
          for (final v in p['variacoes'] as List)
            if (v['ativo'] == true &&
                (!lowOnly || alerts.any((a) => a['id'] == v['id'])) &&
                '${p['nome']} ${v['cor']} ${v['tamanho']}'
                    .toLowerCase()
                    .contains(search.toLowerCase()))
              {'product': p, 'variation': v},
    ];
    return Scaffold(
      appBar: AppBar(
        title: const Text('Estoque'),
        actions: [
          if (widget.api.isTeam)
            IconButton(
              tooltip: 'Histórico geral',
              icon: const Icon(Icons.history),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => StockHistoryPage(api: widget.api),
                ),
              ),
            ),
          IconButton(
            tooltip: 'Atualizar estoque',
            onPressed: loading ? null : load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: !widget.api.isTeam
          ? const Center(child: Text('Acesso restrito à equipe da loja.'))
          : SafeArea(
              child: RefreshIndicator(
                onRefresh: load,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 80),
                  children: [
                    Text(
                      'Cuidado com cada peça.',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Disponível é o saldo físico menos as unidades reservadas para pedidos.',
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      decoration: const InputDecoration(
                        labelText: 'Buscar produto, cor ou tamanho',
                        prefixIcon: Icon(Icons.search),
                      ),
                      onChanged: (value) => setState(() => search = value),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Somente estoque baixo'),
                      subtitle: Text(
                        loading
                            ? 'Consultando alertas…'
                            : '${alerts.length} combinações no mínimo ou abaixo',
                      ),
                      value: lowOnly,
                      onChanged: (value) => setState(() => lowOnly = value),
                    ),
                    if (loading)
                      const Center(child: CircularProgressIndicator())
                    else if (error != null) ...[
                      Text(
                        error!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                      TextButton(
                        onPressed: load,
                        child: const Text('Tentar novamente'),
                      ),
                    ] else if (rows.isEmpty)
                      const Text('Nenhuma combinação encontrada.')
                    else
                      for (final row in rows)
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  row['product']['nome'],
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                Text(
                                  '${row['variation']['cor']} • Tamanho ${row['variation']['tamanho']}',
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Físico: ${row['variation']['estoque']}   Reservado: ${row['variation']['reservado']}',
                                ),
                                Text(
                                  'Disponível: ${row['variation']['disponivel']}   Mínimo: ${row['variation']['estoqueMinimo']}',
                                ),
                                if (alerts.any(
                                  (a) => a['id'] == row['variation']['id'],
                                ))
                                  const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 8),
                                    child: Text(
                                      'Estoque baixo • Reposição recomendada',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                const SizedBox(height: 12),
                                FilledButton.icon(
                                  icon: const Icon(Icons.inventory_outlined),
                                  label: const Text('Movimentar estoque'),
                                  onPressed: () async {
                                    await Navigator.push(
                                      context,
                                      MaterialPageRoute<void>(
                                        builder: (_) => StockMovePage(
                                          api: widget.api,
                                          productId: row['product']['id'],
                                          variationId: row['variation']['id'],
                                        ),
                                      ),
                                    );
                                    if (mounted) await load();
                                  },
                                ),
                                TextButton.icon(
                                  icon: const Icon(Icons.history),
                                  label: const Text('Ver histórico'),
                                  onPressed: () => Navigator.push(
                                    context,
                                    MaterialPageRoute<void>(
                                      builder: (_) => StockHistoryPage(
                                        api: widget.api,
                                        variationId: row['variation']['id'],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                  ],
                ),
              ),
            ),
    );
  }
}

class StockMovePage extends StatefulWidget {
  const StockMovePage({
    super.key,
    required this.api,
    required this.productId,
    required this.variationId,
  });
  final UniduniApi api;
  final int productId, variationId;
  @override
  State<StockMovePage> createState() => _StockMoveState();
}

class _StockMoveState extends State<StockMovePage> {
  final form = GlobalKey<FormState>();
  final quantity = TextEditingController(), reason = TextEditingController();
  Map<String, dynamic>? product, variation;
  String type = 'Entrada';
  String? error;
  bool loading = true, saving = false, conflict = false, retryOnly = false;
  @override
  void initState() {
    super.initState();
    load();
  }

  @override
  void dispose() {
    quantity.dispose();
    reason.dispose();
    super.dispose();
  }

  Future<void> load() async {
    if (!widget.api.isTeam) {
      setState(() => loading = false);
      return;
    }
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final p = await widget.api.adminProduct(widget.productId);
      final v = (p['variacoes'] as List)
          .where((v) => v['id'] == widget.variationId)
          .firstOrNull;
      if (p['ativo'] != true || v == null || v['ativo'] != true) {
        throw const ApiException(
          'Esta combinação está inativa. Volte à lista de estoque.',
        );
      }
      if (mounted) {
        setState(() {
          product = p;
          variation = Map<String, dynamic>.from(v);
          conflict = false;
          retryOnly = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          error = e.toString();
          variation = null;
        });
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> save() async {
    if (!form.currentState!.validate() || conflict) return;
    final q = int.parse(quantity.text.trim());
    final total = type == 'Entrada' ? (variation!['estoque'] as int) + q : q;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        scrollable: true,
        title: const Text('Confirmar movimentação?'),
        content: Text(
          '${product!['nome']} • ${variation!['cor']} • ${variation!['tamanho']}\nSaldo físico: ${variation!['estoque']} → $total\nReservado: ${variation!['reservado']}\nJustificativa: ${reason.text.trim()}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Voltar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() {
      saving = true;
      error = null;
    });
    try {
      await StockService(widget.api)
          .move(widget.variationId, variation!['versao'], type, q, reason.text);
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(
            const SnackBar(
              content: Text('Estoque atualizado e movimentação registrada.'),
            ),
          );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          error = e.toString();
          conflict = e is ApiException && e.statusCode == 409;
          retryOnly =
              e is! ApiException ||
              e.statusCode == null ||
              (e.statusCode! >= 500);
        });
      }
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !saving,
    child: Scaffold(
      appBar: AppBar(title: const Text('Movimentar estoque')),
      body: !widget.api.isTeam
          ? const Center(child: Text('Acesso restrito à equipe da loja.'))
          : SafeArea(
              child: loading
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Form(
                        key: form,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (variation != null) ...[
                              Text(
                                product!['nome'],
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineSmall,
                              ),
                              Text(
                                '${variation!['cor']} • Tamanho ${variation!['tamanho']}',
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Físico: ${variation!['estoque']}\nReservado: ${variation!['reservado']}\nDisponível: ${variation!['disponivel']}',
                              ),
                              const SizedBox(height: 24),
                              DropdownButtonFormField<String>(
                                initialValue: type,
                                isExpanded: true,
                                decoration: const InputDecoration(
                                  labelText: 'Tipo de movimentação',
                                ),
                                items: const [
                                  DropdownMenuItem(
                                    value: 'Entrada',
                                    child: Text('Entrada de unidades'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'Ajuste',
                                    child: Text('Ajustar saldo físico'),
                                  ),
                                ],
                                onChanged: saving || conflict || retryOnly
                                    ? null
                                    : (value) => setState(() {
                                        type = value!;
                                        quantity.clear();
                                      }),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                type == 'Entrada'
                                    ? 'Informe quantas unidades chegaram. Elas serão somadas ao saldo físico.'
                                    : 'Informe o total de unidades contadas, incluindo as reservadas. Este será o novo saldo físico.',
                              ),
                              const SizedBox(height: 20),
                              TextFormField(
                                controller: quantity,
                                enabled: !saving && !conflict && !retryOnly,
                                keyboardType: TextInputType.number,
                                maxLength: 7,
                                decoration: InputDecoration(
                                  labelText: type == 'Entrada'
                                      ? 'Unidades recebidas'
                                      : 'Novo saldo físico',
                                ),
                                validator: (s) {
                                  final q = int.tryParse(s?.trim() ?? '');
                                  if (q == null ||
                                      q < (type == 'Entrada' ? 1 : 0) ||
                                      q > 1000000) {
                                    return 'Informe um inteiro de ${type == 'Entrada' ? 1 : 0} a 1.000.000.';
                                  }
                                  if (type == 'Ajuste' &&
                                      q < variation!['reservado']) {
                                    return 'O saldo não pode ser menor que o reservado.';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: reason,
                                enabled: !saving && !conflict && !retryOnly,
                                maxLength: 250,
                                minLines: 2,
                                maxLines: 4,
                                decoration: const InputDecoration(
                                  labelText: 'Justificativa',
                                ),
                                validator: (s) => (s?.trim().length ?? 0) < 5
                                    ? 'Explique o motivo com pelo menos 5 caracteres.'
                                    : null,
                              ),
                            ],
                            if (error != null)
                              Semantics(
                                liveRegion: true,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  child: Text(
                                    error!,
                                    style: TextStyle(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .error,
                                    ),
                                  ),
                                ),
                              ),
                            if (retryOnly)
                              const Text(
                                'A resposta não foi confirmada. Tente novamente com os mesmos dados para evitar duplicação.',
                              ),
                            if (conflict || variation == null)
                              FilledButton(
                                onPressed: saving ? null : load,
                                child: const Text('Atualizar saldos'),
                              )
                            else
                              FilledButton(
                                onPressed: saving ? null : save,
                                child: Text(
                                  saving
                                      ? 'Registrando…'
                                      : retryOnly
                                      ? 'Tentar novamente'
                                      : 'Revisar movimentação',
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
            ),
    ),
  );
}

class StockHistoryPage extends StatefulWidget {
  const StockHistoryPage({super.key, required this.api, this.variationId});
  final UniduniApi api;
  final int? variationId;
  @override
  State<StockHistoryPage> createState() => _StockHistoryState();
}

class _StockHistoryState extends State<StockHistoryPage> {
  List<Map<String, dynamic>> items = [];
  bool loading = true;
  String? error;
  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final data = await StockService(widget.api)
          .history(variationId: widget.variationId);
      if (mounted) setState(() => items = data);
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  String date(String value) {
    final d = DateTime.parse(value).toLocal();
    String two(int n) => '$n'.padLeft(2, '0');
    return '${two(d.day)}/${two(d.month)}/${d.year} às ${two(d.hour)}:${two(d.minute)}';
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Histórico de estoque')),
    body: SafeArea(
      child: RefreshIndicator(
        onRefresh: load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          children: [
            const Text(
              'Até 100 movimentações mais recentes, com o responsável e o motivo de cada alteração.',
            ),
            const SizedBox(height: 16),
            if (loading)
              const Center(child: CircularProgressIndicator())
            else if (error != null) ...[
              Text(error!),
              TextButton(
                onPressed: load,
                child: const Text('Tentar novamente'),
              ),
            ] else if (items.isEmpty)
              const Text('Nenhuma movimentação registrada.')
            else
              for (final m in items)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${m['produto']} • ${m['cor']} • ${m['tamanho']}',
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        Text('${m['tipo']} • ${date(m['criadaEm'])}'),
                        Text(
                          'Saldo físico: ${m['saldoAnterior']} → ${m['saldoAtual']}',
                        ),
                        Text(
                          'Reservado: ${m['reservadoAnterior']} → ${m['reservadoAtual']}',
                        ),
                        Text('Responsável: ${m['responsavel']}'),
                        Text(m['justificativa']),
                      ],
                    ),
                  ),
                ),
          ],
        ),
      ),
    ),
  );
}
