import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:instant_chat/app/app_localizations.dart';
import 'package:instant_chat/app/authenticated_shell.dart';
import 'package:instant_chat/core/platform/macos_window_controller.dart';
import 'package:instant_chat/core/theme/retro_theme.dart';
import 'package:instant_chat/features/auth/presentation/auth_controller.dart';
import 'package:instant_chat/features/auth/presentation/auth_page.dart';

class AuthGate extends ConsumerStatefulWidget {
  const AuthGate({super.key});

  @override
  ConsumerState<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends ConsumerState<AuthGate> {
  AppWindowMode? _requestedWindowMode;

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final mode = auth.asData?.value.session == null
        ? AppWindowMode.authentication
        : AppWindowMode.main;
    _requestWindowMode(mode);

    return auth.when(
      loading: () => const _BootPage(),
      error: (_, _) => _SessionErrorPage(
        onRetry: () => ref.invalidate(authControllerProvider),
      ),
      data: (auth) {
        final session = auth.session;
        if (session == null) {
          return const AuthPage();
        }
        return AuthenticatedShell(
          session: session,
          onSignOut: () => ref.read(authControllerProvider.notifier).signOut(),
        );
      },
    );
  }

  void _requestWindowMode(AppWindowMode mode) {
    if (_requestedWindowMode == mode) {
      return;
    }
    _requestedWindowMode = mode;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _requestedWindowMode != mode) {
        return;
      }
      unawaited(ref.read(appWindowControllerProvider).setMode(mode));
    });
  }
}

class _BootPage extends StatelessWidget {
  const _BootPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Semantics(
          label: context.l10n.ui('Restoring secure session'),
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
                context.l10n.ui('Unable to restore your session'),
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: RetroMetrics.spaceMedium),
              Text(context.l10n.ui('The saved session could not be loaded.')),
              const SizedBox(height: RetroMetrics.spaceLarge),
              FilledButton(
                onPressed: onRetry,
                child: Text(context.l10n.ui('Try again')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
