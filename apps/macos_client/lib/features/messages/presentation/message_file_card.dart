import 'package:flutter/material.dart';
import 'package:instant_chat/app/app_localizations.dart';
import 'package:instant_chat/features/messages/domain/message.dart';

class MessageFileCard extends StatelessWidget {
  const MessageFileCard({
    required this.file,
    required this.isMine,
    required this.onOpen,
    this.openKey,
    super.key,
  });

  final MessageFile file;
  final bool isMine;
  final VoidCallback onOpen;
  final Key? openKey;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final accent = isMine ? colors.primary : colors.onSurfaceVariant;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        key: openKey,
        behavior: HitTestBehavior.opaque,
        onTap: onOpen,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 340),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colors.surface.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isMine
                  ? colors.primary.withValues(alpha: 0.22)
                  : colors.outlineVariant,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x140F172A),
                blurRadius: 22,
                offset: Offset(0, 12),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _FileIcon(color: accent),
              const SizedBox(width: 12),
              Flexible(child: _FileText(file: file)),
              const SizedBox(width: 12),
              _FileAction(color: accent),
            ],
          ),
        ),
      ),
    );
  }
}

class _FileIcon extends StatelessWidget {
  const _FileIcon({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 48,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(11),
      ),
      alignment: Alignment.center,
      child: Icon(Icons.insert_drive_file_outlined, color: color, size: 24),
    );
  }
}

class _FileText extends StatelessWidget {
  const _FileText({required this.file});

  final MessageFile file;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          file.filename,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: colors.onSurface,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${context.l10n.ui(_typeLabel(file.contentType))} · '
          '${_formatBytes(file.byteSize)}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
        ),
      ],
    );
  }
}

class _FileAction extends StatelessWidget {
  const _FileAction({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Icon(Icons.more_horiz_rounded, color: color, size: 17),
    );
  }
}

String _typeLabel(String contentType) {
  if (contentType == 'application/pdf') {
    return 'PDF Document';
  }
  if (contentType.contains('zip')) {
    return 'Archive';
  }
  if (contentType.startsWith('text/')) {
    return 'Text Document';
  }
  return 'File';
}

String _formatBytes(int bytes) {
  if (bytes >= 1024 * 1024) {
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
  if (bytes >= 1024) {
    return '${(bytes / 1024).toStringAsFixed(1)} KB';
  }
  return '$bytes B';
}
