import 'dart:async';
import 'dart:io';

import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';
import 'package:instant_chat/core/theme/retro_theme.dart';

class MessageDropZone extends StatefulWidget {
  const MessageDropZone({
    required this.disabled,
    required this.onFiles,
    required this.child,
    super.key,
  });

  final bool disabled;
  final Future<void> Function(List<MessageDroppedFile> files) onFiles;
  final Widget child;

  @override
  State<MessageDropZone> createState() => _MessageDropZoneState();
}

class _MessageDropZoneState extends State<MessageDropZone> {
  var _dragging = false;

  @override
  Widget build(BuildContext context) {
    return DropTarget(
      enable: !widget.disabled,
      onDragEntered: (_) => _setDragging(true),
      onDragExited: (_) => _setDragging(false),
      onDragDone: (details) {
        _setDragging(false);
        final files = details.files
            .map(MessageDroppedFile.new)
            .toList(growable: false);
        Timer.run(() {
          if (mounted) {
            unawaited(widget.onFiles(files));
          }
        });
      },
      child: Stack(
        fit: StackFit.expand,
        children: [widget.child, if (_dragging) const _DropOverlay()],
      ),
    );
  }

  void _setDragging(bool value) {
    if (mounted && _dragging != value) {
      setState(() => _dragging = value);
    }
  }
}

class MessageDroppedFile {
  const MessageDroppedFile(this._item);

  final DropItem _item;

  String get path => _item.path;
  bool get isDirectory => _item is DropItemDirectory;
  bool get isTemporary => _item.fromPromise;

  Future<T> withAccess<T>(Future<T> Function() action) async {
    final bookmark = _item.extraAppleBookmark;
    var accessStarted = false;
    if (bookmark != null && bookmark.isNotEmpty) {
      accessStarted = await DesktopDrop.instance
          .startAccessingSecurityScopedResource(bookmark: bookmark);
      if (!accessStarted) {
        throw const MessageDropAccessException();
      }
    }
    try {
      return await action();
    } finally {
      if (accessStarted) {
        try {
          await DesktopDrop.instance.stopAccessingSecurityScopedResource(
            bookmark: bookmark!,
          );
        } catch (_) {
          // Access also expires when the process exits; the upload is complete.
        }
      }
    }
  }

  Future<void> deleteTemporaryCopy() async {
    if (!isTemporary) {
      return;
    }
    try {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
    } on FileSystemException {
      // A failed cleanup must not turn a completed upload into a send failure.
    }
  }
}

class MessageDropAccessException implements Exception {
  const MessageDropAccessException();
}

class _DropOverlay extends StatelessWidget {
  const _DropOverlay();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return IgnorePointer(
      child: ColoredBox(
        key: const Key('message-drop-overlay'),
        color: colors.primaryContainer.withValues(alpha: 0.92),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: RetroMetrics.spaceLarge,
              vertical: RetroMetrics.spaceMedium,
            ),
            decoration: BoxDecoration(
              color: colors.surface,
              border: Border.all(
                color: colors.primary,
                width: RetroMetrics.border,
              ),
              borderRadius: BorderRadius.circular(RetroMetrics.cornerLarge),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.file_upload_outlined,
                  color: colors.primary,
                  size: RetroMetrics.spaceLarge,
                ),
                const SizedBox(width: RetroMetrics.spaceSmall),
                Text(
                  'Release to send',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
