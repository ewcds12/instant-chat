import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:instant_chat/features/posts/domain/public_post.dart';
import 'package:instant_chat/features/posts/presentation/posts_controller.dart';
import 'package:instant_chat/features/profile/presentation/profile_avatar.dart';
import 'package:instant_chat/features/users/domain/public_user.dart';

Future<bool> confirmDeletePost(BuildContext context) async {
  return await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Delete Post?'),
          content: const Text('This post will be permanently removed.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete'),
            ),
          ],
        ),
      ) ??
      false;
}

Future<String?> askReportReason(BuildContext context) async {
  final controller = TextEditingController();
  final result = await showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Report Post'),
      content: SizedBox(
        width: 340,
        child: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 500,
          minLines: 2,
          maxLines: 4,
          decoration: const InputDecoration(
            hintText: 'Tell us what is wrong with this post',
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            final value = controller.text.trim();
            if (value.isNotEmpty) Navigator.of(context).pop(value);
          },
          child: const Text('Report'),
        ),
      ],
    ),
  );
  controller.dispose();
  return result;
}

Future<bool> confirmBlockUser(BuildContext context, PublicPost post) async {
  return await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Block ${post.author.displayName}?'),
          content: const Text(
            'Their posts will disappear from Explore. You can unblock them later.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Block'),
            ),
          ],
        ),
      ) ??
      false;
}

Future<void> showBlockedUsersDialog({
  required BuildContext context,
  required WidgetRef ref,
  required String accessToken,
}) {
  return showDialog<void>(
    context: context,
    builder: (_) => _BlockedUsersDialog(
      accessToken: accessToken,
      controller: ref.read(postsControllerProvider.notifier),
    ),
  );
}

class _BlockedUsersDialog extends StatefulWidget {
  const _BlockedUsersDialog({
    required this.accessToken,
    required this.controller,
  });

  final String accessToken;
  final PostsController controller;

  @override
  State<_BlockedUsersDialog> createState() => _BlockedUsersDialogState();
}

class _BlockedUsersDialogState extends State<_BlockedUsersDialog> {
  late Future<List<PublicUser>> _users = widget.controller.listBlocked();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Blocked Users'),
      content: SizedBox(
        width: 360,
        height: 260,
        child: FutureBuilder<List<PublicUser>>(
          future: _users,
          builder: _blockedContent,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Done'),
        ),
      ],
    );
  }

  Widget _blockedContent(
    BuildContext context,
    AsyncSnapshot<List<PublicUser>> snapshot,
  ) {
    if (snapshot.connectionState != ConnectionState.done) {
      return const Center(child: CircularProgressIndicator());
    }
    if (snapshot.hasError) {
      return const Center(child: Text('Could not load blocked users.'));
    }
    final users = snapshot.data!;
    if (users.isEmpty) {
      return const Center(child: Text('No blocked users.'));
    }
    return ListView.separated(
      itemCount: users.length,
      separatorBuilder: (_, _) => const Divider(),
      itemBuilder: (_, index) => _blockedUserRow(users[index]),
    );
  }

  Widget _blockedUserRow(PublicUser user) {
    return SizedBox(
      height: 50,
      child: Row(
        children: [
          ProfileAvatar(
            name: user.displayName,
            accessToken: widget.accessToken,
            avatarUrl: user.avatarUrl,
            radius: 16,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              user.displayName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          TextButton(
            style: TextButton.styleFrom(
              minimumSize: const Size(0, 30),
              padding: const EdgeInsets.symmetric(horizontal: 10),
            ),
            onPressed: () => _unblock(user.id),
            child: const Text('Unblock'),
          ),
        ],
      ),
    );
  }

  Future<void> _unblock(String userId) async {
    try {
      await widget.controller.unblock(userId);
      if (mounted) setState(() => _users = widget.controller.listBlocked());
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not unblock this user.')),
      );
    }
  }
}
