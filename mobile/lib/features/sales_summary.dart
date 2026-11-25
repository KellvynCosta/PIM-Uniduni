import 'package:flutter/material.dart';

import '../core/api.dart';
import '../core/shopping_service.dart';
import 'shopping.dart' show shopMoney;

class SalesSummaryPage extends StatefulWidget {
  const SalesSummaryPage({super.key, required this.api});
  final UniduniApi api;
  @override
  State<SalesSummaryPage> createState() => _SalesSummaryState();
}

class _SalesSummaryState extends State<SalesSummaryPage> {
  DateTime? start, end;
  Map<String, dynamic>? summary;
  bool busy = false;
  String? error;
  bool get allowed => widget.api.user?['tipoUsuario'] == 'Administrador';
  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    if (!allowed) return;
    setState(() {
      busy = true;
      error = null;
      summary = null;
    });
    try {
      final result = await ShoppingService(widget.api)
          .summary(start: start, end: end);
      if (mounted) setState(() => summary = result);
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  String dateLabel(DateTime? date) => date == null
      ? 'Sem limite'
      : '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  Future<void> pick(bool initial) async {
    final selected = await showDatePicker(
      context: context,
      initialDate: (initial ? start : end) ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100, 12, 31),
      helpText: initial ? 'Data inicial' : 'Data final (inclusive)',
    );
    if (selected != null && mounted) {
      setState(() {
        if (initial) {
          start = selected;
        } else {
          end = selected;
        }
        summary = null;
        error = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Total vendido')),
    body: SafeArea(
      child: !allowed
          ? const Center(child: Text('Acesso exclusivo do Administrador.'))
          : RefreshIndicator(
              onRefresh: () async {
                if (!busy) await load();
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'As vendas da Uniduni',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Total dos pagamentos simulados atualmente aprovados, excluindo os estornados. O período considera a data de aprovação. Os dias são os do horário local do aparelho.',
                    ),
                    const SizedBox(height: 24),
                    OutlinedButton.icon(
                      onPressed: busy ? null : () => pick(true),
                      icon: const Icon(Icons.calendar_today_outlined),
                      label: Text('De: ${dateLabel(start)}'),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: busy ? null : () => pick(false),
                      icon: const Icon(Icons.event_outlined),
                      label: Text('Até (inclusive): ${dateLabel(end)}'),
                    ),
                    TextButton(
                      onPressed: busy
                          ? null
                          : () {
                              setState(() {
                                start = null;
                                end = null;
                                summary = null;
                              });
                              load();
                            },
                      child: const Text('Consultar todo o período'),
                    ),
                    FilledButton(
                      onPressed: busy ? null : load,
                      child: const Text('Consultar período'),
                    ),
                    const SizedBox(height: 24),
                    if (busy)
                      const LinearProgressIndicator(
                        semanticsLabel: 'Consultando vendas',
                      ),
                    if (error != null)
                      Semantics(
                        liveRegion: true,
                        child: Text(
                          error!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ),
                    if (summary != null)
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: const Color(0xffeee6f7),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Total vendido na simulação',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              shopMoney(summary!['totalVendido']),
                              style: const TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.w900,
                                color: Color(0xff166b72),
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 20),
                    const Text(
                      'Um estorno posterior também remove a venda do período da aprovação. Este indicador não representa lucro nem fluxo de caixa por data de estorno.',
                    ),
                  ],
                ),
              ),
            ),
    ),
  );
}
