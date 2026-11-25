import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/api.dart';
import 'features/products_admin.dart';
import 'features/shopping.dart';
import 'features/sales_summary.dart';
import 'features/stock.dart';
import 'features/users_admin.dart';
import 'features/account.dart';

void main() => runApp(UniduniApp(api: UniduniApi()));
const teal = Color(0xff166b72);
String money(num value) =>
    'R\$ ${value.toStringAsFixed(2).replaceAll('.', ',')}';

class UniduniApp extends StatelessWidget {
  const UniduniApp({super.key, required this.api});
  final UniduniApi api;
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Uniduni',
    locale: const Locale('pt', 'BR'),
    supportedLocales: const [Locale('pt', 'BR')],
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
    debugShowCheckedModeBanner: false,
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
    home: ShopPage(api: api),
  );
}

class ShopPage extends StatefulWidget {
  const ShopPage({super.key, required this.api});
  final UniduniApi api;
  @override
  State<ShopPage> createState() => _ShopPageState();
}

class _ShopPageState extends State<ShopPage> {
  List<Map<String, dynamic>> products = [];
  String search = '', category = 'Todas';
  String? catalogError, accountError;
  bool loading = true, busy = false, hidePassword = true;
  int page = 0;
  final form = GlobalKey<FormState>();
  final email = TextEditingController(), password = TextEditingController();
  @override
  void initState() {
    super.initState();
    load();
    widget.api.onSessionExpired = () {
      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
        setState(() {
          page = 1;
          accountError = 'Sua sessão expirou. Entre novamente.';
        });
      }
    };
  }

  @override
  void dispose() {
    widget.api.onSessionExpired = null;
    email.dispose();
    password.dispose();
    super.dispose();
  }

  Future<void> load() async {
    setState(() {
      loading = true;
      catalogError = null;
    });
    try {
      final data = await widget.api.catalog();
      if (mounted) {
        setState(() {
          products = data;
          if (!data.any((p) => p['categoriaNome'] == category)) {
            category = 'Todas';
          }
        });
      }
    } catch (e) {
      if (mounted) setState(() => catalogError = e.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> accountAction(Future<void> Function() operation) async {
    setState(() {
      busy = true;
      accountError = null;
    });
    try {
      await operation();
    } catch (e) {
      if (mounted) setState(() => accountError = e.toString());
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> openAccountForm({bool register = false}) async {
    final result = await Navigator.of(context).push<String>(
      MaterialPageRoute<String>(
        builder: (_) => AccountFormPage(api: widget.api, register: register),
      ),
    );
    if (!mounted || result == null) return;
    setState(() {
      password.clear();
      if (register) {
        email.text = result;
        accountError = 'Conta criada! Entre com seu e-mail e senha.';
      } else {
        accountError = 'Senha alterada. Entre novamente.';
      }
    });
  }

  Widget account() {
    final user = widget.api.user;
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          user == null ? 'Bom ter você por aqui.' : 'Olá, ${user['nome']}.',
          style: Theme.of(context).textTheme.headlineMedium
              ?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 20),
        if (user != null) ...[
          Text(user['email']),
          const SizedBox(height: 12),
          Text(
            'Perfil: ${user['tipoUsuario'] == 'Funcionario' ? 'Funcionário' : user['tipoUsuario']}',
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: busy
                ? null
                : () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => CartPage(api: widget.api),
                    ),
                  ),
            icon: const Icon(Icons.shopping_bag_outlined),
            label: const Text('Meu carrinho'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: busy
                ? null
                : () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => OrdersPage(api: widget.api),
                    ),
                  ),
            icon: const Icon(Icons.receipt_long_outlined),
            label: const Text('Meus pedidos'),
          ),
          const SizedBox(height: 16),
          if (widget.api.isTeam) ...[
            FilledButton.icon(
              onPressed: busy
                  ? null
                  : () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => OrdersPage(api: widget.api, team: true),
                      ),
                    ),
              icon: const Icon(Icons.local_mall_outlined),
              label: const Text('Pedidos e retirada'),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              icon: const Icon(Icons.inventory_2_outlined),
              label: const Text('Gerenciar produtos'),
              onPressed: busy
                  ? null
                  : () async {
                      await Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => ProductsAdminPage(api: widget.api),
                        ),
                      );
                      if (mounted) await load();
                    },
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              icon: const Icon(Icons.warehouse_outlined),
              label: const Text('Estoque e movimentações'),
              onPressed: busy
                  ? null
                  : () async {
                      await Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => StockPage(api: widget.api),
                        ),
                      );
                      if (mounted) await load();
                    },
            ),
            const SizedBox(height: 16),
          ],
          if (user['tipoUsuario'] == 'Administrador') ...[
            OutlinedButton.icon(
              icon: const Icon(Icons.manage_accounts_outlined),
              label: const Text('Gerenciar usuários'),
              onPressed: busy
                  ? null
                  : () async {
                      final changed = await Navigator.of(context).push<bool>(
                        MaterialPageRoute<bool>(
                          builder: (_) => UsersAdminPage(api: widget.api),
                        ),
                      );
                      if (mounted) {
                        setState(() {
                          if (changed == true && widget.api.user == null) {
                            accountError = 'Senha alterada. Entre novamente.';
                          }
                        });
                      }
                    },
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: busy
                  ? null
                  : () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => SalesSummaryPage(api: widget.api),
                      ),
                    ),
              icon: const Icon(Icons.payments_outlined),
              label: const Text('Total vendido'),
            ),
            const SizedBox(height: 16),
          ],
          OutlinedButton.icon(
            onPressed: busy ? null : () => openAccountForm(),
            icon: const Icon(Icons.lock_outline),
            label: const Text('Alterar minha senha'),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: busy ? null : () => accountAction(widget.api.logout),
            child: const Text('Sair da conta'),
          ),
        ] else
          Form(
            key: form,
            child: Column(
              children: [
                const Text('Entre com a mesma conta que você utiliza no site.'),
                const SizedBox(height: 24),
                TextFormField(
                  controller: email,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.email],
                  decoration: const InputDecoration(labelText: 'E-mail'),
                  validator: (v) => v == null || !v.trim().contains('@')
                      ? 'Informe seu e-mail.'
                      : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: password,
                  obscureText: hidePassword,
                  enableSuggestions: false,
                  autocorrect: false,
                  decoration: InputDecoration(
                    labelText: 'Senha',
                    suffixIcon: IconButton(
                      tooltip: hidePassword ? 'Mostrar senha' : 'Ocultar senha',
                      onPressed: () =>
                          setState(() => hidePassword = !hidePassword),
                      icon: Icon(
                        hidePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                    ),
                  ),
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Informe sua senha.' : null,
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: busy
                      ? null
                      : () {
                          if (form.currentState!.validate()) {
                            accountAction(() async {
                              await widget.api.login(email.text, password.text);
                              password.clear();
                            });
                          }
                        },
                  child: const Text('Entrar na minha conta'),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: busy
                      ? null
                      : () => openAccountForm(register: true),
                  icon: const Icon(Icons.person_add_outlined),
                  label: const Text('Criar minha conta'),
                ),
              ],
            ),
          ),
        if (busy)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(),
            ),
          ),
        if (accountError != null)
          Padding(
            padding: const EdgeInsets.only(top: 20),
            child: Semantics(liveRegion: true, child: Text(accountError!)),
          ),
      ],
    );
  }

  Widget catalog() {
    final visible = products
        .where(
          (p) =>
              (category == 'Todas' || p['categoriaNome'] == category) &&
              '${p['nome']} ${p['descricao']}'.toLowerCase().contains(
                search.toLowerCase(),
              ),
        )
        .toList();
    return RefreshIndicator(
      onRefresh: load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: const LinearGradient(
                colors: [Color(0xfffce6f2), Color(0xffe4f6f8)],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'O começo de tantas histórias.',
                  style: Theme.of(context).textTheme.headlineMedium
                      ?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Roupas, calçados e pequenos detalhes para o seu bebê.',
                ),
                const SizedBox(height: 12),
                const Text('Retirada na loja · pagamentos simulados'),
              ],
            ),
          ),
          const SizedBox(height: 24),
          TextField(
            decoration: const InputDecoration(
              labelText: 'Buscar produtos',
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: (s) => setState(() => search = s),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                {'Todas', ...products.map((p) => p['categoriaNome'] as String)}
                    .map(
                      (c) => ChoiceChip(
                        label: Text(c),
                        selected: category == c,
                        onSelected: (_) => setState(() => category = c),
                      ),
                    )
                    .toList(),
          ),
          const SizedBox(height: 20),
          if (loading)
            const Center(
              child: CircularProgressIndicator(
                semanticsLabel: 'Carregando catálogo',
              ),
            )
          else if (catalogError != null) ...[
            Semantics(liveRegion: true, child: Text(catalogError!)),
            FilledButton.icon(
              onPressed: load,
              icon: const Icon(Icons.refresh),
              label: const Text('Tentar novamente'),
            ),
          ] else ...[
            Text('${visible.length} produtos encontrados'),
            const SizedBox(height: 12),
            if (visible.isEmpty)
              const Text(
                'Nenhuma peça encontrada. Experimente outra busca ou categoria.',
              ),
            ...visible.map(
              (p) => Card(
                color: Colors.white,
                clipBehavior: Clip.antiAlias,
                margin: const EdgeInsets.only(bottom: 16),
                child: InkWell(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => ProductPage(
                        api: widget.api,
                        product: p,
                        onLogin: () {
                          Navigator.of(context).popUntil((r) => r.isFirst);
                          setState(() => page = 1);
                        },
                      ),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: ProductImage(
                            api: widget.api,
                            product: p,
                            height: 200,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          p['categoriaNome'],
                          style: const TextStyle(color: teal),
                        ),
                        Text(
                          p['nome'],
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          money(p['preco']),
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: teal,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Row(
                          children: [
                            Text('Ver detalhes'),
                            SizedBox(width: 8),
                            Icon(Icons.arrow_forward),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      actions: [
        IconButton(
          tooltip: 'Meu carrinho',
          icon: const Icon(Icons.shopping_bag_outlined),
          onPressed: () {
            if (widget.api.user == null) {
              setState(() => page = 1);
              return;
            }
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => CartPage(api: widget.api),
              ),
            );
          },
        ),
      ],
      title: Image.asset(
        'assets/uniduni-logo.png',
        width: 155,
        semanticLabel: 'Uniduni, moda para bebês',
      ),
    ),
    body: SafeArea(child: page == 0 ? catalog() : account()),
    bottomNavigationBar: NavigationBar(
      selectedIndex: page,
      onDestinationSelected: (value) => setState(() => page = value),
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.storefront_outlined),
          label: 'Catálogo',
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline),
          label: 'Minha conta',
        ),
      ],
    ),
  );
}

