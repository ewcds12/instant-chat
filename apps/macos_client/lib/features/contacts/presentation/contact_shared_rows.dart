import 'package:flutter/material.dart';
import 'package:instant_chat/app/app_localizations.dart';
import 'package:instant_chat/core/theme/retro_theme.dart';
import 'package:instant_chat/features/messages/domain/message.dart';

class ContactSharedFileGroup extends StatelessWidget {
  const ContactSharedFileGroup({
    required this.files,
    required this.onOpen,
    super.key,
  });

  final List<MessageFile> files;
  final ValueChanged<MessageFile> onOpen;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: colors.surface.withValues(alpha: 0.84),
        border: Border.all(color: colors.outlineVariant),
        borderRadius: BorderRadius.circular(RetroMetrics.corner),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var index = 0; index < files.length; index++) ...[
            if (index > 0) const Divider(),
            _FileRow(file: files[index], onOpen: () => onOpen(files[index])),
          ],
        ],
      ),
    );
  }
}

class ContactSharedLinksRow extends StatelessWidget {
  const ContactSharedLinksRow({
    required this.count,
    required this.onTap,
    super.key,
  });

  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: colors.surface.withValues(alpha: 0.84),
      shape: RoundedRectangleBorder(
        side: BorderSide(color: colors.outlineVariant),
        borderRadius: BorderRadius.circular(RetroMetrics.corner),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: const Key('contact-shared-links'),
        onTap: onTap,
        child: SizedBox(
          height: RetroMetrics.contactSharedRowHeight,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Icon(Icons.link_rounded, color: colors.onSurfaceVariant),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    context.l10n.linksCount(count),
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: colors.outline,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ContactSharedEmptyRow extends StatelessWidget {
  const ContactSharedEmptyRow({
    required this.icon,
    required this.label,
    super.key,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      height: RetroMetrics.contactSharedRowHeight,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: colors.surface.withValues(alpha: 0.52),
        border: Border.all(color: colors.outlineVariant),
        borderRadius: BorderRadius.circular(RetroMetrics.corner),
      ),
      child: Row(
        children: [
          Icon(icon, color: colors.outline, size: 20),
          const SizedBox(width: 10),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _FileRow extends StatelessWidget {
  const _FileRow({required this.file, required this.onOpen});

  final MessageFile file;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isPdf = file.contentType == 'application/pdf';
    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: ValueKey('contact-shared-file-${file.id}'),
        onTap: onOpen,
        child: SizedBox(
          height: RetroMetrics.contactSharedRowHeight,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Icon(
                  isPdf
                      ? Icons.picture_as_pdf_rounded
                      : Icons.insert_drive_file_rounded,
                  color: isPdf ? colors.error : colors.primary,
                  size: 24,
                ),
                const SizedBox(width: 10),
                Expanded(child: _FileMetadata(file: file)),
                Icon(
                  Icons.chevron_right_rounded,
                  color: colors.outline,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FileMetadata extends StatelessWidget {
  const _FileMetadata({required this.file});

  final MessageFile file;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          file.filename,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(
            context,
          ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 2),
        Text(
          _formatBytes(file.byteSize),
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
        ),
      ],
    );
  }
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
