import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:instant_chat/core/theme/retro_theme.dart';
import 'package:instant_chat/features/auth/domain/auth_session.dart';
import 'package:instant_chat/features/contacts/presentation/contacts_page.dart';
import 'package:instant_chat/features/contacts/presentation/requests_page.dart';
import 'package:instant_chat/features/conversations/presentation/conversations_controller.dart';
import 'package:instant_chat/features/conversations/presentation/conversations_page.dart';
import 'package:instant_chat/features/system_status/presentation/system_status_page.dart';

class AuthenticatedShell extends ConsumerStatefulWidget {
  const AuthenticatedShell({
    required this.session,
    required this.onSignOut,
    super.key,
  });

  final AuthSession session;
  final Future<void> Function() onSignOut;

  @override
  ConsumerState<AuthenticatedShell> createState() => _AuthenticatedShellState();
}

class _AuthenticatedShellState extends ConsumerState<AuthenticatedShell> {
  var _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      body: Column(
        children: [
          Container(
            color: colors.onSurface,
            padding: const EdgeInsets.symmetric(
              horizontal: RetroMetrics.spaceMedium,
              vertical: RetroMetrics.spaceSmall,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '${widget.session.user.displayName} // @${widget.session.user.username} // ${widget.session.user.email}',
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(
                      context,
                    ).textTheme.labelLarge?.copyWith(color: colors.surface),
                  ),
                ),
                TextButton(
                  onPressed: widget.onSignOut,
                  child: const Text('SIGN OUT'),
                ),
              ],
            ),
          ),
          Expanded(
            child: Row(
              children: [
                NavigationRail(
                  selectedIndex: _selectedIndex,
                  labelType: NavigationRailLabelType.all,
                  onDestinationSelected: (index) {
                    setState(() => _selectedIndex = index);
                  },
                  destinations: const [
                    NavigationRailDestination(
                      icon: Icon(Icons.forum_outlined),
                      selectedIcon: Icon(Icons.forum),
                      label: Text('CONVERSATIONS'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.people_outline),
                      selectedIcon: Icon(Icons.people),
                      label: Text('CONTACTS'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.mark_email_unread_outlined),
                      selectedIcon: Icon(Icons.mark_email_unread),
                      label: Text('REQUESTS'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.monitor_heart_outlined),
                      selectedIcon: Icon(Icons.monitor_heart),
                      label: Text('SYSTEM'),
                    ),
                  ],
                ),
                VerticalDivider(
                  width: RetroMetrics.border,
                  thickness: RetroMetrics.border,
                  color: colors.onSurface,
                ),
                Expanded(
                  child: IndexedStack(
                    index: _selectedIndex,
                    children: [
                      const ConversationsPage(),
                      ContactsPage(onOpenConversation: _openConversation),
                      const RequestsPage(),
                      const SystemStatusPage(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openConversation(String userId) async {
    await ref.read(conversationsControllerProvider.future);
    await ref.read(conversationsControllerProvider.notifier).create(userId);
    if (!mounted) {
      return;
    }
    setState(() => _selectedIndex = 0);
  }
}