class ProductImage extends StatelessWidget {
  const ProductImage({
    super.key,
    required this.api,
    required this.product,
    required this.height,
  });
  final UniduniApi api;
  final Map<String, dynamic> product;
  final double height;
  @override
  Widget build(BuildContext context) => Image.network(
    api.image(product['imagem'] as String? ?? '').toString(),
    height: height,
    fit: BoxFit.contain,
    semanticLabel: product['nome'],
    errorBuilder: (_, _, _) => SizedBox(
      height: height,
      child: const Center(
        child: Icon(
          Icons.image_not_supported_outlined,
          size: 60,
          semanticLabel: 'Imagem indisponível',
        ),
      ),
    ),
  );
}

class ProductPage extends StatelessWidget {
  const ProductPage({
    super.key,
    required this.api,
    required this.product,
    this.onLogin,
  });
  final UniduniApi api;
  final Map<String, dynamic> product;
  final VoidCallback? onLogin;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Detalhes da peça')),
    body: SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          ProductImage(api: api, product: product, height: 280),
          const SizedBox(height: 24),
          Text(
            product['nome'],
            style: Theme.of(context).textTheme.headlineMedium
                ?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 12),
          Text(product['descricao']),
          Text(
            money(product['preco']),
            style: const TextStyle(
              fontSize: 30,
              color: teal,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Cores e tamanhos',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          ...(product['variacoes'] as List).map(
            (v) => ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('${v['cor']} · ${v['tamanho']}'),
              subtitle: Text('${v['disponivel']} unidades disponíveis'),
            ),
          ),
          ProductPurchase(api: api, product: product, onLogin: onLogin),
          if ((product['guiaMedidas'] as String? ?? '').isNotEmpty)
            ExpansionTile(
              title: const Text('Guia de medidas'),
              children: [Text(product['guiaMedidas'])],
            ),
          const Divider(height: 40),
          const Text(
            'Retirada na loja',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          const Text(
            'Av. Yojiro Takaoka, 3500 — Alphaville, Santana de Parnaíba — SP, 06500-000.',
          ),
          const SizedBox(height: 12),
          const Text(
            'Seg. a sex.: 9h às 18h · sábado: 9h às 13h. Horário informativo.',
          ),
          const SizedBox(height: 12),
          const Text(
            'Loja fictícia para fins acadêmicos. Endereço de referência da faculdade.',
          ),
        ],
      ),
    ),
  );
}
