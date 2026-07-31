import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:instant_chat/core/config/app_config.dart';
import 'package:instant_chat/core/network/api_response.dart';
import 'package:instant_chat/core/theme/retro_theme.dart';
import 'package:instant_chat/features/contacts/presentation/contact_shared_content.dart';
import 'package:instant_chat/features/contacts/presentation/contact_shared_rows.dart';
import 'package:instant_chat/features/messages/domain/message.dart';

class ContactSharedSection extends StatelessWidget {
  const ContactSharedSection({
    required this.value,
    required this.onRetry,
    required this.onSeeAll,
    required this.onOpenImage,
    required this.onOpenFile,
    required this.onOpenLinks,
    required this.accessToken,
    super.key,
  });

  final AsyncValue<ContactSharedContent> value;
  final VoidCallback onRetry;
  final VoidCallback onSeeAll;
  final ValueChanged<MessageImage> onOpenImage;
  final ValueChanged<MessageFile> onOpenFile;
  final ValueChanged<List<Uri>> onOpenLinks;
  final String accessToken;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SharedHeader(onSeeAll: onSeeAll),
        const SizedBox(height: 12),
        value.when(
          skipLoadingOnReload: true,
          skipError: true,
          loading: () => const _SharedLoading(),
          error: (_, _) => _SharedFailure(onRetry: onRetry),
          data: (content) => content.isEmpty
              ? const _SharedEmpty()
              : _SharedContent(
                  content: content,
                  accessToken: accessToken,
                  onOpenImage: onOpenImage,
                  onOpenFile: onOpenFile,
                  onOpenLinks: onOpenLinks,
                ),
        ),
      ],
    );
  }
}

class _SharedHeader extends StatelessWidget {
  const _SharedHeader({required this.onSeeAll});

  final VoidCallback onSeeAll;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text('Shared', style: Theme.of(context).textTheme.titleLarge),
        ),
        TextButton.icon(
          key: const Key('contact-shared-see-all'),
          onPressed: onSeeAll,
          iconAlignment: IconAlignment.end,
          icon: const Icon(Icons.chevron_right_rounded, size: 20),
          label: const Text('See All'),
        ),
      ],
    );
  }
}

class _SharedContent extends StatelessWidget {
  const _SharedContent({
    required this.content,
    required this.accessToken,
    required this.onOpenImage,
    required this.onOpenFile,
    required this.onOpenLinks,
  });

  final ContactSharedContent content;
  final String accessToken;
  final ValueChanged<MessageImage> onOpenImage;
  final ValueChanged<MessageFile> onOpenFile;
  final ValueChanged<List<Uri>> onOpenLinks;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (content.images.isNotEmpty) ...[
          _MediaStrip(
            images: content.images.take(3).toList(growable: false),
            accessToken: accessToken,
            onOpen: onOpenImage,
          ),
          const SizedBox(height: RetroMetrics.spaceMedium),
        ],
        if (content.files.isNotEmpty)
          ContactSharedFileGroup(
            files: content.files.take(2).toList(growable: false),
            onOpen: onOpenFile,
          )
        else
          const ContactSharedEmptyRow(
            icon: Icons.insert_drive_file_outlined,
            label: 'No shared files yet',
          ),
        const SizedBox(height: RetroMetrics.spaceMedium),
        if (content.links.isNotEmpty)
          ContactSharedLinksRow(
            count: content.links.length,
            onTap: () => onOpenLinks(content.links),
          )
        else
          const ContactSharedEmptyRow(
            icon: Icons.link_rounded,
            label: 'No shared links yet',
          ),
      ],
    );
  }
}

class _MediaStrip extends StatelessWidget {
  const _MediaStrip({
    required this.images,
    required this.accessToken,
    required this.onOpen,
  });

  final List<MessageImage> images;
  final String accessToken;
  final ValueChanged<MessageImage> onOpen;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = RetroMetrics.contactSharedThumbnailGap;
        final width = (constraints.maxWidth - gap * 2) / 3;
        final height = math.min(
          width,
          RetroMetrics.contactSharedThumbnailMaxHeight,
        );
        return Row(
          key: const Key('contact-shared-media-strip'),
          children: [
            for (var index = 0; index < images.length; index++) ...[
              if (index > 0) const SizedBox(width: gap),
              SizedBox(
                width: width,
                height: height,
                child: _MediaThumbnail(
                  image: images[index],
                  accessToken: accessToken,
                  onOpen: () => onOpen(images[index]),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _MediaThumbnail extends StatelessWidget {
  const _MediaThumbnail({
    required this.image,
    required this.accessToken,
    required this.onOpen,
  });

  final MessageImage image;
  final String accessToken;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: colors.surfaceContainer,
      borderRadius: BorderRadius.circular(
        RetroMetrics.contactSharedThumbnailRadius,
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: ValueKey('contact-shared-image-${image.id}'),
        onTap: onOpen,
        child: Image.network(
          Uri.parse(AppConfig.apiBaseUrl).resolve(image.url).toString(),
          headers: bearerAuthorization(accessToken),
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) =>
              Icon(Icons.broken_image_outlined, color: colors.onSurfaceVariant),
        ),
      ),
    );
  }
}

class _SharedLoading extends StatelessWidget {
  const _SharedLoading();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 112,
      child: Center(child: CircularProgressIndicator()),
    );
  }
}

class _SharedFailure extends StatelessWidget {
  const _SharedFailure({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return _SharedStatus(
      icon: Icons.cloud_off_outlined,
      message: 'Shared content is unavailable.',
      action: TextButton(onPressed: onRetry, child: const Text('Try Again')),
    );
  }
}

class _SharedEmpty extends StatelessWidget {
  const _SharedEmpty();

  @override
  Widget build(BuildContext context) {
    return const _SharedStatus(
      icon: Icons.photo_library_outlined,
      message: 'No shared photos, files, or links yet.',
    );
  }
}

class _SharedStatus extends StatelessWidget {
  const _SharedStatus({required this.icon, required this.message, this.action});

  final IconData icon;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      height: 112,
      decoration: BoxDecoration(
        color: colors.surface.withValues(alpha: 0.56),
        border: Border.all(color: colors.outlineVariant),
        borderRadius: BorderRadius.circular(RetroMetrics.corner),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: colors.onSurfaceVariant),
          const SizedBox(width: 10),
          Text(
            message,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
          ),
          if (action != null) ...[const SizedBox(width: 8), action!],
        ],
      ),
    );
  }
}
