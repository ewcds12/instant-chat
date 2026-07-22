import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:instant_chat/app/shell_navigation_refresh.dart';
import 'package:instant_chat/core/theme/glass.dart';
import 'package:instant_chat/core/theme/retro_theme.dart';
import 'package:instant_chat/features/auth/domain/auth_session.dart';
import 'package:instant_chat/features/contacts/presentation/contacts_page.dart';
import 'package:instant_chat/features/contacts/presentation/contacts_controller.dart';
import 'package:instant_chat/features/contacts/presentation/requests_page.dart';
import 'package:instant_chat/features/conversations/presentation/conversations_controller.dart';
import 'package:instant_chat/features/conversations/presentation/conversations_page.dart';
import 'package:instant_chat/features/profile/presentation/profile_sheet.dart';
import 'package:instant_chat/features/profile/presentation/profile_avatar.dart';
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
      body: LiquidGradientBackground(
        child: Row(
          children: [
            _AppSidebar(
              session: widget.session,
              selectedIndex: _selectedIndex,
              onSelect: (index) {
                if (index == _selectedIndex) {
                  refreshShellPage(ref, index);
                  return;
                }
                setState(() => _selectedIndex = index);
              },
              onOpenProfile: () =>
                  showProfileSheet(context: context, session: widget.session),
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
                  RequestsPage(onOpenContact: _openContact),
                  SystemStatusPage(onSignOut: widget.onSignOut),
                ],
              ),
            ),
          ],
        ),
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

  void _openContact(String userId) {
    if (!mounted) {
      return;
    }
    ref.read(selectedContactUserIdProvider.notifier).select(userId);
    setState(() => _selectedIndex = 1);
  }
}

class _AppSidebar extends StatelessWidget {
  const _AppSidebar({
    required this.session,
    required this.selectedIndex,
    required this.onSelect,
    required this.onOpenProfile,
  });

  final AuthSession session;
  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final VoidCallback onOpenProfile;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      key: const Key('app-sidebar'),
      width: RetroMetrics.sidebarWidth,
      child: GlassPanel(
        radius: 0,
        tint: RetroColors.glassMuted,
        borderColor: Colors.transparent,
        shadows: const [],
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 56, 10, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
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
              _SystemButton(
                selected: selectedIndex == 3,
                onTap: () => onSelect(3),
              ),
              const SizedBox(height: 10),
              _AccountTile(session: session, onTap: onOpenProfile),
            ],
          ),
        ),
      ),
    );
  }
}

class _AccountTile extends StatelessWidget {
  const _AccountTile({required this.session, required this.onTap});

  final AuthSession session;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        key: const Key('profile-account-card'),
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: RetroColors.glass,
            border: Border.all(color: colors.outlineVariant),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              ProfileAvatar(
                name: session.user.displayName,
                accessToken: session.accessToken,
                avatarUrl: session.user.avatarUrl,
                radius: 15,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      session.user.displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    Text(
                      '@${session.user.username}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SystemButton extends StatelessWidget {
  const _SystemButton({required this.selected, required this.onTap});

  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Align(
      alignment: Alignment.centerLeft,
      child: Tooltip(
        message: 'System',
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: selected ? colors.primaryContainer : Colors.transparent,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              Icons.settings_outlined,
              size: 20,
              color: selected ? colors.primary : colors.onSurfaceVariant,
            ),
          ),
        ),
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
    final foreground = selected ? colors.onSurface : colors.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: selected ? colors.surfaceContainerHigh : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
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
                      fontSize: 13,
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
