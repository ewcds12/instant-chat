import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:instant_chat/core/theme/retro_theme.dart';
import 'package:instant_chat/features/contacts/domain/contact_request.dart';
import 'package:instant_chat/features/contacts/presentation/contacts_controller.dart';

class RequestsPage extends ConsumerWidget {
  const RequestsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(contactsControllerProvider);
    return state.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => Center(
        child: FilledButton(
          onPressed: () => ref.invalidate(contactsControllerProvider),
          child: const Text('RETRY REQUESTS'),
        ),
      ),
      data: (contacts) => Padding(
        padding: const EdgeInsets.all(RetroMetrics.spaceLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'CONTACT REQUESTS',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: RetroMetrics.spaceSmall),
            const Text('Incoming requests require your approval.'),
            if (contacts.errorMessage case final message?) ...[
              const SizedBox(height: RetroMetrics.spaceSmall),
              Text(
                message,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: RetroMetrics.spaceLarge),
            Expanded(
              child: ListView(
                children: [
                  _SectionTitle(
                    label: 'INCOMING',
                    count: contacts.incoming.length,
                  ),
                  const SizedBox(height: RetroMetrics.spaceSmall),
                  if (contacts.incoming.isEmpty)
                    const _EmptyRow(label: 'NO INCOMING REQUESTS')
                  else
                    ...contacts.incoming.map(
                      (request) => Padding(
                        padding: const EdgeInsets.only(
                          bottom: RetroMetrics.spaceSmall,
                        ),
                        child: _IncomingRow(
                          request: request,
                          disabled: contacts.isSubmitting,
                          onAccept: () => ref
                              .read(contactsControllerProvider.notifier)
                              .accept(request.id),
                          onReject: () => ref
                              .read(contactsControllerProvider.notifier)
                              .reject(request.id),
                        ),
                      ),
                    ),
                  const SizedBox(height: RetroMetrics.spaceLarge),
                  _SectionTitle(
                    label: 'OUTGOING',
                    count: contacts.outgoing.length,
                  ),
                  const SizedBox(height: RetroMetrics.spaceSmall),
                  if (contacts.outgoing.isEmpty)
                    const _EmptyRow(label: 'NO OUTGOING REQUESTS')
                  else
                    ...contacts.outgoing.map(
                      (request) => Padding(
                        padding: const EdgeInsets.only(
                          bottom: RetroMetrics.spaceSmall,
                        ),
                        child: _OutgoingRow(request: request),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.label, required this.count});

  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Text(
      '$label // $count',
      style: Theme.of(context).textTheme.titleMedium,
    );
  }
}

class _IncomingRow extends StatelessWidget {
  const _IncomingRow({
    required this.request,
    required this.disabled,
    required this.onAccept,
    required this.onReject,
  });

  final ContactRequest request;
  final bool disabled;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    return _RequestFrame(
      child: Row(
        children: [
          Expanded(
            child: Text(
              '${request.user.displayName} // @${request.user.username}',
            ),
          ),
          TextButton(
            onPressed: disabled ? null : onReject,
            child: const Text('REJECT'),
          ),
          const SizedBox(width: RetroMetrics.spaceSmall),
          FilledButton(
            onPressed: disabled ? null : onAccept,
            child: const Text('ACCEPT'),
          ),
        ],
      ),
    );
  }
}

class _OutgoingRow extends StatelessWidget {
  const _OutgoingRow({required this.request});

  final ContactRequest request;

  @override
  Widget build(BuildContext context) {
    return _RequestFrame(
      child: Row(
        children: [
          Expanded(
            child: Text(
              '${request.user.displayName} // @${request.user.username}',
            ),
          ),
          Text('PENDING', style: Theme.of(context).textTheme.labelLarge),
        ],
      ),
    );
  }
}

class _EmptyRow extends StatelessWidget {
  const _EmptyRow({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return _RequestFrame(child: Text(label));
  }
}

class _RequestFrame extends StatelessWidget {
  const _RequestFrame({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(RetroMetrics.spaceMedium),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border.all(
          color: Theme.of(context).colorScheme.onSurface,
          width: RetroMetrics.border,
        ),
      ),
      child: child,
    );
  }
}
