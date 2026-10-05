import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mede_ja_admin/app/routes/app_routes.dart';

class NewCondominiumUserPage extends StatefulWidget {
  final String condominiumId;

  const NewCondominiumUserPage({super.key, required this.condominiumId});

  @override
  State<NewCondominiumUserPage> createState() => _NewCondominiumUserPageState();
}

class _NewCondominiumUserPageState extends State<NewCondominiumUserPage> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _active = true;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmall = constraints.maxWidth < 700;

        return SingleChildScrollView(
          padding: EdgeInsets.all(isSmall ? 16 : 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              const SizedBox(height: 32),
              _buildForm(context, isSmall),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextButton.icon(
          onPressed: () {
            context.go(
              AppRoutes.condominiumUsers.replaceFirst(
                ':condominiumId',
                widget.condominiumId,
              ),
            );
          },
          icon: const Icon(Icons.arrow_back),
          label: const Text('Contas e usuários'),
        ),
        const SizedBox(height: 20),
        Text(
          'Nova conta',
          style: Theme.of(
            context,
          ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'Crie uma conta de acesso para este condomínio.',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ],
    );
  }

  Widget _buildForm(BuildContext context, bool isSmall) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(isSmall ? 20 : 24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Dados da conta',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Informe os dados que serão utilizados para acessar o sistema.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),

              const SizedBox(height: 24),

              TextFormField(
                controller: _nameController,
                autofocus: true,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Nome completo',
                  hintText: 'Ex.: João Silva',
                  prefixIcon: Icon(Icons.person_outline),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Informe o nome completo';
                  }

                  if (value.trim().length < 3) {
                    return 'Informe um nome válido';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 20),

              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'E-mail',
                  hintText: 'Ex.: joao@email.com',
                  prefixIcon: Icon(Icons.email_outlined),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Informe o e-mail';
                  }

                  final email = value.trim();

                  if (!email.contains('@') || !email.contains('.')) {
                    return 'Informe um e-mail válido';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 20),

              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: 'Senha',
                  hintText: 'Informe uma senha',
                  prefixIcon: const Icon(Icons.lock_outline),
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Informe a senha';
                  }

                  if (value.length < 6) {
                    return 'A senha deve ter pelo menos 6 caracteres';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 20),

              TextFormField(
                controller: _confirmPasswordController,
                obscureText: _obscureConfirmPassword,
                decoration: InputDecoration(
                  labelText: 'Confirmar senha',
                  hintText: 'Digite a senha novamente',
                  prefixIcon: const Icon(Icons.lock_outline),
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    onPressed: () {
                      setState(() {
                        _obscureConfirmPassword = !_obscureConfirmPassword;
                      });
                    },
                    icon: Icon(
                      _obscureConfirmPassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Confirme a senha';
                  }

                  if (value != _passwordController.text) {
                    return 'As senhas não coincidem';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 24),

              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Conta ativa'),
                subtitle: const Text('O usuário poderá acessar o sistema.'),
                value: _active,
                onChanged: (value) {
                  setState(() {
                    _active = value;
                  });
                },
              ),

              const SizedBox(height: 24),

              const Divider(),

              const SizedBox(height: 24),

              _buildActions(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        OutlinedButton(
          onPressed: () {
            context.go(
              AppRoutes.condominiumUsers.replaceFirst(
                ':condominiumId',
                widget.condominiumId,
              ),
            );
          },
          child: const Text('Cancelar'),
        ),
        const SizedBox(width: 12),
        FilledButton.icon(
          onPressed: _createUser,
          icon: const Icon(Icons.person_add_outlined),
          label: const Text('Criar conta'),
        ),
      ],
    );
  }

  void _createUser() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final name = _nameController.text.trim();
    final email = _emailController.text.trim();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Conta de $name criada com sucesso.')),
    );

    context.go(
      AppRoutes.condominiumUsers.replaceFirst(
        ':condominiumId',
        widget.condominiumId,
      ),
    );
  }
}
