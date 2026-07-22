import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
          child: const Text('Try Again'),
        ),
      ),
      data: (requests) => LiquidGradientBackground(
        child: Column(
          children: [
            _RequestsHeader(
              isRefreshing: requests.isSubmitting,
              onRefresh: () =>
                  ref.read(contactsControllerProvider.notifier).refresh(),
            ),
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
                        _RequestError(message: message),
                        const SizedBox(height: RetroMetrics.spaceMedium),
                      ],
                      RequestSection(
                        title: 'Incoming',
                        countLabel: '${requests.incoming.length} pending',
                        requests: requests.incoming,
                        accessToken: session.accessToken,
                        isIncoming: true,
                        disabled: requests.isSubmitting,
                        onAccept: _accept,
                        onDecline: (request) => ref
                            .read(contactsControllerProvider.notifier)
                            .reject(request.id),
                        onCancel: (_) {},
                      ),
                      const SizedBox(height: RetroMetrics.spaceLarge),
                      RequestSection(
                        title: 'Sent',
                        countLabel: '${requests.outgoing.length} pending',
                        requests: requests.outgoing,
                        accessToken: session.accessToken,
                        isIncoming: false,
                        disabled: requests.isSubmitting,
                        onAccept: (_) {},
                        onDecline: (_) {},
                        onCancel: (request) =>
                            _confirmCancel(context, ref, request),
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

  Future<void> _confirmCancel(
    BuildContext context,
    WidgetRef ref,
    ContactRequest request,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Request?'),
        content: Text(
          'Cancel the request sent to ${request.user.displayName}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Keep Request'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Cancel Request'),
          ),
        ],
      ),
    );
    if (!mounted || confirmed != true) {
      return;
    }
    await ref.read(contactsControllerProvider.notifier).cancel(request.id);
  }
}

class _RequestsHeader extends StatelessWidget {
  const _RequestsHeader({required this.isRefreshing, required this.onRefresh});

  final bool isRefreshing;
  final VoidCallback onRefresh;

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
              Text('Requests', style: Theme.of(context).textTheme.titleLarge),
              const Spacer(),
              SizedBox(
                width: RetroMetrics.composerControlHeight,
                height: RetroMetrics.composerControlHeight,
                child: IconButton(
                  tooltip: 'Refresh requests',
                  padding: EdgeInsets.zero,
                  onPressed: isRefreshing ? null : onRefresh,
                  icon: isRefreshing
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.refresh_rounded, size: 20),
                ),
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
        message,
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(color: colors.onErrorContainer),
      ),
    );
  }
}
