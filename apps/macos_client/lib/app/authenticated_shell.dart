import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:instant_chat/core/theme/retro_theme.dart';
import 'package:instant_chat/features/auth/domain/auth_session.dart';
import 'package:instant_chat/features/contacts/presentation/contacts_page.dart';
import 'package:instant_chat/features/contacts/presentation/requests_page.dart';
import 'package:instant_chat/features/conversations/presentation/conversations_controller.dart';
import 'package:instant_chat/features/conversations/presentation/conversations_page.dart';
import 'package:instant_chat/features/realtime/presentation/realtime_provider.dart';
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
    ref.watch(realtimeConnectionProvider);
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      body: Row(
        children: [
          _AppSidebar(
            selectedIndex: _selectedIndex,
            onSelect: (index) => setState(() => _selectedIndex = index),
          ),
          VerticalDivider(color: colors.outlineVariant),
          Expanded(
            child: IndexedStack(
              index: _selectedIndex,
              children: [
                ConversationsPage(
                  onCompose: () => setState(() => _selectedIndex = 1),
                ),
                ContactsPage(onOpenConversation: _openConversation),
                const RequestsPage(),
                SystemStatusPage(onSignOut: widget.onSignOut),
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

class _AppSidebar extends StatelessWidget {
  const _AppSidebar({required this.selectedIndex, required this.onSelect});

  final int selectedIndex;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      key: const Key('app-sidebar'),
      width: 136,
      color: colors.surface,
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 44),
          _SidebarItem(
            label: 'Chats',
            icon: Icons.chat_bubble_outline_rounded,
            selected: selectedIndex == 0,
            onTap: () => onSelect(0),
          ),
          _SidebarItem(
            label: 'Contacts',
            icon: Icons.person_outline_rounded,
            selected: selectedIndex == 1,
            onTap: () => onSelect(1),
          ),
          _SidebarItem(
            label: 'Requests',
            icon: Icons.person_add_alt_rounded,
            selected: selectedIndex == 2,
            onTap: () => onSelect(2),
          ),
          const Spacer(),
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              tooltip: 'System',
              style: IconButton.styleFrom(
                foregroundColor: selectedIndex == 3
                    ? colors.primary
                    : colors.onSurfaceVariant,
                backgroundColor: selectedIndex == 3
                    ? colors.primaryContainer
                    : Colors.transparent,
              ),
              onPressed: () => onSelect(3),
              icon: const Icon(Icons.settings_outlined, size: 20),
            ),
          ),
          const SizedBox(height: 6),
        ],
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  const _SidebarItem({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final foreground = selected ? colors.primary : colors.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: selected ? colors.primaryContainer : Colors.transparent,
        borderRadius: BorderRadius.circular(RetroMetrics.corner),
        child: InkWell(
          borderRadius: BorderRadius.circular(RetroMetrics.corner),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
            child: Row(
              children: [
                Icon(icon, color: foreground, size: 17),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: foreground,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
