import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:instant_chat/core/theme/retro_theme.dart';
import 'package:instant_chat/features/auth/presentation/auth_controller.dart';
import 'package:instant_chat/features/auth/presentation/auth_page.dart';
import 'package:instant_chat/features/system_status/presentation/system_status_page.dart';

class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref
        .watch(authControllerProvider)
        .when(
          loading: () => const _BootPage(),
          error: (_, _) => _SessionErrorPage(
            onRetry: () => ref.invalidate(authControllerProvider),
          ),
          data: (auth) {
            final session = auth.session;
            if (session == null) {
              return const AuthPage();
            }
            return Scaffold(
              body: Column(
                children: [
                  Container(
                    color: Theme.of(context).colorScheme.onSurface,
                    padding: const EdgeInsets.symmetric(
                      horizontal: RetroMetrics.spaceMedium,
                      vertical: RetroMetrics.spaceSmall,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${session.user.displayName} // ${session.user.email}',
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.labelLarge
                                ?.copyWith(
                                  color: Theme.of(context).colorScheme.surface,
                                ),
                          ),
                        ),
                        TextButton(
                          onPressed: auth.isSubmitting
                              ? null
                              : () => ref
                                    .read(authControllerProvider.notifier)
                                    .signOut(),
                          child: const Text('SIGN OUT'),
                        ),
                      ],
                    ),
                  ),
                  const Expanded(child: SystemStatusPage()),
                ],
              ),
            );
          },
        );
  }
}

class _BootPage extends StatelessWidget {
  const _BootPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Semantics(
          label: 'Restoring secure session',
          child: CircularProgressIndicator(),
        ),
      ),
    );
  }
}

class _SessionErrorPage extends StatelessWidget {
  const _SessionErrorPage({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(RetroMetrics.spaceLarge),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'SECURE SESSION UNAVAILABLE',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: RetroMetrics.spaceMedium),
              const Text('The saved session could not be loaded.'),
              const SizedBox(height: RetroMetrics.spaceLarge),
              FilledButton(onPressed: onRetry, child: const Text('RETRY')),
            ],
          ),
        ),
      ),
    );
  }
}
