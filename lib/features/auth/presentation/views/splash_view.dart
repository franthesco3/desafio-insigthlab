import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:matrix_desktop/core/ui/failure_messages.dart';
import 'package:matrix_desktop/core/ui/view_state.dart';
import 'package:matrix_desktop/features/auth/presentation/viewmodels/splash_viewmodel.dart';

class SplashView extends GetView<SplashViewModel> {
  const SplashView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Obx(
          () => switch (controller.state.value) {
            Failed(:final failure) => _RestoreError(
              message: failure.userMessage,
              onRetry: controller.restore,
              onLogin: controller.goToLogin,
            ),
            _ => const _Restoring(),
          },
        ),
      ),
    );
  }
}

class _Restoring extends StatelessWidget {
  const _Restoring();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.forum_outlined,
          size: 56,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(height: 24),
        const SizedBox.square(
          dimension: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ],
    );
  }
}

class _RestoreError extends StatelessWidget {
  const _RestoreError({
    required this.message,
    required this.onRetry,
    required this.onLogin,
  });

  final String message;
  final VoidCallback onRetry;
  final VoidCallback onLogin;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(message, textAlign: TextAlign.center),
        const SizedBox(height: 16),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            FilledButton(
              onPressed: onRetry,
              child: const Text('Tentar de novo'),
            ),
            const SizedBox(width: 8),
            TextButton(
              onPressed: onLogin,
              child: const Text('Ir para o login'),
            ),
          ],
        ),
      ],
    );
  }
}
