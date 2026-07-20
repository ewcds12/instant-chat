import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:instant_chat/core/theme/retro_theme.dart';
import 'package:instant_chat/features/messages/domain/message.dart';

const _recallWindow = Duration(minutes: 5);

enum _MessageMenuAction { copy, recall, delete }

class MessageContextMenu extends StatelessWidget {
  const MessageContextMenu({
    required this.message,
    required this.isMine,
    required this.onRecall,
    required this.onDelete,
    required this.child,
    super.key,
  });

  final Message message;
  final bool isMine;
  final Future<bool> Function(Message message) onRecall;
  final Future<bool> Function(Message message) onDelete;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onSecondaryTapUp: (details) =>
          unawaited(_show(context, details.globalPosition)),
      child: child,
    );
  }

  Future<void> _show(BuildContext context, Offset position) async {
    final overlay =
        Overlay.of(context).context.findRenderObject()! as RenderBox;
    final colors = Theme.of(context).colorScheme;
    final action = await showMenu<_MessageMenuAction>(
      context: context,
      position: RelativeRect.fromSize(
        Rect.fromLTWH(position.dx, position.dy, 0, 0),
        overlay.size,
      ),
      color: colors.surface,
      surfaceTintColor: colors.surface,
      shadowColor: colors.scrim.withValues(alpha: 0.24),
      elevation: 16,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(RetroMetrics.corner),
        side: BorderSide(color: colors.outlineVariant),
      ),
      menuPadding: const EdgeInsets.symmetric(
        vertical: RetroMetrics.spaceSmall,
      ),
      items: _items(context),
    );
    switch (action) {
      case _MessageMenuAction.copy:
        await Clipboard.setData(ClipboardData(text: message.body));
      case _MessageMenuAction.recall:
        await onRecall(message);
      case _MessageMenuAction.delete:
        await onDelete(message);
      case null:
        return;
    }
  }

  List<PopupMenuEntry<_MessageMenuAction>> _items(BuildContext context) {
    final items = <PopupMenuEntry<_MessageMenuAction>>[];
    if (message.kind == MessageKind.text) {
      items.add(_item(_MessageMenuAction.copy, Icons.copy_outlined, 'Copy'));
    }
    if (isMine && _canRecall(message.createdAt)) {
      items.add(_item(_MessageMenuAction.recall, Icons.undo_rounded, 'Recall'));
    } else {
      items.add(
        _item(
          _MessageMenuAction.delete,
          Icons.delete_outline_rounded,
          'Delete',
          color: Theme.of(context).colorScheme.error,
        ),
      );
    }
    return items;
  }

  PopupMenuItem<_MessageMenuAction> _item(
    _MessageMenuAction action,
    IconData icon,
    String label, {
    Color? color,
  }) {
    return PopupMenuItem(
      value: action,
      child: Row(
        children: [
          Icon(icon, size: 17, color: color),
          const SizedBox(width: 10),
          Text(label, style: TextStyle(color: color)),
        ],
      ),
    );
  }
}

bool _canRecall(DateTime createdAt) =>
    DateTime.now().toUtc().difference(createdAt.toUtc()) < _recallWindow;
