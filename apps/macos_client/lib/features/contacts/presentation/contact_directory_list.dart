import 'package:flutter/material.dart';
import 'package:instant_chat/core/theme/retro_theme.dart';
import 'package:instant_chat/features/contacts/domain/contact.dart';
import 'package:instant_chat/features/profile/presentation/profile_avatar.dart';
import 'package:instant_chat/features/users/domain/public_user.dart';

class ContactDirectoryList extends StatelessWidget {
  const ContactDirectoryList({
    required this.contacts,
    required this.accessToken,
    required this.query,
    required this.selectedUserId,
    required this.onSelect,
    super.key,
  });

  final List<Contact> contacts;
  final String accessToken;
  final String query;
  final String? selectedUserId;
  final ValueChanged<Contact> onSelect;

  @override
  Widget build(BuildContext context) {
    final groups = groupContacts(contacts, query);
    if (contacts.isEmpty) {
      return const ContactDirectoryEmptyState(
        title: 'No contacts yet',
        description: 'Search for an exact ID to send a contact request.',
      );
    }
    if (groups.isEmpty) {
      return const ContactDirectoryEmptyState(
        title: 'No matching contacts',
        description: 'Try a different name or ID.',
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
      itemCount: groups.length,
      itemBuilder: (context, index) => _ContactGroupSection(
        group: groups[index],
        accessToken: accessToken,
        selectedUserId: selectedUserId,
        onSelect: onSelect,
      ),
    );
  }
}

class _ContactGroupSection extends StatelessWidget {
  const _ContactGroupSection({
    required this.group,
    required this.accessToken,
    required this.selectedUserId,
    required this.onSelect,
  });

  final ContactGroup group;
  final String accessToken;
  final String? selectedUserId;
  final ValueChanged<Contact> onSelect;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(6, RetroMetrics.spaceSmall, 6, 4),
          child: Text(
            group.label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 11,
            ),
          ),
        ),
        for (var index = 0; index < group.contacts.length; index++) ...[
          _DirectoryContactRow(
            contact: group.contacts[index],
            accessToken: accessToken,
            selected: group.contacts[index].user.id == selectedUserId,
            onTap: () => onSelect(group.contacts[index]),
          ),
          if (index < group.contacts.length - 1)
            _ContactRowSeparator(
              currentSelected: group.contacts[index].user.id == selectedUserId,
              nextSelected: group.contacts[index + 1].user.id == selectedUserId,
            ),
        ],
      ],
    );
  }
}

class _ContactRowSeparator extends StatelessWidget {
  const _ContactRowSeparator({
    required this.currentSelected,
    required this.nextSelected,
  });

  final bool currentSelected;
  final bool nextSelected;

  @override
  Widget build(BuildContext context) {
    if (currentSelected || nextSelected) {
      return const SizedBox(height: RetroMetrics.spaceSmall);
    }
    return Divider(
      height: RetroMetrics.spaceSmall,
      indent: 64,
      endIndent: 14,
      color: Theme.of(context).colorScheme.outlineVariant,
    );
  }
}

class _DirectoryContactRow extends StatelessWidget {
  const _DirectoryContactRow({
    required this.contact,
    required this.accessToken,
    required this.selected,
    required this.onTap,
  });

  final Contact contact;
  final String accessToken;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      selected: selected,
      button: true,
      label: 'Contact ${contact.user.displayName}',
      child: Container(
        key: ValueKey('contact-directory-selection-${contact.user.id}'),
        height: RetroMetrics.contactRowHeight,
        decoration: BoxDecoration(
          color: selected ? colors.surfaceContainerHigh : Colors.transparent,
          border: selected ? Border.all(color: colors.outlineVariant) : null,
          borderRadius: BorderRadius.circular(RetroMetrics.cornerLarge),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: colors.scrim.withValues(alpha: 0.06),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ]
              : const [],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(RetroMetrics.cornerLarge),
          child: InkWell(
            key: ValueKey('contact-directory-row-${contact.user.id}'),
            borderRadius: BorderRadius.circular(RetroMetrics.cornerLarge),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 11),
              child: Row(
                children: [
                  ProfileAvatar(
                    name: contact.user.displayName,
                    accessToken: accessToken,
                    avatarUrl: contact.user.avatarUrl,
                    radius: RetroMetrics.contactDirectoryAvatarRadius,
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: ContactIdentity(user: contact.user)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ContactIdentity extends StatelessWidget {
  const ContactIdentity({required this.user, super.key});

  final PublicUser user;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          user.displayName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontSize: 13),
        ),
        const SizedBox(height: 4),
        Text(
          '@${user.username}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

class ContactDirectoryEmptyState extends StatelessWidget {
  const ContactDirectoryEmptyState({
    required this.title,
    required this.description,
    super.key,
  });

  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(RetroMetrics.spaceLarge),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.person_search_outlined,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: RetroMetrics.spaceSmall),
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: RetroMetrics.spaceSmall),
            Text(
              description,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ContactGroup {
  const ContactGroup({required this.label, required this.contacts});

  final String label;
  final List<Contact> contacts;
}

List<ContactGroup> groupContacts(List<Contact> contacts, String query) {
  final normalizedQuery = query.trim().toLowerCase();
  final filtered =
      contacts.where((contact) {
        if (normalizedQuery.isEmpty) {
          return true;
        }
        return contact.user.displayName.toLowerCase().contains(
              normalizedQuery,
            ) ||
            contact.user.username.toLowerCase().contains(normalizedQuery);
      }).toList()..sort(
        (left, right) => left.user.displayName.toLowerCase().compareTo(
          right.user.displayName.toLowerCase(),
        ),
      );
  final grouped = <String, List<Contact>>{};
  for (final contact in filtered) {
    final label = contactGroupLabel(contact.user.displayName);
    grouped.putIfAbsent(label, () => []).add(contact);
  }
  return grouped.entries
      .map((entry) => ContactGroup(label: entry.key, contacts: entry.value))
      .toList(growable: false);
}

String contactGroupLabel(String displayName) {
  final firstCharacter = displayName.trim().isEmpty
      ? ''
      : displayName.trim().characters.first.toUpperCase();
  return RegExp(r'^[A-Z]$').hasMatch(firstCharacter) ? firstCharacter : '#';
}
