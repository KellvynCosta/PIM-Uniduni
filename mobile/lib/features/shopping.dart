import 'package:flutter/material.dart';

import '../core/api.dart';
import '../core/shopping_service.dart';

String shopMoney(num value) =>
    'R\$ ${value.toStringAsFixed(2).replaceAll('.', ',')}';
String shopDate(dynamic value) {
  final date = DateTime.tryParse(value?.toString() ?? '')?.toLocal();
  if (date == null) return '—';
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(date.day)}/${two(date.month)}/${date.year} ${two(date.hour)}:${two(date.minute)}';
}

const orderStates = {
  'Pendente': 'Aguardando pagamento',
  'Recusado': 'Pagamento recusado',
  'Pago': 'Pagamento aprovado',
  'EmPreparacao': 'Em preparação',
  'Pronto': 'Pronto para retirada',
  'Retirado': 'Retirado',
  'Cancelado': 'Cancelado',
  'Expirado': 'Reserva expirada',
};

class ProductPurchase extends StatefulWidget {
  const ProductPurchase({
    super.key,
    required this.api,
    required this.product,
    this.onLogin,
  });
  final UniduniApi api;
  final Map<String, dynamic> product;
  final VoidCallback? onLogin;
  @override
  State<ProductPurchase> createState() => _ProductPurchaseState();
}

class _ProductPurchaseState extends State<ProductPurchase> {
  final form = GlobalKey<FormState>();
  final quantity = TextEditingController(text: '1');
  int? variation;
  bool busy = false;
  String? error;
  @override
  void initState() {
    super.initState();
    variation = (widget.product['variacoes'] as List)
        .where((v) => (v['disponivel'] as num) > 0)
        .firstOrNull?['id'];
  }

  @override
  void dispose() {
    quantity.dispose();
    super.dispose();
  }

  Future<void> add() async {
    if (widget.api.user == null) {
      widget.onLogin?.call();
      return;
    }
    if (!form.currentState!.validate()) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await ShoppingService(widget.api)
          .add(variation!, int.parse(quantity.text));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Peça adicionada ao carrinho.')),
        );
      }
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final choices = widget.product['variacoes'] as List;
    final selected = choices.where((v) => v['id'] == variation).firstOrNull;
    return Form(
      key: form,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 20),
          DropdownButtonFormField<int>(
            initialValue: variation,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Cor e tamanho'),
            items: choices
                .map(
                  (v) => DropdownMenuItem<int>(
                    value: v['id'],
                    enabled: (v['disponivel'] as num) > 0,
                    child: Text(
                      '${v['cor']} · ${v['tamanho']} (${v['disponivel']} disponíveis)',
                    ),
                  ),
                )
                .toList(),
            onChanged: busy ? null : (v) => setState(() => variation = v),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: quantity,
            enabled: !busy,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Quantidade'),
            validator: (s) {
              final n = int.tryParse(s ?? '');
              return n == null ||
                      n < 1 ||
                      n > 99 ||
                      n > (selected?['disponivel'] as num? ?? 0)
                  ? 'Informe uma quantidade de 1 a 99 dentro do estoque.'
                  : null;
            },
          ),
          const SizedBox(height: 16),
          if (error != null)
            Semantics(
              liveRegion: true,
              child: Text(
                error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          FilledButton.icon(
            onPressed: busy || variation == null ? null : add,
            icon: const Icon(Icons.add_shopping_cart),
            label: Text(
              busy
                  ? 'Adicionando…'
                  : widget.api.user == null
                  ? 'Entrar para comprar'
                  : 'Adicionar ao carrinho',
            ),
          ),
          if (variation == null)
            const Text('Esta peça está sem estoque disponível.'),
          if (widget.api.user != null)
            TextButton(
              onPressed: busy
                  ? null
                  : () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => CartPage(api: widget.api),
                      ),
                    ),
              child: const Text('Ver meu carrinho'),
            ),
          const Text(
            'Pagamento exclusivamente simulado. Nenhuma cobrança real.',
          ),
        ],
      ),
    );
  }
}

