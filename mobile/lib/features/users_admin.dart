import 'package:flutter/material.dart';

import '../core/api.dart';
import '../core/users_service.dart';

String _role(String value) => value == 'Funcionario' ? 'Funcionário' : value;

class UsersAdminPage extends StatefulWidget {
  const UsersAdminPage({super.key, required this.api});
  final UniduniApi api;
  @override
  State<UsersAdminPage> createState() => _UsersAdminState();
}

class _UsersAdminState extends State<UsersAdminPage> {
  List<Map<String, dynamic>> users = [];
  bool loading = true, busy = false;
  String search = '', role = 'Todos';
  String? error;
  bool get allowed => widget.api.user?['tipoUsuario'] == 'Administrador';
  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    if (!allowed) {
      setState(() => loading = false);
      return;
    }
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final data = await UsersService(widget.api).list();
      data.sort(
        (a, b) => (a['nome'] as String).toLowerCase().compareTo(
          (b['nome'] as String).toLowerCase(),
        ),
      );
      if (mounted) setState(() => users = data);
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  void message(String value) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(value)));
  }

  Future<void> edit([int? id]) async {
    setState(() => busy = true);
    try {
      final current = id == null
          ? null
          : await UsersService(widget.api).get(id);
      if (!mounted) return;
      final result = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (_) => UserFormPage(api: widget.api, user: current),
        ),
      );
      if (!mounted) return;
      if (widget.api.user == null) {
        Navigator.pop(context, result == true);
        return;
      }
      if (result == true) {
        message('Usuário salvo.');
        await load();
      }
    } catch (e) {
      if (mounted) message(e.toString());
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> deactivateAccount(Map<String, dynamic> user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        scrollable: true,
        title: const Text('Desativar conta?'),
        content: Text(
          '${user['nome']} não poderá mais entrar no site ou no aplicativo. As sessões serão encerradas e o histórico será preservado.',
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
    setState(() => busy = true);
    try {
      await UsersService(widget.api).deactivate(user['id']);
      if (mounted) {
        message('Conta desativada. Histórico preservado.');
        await load();
      }
    } catch (e) {
      if (mounted) message(e.toString());
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final visible = users
        .where(
          (u) =>
              (role == 'Todos' || u['tipoUsuario'] == role) &&
              '${u['nome']} ${u['email']}'.toLowerCase().contains(
                search.toLowerCase(),
              ),
        )
        .toList();
    return PopScope(
      canPop: !busy,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Gerenciar usuários'),
          actions: [
            IconButton(
              tooltip: 'Atualizar usuários',
              onPressed: loading || busy ? null : load,
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        body: !allowed
            ? const Center(child: Text('Acesso exclusivo do Administrador.'))
            : SafeArea(
                child: RefreshIndicator(
                  onRefresh: () async {
                    if (!busy) await load();
                  },
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      Text(
                        'As pessoas da Uniduni.',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Gerencie as contas ativas de clientes e da equipe, compartilhadas com o site.',
                      ),
                      const SizedBox(height: 20),
                      FilledButton.icon(
                        onPressed: busy || loading ? null : () => edit(),
                        icon: const Icon(Icons.person_add_outlined),
                        label: const Text('Cadastrar usuário'),
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        decoration: const InputDecoration(
                          labelText: 'Buscar nome ou e-mail',
                          prefixIcon: Icon(Icons.search),
                        ),
                        onChanged: (s) => setState(() => search = s),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        initialValue: role,
                        isExpanded: true,
                        decoration: const InputDecoration(labelText: 'Perfil'),
                        items:
                            ['Todos', 'Cliente', 'Funcionario', 'Administrador']
                                .map(
                                  (r) => DropdownMenuItem(
                                    value: r,
                                    child: Text(_role(r)),
                                  ),
                                )
                                .toList(),
                        onChanged: (r) => setState(() => role = r!),
                      ),
                      const SizedBox(height: 20),
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
                      ] else if (visible.isEmpty)
                        const Text('Nenhuma conta ativa encontrada.')
                      else
                        for (final u in visible)
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Text(
                                    u['nome'],
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  Text(u['email']),
                                  Text('Perfil: ${_role(u['tipoUsuario'])}'),
                                  if ((u['telefone'] as String?)?.isNotEmpty ==
                                      true)
                                    Text('Telefone: ${u['telefone']}'),
                                  if (u['id'] == widget.api.user?['id'])
                                    const Padding(
                                      padding: EdgeInsets.only(top: 8),
                                      child: Text(
                                        'Sua conta',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                  const SizedBox(height: 12),
                                  OutlinedButton.icon(
                                    onPressed: busy
                                        ? null
                                        : () => edit(u['id']),
                                    icon: const Icon(Icons.edit_outlined),
                                    label: const Text('Editar usuário'),
                                  ),
                                  if (u['id'] != widget.api.user?['id'])
                                    TextButton.icon(
                                      onPressed: busy
                                          ? null
                                          : () => deactivateAccount(u),
                                      icon: const Icon(
                                        Icons.person_off_outlined,
                                      ),
                                      label: const Text('Desativar conta'),
                                    ),
                                ],
                              ),
                            ),
                          ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}

class UserFormPage extends StatefulWidget {
  const UserFormPage({super.key, required this.api, this.user});
  final UniduniApi api;
  final Map<String, dynamic>? user;
  @override
  State<UserFormPage> createState() => _UserFormState();
}

class _UserFormState extends State<UserFormPage> {
  final form = GlobalKey<FormState>();
  final name = TextEditingController(),
      email = TextEditingController(),
      phone = TextEditingController(),
      password = TextEditingController(),
      confirm = TextEditingController();
  late String role;
  bool saving = false, hide = true;
  String? error;
  bool get creating => widget.user == null;
  bool get own => !creating && widget.user!['id'] == widget.api.user?['id'];
  @override
  void initState() {
    super.initState();
    final u = widget.user;
    name.text = u?['nome'] ?? '';
    email.text = u?['email'] ?? '';
    phone.text = u?['telefone'] ?? '';
    role = u?['tipoUsuario'] ?? 'Cliente';
  }

  @override
  void dispose() {
    for (final c in [name, email, phone, password, confirm]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> save() async {
    if (!form.currentState!.validate()) return;
    if (!creating && password.text.isNotEmpty) {
      final yes = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          scrollable: true,
          title: const Text('Redefinir senha?'),
          content: Text(
            own
                ? 'Sua senha será alterada e será necessário entrar novamente no site e no aplicativo.'
                : 'A senha de ${name.text.trim()} será alterada. As sessões dessa conta no site e no aplicativo serão encerradas.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Voltar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Salvar e redefinir'),
            ),
          ],
        ),
      );
      if (yes != true || !mounted) return;
    }
    setState(() {
      saving = true;
      error = null;
    });
    try {
      await UsersService(widget.api).save({
        'nome': name.text.trim(),
        'email': email.text.trim(),
        'telefone': phone.text.trim(),
        'tipoUsuario': role,
        'senha': password.text.isEmpty ? null : password.text,
      }, id: widget.user?['id']);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !saving,
    child: Scaffold(
      appBar: AppBar(
        title: Text(creating ? 'Cadastrar usuário' : 'Editar usuário'),
      ),
      body: widget.api.user?['tipoUsuario'] != 'Administrador'
          ? const Center(child: Text('Acesso exclusivo do Administrador.'))
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: form,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Dados da conta',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: name,
                        enabled: !saving,
                        maxLength: 100,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(labelText: 'Nome'),
                        validator: (s) => (s?.trim().length ?? 0) < 2
                            ? 'Informe pelo menos 2 caracteres.'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: email,
                        enabled: !saving,
                        maxLength: 100,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(labelText: 'E-mail'),
                        validator: (s) =>
                            !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$')
                                .hasMatch(s?.trim() ?? '')
                            ? 'Informe um e-mail válido.'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: phone,
                        enabled: !saving,
                        maxLength: 20,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'Telefone (opcional)',
                        ),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        initialValue: role,
                        isExpanded: true,
                        decoration: const InputDecoration(labelText: 'Perfil'),
                        items: ['Cliente', 'Funcionario', 'Administrador']
                            .map(
                              (r) => DropdownMenuItem(
                                value: r,
                                child: Text(_role(r)),
                              ),
                            )
                            .toList(),
                        onChanged: saving || own
                            ? null
                            : (r) => setState(() => role = r!),
                      ),
                      if (own)
                        const Padding(
                          padding: EdgeInsets.only(top: 8),
                          child: Text(
                            'Seu perfil de Administrador deve ser mantido.',
                          ),
                        ),
                      const SizedBox(height: 24),
                      Text(
                        creating ? 'Crie uma senha de 8 a 128 caracteres.' : 'Deixe os campos de senha vazios para manter a senha atual. Uma nova senha encerra as sessões dessa conta.',
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: password,
                        enabled: !saving,
                        obscureText: hide,
                        maxLength: 128,
                        autocorrect: false,
                        enableSuggestions: false,
                        decoration: InputDecoration(
                          labelText: creating
                              ? 'Senha'
                              : 'Nova senha (opcional)',
                          suffixIcon: IconButton(
                            tooltip: hide ? 'Mostrar senha' : 'Ocultar senha',
                            onPressed: () => setState(() => hide = !hide),
                            icon: Icon(
                              hide
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                          ),
                        ),
                        validator: (s) =>
                            (creating || (s?.isNotEmpty ?? false)) &&
                                (s?.length ?? 0) < 8
                            ? 'Use pelo menos 8 caracteres.'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: confirm,
                        enabled: !saving,
                        obscureText: hide,
                        maxLength: 128,
                        autocorrect: false,
                        enableSuggestions: false,
                        decoration: const InputDecoration(
                          labelText: 'Confirmar senha',
                        ),
                        validator: (s) => s != password.text
                            ? 'As senhas precisam ser iguais.'
                            : null,
                      ),
                      if (error != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
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
                      const SizedBox(height: 20),
                      FilledButton.icon(
                        onPressed: saving ? null : save,
                        icon: const Icon(Icons.check),
                        label: Text(saving ? 'Salvando…' : 'Salvar usuário'),
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
