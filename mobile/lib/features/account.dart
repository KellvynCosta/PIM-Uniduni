import 'package:flutter/material.dart';

import '../core/api.dart';
import '../core/account_service.dart';

class AccountFormPage extends StatefulWidget {
  const AccountFormPage({super.key, required this.api, this.register = false});
  final UniduniApi api;
  final bool register;
  @override
  State<AccountFormPage> createState() => _AccountFormState();
}

class _AccountFormState extends State<AccountFormPage> {
  final form = GlobalKey<FormState>();
  final name = TextEditingController(),
      email = TextEditingController(),
      phone = TextEditingController(),
      current = TextEditingController(),
      password = TextEditingController(),
      confirm = TextEditingController();
  bool saving = false, hide = true, hideCurrent = true;
  String? error;
  @override
  void dispose() {
    for (final c in [name, email, phone, current, password, confirm]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> save() async {
    if (!form.currentState!.validate()) return;
    setState(() {
      saving = true;
      error = null;
    });
    try {
      final account = AccountService(widget.api);
      if (widget.register) {
        await account.register(
          name: name.text,
          email: email.text,
          password: password.text,
          phone: phone.text,
        );
      } else {
        await account.changePassword(current.text, password.text);
      }
      if (mounted) {
        Navigator.pop(
          context,
          widget.register ? email.text.trim() : 'passwordChanged',
        );
      }
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Widget secret(
    TextEditingController controller,
    String label, {
    bool old = false,
    bool confirmation = false,
  }) => TextFormField(
    controller: controller,
    enabled: !saving,
    obscureText: old ? hideCurrent : hide,
    maxLength: 128,
    autocorrect: false,
    enableSuggestions: false,
    autofillHints: [old ? AutofillHints.password : AutofillHints.newPassword],
    decoration: InputDecoration(
      labelText: label,
      suffixIcon: confirmation
          ? null
          : IconButton(
              tooltip: (old ? hideCurrent : hide)
                  ? 'Mostrar senha'
                  : 'Ocultar senha',
              onPressed: saving
                  ? null
                  : () => setState(() {
                      if (old) {
                        hideCurrent = !hideCurrent;
                      } else {
                        hide = !hide;
                      }
                    }),
              icon: Icon(
                (old ? hideCurrent : hide)
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
              ),
            ),
    ),
    validator: (s) {
      if (confirmation) {
        return s == password.text ? null : 'As senhas precisam ser iguais.';
      }
      if (s == null || s.isEmpty) {
        return old ? 'Informe a senha atual.' : 'Informe uma senha.';
      }
      if (!old && s.length < 8) return 'Use pelo menos 8 caracteres.';
      return null;
    },
  );
  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !saving,
    child: Scaffold(
      appBar: AppBar(
        title: Text(
          widget.register ? 'Criar minha conta' : 'Alterar minha senha',
        ),
      ),
      body: !widget.register && widget.api.user == null
          ? const Center(
              child: Text('Entre na sua conta para alterar a senha.'),
            )
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: AutofillGroup(
                  child: Form(
                    key: form,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          widget.register
                              ? 'Seu cantinho na Uniduni.'
                              : 'Cuide do acesso à sua conta.',
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          widget.register
                              ? 'Crie uma conta de cliente para comprar e acompanhar seus pedidos no site e no aplicativo.'
                              : 'Confirme sua senha atual. Após a troca, será necessário entrar novamente no site e no aplicativo.',
                        ),
                        const SizedBox(height: 24),
                        if (widget.register) ...[
                          TextFormField(
                            controller: name,
                            enabled: !saving,
                            maxLength: 100,
                            textCapitalization: TextCapitalization.words,
                            autofillHints: const [AutofillHints.name],
                            decoration: const InputDecoration(
                              labelText: 'Nome',
                            ),
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
                            autofillHints: const [AutofillHints.email],
                            decoration: const InputDecoration(
                              labelText: 'E-mail',
                            ),
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
                            autofillHints: const [
                              AutofillHints.telephoneNumber,
                            ],
                            decoration: const InputDecoration(
                              labelText: 'Telefone (opcional)',
                            ),
                          ),
                        ] else
                          secret(current, 'Senha atual', old: true),
                        const SizedBox(height: 16),
                        secret(
                          password,
                          widget.register ? 'Senha' : 'Nova senha',
                        ),
                        const Padding(
                          padding: EdgeInsets.only(bottom: 16),
                          child: Text('Use de 8 a 128 caracteres.'),
                        ),
                        secret(confirm, 'Confirmar senha', confirmation: true),
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
                          icon: Icon(
                            widget.register
                                ? Icons.person_add_outlined
                                : Icons.lock_outline,
                          ),
                          label: Text(
                            saving
                                ? 'Salvando…'
                                : widget.register
                                ? 'Criar conta de cliente'
                                : 'Salvar nova senha',
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    ),
  );
}
