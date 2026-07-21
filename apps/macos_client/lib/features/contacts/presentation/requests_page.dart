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
        child: Padding(
          padding: const EdgeInsets.all(RetroMetrics.spaceLarge),
          child: GlassPanel(
            tint: RetroColors.glassStrong,
            padding: const EdgeInsets.all(RetroMetrics.spaceLarge),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Requests',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                    ),
                    IconButton(
                      tooltip: 'Refresh requests',
                      onPressed: requests.isSubmitting
                          ? null
                          : () => ref
                                .read(contactsControllerProvider.notifier)
                                .refresh(),
                      icon: const Icon(Icons.refresh_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: RetroMetrics.spaceSmall),
                Text(
                  'Review new contact requests and track the ones you sent.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                if (requests.errorMessage case final message?) ...[
                  const SizedBox(height: RetroMetrics.spaceMedium),
                  _RequestError(message: message),
                ],
                const SizedBox(height: RetroMetrics.spaceLarge),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final incoming = RequestSection(
                        title: 'Incoming',
                        description: 'People waiting for your approval.',
                        requests: requests.incoming,
                        accessToken: session.accessToken,
                        isIncoming: true,
                        disabled: requests.isSubmitting,
                        onAccept: _accept,
                        onDecline: (request) => ref
                            .read(contactsControllerProvider.notifier)
                            .reject(request.id),
                        onCancel: (_) {},
                      );
                      final outgoing = RequestSection(
                        title: 'Sent',
                        description: 'Requests waiting for a response.',
                        requests: requests.outgoing,
                        accessToken: session.accessToken,
                        isIncoming: false,
                        disabled: requests.isSubmitting,
                        onAccept: (_) {},
                        onDecline: (_) {},
                        onCancel: (request) =>
                            _confirmCancel(context, ref, request),
                      );
                      if (constraints.maxWidth <
                          RetroMetrics.contactLayoutBreakpoint) {
                        return ListView(
                          children: [
                            incoming,
                            const SizedBox(height: RetroMetrics.spaceLarge),
                            outgoing,
                          ],
                        );
                      }
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: incoming),
                          const VerticalDivider(
                            width: RetroMetrics.spaceLarge * 2,
                          ),
                          Expanded(child: outgoing),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
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