class CartPage extends StatefulWidget {
  const CartPage({super.key, required this.api});
  final UniduniApi api;
  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  Map<String, dynamic>? cart;
  bool busy = false;
  String? error;
  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> run(Future<void> Function() action) async {
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await action();
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> load() => run(() async {
    final data = await ShoppingService(widget.api).cart();
    if (mounted) setState(() => cart = data);
  });
  Future<void> change(Map item, int n) => run(() async {
    await ShoppingService(widget.api).quantity(item['variacaoId'], n);
    final data = await ShoppingService(widget.api).cart();
    if (mounted) setState(() => cart = data);
  });
  Future<void> checkout() => run(() async {
    final order = await ShoppingService(widget.api).checkout();
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => OrderPage(api: widget.api, id: order['id']),
      ),
    );
    final data = await ShoppingService(widget.api).cart();
    if (mounted) setState(() => cart = data);
  });
  @override
  Widget build(BuildContext context) {
    final items = cart?['itens'] as List? ?? [];
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meu carrinho'),
        actions: [
          IconButton(
            tooltip: 'Atualizar carrinho',
            onPressed: busy ? null : load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            if (!busy) await load();
          },
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            children: [
              if (busy) const LinearProgressIndicator(),
              if (error != null) ...[
                Semantics(liveRegion: true, child: Text(error!)),
                TextButton(
                  onPressed: busy ? null : load,
                  child: const Text('Tentar novamente'),
                ),
              ],
              if (cart != null && items.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'Seu carrinho está vazio. Explore o catálogo para escolher uma peça.',
                  ),
                ),
              ...items.map(
                (i) => Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          i['nome'],
                          style: const TextStyle(
                            fontSize: 21,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text('${i['cor']} · ${i['tamanho']}'),
                        Text(
                          '${shopMoney(i['preco'])} por unidade · ${i['disponivel']} disponíveis',
                        ),
                        if (i['ativo'] != true ||
                            i['quantidade'] > i['disponivel'])
                          const Text(
                            'Revise a disponibilidade antes de finalizar.',
                          ),
                        Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 10,
                          children: [
                            IconButton(
                              tooltip: 'Diminuir quantidade de ${i['nome']}',
                              onPressed: busy || i['quantidade'] <= 1
                                  ? null
                                  : () => change(i, i['quantidade'] - 1),
                              icon: const Icon(Icons.remove_circle_outline),
                            ),
                            Text('${i['quantidade']} unidades'),
                            IconButton(
                              tooltip: 'Aumentar quantidade de ${i['nome']}',
                              onPressed:
                                  busy ||
                                      i['quantidade'] >= 99 ||
                                      i['quantidade'] >= i['disponivel'] ||
                                      i['ativo'] != true
                                  ? null
                                  : () => change(i, i['quantidade'] + 1),
                              icon: const Icon(Icons.add_circle_outline),
                            ),
                            TextButton(
                              onPressed: busy ? null : () => change(i, 0),
                              child: const Text('Remover'),
                            ),
                          ],
                        ),
                        Text(
                          shopMoney(i['subtotal']),
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (items.isNotEmpty) ...[
                const SizedBox(height: 20),
                Text(
                  'Total: ${shopMoney(cart!['total'])}',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Retirada na loja, sem frete. Ao finalizar, as peças são reservadas por 30 minutos. Preço e disponibilidade são conferidos pela loja.',
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: busy ? null : checkout,
                  child: const Text('Finalizar pedido'),
                ),
                const Text('Loja fictícia · pagamento somente simulado.'),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class OrdersPage extends StatefulWidget {
  const OrdersPage({super.key, required this.api, this.team = false});
  final UniduniApi api;
  final bool team;
  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  List? orders;
  bool busy = false;
  String? error;
  String filter = 'Todas', search = '';
  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final data = await ShoppingService(widget.api).orders(team: widget.team);
      if (mounted) setState(() => orders = data);
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.team && !widget.api.isTeam) {
      return Scaffold(
        appBar: AppBar(title: const Text('Pedidos da loja')),
        body: const Center(child: Text('Acesso restrito à equipe.')),
      );
    }
    final visible = orders
        ?.where(
          (p) =>
              (filter == 'Todas' || p['status'] == filter) &&
              '${p['id']} ${p['cliente'] ?? ''}'.toLowerCase().contains(
                search.toLowerCase(),
              ),
        )
        .toList();
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.team ? 'Pedidos da loja' : 'Meus pedidos'),
        actions: [
          IconButton(
            tooltip: 'Atualizar pedidos',
            onPressed: busy ? null : load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            if (!busy) await load();
          },
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            children: [
              const Text(
                'Últimos 100 pedidos. Atualize para acompanhar as mudanças.',
              ),
              if (widget.team) ...[
                const SizedBox(height: 16),
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Buscar por pedido ou cliente',
                    prefixIcon: Icon(Icons.search),
                  ),
                  onChanged: (v) => setState(() => search = v),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: filter,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Situação do pedido',
                  ),
                  items: [
                    const DropdownMenuItem(
                      value: 'Todas',
                      child: Text('Todas as situações'),
                    ),
                    ...orderStates.entries.map(
                      (e) =>
                          DropdownMenuItem(value: e.key, child: Text(e.value)),
                    ),
                  ],
                  onChanged: (v) => setState(() => filter = v!),
                ),
                const SizedBox(height: 16),
              ],
              if (busy) const LinearProgressIndicator(),
              if (error != null) ...[
                Text(error!),
                TextButton(
                  onPressed: busy ? null : load,
                  child: const Text('Tentar novamente'),
                ),
              ],
              if (visible?.isEmpty == true)
                Text(
                  widget.team
                      ? 'Nenhum pedido encontrado nesta consulta.'
                      : 'Você ainda não fez pedidos.',
                ),
              ...?visible?.map(
                (p) => Card(
                  child: ListTile(
                    title: Text('Pedido #${p['id']}'),
                    subtitle: Text(
                      '${widget.team ? '${p['cliente'] ?? 'Cliente'}\n' : ''}${orderStates[p['status']] ?? p['status']}\n${shopDate(p['criadoEm'])} · ${shopMoney(p['total'])}',
                    ),
                    isThreeLine: true,
                    trailing: const Icon(Icons.chevron_right),
                    onTap: busy
                        ? null
                        : () async {
                            await Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => OrderPage(
                                  api: widget.api,
                                  id: p['id'],
                                  team: widget.team,
                                ),
                              ),
                            );
                            if (mounted) await load();
                          },
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

class OrderPage extends StatefulWidget {
  const OrderPage({
    super.key,
    required this.api,
    required this.id,
    this.team = false,
  });
  final UniduniApi api;
  final int id;
  final bool team;
  @override
  State<OrderPage> createState() => _OrderPageState();
}

class _OrderPageState extends State<OrderPage> {
  Map<String, dynamic>? order;
  bool busy = false;
  String? error;
  String method = 'Pix', result = 'Aprovado';
  final pickupCode = TextEditingController();
  @override
  void dispose() {
    pickupCode.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> action(Future<dynamic> Function() operation) async {
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final data = await operation();
      if (mounted) setState(() => order = Map<String, dynamic>.from(data));
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> load() => action(() {
    if (widget.team && !widget.api.isTeam) {
      throw const ApiException('Acesso restrito à equipe.');
    }
    return widget.api.request('GET', '/api/compras/pedidos/${widget.id}');
  });
  Future<void> advance(String status) async {
    if (status == 'Retirado') {
      if (pickupCode.text.trim().isEmpty) {
        setState(() => error = 'Informe o código apresentado pelo cliente.');
        return;
      }
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Confirmar retirada?'),
          content: Text(
            'Pedido #${widget.id}. Confirme que as peças estão sendo entregues à pessoa que apresentou o código.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Voltar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Confirmar entrega'),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;
    }
    await action(
      () => ShoppingService(widget.api).advance(
        widget.id,
        status,
        code: status == 'Retirado' ? pickupCode.text : null,
      ),
    );
  }

  Future<void> cancel() async {
    final reason = TextEditingController();
    final key = GlobalKey<FormState>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancelar pedido?'),
        scrollable: true,
        content: Form(
          key: key,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'A reserva será liberada. Se já houver pagamento aprovado, será registrado um estorno simulado.',
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: reason,
                maxLength: 200,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Motivo do cancelamento',
                ),
                validator: (s) => (s?.trim().length ?? 0) < 5
                    ? 'Informe um motivo com pelo menos 5 caracteres.'
                    : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Voltar'),
          ),
          FilledButton(
            onPressed: () {
              if (key.currentState!.validate()) Navigator.pop(ctx, true);
            },
            child: const Text('Confirmar cancelamento'),
          ),
        ],
      ),
    );
    final text = reason.text.trim();
    // O diálogo ainda pode estar finalizando sua animação de saída.
    if (confirmed == true && mounted) {
      await action(
        () => widget.api.request(
          'POST',
          '/api/compras/pedidos/${widget.id}/cancelar',
          body: {'motivo': text},
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = order;
    final payments = p?['pagamentos'] as List? ?? [];
    final pending = payments
        .where((pg) => pg['status'] == 'Pendente')
        .firstOrNull;
    final own = p?['usuarioId'] == widget.api.user?['id'];
    final payable =
        own && !widget.team && ['Pendente', 'Recusado'].contains(p?['status']);
    final team = widget.team && widget.api.isTeam;
    final cancelable = team
        ? p != null &&
              !['Cancelado', 'Expirado', 'Retirado'].contains(p['status'])
        : own && ['Pendente', 'Recusado', 'Pago'].contains(p?['status']);
    if (widget.team && !widget.api.isTeam) {
      return Scaffold(
        appBar: AppBar(title: const Text('Pedido')),
        body: const Center(child: Text('Acesso restrito à equipe.')),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: Text('Pedido #${widget.id}'),
        actions: [
          IconButton(
            tooltip: 'Atualizar pedido',
            onPressed: busy ? null : load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            if (!busy) await load();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (busy) const LinearProgressIndicator(),
                if (error != null) ...[
                  Semantics(
                    liveRegion: true,
                    child: Text(
                      error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: busy ? null : load,
                    child: const Text('Atualizar situação'),
                  ),
                ],
                if (p != null) ...[
                  if (team)
                    Text(
                      p['cliente'] ?? 'Cliente',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  Text(
                    orderStates[p['status']] ?? p['status'],
                    style: Theme.of(context).textTheme.headlineSmall
                        ?.copyWith(fontWeight: FontWeight.w900),
                  ),
                  Text(shopDate(p['criadoEm'])),
                  Text(
                    'Total: ${shopMoney(p['total'])}',
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  if (p['reservaAte'] != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Text(
                        'Reserva até ${shopDate(p['reservaAte'])}. Atualize para conferir a situação.',
                      ),
                    ),
                  ...(p['itens'] as List).map(
                    (i) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(i['nome']),
                      subtitle: Text(
                        '${i['cor']} · ${i['tamanho']}\n${i['quantidade']} × ${shopMoney(i['precoUnitario'])}',
                      ),
                      trailing: Text(shopMoney(i['subtotal'])),
                    ),
                  ),
                  const Divider(height: 32),
                  const Text(
                    'Retirada na loja',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                  ),
                  const Text(
                    'Av. Yojiro Takaoka, 3500 — Alphaville, Santana de Parnaíba — SP, 06500-000.',
                  ),
                  const Text(
                    'Seg. a sex.: 9h às 18h · sábado: 9h às 13h. Horário informativo, sem bloqueio para demonstração.',
                  ),
                  if (own &&
                      [
                        'Pago',
                        'EmPreparacao',
                        'Pronto',
                        'Retirado',
                      ].contains(p['status'])) ...[
                    const SizedBox(height: 16),
                    const Text('Código de retirada'),
                    SelectableText(
                      p['codigoRetirada'] ?? '',
                      style: const TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const Text(
                      'Apresente este código à equipe quando o pedido estiver pronto.',
                    ),
                  ],
                  if (p['retiradoEm'] != null)
                    Text(
                      'Retirado em ${shopDate(p['retiradoEm'])} · operador ${p['retiradoPor']}',
                    ),
                  if (team &&
                      [
                        'Pago',
                        'EmPreparacao',
                        'Pronto',
                      ].contains(p['status'])) ...[
                    const Divider(height: 36),
                    const Text(
                      'Atendimento pela equipe',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (p['status'] == 'Pago')
                      FilledButton(
                        onPressed: busy ? null : () => advance('EmPreparacao'),
                        child: const Text('Iniciar preparação'),
                      ),
                    if (p['status'] == 'EmPreparacao')
                      FilledButton(
                        onPressed: busy ? null : () => advance('Pronto'),
                        child: const Text('Marcar pronto para retirada'),
                      ),
                    if (p['status'] == 'Pronto') ...[
                      const Text(
                        'Peça o código à pessoa que veio retirar. Ele aparece em Meus pedidos na conta do comprador.',
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: pickupCode,
                        enabled: !busy,
                        maxLength: 12,
                        textCapitalization: TextCapitalization.characters,
                        decoration: const InputDecoration(
                          labelText: 'Código apresentado pelo cliente',
                        ),
                      ),
                      FilledButton(
                        onPressed: busy ? null : () => advance('Retirado'),
                        child: const Text('Confirmar retirada'),
                      ),
                    ],
                  ],
                  if (payable) ...[
                    const Divider(height: 40),
                    const Text(
                      'Pagamento simulado',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const Text(
                      'Ambiente acadêmico. Nenhuma cobrança real. Não informe dados bancários ou de cartão.',
                    ),
                    const SizedBox(height: 16),
                    if (pending == null) ...[
                      DropdownButtonFormField<String>(
                        initialValue: method,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Forma de pagamento',
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'Pix',
                            child: Text('Pix simulado'),
                          ),
                          DropdownMenuItem(
                            value: 'Cartao',
                            child: Text('Cartão de teste'),
                          ),
                        ],
                        onChanged: busy
                            ? null
                            : (v) => setState(() => method = v!),
                      ),
                      if (method == 'Cartao')
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Text(
                            'Cartão fictício ···· 4242 · validade 12/2099 · código 123. Nenhum dado real é solicitado.',
                          ),
                        ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        initialValue: result,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Resultado da simulação',
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'Aprovado',
                            child: Text('Aprovar pagamento'),
                          ),
                          DropdownMenuItem(
                            value: 'Recusado',
                            child: Text('Recusar pagamento'),
                          ),
                          DropdownMenuItem(
                            value: 'Pendente',
                            child: Text('Deixar pendente'),
                          ),
                        ],
                        onChanged: busy
                            ? null
                            : (v) => setState(() => result = v!),
                      ),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: busy
                            ? null
                            : () => action(
                                () =>
                                    ShoppingService(widget.api)
                                        .pay(widget.id, method, result),
                              ),
                        child: const Text('Simular pagamento'),
                      ),
                    ] else ...[
                      const Text(
                        'Uma tentativa está pendente. O prazo original da reserva é mantido.',
                      ),
                      if (pending['codigoPix'] != null)
                        SelectableText(pending['codigoPix']),
                      Wrap(
                        spacing: 12,
                        children: [
                          for (final entry in [
                            ('Aprovado', 'Aprovar tentativa'),
                            ('Recusado', 'Recusar tentativa'),
                          ])
                            OutlinedButton(
                              onPressed: busy
                                  ? null
                                  : () => action(
                                      () => widget.api.request(
                                        'POST',
                                        '/api/compras/pedidos/${widget.id}/pagamentos/${pending['id']}/resolver',
                                        body: {'resultado': entry.$1},
                                      ),
                                    ),
                              child: Text(entry.$2),
                            ),
                        ],
                      ),
                    ],
                  ],
                  if (cancelable)
                    TextButton(
                      onPressed: busy ? null : cancel,
                      child: const Text('Cancelar pedido'),
                    ),
                  const Divider(height: 36),
                  const Text(
                    'Tentativas de pagamento',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                  ),
                  if (payments.isEmpty)
                    const Text('Nenhuma tentativa registrada.'),
                  ...payments.map(
                    (pg) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        '${pg['metodo'] == 'Cartao' ? 'Cartão' : pg['metodo']} · ${pg['status']}',
                      ),
                      subtitle: Text(
                        '${shopDate(pg['atualizadoEm'])} · ${shopMoney(pg['valor'])}',
                      ),
                    ),
                  ),
                  const Divider(height: 32),
                  const Text(
                    'Histórico do pedido',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                  ),
                  ...(p['eventos'] as List).map(
                    (ev) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        '${shopDate(ev['criadoEm'])}\n${ev['descricao']}',
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Loja fictícia para fins acadêmicos. Endereço de referência da faculdade.',
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
