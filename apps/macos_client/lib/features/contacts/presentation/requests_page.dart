import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:instant_chat/app/app_localizations.dart';
import 'package:instant_chat/core/theme/glass.dart';
import 'package:instant_chat/core/theme/retro_theme.dart';
import 'package:instant_chat/features/auth/presentation/auth_controller.dart';
import 'package:instant_chat/features/contacts/domain/contact_request.dart';
import 'package:instant_chat/features/contacts/presentation/contacts_controller.dart';
import 'package:instant_chat/features/contacts/presentation/request_section.dart';

class RequestsPage extends ConsumerStatefulWidget {
  const RequestsPage({required this.onOpenContact, super.key});

  final ValueChanged<String> onOpenContact;

  @override
  ConsumerState<RequestsPage> createState() => _RequestsPageState();
}

class _RequestsPageState extends ConsumerState<RequestsPage> {
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(contactsControllerProvider);
    final session = ref.watch(authControllerProvider).asData?.value.session;
    if (session == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return state.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => Center(
        child: FilledButton(
          onPressed: () => ref.invalidate(contactsControllerProvider),
          child: Text(context.l10n.ui('Try Again')),
        ),
      ),
      data: (requests) => LiquidGradientBackground(
        child: Column(
          children: [
            const _RequestsHeader(),
            Expanded(
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: RetroMetrics.maxPanelWidth,
                  ),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(
                      RetroMetrics.spaceLarge,
                      RetroMetrics.spaceLarge,
                      RetroMetrics.spaceLarge,
                      RetroMetrics.spaceLarge * 2,
                    ),
                    children: [
                      if (requests.errorMessage case final message?) ...[
                        _RequestError(message: context.l10n.ui(message)),
                        const SizedBox(height: RetroMetrics.spaceMedium),
                      ],
                      RequestSection(
                        title: context.l10n.ui('Incoming'),
                        countLabel: context.l10n.pendingCount(
                          requests.incoming.length,
                        ),
                        requests: requests.incoming,
                        accessToken: session.accessToken,
                        disabled: requests.isSubmitting,
                        onAccept: _accept,
                        onDecline: (request) => ref
                            .read(contactsControllerProvider.notifier)
                            .reject(request.id),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _accept(ContactRequest request) async {
    final accepted = await ref
        .read(contactsControllerProvider.notifier)
        .accept(request.id);
    if (accepted && mounted) {
      widget.onOpenContact(request.user.id);
    }
  }
}

class _RequestsHeader extends StatelessWidget {
  const _RequestsHeader();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface.withValues(alpha: 0.76),
        border: Border(bottom: BorderSide(color: colors.outlineVariant)),
      ),
      child: SizedBox(
        height: RetroMetrics.contactDetailHeaderHeight,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: RetroMetrics.spaceLarge,
          ),
          child: Row(
            children: [
              Text(
                context.l10n.ui('Requests'),
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RequestError extends StatelessWidget {
  const _RequestError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(RetroMetrics.spaceSmall),
      decoration: BoxDecoration(
        color: colors.errorContainer,
        borderRadius: BorderRadius.circular(RetroMetrics.corner),
      ),
      child: Text(
        context.l10n.ui(message),
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(color: colors.onErrorContainer),
      ),
    );
  }
}
