import 'package:flutter/material.dart';

import '../core/api.dart';

String _price(num value) =>
    'R\$ ${value.toStringAsFixed(2).replaceAll('.', ',')}';

class ProductsAdminPage extends StatefulWidget {
  const ProductsAdminPage({super.key, required this.api});
  final UniduniApi api;
  @override
  State<ProductsAdminPage> createState() => _ProductsAdminState();
}

class _ProductsAdminState extends State<ProductsAdminPage> {
  List<Map<String, dynamic>> products = [];
  bool loading = true, changing = false, showInactive = false;
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
      final data = await widget.api.adminProducts();
      if (mounted) setState(() => products = data);
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  void message(String text) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> edit([Map<String, dynamic>? product]) async {
    setState(() => changing = true);
    try {
      // Busca a versão atual ao abrir a edição, inclusive mudanças feitas no site.
      final current = product == null
          ? null
          : await widget.api.adminProduct(product['id']);
      if (!mounted) return;
      final saved = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => ProductFormPage(api: widget.api, product: current),
        ),
      );
      if (saved == true && mounted) {
        message('Produto salvo.');
        await load();
      }
    } catch (e) {
      if (mounted) message(e.toString());
    } finally {
      if (mounted) setState(() => changing = false);
    }
  }

  Future<void> deactivateItem(Map<String, dynamic> product) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Desativar produto?'),
        content: Text(
          '“${product['nome']}” deixará de aparecer no catálogo. O histórico será preservado. Você poderá reativá-lo pela edição.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Voltar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Desativar'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => changing = true);
    try {
      await widget.api.deactivateProduct(product['id']);
      if (mounted) {
        message('Produto desativado.');
        await load();
      }
    } catch (e) {
      if (mounted) message(e.toString());
    } finally {
      if (mounted) setState(() => changing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.api.isTeam) {
      return Scaffold(
        appBar: AppBar(title: const Text('Produtos')),
        body: const Center(child: Text('Acesso restrito à equipe da loja.')),
      );
    }
    final visible = products
        .where(
          (p) =>
              (showInactive || p['ativo'] == true) &&
              '${p['nome']} ${p['categoriaNome']}'.toLowerCase().contains(
                search.toLowerCase(),
              ),
        )
        .toList();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gerenciar produtos'),
        actions: [
          IconButton(
            tooltip: 'Atualizar produtos',
            onPressed: loading || changing ? null : load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            if (!changing) await load();
          },
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
            children: [
              Text(
                'Cada peça em seu lugar.',
                style: Theme.of(context).textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 8),
              const Text(
                'Cadastre e atualize os produtos da mesma loja que aparece no site.',
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: changing || loading ? null : () => edit(),
                icon: const Icon(Icons.add),
                label: const Text('Cadastrar produto'),
              ),
              const SizedBox(height: 20),
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Buscar na administração',
                  prefixIcon: Icon(Icons.search),
                ),
                onChanged: (value) => setState(() => search = value),
              ),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: const Text('Mostrar também os inativos'),
                value: showInactive,
                onChanged: (value) => setState(() => showInactive = value),
              ),
              if (loading || changing)
                const LinearProgressIndicator(
                  semanticsLabel: 'Atualizando produtos',
                ),
              if (error != null) ...[
                Semantics(liveRegion: true, child: Text(error!)),
                TextButton(
                  onPressed: loading ? null : load,
                  child: const Text('Tentar novamente'),
                ),
              ],
              if (!loading && error == null && visible.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Text('Nenhum produto encontrado.'),
                ),
              ...visible.map(
                (p) => Card(
                  color: Colors.white,
                  margin: const EdgeInsets.only(top: 14),
                  child: ExpansionTile(
                    key: ValueKey(
                      '${p['id']}-${p['ativo']}-${p['nome']}-${p['preco']}',
                    ),
                    title: Text(
                      p['nome'],
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    subtitle: Text(
                      '${p['categoriaNome']} · ${_price(p['preco'])}\n${p['ativo'] == true ? 'Ativo' : 'Inativo'} · ${p['estoque']} disponíveis',
                    ),
                    childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(p['descricao']),
                      ),
                      const SizedBox(height: 16),
                      ...(p['variacoes'] as List).map(
                        (v) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            '${v['cor']} · ${v['tamanho']}${v['ativo'] == true ? '' : ' · Inativa'}',
                          ),
                          subtitle: Text(
                            'Físico: ${v['estoque']} · Reservado: ${v['reservado']}\nDisponível: ${v['disponivel']} · Mínimo: ${v['estoqueMinimo']}',
                          ),
                        ),
                      ),
                      Wrap(
                        spacing: 12,
                        runSpacing: 8,
                        children: [
                          OutlinedButton.icon(
                            onPressed: changing || loading
                                ? null
                                : () => edit(p),
                            icon: const Icon(Icons.edit_outlined),
                            label: const Text('Editar produto'),
                          ),
                          if (p['ativo'] == true)
                            TextButton.icon(
                              onPressed: changing || loading
                                  ? null
                                  : () => deactivateItem(p),
                              icon: const Icon(Icons.archive_outlined),
                              label: const Text('Desativar produto'),
                            ),
                        ],
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

class ProductFormPage extends StatefulWidget {
  const ProductFormPage({super.key, required this.api, this.product});
  final UniduniApi api;
  final Map<String, dynamic>? product;
  @override
  State<ProductFormPage> createState() => _ProductFormState();
}

class _ProductFormState extends State<ProductFormPage> {
  final form = GlobalKey<FormState>();
  late final Map<String, TextEditingController> fields;
  List<Map<String, dynamic>> categories = [];
  int? category;
  String gender = 'Unissex';
  bool active = true, loading = true, saving = false;
  String? error;
  bool get creating => widget.product == null;
  String get categoryName =>
      categories.where((c) => c['id'] == category).firstOrNull?['nome'] ?? '';
  @override
  void initState() {
    super.initState();
    final p = widget.product;
    fields = {
      for (final name in [
        'nome',
        'descricao',
        'preco',
        'imagem',
        'guiaMedidas',
        'cor',
        'tamanho',
        'estoqueInicial',
        'estoqueMinimo',
      ])
        name: TextEditingController(
          text: name == 'preco'
              ? p == null
                    ? ''
                    : (p[name] as num).toStringAsFixed(2).replaceAll('.', ',')
              : name == 'estoqueInicial'
              ? '0'
              : name == 'estoqueMinimo'
              ? '3'
              : p?[name]?.toString() ?? '',
        ),
    };
    category = p?['categoriaId'];
    gender = p?['genero'] ?? 'Unissex';
    active = p?['ativo'] ?? true;
    loadCategories();
  }

  @override
  void dispose() {
    for (final controller in fields.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> loadCategories() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final data = await widget.api.categories();
      if (data.isEmpty) {
        throw const ApiException(
          'Não há categorias disponíveis. Confira o cadastro no site.',
        );
      }
      if (mounted) {
        setState(() {
          categories = data;
          if (!data.any((c) => c['id'] == category)) {
            category = data.first['id'];
          }
          if (creating &&
              categoryName == 'Roupas' &&
              fields['tamanho']!.text.isEmpty) {
            fields['tamanho']!.text = 'RN';
          }
        });
      }
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  String text(String name) => fields[name]!.text.trim();
  num? get price => num.tryParse(text('preco').replaceAll(',', '.'));
  Future<void> save() async {
    if (!form.currentState!.validate()) return;
    setState(() {
      saving = true;
      error = null;
    });
    try {
      await widget.api.saveProduct({
        'nome': text('nome'),
        'descricao': text('descricao'),
        'preco': price,
        'categoriaId': category,
        'genero': gender,
        'imagem': text('imagem'),
        'guiaMedidas': text('guiaMedidas'),
        'ativo': active,
        if (creating)
          'variacaoInicial': {
            'cor': text('cor'),
            'tamanho': text('tamanho').toUpperCase(),
            'estoqueInicial': int.parse(text('estoqueInicial')),
            'estoqueMinimo': int.parse(text('estoqueMinimo')),
          },
      }, id: widget.product?['id']);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Widget input(
    String name,
    String label, {
    int min = 0,
    int max = 100,
    int lines = 1,
    bool number = false,
    String? helper,
    String? Function(String)? validate,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 18),
    child: TextFormField(
      controller: fields[name],
      enabled: !saving,
      maxLength: max,
      maxLines: lines,
      keyboardType: number
          ? const TextInputType.numberWithOptions(decimal: true)
          : null,
      decoration: InputDecoration(
        labelText: label,
        helperText: helper,
        helperMaxLines: 4,
        counterText: '',
      ),
      validator: (value) {
        final s = value?.trim() ?? '';
        return s.length < min ? 'Informe $label.' : validate?.call(s);
      },
    ),
  );
  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !saving,
    child: Scaffold(
      appBar: AppBar(
        title: Text(creating ? 'Cadastrar produto' : 'Editar produto'),
      ),
      body: SafeArea(
        child: loading
            ? const Center(child: CircularProgressIndicator())
            : categories.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(error ?? 'Não foi possível carregar as categorias.'),
                      TextButton(
                        onPressed: loadCategories,
                        child: const Text('Tentar novamente'),
                      ),
                    ],
                  ),
                ),
              )
            : Form(
                key: form,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Dados da peça',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 20),
                      input('nome', 'Nome do produto', min: 2),
                      input(
                        'descricao',
                        'Descrição',
                        min: 5,
                        max: 500,
                        lines: 3,
                      ),
                      input(
                        'preco',
                        'Preço (R\$)',
                        min: 1,
                        max: 12,
                        number: true,
                        helper: 'Exemplo: 49,90. Sem separador de milhares.',
                        validate: (s) =>
                            !RegExp(r'^\d{1,8}([.,]\d{1,2})?$').hasMatch(s) ||
                                price == null ||
                                price! < .01 ||
                                price! > 99999999.99
                            ? 'Informe um preço entre 0,01 e 99.999.999,99.'
                            : null,
                      ),
                      DropdownButtonFormField<int>(
                        initialValue: category,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Categoria',
                        ),
                        items: categories
                            .map(
                              (c) => DropdownMenuItem<int>(
                                value: c['id'],
                                child: Text(c['nome']),
                              ),
                            )
                            .toList(),
                        onChanged: saving
                            ? null
                            : (value) => setState(() {
                                category = value;
                                if (creating) {
                                  fields['tamanho']!.text =
                                      categoryName == 'Roupas' ? 'RN' : '';
                                }
                              }),
                      ),
                      const SizedBox(height: 18),
                      DropdownButtonFormField<String>(
                        initialValue: gender,
                        isExpanded: true,
                        decoration: const InputDecoration(labelText: 'Gênero'),
                        items: ['Unissex', 'Masculino', 'Feminino']
                            .map(
                              (g) => DropdownMenuItem(value: g, child: Text(g)),
                            )
                            .toList(),
                        onChanged: saving
                            ? null
                            : (v) => setState(() => gender = v!),
                      ),
                      const SizedBox(height: 18),
                      input(
                        'imagem',
                        'Arquivo da imagem (opcional)',
                        max: 255,
                        helper: 'Use o nome de uma imagem já disponível na loja. Sem imagem, será exibido um ícone.',
                        validate: (s) =>
                            s.isEmpty ||
                                RegExp(
                                  r'^[\p{L}\p{N}_ .-]+\.(jpg|jpeg|png|webp)$',
                                  unicode: true,
                                ).hasMatch(s)
                            ? null
                            : 'Informe somente o nome de um arquivo JPG, PNG ou WebP.',
                      ),
                      input(
                        'guiaMedidas',
                        'Guia de medidas (opcional)',
                        max: 500,
                        lines: 3,
                      ),
                      if (!creating)
                        SwitchListTile.adaptive(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Ativo no catálogo'),
                          value: active,
                          onChanged: saving
                              ? null
                              : (value) => setState(() => active = value),
                        ),
                      if (creating) ...[
                        const Divider(height: 36),
                        const Text(
                          'Primeira cor e tamanho',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Cada combinação possui seu próprio estoque.',
                        ),
                        const SizedBox(height: 18),
                        input('cor', 'Cor', min: 1, max: 40),
                        input(
                          'tamanho',
                          'Tamanho',
                          min: 1,
                          max: 20,
                          helper: categoryName == 'Roupas'
                              ? 'RN, P, M ou G.'
                              : categoryName == 'Calçados'
                              ? 'Numeração de 1 a 99.'
                              : 'Informe a medida ou tamanho da peça.',
                          validate: (s) =>
                              categoryName == 'Roupas' &&
                                  ![
                                    'RN',
                                    'P',
                                    'M',
                                    'G',
                                  ].contains(s.toUpperCase())
                              ? 'Escolha RN, P, M ou G.'
                              : categoryName == 'Calçados' &&
                                    (int.tryParse(s) == null ||
                                        int.parse(s) < 1 ||
                                        int.parse(s) > 99)
                              ? 'Informe a numeração de 1 a 99.'
                              : null,
                        ),
                        for (final item in [
                          ('estoqueInicial', 'Estoque inicial'),
                          ('estoqueMinimo', 'Estoque mínimo'),
                        ])
                          input(
                            item.$1,
                            item.$2,
                            min: 1,
                            max: 7,
                            number: true,
                            validate: (s) =>
                                int.tryParse(s) == null ||
                                    int.parse(s) < 0 ||
                                    int.parse(s) > 1000000
                                ? 'Informe um inteiro de 0 a 1.000.000.'
                                : null,
                          ),
                      ] else
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 18),
                          child: Text(
                            'A edição do produto preserva os saldos e as variações. Para entradas e ajustes, acesse Estoque e movimentações em Minha conta.',
                          ),
                        ),
                      if (error != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 18),
                          child: Semantics(
                            liveRegion: true,
                            child: Text(
                              error!,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                              ),
                            ),
                          ),
                        ),
                      FilledButton.icon(
                        onPressed: saving ? null : save,
                        icon: const Icon(Icons.check),
                        label: Text(saving ? 'Salvando…' : 'Salvar produto'),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
      ),
    ),
  );
}
