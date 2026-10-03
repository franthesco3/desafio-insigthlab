import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:matrix_desktop/features/auth/presentation/viewmodels/login_viewmodel.dart';

class LoginView extends GetView<LoginViewModel> {
  const LoginView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: LoginForm(viewModel: controller),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class LoginForm extends StatefulWidget {
  const LoginForm({required this.viewModel, super.key});

  final LoginViewModel viewModel;

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final _homeserver = TextEditingController(
    text: LoginViewModel.defaultHomeserver,
  );
  final _username = TextEditingController();
  final _password = TextEditingController();
  bool _obscurePassword = true;

  LoginViewModel get _viewModel => widget.viewModel;

  @override
  void dispose() {
    _homeserver.dispose();
    _username.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    await _viewModel.submit(
      homeserver: _homeserver.text,
      username: _username.text,
      password: _password.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Obx(() {
      final isLoading = _viewModel.isLoading;
      final error = _viewModel.errorMessage;
      return AutofillGroup(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Entrar', style: textTheme.headlineSmall),
            const SizedBox(height: 4),
            Text(
              'Use sua conta de qualquer servidor Matrix.',
              style: textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            TextField(
              key: const Key('login.homeserver'),
              controller: _homeserver,
              enabled: !isLoading,
              decoration: const InputDecoration(
                labelText: 'Servidor',
                hintText: 'matrix.org',
                prefixIcon: Icon(Icons.dns_outlined),
              ),
              textInputAction: TextInputAction.next,
              onChanged: (_) => _viewModel.clearError(),
            ),
            const SizedBox(height: 16),
            TextField(
              key: const Key('login.username'),
              controller: _username,
              enabled: !isLoading,
              autofillHints: const [AutofillHints.username],
              decoration: const InputDecoration(
                labelText: 'Usuário',
                hintText: 'alice ou @alice:matrix.org',
                prefixIcon: Icon(Icons.person_outline),
              ),
              textInputAction: TextInputAction.next,
              onChanged: (_) => _viewModel.clearError(),
            ),
            const SizedBox(height: 16),
            TextField(
              key: const Key('login.password'),
              controller: _password,
              enabled: !isLoading,
              obscureText: _obscurePassword,
              autofillHints: const [AutofillHints.password],
              decoration: InputDecoration(
                labelText: 'Senha',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  tooltip: _obscurePassword ? 'Mostrar senha' : 'Ocultar senha',
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
              onChanged: (_) => _viewModel.clearError(),
              onSubmitted: (_) => _submit(),
            ),
            if (error != null) ...[
              const SizedBox(height: 16),
              _ErrorBanner(message: error),
            ],
            const SizedBox(height: 24),
            FilledButton(
              key: const Key('login.submit'),
              onPressed: isLoading ? null : _submit,
              child: isLoading
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Entrar'),
            ),
          ],
        ),
      );
    });
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.errorContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: colors.onErrorContainer),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: colors.onErrorContainer),
            ),
          ),
        ],
      ),
    );
  }
}
