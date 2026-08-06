import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:instant_chat/core/theme/retro_theme.dart';
import 'package:instant_chat/features/messages/domain/message.dart';

const _recallWindow = Duration(minutes: 5);

enum _MessageMenuAction {
  reply,
  copy,
  translate,
  removeTranslation,
  translationSettings,
  recall,
  delete,
}

class MessageContextMenu extends StatelessWidget {
  const MessageContextMenu({
    required this.message,
    required this.isMine,
    required this.onRecall,
    required this.onDelete,
    this.onReply,
    this.onTranslate,
    this.onRemoveTranslation,
    this.onTranslationSettings,
    this.translationVisible = false,
    required this.child,
    super.key,
  });

  final Message message;
  final bool isMine;
  final Future<bool> Function(Message message) onRecall;
  final Future<bool> Function(Message message) onDelete;
  final ValueChanged<Message>? onReply;
  final Future<void> Function(Message message)? onTranslate;
  final Future<void> Function(Message message)? onRemoveTranslation;
  final Future<void> Function()? onTranslationSettings;
  final bool translationVisible;
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
      elevation: 12,
      constraints: const BoxConstraints.tightFor(
        width: RetroMetrics.messageMenuWidth,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(RetroMetrics.corner),
        side: BorderSide(color: colors.outlineVariant),
      ),
      menuPadding: const EdgeInsets.symmetric(
        vertical: RetroMetrics.messageMenuVerticalInset,
      ),
      items: _items(context),
    );
    switch (action) {
      case _MessageMenuAction.reply:
        onReply?.call(message);
      case _MessageMenuAction.copy:
        await Clipboard.setData(ClipboardData(text: message.body));
      case _MessageMenuAction.translate:
        await onTranslate?.call(message);
      case _MessageMenuAction.removeTranslation:
        await onRemoveTranslation?.call(message);
      case _MessageMenuAction.translationSettings:
        await onTranslationSettings?.call();
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
    if (onReply != null) {
      items.add(_item(_MessageMenuAction.reply, Icons.reply_rounded, 'Reply'));
    }
    if (message.kind == MessageKind.text) {
      items.add(_item(_MessageMenuAction.copy, Icons.copy_outlined, 'Copy'));
      if (onTranslate != null && onTranslationSettings != null) {
        items.add(
          _translationItem(
            context,
            action: translationVisible
                ? _MessageMenuAction.removeTranslation
                : _MessageMenuAction.translate,
            label: translationVisible ? 'Original' : 'Translate',
          ),
        );
      }
    }
    if (isMine && _canRecall(message.createdAt)) {
      items.add(
        _item(
          _MessageMenuAction.recall,
          Icons.undo_rounded,
          'Recall',
          color: Theme.of(context).colorScheme.error,
        ),
      );
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

  PopupMenuItem<_MessageMenuAction> _translationItem(
    BuildContext context, {
    required _MessageMenuAction action,
    required String label,
  }) {
    return PopupMenuItem(
      value: action,
      height: RetroMetrics.messageMenuItemHeight,
      padding: const EdgeInsets.symmetric(
        horizontal: RetroMetrics.messageMenuHorizontalInset,
      ),
      child: Row(
        children: [
          const Icon(
            Icons.translate_rounded,
            size: RetroMetrics.messageMenuIconSize,
          ),
          const SizedBox(width: RetroMetrics.messageMenuItemGap),
          Expanded(child: _MessageMenuLabel(label)),
          IconButton(
            key: const Key('message-translation-settings'),
            tooltip: 'Translation settings',
            visualDensity: VisualDensity.compact,
            constraints: const BoxConstraints.tightFor(
              width: RetroMetrics.messageMenuSettingsDiameter,
              height: RetroMetrics.messageMenuSettingsDiameter,
            ),
            padding: EdgeInsets.zero,
            onPressed: () =>
                Navigator.pop(context, _MessageMenuAction.translationSettings),
            icon: const Icon(
              Icons.settings_outlined,
              size: RetroMetrics.messageMenuSettingsIconSize,
            ),
          ),
        ],
      ),
    );
  }

  PopupMenuItem<_MessageMenuAction> _item(
    _MessageMenuAction action,
    IconData icon,
    String label, {
    Color? color,
  }) {
    return PopupMenuItem(
      value: action,
      height: RetroMetrics.messageMenuItemHeight,
      padding: const EdgeInsets.symmetric(
        horizontal: RetroMetrics.messageMenuHorizontalInset,
      ),
      child: Row(
        children: [
          Icon(icon, size: RetroMetrics.messageMenuIconSize, color: color),
          const SizedBox(width: RetroMetrics.messageMenuItemGap),
          _MessageMenuLabel(label, color: color),
        ],
      ),
    );
  }
}

class _MessageMenuLabel extends StatelessWidget {
  const _MessageMenuLabel(this.label, {this.color});

  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
        color: color,
        fontSize: RetroMetrics.messageMenuTextSize,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}

bool _canRecall(DateTime createdAt) =>
    DateTime.now().toUtc().difference(createdAt.toUtc()) < _recallWindow;
